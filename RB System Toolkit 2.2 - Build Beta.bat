@echo off

:: ==========================================================
:: Verifica se esta como administrador
:: ==========================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: ==========================================================
:: RB SYSTEM TOOLKIT - INFORMACOES
:: ==========================================================

set "ToolkitVersion=2.2"
set "ToolkitEdition=EasterEgg Edition"
set "ToolkitAuthor=Relbety"

:: Sera utilizado futuramente
set "ToolkitGithub=" 
set "UpdateAvailable=0"
set "LatestVersion="
set "LatestDate="
set "LatestNotes="

:: ==========================================================
:: CONFIGURACAO DA JANELA
:: ==========================================================

title RB System Toolkit %ToolkitVersion%
color 0A

for /F "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

mode con: cols=60 lines=20

:menu
cls
echo ================================
echo     RB SYSTEM TOOLKIT 2.2
echo          Por Relbety
echo       EasterEgg Edition
echo ================================
echo.
echo 1 - Informacoes do Sistema
echo 2 - Limpeza Pesada
echo 3 - Limpar Cache DNS
echo 4 - Limpar Windows Update
echo 5 - Abrir Limpeza de Disco
echo 6 - Verificar Atualizacoes de Apps Pendentes
echo 7 - Reparar Arquivos do Windows
echo 8 - WinUtil
echo 9 - Sair
echo.
set /p opcao=Escolha uma opcao:

if "%opcao%"=="1" goto infosistema
if "%opcao%"=="2" goto pesada
if "%opcao%"=="3" goto dns
if "%opcao%"=="4" goto winupdate
if "%opcao%"=="5" goto cleanmgr
if "%opcao%"=="6" goto apps
if "%opcao%"=="8" goto ativar
if "%opcao%"=="9" exit /b
if /I "%opcao%"=="relbety" goto secreto
goto menu

:infosistema
cls
color 0A

echo ================================
echo    INFORMACOES DO SISTEMA
echo ================================
echo.

echo Nome do PC:
hostname

echo.
echo Windows:
for /f "tokens=2 delims==" %%a in ('wmic os get Caption /value ^| find "="') do (
echo %%a
)

echo.

echo Processador:
for /f "skip=1 delims=" %%a in ('wmic cpu get name') do (
if not "%%a"=="" (
echo %%a
goto cpuOK
)
)
:cpuOK

echo.
echo Memoria RAM:

for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB)"') do (
echo %%a GB
)

echo.
echo Placa de Video:
for /f "skip=1 delims=" %%a in ('wmic path win32_videocontroller get name') do (
if not "%%a"=="" (
echo %%a
goto gpuOK
)
)
:gpuOK

echo.
echo Espaco em disco:
echo.

for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | ForEach-Object { '{0} Livre {1} GB / Total {2} GB' -f $_.DeviceID,[math]::Round($_.FreeSpace/1GB),[math]::Round($_.Size/1GB) }"') do (
echo %%a
)

echo.
echo ================================

pause
goto menu

:pesada
cls
color 0A

echo ========================================
echo          LIMPEZA PESADA
echo ========================================
echo.
echo Serao removidos:
echo.
echo - Arquivos temporarios do Windows
echo - Arquivos temporarios do usuario
echo - Cache do Windows Update
echo - Arquivos recentes
echo - Lixeira
echo.
echo Pastas de aplicativos serao preservadas.
echo.

set /p confirmar=Deseja continuar? [Y/N]:

if /I "%confirmar%"=="N" goto menu
if /I not "%confirmar%"=="Y" goto pesada

for /f "delims=" %%a in ('powershell -NoProfile -Command "[int]((Get-PSDrive C).Free/1MB)"') do (
    set "LivreAntes=%%a"
)

echo Livre Antes = %LivreAntes%
timeout /t 3 /nobreak >nul

cls
color 0A

echo ========================================
echo        EXECUTANDO LIMPEZA...
echo ========================================
echo.

echo [1/5] Limpando TEMP do usuario...

:: Remove apenas arquivos da raiz do TEMP
del /f /q "%TEMP%\*" >nul 2>&1

:: Remove arquivos temporários conhecidos das subpastas
for %%E in (tmp temp log bak old) do (
    del /f /s /q "%TEMP%\*.%%E" >nul 2>&1
)

:: NÃO remove pastas do TEMP.
:: Isso vai evitar de eu fazer merda denovo e apagar meus clipes da Nvidea, se apagar mais uma vez, eu me mato na frente da micro e soft.

echo [2/5] Limpando TEMP do Windows...

del /f /s /q "%WINDIR%\Temp\*" >nul 2>&1

for /d %%d in ("%WINDIR%\Temp\*") do (
    rd /s /q "%%d" >nul 2>&1
)

echo [3/5] Limpando cache do Windows Update...

net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

if exist "%WINDIR%\SoftwareDistribution\Download" (
    del /f /s /q "%WINDIR%\SoftwareDistribution\Download\*" >nul 2>&1
)

net start wuauserv >nul 2>&1
net start bits >nul 2>&1

echo [4/5] Limpando arquivos recentes...

del /f /s /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1

echo [5/5] Esvaziando lixeira...

powershell -NoProfile -Command "Clear-RecycleBin -Force" >nul 2>&1

echo.
echo Aguardando o Windows atualizar o espaco em disco...

timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo      LIMPEZA CONCLUIDA!
echo ========================================
echo.
echo O Windows recriara automaticamente os
echo arquivos temporarios quando necessario.
echo.

echo.
echo Calculando espaco livre depois...

for /f "delims=" %%a in ('powershell -NoProfile -Command "[int]((Get-PSDrive C).Free/1MB)"') do (
    set "LivreDepois=%%a"
)

