# =============================================================================
# PaintManager — Geração das evidências de Verificação e Validação (TFC II)
#
# Rodar na RAIZ do paintmanager_app, no PowerShell:
#   powershell -ExecutionPolicy Bypass -File tool\evidencias\gerar_evidencias.ps1
#
# Gera em docs\evidencias\:
#   00_ambiente\         versão do Flutter, flutter doctor, commit avaliado
#   01_testes\           saída completa do flutter test, JSON da execução,
#                        resumo com totais e %, quadro por arquivo (CSV)
#   02_analise_estatica\ saída do flutter analyze e regras de lint usadas
#   03_cobertura\        lcov.info e resumo de cobertura por arquivo (CSV)
#   04_gerencia\         lista de commits (data e mensagem) para o cronograma
#
# Os testes rodam UMA vez (com cobertura). O script PARA em três momentos
# para você tirar os prints P2, P3 e P4 do roteiro. Para rodar sem pausas:
#   powershell -ExecutionPolicy Bypass -File tool\evidencias\gerar_evidencias.ps1 -SemPausas
# =============================================================================

param([switch]$SemPausas)

$ErrorActionPreference = 'Continue'

function Pausa([string]$mensagem) {
    if ($SemPausas) { return }
    Write-Host ''
    Write-Host ">>> $mensagem" -ForegroundColor Yellow
    Read-Host '    Depois do print, aperte Enter para continuar' | Out-Null
}
$raiz = 'docs\evidencias'

if (-not (Test-Path 'pubspec.yaml') -or -not (Select-String -Path 'pubspec.yaml' -Pattern '^name:\s*paintmanager_app' -Quiet)) {
    Write-Host 'Rode este script na pasta raiz do paintmanager_app.' -ForegroundColor Red
    exit 1
}

foreach ($p in '00_ambiente', '01_testes', '02_analise_estatica', '03_cobertura', '04_gerencia') {
    New-Item -ItemType Directory -Force -Path (Join-Path $raiz $p) | Out-Null
}

function Salvar([string]$arquivo, $conteudo) {
    $conteudo | Out-File -FilePath $arquivo -Encoding utf8
}

$data = Get-Date -Format 'dd/MM/yyyy HH:mm'
$commit = (git log -1 --format='%h - %s (%ad)' --date=format:'%d/%m/%Y %H:%M') 2>$null
$cabecalho = @("PaintManager - gerado em $data", "Commit avaliado: $commit", '')

# -----------------------------------------------------------------------------
Write-Host "`n=== 1/5 Ambiente ===" -ForegroundColor Cyan
$versao = flutter --version 2>&1 | ForEach-Object { "$_" }
Salvar "$raiz\00_ambiente\flutter_version.txt" ($cabecalho + $versao)
$doctor = flutter doctor -v 2>&1 | ForEach-Object { "$_" }
Salvar "$raiz\00_ambiente\flutter_doctor.txt" ($cabecalho + $doctor)
Salvar "$raiz\00_ambiente\commit_avaliado.txt" ($cabecalho)
Write-Host '  ok: versão do Flutter, flutter doctor e commit salvos'

# -----------------------------------------------------------------------------
Write-Host "`n=== 2/5 Testes automatizados (flutter test --coverage) ===" -ForegroundColor Cyan
$json = "$raiz\01_testes\resultado_testes.json"
if (Test-Path $json) { Remove-Item $json }
flutter test --coverage --reporter expanded --file-reporter "json:$json" 2>&1 | ForEach-Object { "$_" } | Tee-Object -Variable saidaTestes
$codigoTestes = $LASTEXITCODE
Pausa 'PRINT P2: final da saída dos testes (a linha "All tests passed!" ou "Some tests failed")'
Salvar "$raiz\01_testes\testes_console.txt" ($cabecalho + $saidaTestes)

# Leitura do JSON (uma linha = um evento do executor de testes)
$suites = @{}
$testes = @{}
$feitos = @()
if (Test-Path $json) {
    foreach ($linha in Get-Content $json -Encoding utf8) {
        if (-not $linha.Trim()) { continue }
        $e = $linha | ConvertFrom-Json
        switch ($e.type) {
            'suite'     { $suites[[string]$e.suite.id] = $e.suite.path }
            'testStart' { $testes[[string]$e.test.id] = $e.test }
            'testDone'  { if (-not $e.hidden) { $feitos += $e } }
        }
    }
}

