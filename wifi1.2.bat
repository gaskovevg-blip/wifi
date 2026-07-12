@echo off
chcp 1251 >nul
setlocal enabledelayedexpansion

set "BackupDir=%~dp0WiFiBackup"
set "ReportFile=%BackupDir%\WiFi_Summary.txt"

if not exist "%BackupDir%" mkdir "%BackupDir%"

:: Proverka prav administratora
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ОШИБКА: нужен запуск ОТ ИМЕНИ АДМИНИСТРАТОРА.
    pause
    exit /b 1
)

echo === Экспорт Wi-Fi профилей (по файлам) ===
echo Папка: %BackupDir%
echo.

set /p Confirm="Экспортировать профили (пароли будут в XML)? (y/n): "
if /i not "%Confirm%"=="y" exit /b 0

echo Выполняю экспорт профилей...
netsh wlan export profile key=clear folder="%BackupDir%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Ошибка экспорта netsh.
    pause
    exit /b 1
)

:: Proverka: poyavilis' li XML-fayly
dir "%BackupDir%\*.xml" >nul 2>&1
if errorlevel 1 (
    echo В папке нет XML-файлов после экспорта. Что-то пошло не так.
    pause
    exit /b 1
)
echo Экспорт завершён. Формирую отчёт по файлам...

(
    echo === Сводный отчёт по Wi-Fi профилям ===
    echo Дата: %date% %time%
    echo Папка с XML: %BackupDir%
    echo.
    echo SSID — имя сети (из имени XML-файла)
    echo Пароль — извлечён из XML-файла
    echo Файл — имя XML-файла профиля
    echo ---------------------------------------------------------------
) > "%ReportFile%"

set "Count=0"

:: Perebiraem vse XML-fayly v papke
for %%f in ("%BackupDir%\*.xml") do (
    set /a Count+=1
    set "XmlFile=%%~nxf"
    set "XmlPath=%%f"

    :: Izvlekaem SSID iz imeni fayla (bez rasshireniya)
    set "SSID=%%~nf"
    
    :: Ubirayem prefiks "Беспроводная сеть-" esli est'
    set "SSID=!SSID:Беспроводная сеть-=!"
    set "SSID=!SSID:Wi-Fi-=!"

    :: Izvlekaem parol iz XML-fayla s pomoshchyu type (dlya UTF-8)
    set "Password=Не найден"
    for /f "delims=" %%p in ('type "!XmlPath!" ^| findstr /i "<keyMaterial>"') do (
        set "Line=%%p"
        for /f "tokens=2 delims=<>" %%a in ("!Line!") do set "Password=%%a"
    )

    (
        echo SSID: !SSID!
        echo Пароль: !Password!
        echo Файл: !XmlFile!
        echo ---------------------------------------------------------------
    ) >> "%ReportFile%"
)

if %Count% equ 0 (
    echo.
    echo ВНИМАНИЕ: в папке не найдено XML-файлов.
    echo Проверь содержимое папки:
    dir "%BackupDir%" /b
) else (
    echo Готово. Обработано профилей: %Count%.
)

echo.
echo Отчёт: %ReportFile%
pause
endlocal
exit /b 0
