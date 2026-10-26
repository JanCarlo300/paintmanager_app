# =============================================================================
# PaintManager — Print da tela do celular para o Manual do usuário (TFC II)
#
# Rodar na RAIZ do paintmanager_app, no PowerShell:
#   .\tool\evidencias\print_tela.ps1 01 login
#   .\tool\evidencias\print_tela.ps1 17a nova_obra_1
#
# Se o Windows bloquear scripts, use:
#   powershell -ExecutionPolicy Bypass -File tool\evidencias\print_tela.ps1 01 login
#
# Salva em docs\evidencias\05_manual\<numero>_<nome>.png (sobrescreve se já existir).
# =============================================================================

param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Numero,
    [Parameter(Mandatory = $true, Position = 1)][string]$Nome
)

$pasta = 'docs\evidencias\05_manual'
$temporario = '/sdcard/tela.png'
$arquivo = Join-Path $pasta "$($Numero)_$($Nome).png"

function Erro([string]$mensagem) {
    Write-Host "erro: $mensagem" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path 'pubspec.yaml')) {
    Erro 'rode este script na pasta raiz do paintmanager_app.'
}

# adb: do PATH ou do Android SDK padrão
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) {
    $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
    if (-not (Test-Path $adb)) {
        Erro 'adb não encontrado (nem no PATH, nem no Android SDK).'
    }
}

# Celular conectado e autorizado?
$estado = "$(& $adb get-state 2>&1)".Trim()
if ($LASTEXITCODE -ne 0 -or $estado -ne 'device') {
    Erro "o adb não achou o celular ($estado). Confira o cabo, desligue a Ancoragem USB e aceite a depuração USB no aparelho."
}

New-Item -ItemType Directory -Force -Path $pasta | Out-Null

# 1. Print no celular
& $adb shell screencap -p $temporario
if ($LASTEXITCODE -ne 0) { Erro 'o screencap falhou no celular.' }

# 2. Copia para o PC
& $adb pull $temporario $arquivo | Out-Null
$codigoPull = $LASTEXITCODE

# 3. Apaga o temporário do celular (mesmo se o pull falhou)
& $adb shell rm -f $temporario

if ($codigoPull -ne 0) { Erro 'não foi possível copiar o print do celular (adb pull).' }

# Confere se o PNG chegou inteiro
if (-not (Test-Path $arquivo) -or (Get-Item $arquivo).Length -le 10KB) {
    Erro "o arquivo $arquivo não foi gerado ou está vazio/pequeno demais."
}

$tamanho = [math]::Round((Get-Item $arquivo).Length / 1KB)
Write-Host "ok: $arquivo ($tamanho KB)" -ForegroundColor Green