function CaminhoRelativo([string]$caminho) {
    if (-not $caminho) { return '(desconhecido)' }
    return ($caminho -replace '\\', '/') -replace '^.*?/test/', 'test/'
}

$linhas = foreach ($f in $feitos) {
    $t = $testes[[string]$f.testID]
    [pscustomobject]@{
        Arquivo   = CaminhoRelativo $suites[[string]$t.suiteID]
        Teste     = $t.name
        Resultado = if ($f.skipped) { 'pulado' } elseif ($f.result -eq 'success') { 'sucesso' } else { 'falha' }
        TempoMs   = $f.time
    }
}

$total   = @($linhas).Count
$ok      = @($linhas | Where-Object Resultado -eq 'sucesso').Count
$falhas  = @($linhas | Where-Object Resultado -eq 'falha').Count
$pulados = @($linhas | Where-Object Resultado -eq 'pulado').Count
$pct     = if ($total -gt 0) { [math]::Round(100 * $ok / $total, 1) } else { 0 }

# Quadro por arquivo (abre no Excel; separador ; para o Excel em português)
$porArquivo = $linhas | Group-Object Arquivo | ForEach-Object {
    [pscustomobject]@{
        Arquivo = $_.Name
        Testes  = $_.Count
        Sucesso = @($_.Group | Where-Object Resultado -eq 'sucesso').Count
        Falha   = @($_.Group | Where-Object Resultado -eq 'falha').Count
    }
} | Sort-Object Arquivo
$porArquivo | Export-Csv "$raiz\01_testes\testes_por_arquivo.csv" -NoTypeInformation -Delimiter ';' -Encoding UTF8
$linhas | Export-Csv "$raiz\01_testes\testes_lista_completa.csv" -NoTypeInformation -Delimiter ';' -Encoding UTF8

$nomesFalhas = $linhas | Where-Object Resultado -eq 'falha' | ForEach-Object { "  - $($_.Arquivo): $($_.Teste)" }
$resumoTestes = $cabecalho + @(
    "Arquivos de teste: $(@($porArquivo).Count)",
    "Testes executados: $total",
    "Sucesso: $ok",
    "Falha: $falhas",
    "Pulados: $pulados",
    "Percentual de sucesso: $pct%",
    "Código de saída do flutter test: $codigoTestes",
    ''
)
if ($falhas -gt 0) { $resumoTestes += @('Testes que falharam:') + $nomesFalhas }
Salvar "$raiz\01_testes\resumo_testes.txt" $resumoTestes

# -----------------------------------------------------------------------------
Write-Host "`n=== 3/5 Análise estática (flutter analyze) ===" -ForegroundColor Cyan
flutter analyze 2>&1 | ForEach-Object { "$_" } | Tee-Object -Variable saidaAnalise
$codigoAnalise = $LASTEXITCODE
Pausa 'PRINT P3: resultado do flutter analyze (de preferência "No issues found!")'
Salvar "$raiz\02_analise_estatica\analyze_console.txt" ($cabecalho + $saidaAnalise)
Copy-Item 'analysis_options.yaml' "$raiz\02_analise_estatica\analysis_options.yaml" -Force
$erros   = @($saidaAnalise | Select-String -Pattern '^\s*error\s').Count
$avisos  = @($saidaAnalise | Select-String -Pattern '^\s*warning\s').Count
$infos   = @($saidaAnalise | Select-String -Pattern '^\s*info\s').Count
$semProblemas = [bool]($saidaAnalise | Select-String -Pattern 'No issues found' -Quiet)

