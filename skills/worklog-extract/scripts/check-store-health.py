#!/usr/bin/env python3
"""中央ストアのバイト健全性を検査する（ADR-0054 の契約: UTF-8 / BOM なし / LF 固定 / 全行 JSON パース可能）。

grep 系では CR を検出できないため、バイト列を直接数える。
--self-test は検出器自身の検出力を確かめる（正の対照 = 既知の欠陥で発火するか、
負の対照 = 正常な入力を誤検出しないか）。検査が緑であることの意味を保つために必須。
"""
import argparse
import json
import os
import sys
import tempfile

TARGET_SUFFIXES = (".jsonl", ".json")


def check_file(path):
    """1 ファイルを検査し、違反メッセージのリストを返す（空なら健全）。"""
    violations = []
    with open(path, "rb") as f:
        raw = f.read()

    if raw[:3] == b"\xef\xbb\xbf":
        violations.append("BOM が付いている")

    cr = raw.count(b"\r")
    if cr:
        violations.append(f"CR を {cr} 個含む（LF 固定契約に違反）")

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as e:
        violations.append(f"UTF-8 として復号できない: {e}")
        return violations

    if path.endswith(".jsonl"):
        for i, line in enumerate(text.split("\n"), 1):
            if not line.strip():
                continue
            try:
                json.loads(line)
            except json.JSONDecodeError as e:
                violations.append(f"{i} 行目が JSON としてパースできない: {e}")
    else:
        try:
            json.loads(text)
        except json.JSONDecodeError as e:
            violations.append(f"JSON としてパースできない: {e}")

    return violations


def collect_targets(root):
    targets = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in sorted(filenames):
            if name.endswith(TARGET_SUFFIXES):
                targets.append(os.path.join(dirpath, name))
    return sorted(targets)


def run_check(root):
    """ストア全体を検査する。違反があれば 1、無ければ 0 を返す。"""
    targets = collect_targets(root)
    if not targets:
        print(f"[check-store-health] 対象ファイルが見つからない: {root}")
        return 1

    total = 0
    for path in targets:
        violations = check_file(path)
        rel = os.path.relpath(path, root)
        if violations:
            total += len(violations)
            for v in violations:
                print(f"  NG {rel}: {v}")
        else:
            print(f"  OK {rel}")

    if total:
        print(f"[check-store-health] 違反 {total} 件。走査を中止する（ADR-0054: silent tolerance はしない）")
        return 1
    print(f"[check-store-health] {len(targets)} ファイルすべて健全")
    return 0


def self_test():
    """検出器の検出力を確かめる。正の対照 4 件と負の対照 1 件。"""
    cases = [
        ("CRLF", b'{"a":1}\r\n{"a":2}\n', "CR を"),
        ("BOM", b'\xef\xbb\xbf{"a":1}\n', "BOM"),
        ("非 UTF-8", b'{"a":"\xff\xfe"}\n', "UTF-8 として復号できない"),
        ("壊れた JSON", b'{"a":1}\n{"a":\n', "JSON としてパースできない"),
    ]
    failures = []

    with tempfile.TemporaryDirectory() as d:
        # 正の対照: 既知の欠陥それぞれで発火するか
        for label, payload, expected_fragment in cases:
            p = os.path.join(d, f"positive_{label}.jsonl")
            with open(p, "wb") as f:
                f.write(payload)
            got = check_file(p)
            hit = any(expected_fragment in v for v in got)
            print(f"  正の対照 [{label}]: {'発火' if hit else '未発火'} -> {got}")
            if not hit:
                failures.append(f"正の対照 [{label}] が発火しなかった")

        # 負の対照: 正常な入力を誤検出しないか
        p = os.path.join(d, "negative_clean.jsonl")
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(json.dumps({"v": 2, "id": "X-2026-01-01-01"}, ensure_ascii=False) + "\n")
            f.write(json.dumps({"v": 2, "id": "X-2026-01-01-02", "t": "日本語"}, ensure_ascii=False) + "\n")
        got = check_file(p)
        print(f"  負の対照 [clean]: {'誤検出なし' if not got else '誤検出'} -> {got}")
        if got:
            failures.append(f"負の対照が誤検出した: {got}")

    if failures:
        print("[self-test] FAIL")
        for f_ in failures:
            print(f"  - {f_}")
        return 1
    print("[self-test] PASS（正の対照 4 件が発火、負の対照 1 件は誤検出なし）")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.join(os.path.expanduser("~"), ".ai-dev-worklog"))
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    return run_check(args.root)


if __name__ == "__main__":
    sys.exit(main())