set /a LiberadoMB=LivreDepois-LivreAntes

if %LiberadoMB% LSS 0 set LiberadoMB=0

echo.
echo ================================
echo Espaco liberado: %LiberadoMB% MB
echo ================================

pause
goto menu

:dns
cls
echo [LIMPEZA DE DNS]
ipconfig /flushdns
echo.
echo Cache DNS limpo!
pause
goto menu

:winupdate
cls
echo [LIMPEZA WINDOWS UPDATE]

net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

del /s /q /f "%WINDIR%\SoftwareDistribution\Download\*" >nul 2>&1

net start wuauserv >nul 2>&1
net start bits >nul 2>&1

echo.
echo Cache do Windows Update limpo!
pause
goto menu

:cleanmgr
cls
echo Abrindo ferramenta oficial do Windows...
cleanmgr
goto menu

:getSize
setlocal enabledelayedexpansion
set "folder=%~1"
set size=0

for /r "%folder%" %%f in (*) do (
set /a size+=%%~zf
)

endlocal & set "%2=%size%"
goto :eof

:apps
cls
color 0A

echo [ATUALIZACOES DE APPS PENDENTES]
echo.

winget upgrade

color 0A

echo.
set /p resposta=Gostaria de atualizar os aplicativos acima? (Pode levar entre 1 a 3 minutos) [Y/N]

if /i "%resposta%"=="Y" goto atualizarApps
if /i "%resposta%"=="N" goto menu

echo Opcao invalida.
pause
goto apps

:atualizarApps
echo.
echo Atualizando aplicativos...
winget upgrade --all --accept-source-agreements --accept-package-agreements

color 0A

echo.
echo Atualizacao concluida!
pause
goto menu

:reparar
cls
color 0A

echo ================================
echo   REPARO COMPLETO DO WINDOWS
echo ================================
echo.
echo Esta ferramenta executara DUAS ETAPAS: 
echo.
echo [1] DISM - Verifica e repara a imagem interna do windows.
echo [2] SFC - Verifica e restaura arquivos corrompidos do sistema.
echo.
echo O PROCESSO PODE:
echo - Levar entre 10 a 40 minutos
echo - Consumir CPU e disco
echo - Restaurar algumas configuracoes padrao do windows
echo - Exigir reinicializacao ao final
echo.
echo %ESC%[91mNAO%ESC%[92m desligue o computador durante o processo
echo.

set /p confirmar=Tem certeza que deseja continuar? [y/n]:

if /I "%confirmar%"=="N" goto menu
if /I not "%confirmar%"=="Y" goto repararConfirmacao

:repararConfirmacao
cls
color 0A

echo ==========================================
echo            CONFIRMACAO FINAL
echo ==========================================
echo.
echo Este reparo pode alterar componentes
echo internos do Windows.
echo.
echo Execute %ESC%[91mapenas%ESC%[92m se:
echo - O Windows estiver apresentando erros
echo - Atualizacoes estiverem falhando
echo - Apps do sistema estiverem quebrados
echo.
echo Esta acao pode levar %ESC%[91mbastante tempo.%ESC%[92m
echo.

set /p confirmar2=Confirmar inicio do reparo? [y/n]:

if /I "%confirmar2%"=="N" goto menu
if /I not "%confirmar2%"=="Y" goto repararConfirmacao

:repararConfirmacao
cls
color 0A

echo [1/2] Reparando imagem do Windows...
echo.

DISM /Online /Cleanup-Image /RestoreHealth

echo.
echo [2/2] Reparando arquivos do sistema...
echo.

sfc /scannow

echo.
echo ==========================================
echo Processo concluido!
echo.
echo Caso tenham sido feitas correcoes,
echo recomenda-se reiniciar o computador.
echo ==========================================

pause
goto menu



:ativar
cls
color 0A

echo ================================
echo     FERRAMENTAS AVANCADAS
echo ================================
echo.
echo Abrindo Chris Titus WinUtil...
echo.

powershell -ExecutionPolicy Bypass -Command "irm https://get.activated.win/ | iex"

goto menu















:secreto
cls
color 0C

echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...
echo.
echo Usuario:
timeout /t 2 >nul




cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...


echo.
echo Usuario: R
powershell -Command "Start-Sleep -Milliseconds 100"





cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...



echo.
echo Usuario: Re
powershell -Command "Start-Sleep -Milliseconds 300"

cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...




echo.
echo Usuario: Rel
powershell -Command "Start-Sleep -Milliseconds 300"

cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...




echo.
echo Usuario: Relb
powershell -Command "Start-Sleep -Milliseconds 300"

cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...




echo.
echo Usuario: Relbe
timeout /t 1 >nul

cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...




echo.
echo Usuario: Relbet
timeout /t 1 >nul

cls
echo.
echo ========================================
echo      ACESSO CONFIDENCIAL DETECTADO
echo ========================================
echo.
echo Verificando identidade...





echo.
echo Usuario: Relbety
echo.
echo Acessando arquivo restrito...
timeout /t 2 >nul

cls
echo.
echo Localizando arquivo...
echo.

echo [=====               ] 25%%
timeout /t 2 >nul

cls
echo.
echo Abrindo canal reservado...
echo.

echo [==========          ] 50%%
timeout /t 2 >nul

cls
echo.
echo Carregando arquivo confidencial...
echo.

echo [===============     ] 75%%
timeout /t 2 >nul

cls
echo.
echo Descriptografando conteudo...
echo.

echo [====================] 100%%
timeout /t 2 >nul

cls
echo.
echo Arquivo encontrado.
echo Abrindo...
timeout /t 2 >nul

start "" "https://youtube.com/shorts/ecUw5UWpOmU"
timeout /t 5 >nul

color 0A
goto menu