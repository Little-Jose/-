@echo off
chcp 65001 >nul
echo ==========================================
echo          正在提交并推送 Godot 项目...
echo ==========================================

git add .

:: 如果没有修改，就跳过 commit 直接推
git commit -m "自动备份：%date% %time%" >nul 2>&1

echo 正在推送到 GitHub...
:: 尝试推送，如果超时10秒没反应，自动重试一次
git push -u origin main
if %errorlevel% neq 0 (
    echo 推送超时，正在重试...
    git push -u origin main
)

echo.
echo ==========================================
echo              操作完成！
echo ==========================================
pause