# -----------------------------------------------------------------------------
Write-Host "`n=== 4/5 Cobertura de código ===" -ForegroundColor Cyan
$lcov = 'coverage\lcov.info'
$coberturaTotal = 'n/d'
if (Test-Path $lcov) {
    Copy-Item $lcov "$raiz\03_cobertura\lcov.info" -Force
    $arquivos = @()
    $atual = $null
    foreach ($l in Get-Content $lcov) {
        if ($l -like 'SF:*') { $atual = [pscustomobject]@{ Arquivo = (($l.Substring(3)) -replace '\\', '/') -replace '^.*?/lib/', 'lib/'; Linhas = 0; Cobertas = 0 } }
        elseif ($l -like 'LF:*') { $atual.Linhas = [int]$l.Substring(3) }
        elseif ($l -like 'LH:*') { $atual.Cobertas = [int]$l.Substring(3) }
        elseif ($l -eq 'end_of_record' -and $atual) { $arquivos += $atual; $atual = $null }
    }
    $somaLinhas = ($arquivos | Measure-Object Linhas -Sum).Sum
    $somaCobertas = ($arquivos | Measure-Object Cobertas -Sum).Sum
    if ($somaLinhas -gt 0) { $coberturaTotal = "$([math]::Round(100 * $somaCobertas / $somaLinhas, 1))%" }
    $arquivos | ForEach-Object {
        [pscustomobject]@{
            Arquivo   = $_.Arquivo
            Linhas    = $_.Linhas
            Cobertas  = $_.Cobertas
            Cobertura = if ($_.Linhas -gt 0) { "$([math]::Round(100 * $_.Cobertas / $_.Linhas, 1))%" } else { '-' }
        }
    } | Sort-Object Arquivo | Export-Csv "$raiz\03_cobertura\cobertura_por_arquivo.csv" -NoTypeInformation -Delimiter ';' -Encoding UTF8
    Salvar "$raiz\03_cobertura\resumo_cobertura.txt" ($cabecalho + @(
        "Arquivos medidos: $($arquivos.Count)",
        "Linhas executáveis: $somaLinhas",
        "Linhas cobertas pelos testes: $somaCobertas",
        "Cobertura total: $coberturaTotal",
        '',
        'Obs.: a cobertura mede só os arquivos de lib/ carregados pelos testes.'
    ))
    Write-Host "  ok: cobertura $coberturaTotal"
} else {
    Write-Host '  coverage\lcov.info não foi gerado (os testes falharam antes de terminar?)' -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
Write-Host "`n=== 5/5 Histórico de commits (gerência de projeto) ===" -ForegroundColor Cyan
$commits = git log --reverse --format='%h;%ad;%s' --date=format:'%d/%m/%Y' 2>$null
Salvar "$raiz\04_gerencia\commits.csv" (@('hash;data;mensagem') + $commits)
Write-Host "  ok: $(@($commits).Count) commits"

# -----------------------------------------------------------------------------
# RESUMO NA TELA  ->  PRINT P4
# -----------------------------------------------------------------------------
Clear-Host
$resultadoAnalise = if ($semProblemas) { 'No issues found (nenhum problema)' } else { "$erros erro(s), $avisos aviso(s), $infos info(s)" }
Write-Host '=================================================================' -ForegroundColor Green
Write-Host ' PaintManager - Evidências de Verificação e Validação' -ForegroundColor Green
Write-Host '=================================================================' -ForegroundColor Green
Write-Host " Data:                 $data"
Write-Host " Commit avaliado:      $commit"
Write-Host ''
Write-Host ' TESTES AUTOMATIZADOS (flutter test)'
Write-Host "   Arquivos de teste:  $(@($porArquivo).Count)"
Write-Host "   Testes executados:  $total"
Write-Host "   Sucesso:            $ok"
Write-Host "   Falha:              $falhas"
Write-Host "   % de sucesso:       $pct%"
Write-Host ''
Write-Host ' ANÁLISE ESTÁTICA (flutter analyze / flutter_lints)'
Write-Host "   Resultado:          $resultadoAnalise"
Write-Host ''
Write-Host ' COBERTURA DE CÓDIGO'
Write-Host "   Cobertura total:    $coberturaTotal"
Write-Host ''
Write-Host " Arquivos em: $raiz" -ForegroundColor Yellow
Write-Host '=================================================================' -ForegroundColor Green
if ($falhas -gt 0) {
    Write-Host "`n Testes que falharam:" -ForegroundColor Red
    $nomesFalhas | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}
Write-Host ''
Write-Host '>>> PRINT P4: este resumo inteiro.' -ForegroundColor Yellow
