@echo off
chcp 65001 >nul
echo ==========================================
echo          正在准备提交 Godot 项目...
echo ==========================================

:: 1. 先把所有修改放入暂存区
git add .

:: 2. 提示你输入本次的修改说明
set /p msg="请输入本次更新的说明（比如：完成了主角跳跃）: "

:: 3. 自动获取当前时间，并格式化为：年-月-日 时:分:秒
:: 这段代码会去调用系统的日期和时间，替换掉默认格式
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
    set year=%%a
    set month=%%b
    set day=%%c
)
for /f "tokens=1-2 delims=:." %%a in ('echo %time%') do (
    set hour=%%a
    set minute=%%b
)

:: 4. 把输入的备注和时间拼在一起
if "%msg%"=="" (
    set "commit_msg=[自动备份] %year%-%month%-%day% %hour%:%minute%"
) else (
    set "commit_msg=%msg% - %year%-%month%-%day% %hour%:%minute%"
)

:: 5. 执行提交
echo.
echo 正在提交：%commit_msg%
git commit -m "%commit_msg%"

:: 6. 推送到 GitHub
echo.
echo 正在推送到 GitHub...
git push

echo.
echo ==========================================
echo              操作完成！
echo ==========================================
pause