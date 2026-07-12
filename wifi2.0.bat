@echo off
chcp 1251 >nul
setlocal enabledelayedexpansion

set "BackupDir=C:\WiFiBackup"

:MainMenu
cls
echo === Управление профилями Wi-Fi (Windows 11) ===
echo.
echo Выберите действие:
echo 1 — Сохранить (экспортировать) профили Wi-Fi
echo 2 — Восстановить (импортировать) профили Wi-Fi
echo 3 — Показать список профилей
echo 0 — Выход
echo.
set /p Choice="Ваш выбор (0-3): "

if "%Choice%"=="1" goto BackupWiFi
if "%Choice%"=="2" goto RestoreWiFi
if "%Choice%"=="3" goto ShowProfiles
if "%Choice%"=="0" goto EndScript

echo Неверный выбор. Нажмите любую клавишу...
pause >nul
goto MainMenu

:BackupWiFi
echo.
echo Папка для бэкапа: %BackupDir%
if not exist "%BackupDir%" (
    echo Создаю папку %BackupDir%...
    mkdir "%BackupDir%"
)

echo.
echo Внимание: пароли будут сохранены в открытом виде в XML-файлах.
set /p ConfirmBackup="Вы уверены, что хотите экспортировать профили? (y/n): "
if /i not "%ConfirmBackup%"=="y" (
    echo Экспорт отменён.
    pause
    goto MainMenu
)

echo Выполняю экспорт профилей...
netsh wlan export profile key=clear folder="%BackupDir%" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Успешно! Файлы сохранены в: %BackupDir%
    echo В папке будут XML-файлы по одному на каждый профиль.
) else (
    echo.
    echo Ошибка при экспорте. Запустите скрипт от имени администратора.
)
pause
goto MainMenu

:RestoreWiFi
echo.
echo Папка с бэкапом: %BackupDir%
if not exist "%BackupDir%" (
    echo Папка %BackupDir% не найдена. Сначала выполните экспорт (пункт 1).
    pause
    goto MainMenu
)

set /p Scope="Для какого пользователя восстанавливать? (1=текущий, 2=все пользователи): "
if "%Scope%"=="1" (
    set "UserParam=user=current"
) else if "%Scope%"=="2" (
    set "UserParam=user=all"
) else (
    echo Неверный выбор, по умолчанию — текущий пользователь.
    set "UserParam=user=current"
)

echo.
echo Файлы для восстановления в %BackupDir%:
dir "%BackupDir%\*.xml" /b
echo.
set /p ConfirmRestore="Начать восстановление всех профилей из этой папки? (y/n): "
if /i not "%ConfirmRestore%"=="y" (
    echo Восстановление отменено.
    pause
    goto MainMenu
)

echo Начинаю импорт профилей...
set "Count=0"
for %%f in ("%BackupDir%\*.xml") do (
    set /a Count+=1
    echo [%Count%] Восстанавливаю: %%~nxf
    netsh wlan add profile filename="%%f" %UserParam% >nul 2>&1
    if %errorlevel% equ 0 (
        echo   OK
    ) else (
        echo   Ошибка (возможно, профиль уже существует или нет прав).
    )
)

if %Count% equ 0 (
    echo В папке нет XML-файлов.
) else (
    echo Готово. Обработано профилей: %Count%
)
pause
goto MainMenu

:ShowProfiles
echo.
netsh wlan show profiles
echo.
pause
goto MainMenu

:EndScript
endlocal
exit /b 0
