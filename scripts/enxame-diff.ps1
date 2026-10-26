<#
.SYNOPSIS
    Extrai o diff limpo das alterações locais para a banca examinadora do Enxame.
.DESCRIPTION
    Filtra arquivos binários, lockfiles e arquivos gerados para fornecer
    o menor payload possível em tokens para os subagentes auditores.
#>
param(
    [string]$VerifyCommand = ""
)

$ErrorActionPreference = "Stop"

# Verifica se está em repositório git
$isGit = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "ERRO: O diretório atual não é um repositório git válido."
    exit 1
}

# 1. Executa comando de validação local se fornecido
if ($VerifyCommand -ne "") {
    Write-Output "=== [1/3] VALIDAÇÃO DETERMINÍSTICA LOCAL ==="
    Invoke-Expression $VerifyCommand
    if ($LASTEXITCODE -ne 0) {
        Write-Output "FALHA: O comando de verificação '$VerifyCommand' retornou erro ($LASTEXITCODE)."
        exit $LASTEXITCODE
    }
    Write-Output "SUCESSO: Validação local passou com código 0."
}

# 2. Resumo de arquivos alterados
Write-Output "=== [2/3] RESUMO DE ARQUIVOS (GIT STATUS) ==="
$status = git status --short
if (-not $status) {
    Write-Output "STATUS: CLEAN (Nenhuma alteração detectada)"
    exit 0
}
Write-Output $status

# 3. Estatísticas e Diff filtrado
Write-Output "`n=== [3/3] GIT DIFF TELEGRÁFICO ==="
git diff --stat

# Exclui arquivos pesados/irrelevantes para auditoria de código
$excludePatterns = @(
    ":(exclude)*.lock",
    ":(exclude)*-lock.json",
    ":(exclude)*.png",
    ":(exclude)*.jpg",
    ":(exclude)*.webp",
    ":(exclude)*.svg",
    ":(exclude)*.min.js",
    ":(exclude)*.min.css",
    ":(exclude)build/*",
    ":(exclude)dist/*",
    ":(exclude).gradle/*"
)

$diff = git diff -U3 HEAD -- . $excludePatterns
if (-not $diff) {
    # Caso as alterações sejam apenas untracked
    $diff = git diff -U3 -- . $excludePatterns
}

Write-Output "`n--- INÍCIO DO DIFF ---"
Write-Output $diff
Write-Output "--- FIM DO DIFF ---"
