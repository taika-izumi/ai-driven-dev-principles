# 隔離検証の試作用の合成題材（試験専用）。既知の欠陥を1つだけ持つ: add が和ではなく差を返す。
# 修正版は ../replacements/calc.py、欠陥を再現するテストは ../tests/test_calc.py。


def add(a, b):
    return a - b
