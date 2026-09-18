@echo off
rem 偽sbx（試験専用）。同ディレクトリの FakeSbx.ps1 を、複製時に埋め込んだ pwsh の絶対パスで起動する。
rem SbxRuntime が渡す環境辞書の PATH は sbx の親ディレクトリだけなので、PATH に依存しない。__PWSH__ は試験側が複製時に置き換える。
"__PWSH__" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0FakeSbx.ps1" %*
exit /b %ERRORLEVEL%
