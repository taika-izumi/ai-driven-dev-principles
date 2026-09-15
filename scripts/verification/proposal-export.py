#!/usr/bin/env python3
# 提案用VMの中で、子（Codex）の作業先 /home/agent/workspace/proposal を ProposalEnvelopeV3 の JSON 1行へ変換する固定エクスポーター。
# 外側（Proposal.psm1）が子の実行後に sbx cp で搬入し、固定 argv の python3 で起動する。標準ライブラリだけを使う。
# この出力は子に改変されうる VM 内の処理の結果なので、外側は全面的に検査する（仕様02「提案書式と回収」）。ここでの選別は外側の検査を置き換えない。
#
# 出力（stdout に1行、ASCII のみ）:
#   {"schemaVersion":3,"runId":...,"summary":...,"findings":[...],"files":[{"kind","path","contentBase64"}],"truncated":bool}
# - files: tests/ 配下の test_*.py と __init__.py（kind=test、path は tests/ を除いた相対名）、replacements/ 配下の *.py（kind=replacement、path は replacements/ を除いた相対名）。
# - summary・findings: proposal.json の同名キーをそのまま渡す（読めなければ null。外側の型検査で拒否される）。
# - truncated: 上限（件数・1ファイル・合計）を超えたファイル、またはリンク・通常ファイル以外の候補を含めなかったときに true。
#   外側はこれを拒否理由にする（切り詰めた提案を成功にしない）。
import argparse
import base64
import json
import os
import stat
import sys

ROOT = "/home/agent/workspace/proposal"


def read_regular(path, limit):
    """リンクをたどらずに通常ファイルを limit バイトまで読む。通常ファイルでなければ ('not-regular', None)、上限超過なら ('too-large', None)。"""
    try:
        fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    except OSError:
        return "not-regular", None
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            return "not-regular", None
        chunks = []
        remaining = limit + 1
        while remaining > 0:
            chunk = os.read(fd, min(remaining, 1024 * 1024))
            if not chunk:
                break
            chunks.append(chunk)
            remaining -= len(chunk)
        data = b"".join(chunks)
        if len(data) > limit:
            return "too-large", None
        return "ok", data
    finally:
        os.close(fd)


def reject_constant(name):
    raise ValueError("non-finite number: " + name)


def reject_duplicates(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key: " + key)
        result[key] = value
    return result


def read_metadata(limit):
    state, data = read_regular(os.path.join(ROOT, "proposal.json"), limit)
    if state != "ok":
        return None, None
    try:
        value = json.loads(data.decode("utf-8"), parse_constant=reject_constant, object_pairs_hook=reject_duplicates)
    except ValueError:
        return None, None
    if not isinstance(value, dict):
        return None, None
    return value.get("summary"), value.get("findings")


def is_candidate(kind, name):
    if kind == "test":
        return name == "__init__.py" or (name.startswith("test_") and name.endswith(".py"))
    return name.endswith(".py")


def collect(kind, directory, limits, state):
    top = os.path.join(ROOT, directory)
    try:
        top_mode = os.lstat(top).st_mode
    except OSError:
        return
    if not stat.S_ISDIR(top_mode):
        state["truncated"] = True
        return
    for current, dirnames, filenames in os.walk(top, followlinks=False):
        dirnames.sort()
        for name in list(dirnames):
            # リンクされたディレクトリはたどらない。中に候補があっても再現できないので不完全として印を付ける。
            if os.path.islink(os.path.join(current, name)):
                state["truncated"] = True
                dirnames.remove(name)
        for name in sorted(filenames):
            if not is_candidate(kind, name):
                continue
            full = os.path.join(current, name)
            relative = os.path.relpath(full, top).replace(os.sep, "/")
            if len(state["files"]) >= limits.max_files:
                state["truncated"] = True
                continue
            status, data = read_regular(full, limits.max_file_bytes)
            if status != "ok":
                state["truncated"] = True
                continue
            if state["total"] + len(data) > limits.max_proposal_bytes:
                state["truncated"] = True
                continue
            state["total"] += len(data)
            state["files"].append({"kind": kind, "path": relative, "contentBase64": base64.b64encode(data).decode("ascii")})


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--max-files", type=int, required=True)
    parser.add_argument("--max-file-bytes", type=int, required=True)
    parser.add_argument("--max-proposal-bytes", type=int, required=True)
    limits = parser.parse_args()
    state = {"files": [], "total": 0, "truncated": False}
    summary, findings = read_metadata(limits.max_file_bytes)
    try:
        root_ok = stat.S_ISDIR(os.lstat(ROOT).st_mode)
    except OSError:
        root_ok = False
    if root_ok:
        collect("test", "tests", limits, state)
        collect("replacement", "replacements", limits, state)
    envelope = {
        "schemaVersion": 3,
        "runId": limits.run_id,
        "summary": summary,
        "findings": findings,
        "files": state["files"],
        "truncated": state["truncated"],
    }
    try:
        line = json.dumps(envelope, ensure_ascii=True, separators=(",", ":"), allow_nan=False)
    except ValueError:
        envelope["summary"] = None
        envelope["findings"] = None
        line = json.dumps(envelope, ensure_ascii=True, separators=(",", ":"))
    sys.stdout.write(line + "\n")
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    sys.exit(main())
