@echo off
chcp 1251 >nul
setlocal enabledelayedexpansion

set "BackupDir=%~dp0WiFiBackup"
set "ReportFile=%BackupDir%\WiFi_Summary.txt"

if not exist "%BackupDir%" mkdir "%BackupDir%"

:: Проверка прав администратора
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

:: Проверка: появились ли XML-файлы
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
    echo Тип безопасности — аутентификация (запрошено у netsh)
    echo Пароль — извлечён из XML-файла
    echo Файл — имя XML-файла профиля
    echo ---------------------------------------------------------------
) > "%ReportFile%"

set "Count=0"

:: Перебираем все XML-файлы в папке
for %%f in ("%BackupDir%\Wi-Fi-*.xml" "%BackupDir%\беспроводная сеть-*.xml") do (
    set /a Count+=1
    set "XmlFile=%%~nxf"
    set "XmlPath=%%f"

    :: Извлекаем SSID: убираем префикс и расширение .xml
    set "TmpName=!XmlFile!"
    
    :: Убираем "Wi-Fi-"
    if "!TmpName:~0,7!"=="Wi-Fi-" set "TmpName=!TmpName:~7!"
    :: Убираем "беспроводная сеть-"
    if "!TmpName:~0,18!"=="беспроводная сеть-" set "TmpName=!TmpName:~18!"
    
    :: Удаляем ".xml" в конце
    set "SSID=!TmpName:.xml=!"

    :: Получаем тип аутентификации через netsh по имени SSID
    set "AuthType=Неизвестно"
    for /f "tokens=2*" %%c in ('netsh wlan show profile name^="!SSID!" ^| findstr /i "Аутентификация"') do set "AuthType=%%d"
    if "!AuthType!"=="Неизвестно" (
        for /f "tokens=2*" %%c in ('netsh wlan show profile name^="!SSID!" ^| findstr /i "Authentication"') do set "AuthType=%%d"
    )

    :: Извлекаем пароль из XML-файла
    set "Password=Не найден"
    for /f "delims=" %%p in ('findstr /i "<keyMaterial>" "!XmlPath!"') do (
        set "Line=%%p"
        :: Удаляем пробелы в начале и конце
        for /f "tokens=*" %%a in ("!Line!") do set "Line=%%a"
        :: Извлекаем текст между <keyMaterial> и </keyMaterial>
        set "Line=!Line:*<keyMaterial>=!"
        for /f "delims=<" %%a in ("!Line!") do set "Password=%%a"
        :: Убираем возможные пробелы
        set "Password=!Password: =!"
    )

    (
        echo SSID: !SSID!
        echo Тип безопасности: !AuthType!
        echo Пароль: !Password!
        echo Файл: !XmlFile!
        echo ---------------------------------------------------------------
    ) >> "%ReportFile%"
)

if %Count% equ 0 (
    echo.
    echo ВНИМАНИЕ: в папке не найдено XML-файлов с шаблонами Wi-Fi-* или беспроводная сеть-*.
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