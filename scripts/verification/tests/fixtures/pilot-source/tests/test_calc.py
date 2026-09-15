# 合成題材の再現テスト（試験専用）。再実行では .verification-tests/ 直下に置き、作業ディレクトリ（題材のルート）から calc を import する。
import unittest

import calc


class AddTest(unittest.TestCase):
    def test_add_returns_sum(self):
        self.assertEqual(calc.add(1, 2), 3)


if __name__ == "__main__":
    unittest.main()
