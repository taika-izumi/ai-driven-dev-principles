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


BOM = b"\xef\xbb\xbf"


def find_bom_offsets(raw):
    """BOM の混入位置を返す（ファイル先頭、および各行の先頭）。

    ストアは追記専用のため、BOM はファイル頭だけでなく「追記チャンクの先頭」= 行頭にも
    混入しうる（Issue-0032）。頭だけを見る実装ではそれを取り逃がす。
    一方、JSON 文字列値の内部に現れる U+FEFF は行頭に来ないため、行頭に限定することで
    誤検出を避けつつ実際の混入経路を捕捉できる。
    """
    offsets = []
    if raw.startswith(BOM):
        offsets.append(0)
    pos = 0
    while True:
        nl = raw.find(b"\n", pos)
        if nl == -1:
            break
        start = nl + 1
        if raw.startswith(BOM, start):
            offsets.append(start)
        pos = start
    return offsets


def check_file(path):
    """1 ファイルを検査し、違反メッセージのリストを返す（空なら健全）。"""
    violations = []
    with open(path, "rb") as f:
        raw = f.read()

    bom_offsets = find_bom_offsets(raw)
    if bom_offsets:
        head = "先頭" if bom_offsets[0] == 0 else "中途"
        violations.append(
            f"BOM が {len(bom_offsets)} 箇所ある（最初は{head}・バイト位置 {bom_offsets[0]}。"
            f"全位置: {bom_offsets}）"
        )

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
    """検出器の検出力を確かめる（正の対照 = 既知の欠陥で発火するか、負の対照 = 誤検出しないか）。"""
    cases = [
        ("CRLF", b'{"a":1}\r\n{"a":2}\n', "CR を"),
        ("先頭 BOM", b'\xef\xbb\xbf{"a":1}\n', "BOM が"),
        # 追記チャンクの先頭に混入した BOM。頭だけを見る実装では取り逃がす
        ("中途 BOM", b'{"a":1}\n\xef\xbb\xbf{"a":2}\n', "BOM が"),
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
        negatives = [
            (
                "clean",
                [
                    {"v": 2, "id": "X-2026-01-01-01"},
                    {"v": 2, "id": "X-2026-01-01-02", "t": "日本語"},
                ],
            ),
            # JSON 文字列値の内部に現れる U+FEFF は行頭に来ないため BOM ではない。
            # 「全バイト走査で BOM を探す」実装だとここを誤検出する（粒度の対照）
            (
                "値の内部に U+FEFF",
                [{"v": 2, "id": "X-2026-01-01-03", "t": "前" + chr(0xFEFF) + "後"}],
            ),
        ]
        for label, rows in negatives:
            p = os.path.join(d, f"negative_{label}.jsonl")
            with open(p, "w", encoding="utf-8", newline="\n") as f:
                for row in rows:
                    f.write(json.dumps(row, ensure_ascii=False) + "\n")
            # 空振り防止ガード: 不可視文字を仕込む対照は、
            # 入力側からその文字が失われても素通りして PASS する。仕込んだバイト列が
            # 実在することを先に確かめる。アサーション側だけでは入力側の欠落を検出できない
            if label == "値の内部に U+FEFF":
                written = open(p, "rb").read()
                if BOM not in written:
                    failures.append("負の対照 [値の内部に U+FEFF] の入力に U+FEFF が入っていない（対照が空振り）")
                    print("  負の対照 [値の内部に U+FEFF]: 入力不備（U+FEFF 不在）")
                    continue
            got = check_file(p)
            print(f"  負の対照 [{label}]: {'誤検出なし' if not got else '誤検出'} -> {got}")
            if got:
                failures.append(f"負の対照 [{label}] が誤検出した: {got}")

    if failures:
        print("[self-test] FAIL")
        for f_ in failures:
            print(f"  - {f_}")
        return 1
    print(f"[self-test] PASS（正の対照 {len(cases)} 件が発火、負の対照 {len(negatives)} 件は誤検出なし）")
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
