param(
  [Parameter(Mandatory=$true)][string]$HtmlPath
)

if (!(Test-Path -LiteralPath $HtmlPath)) { exit 1 }

$encIn  = [System.Text.Encoding]::Default
$encOut = New-Object System.Text.UTF8Encoding($false)

$text = [System.IO.File]::ReadAllText($HtmlPath, $encIn)

# charset -> utf-8
$text = $text -replace '(?i)charset\s*=\s*windows-1251', 'charset=utf-8'
$text = $text -replace '(?i)charset\s*=\s*iso-8859-1', 'charset=utf-8'
$text = $text -replace '(?i)<meta\s+charset\s*=\s*["'']?[^"''>]+', '<meta charset="utf-8"'

# media/ -> assets/
$text = [regex]::Replace($text, '(?i)\bmedia/', 'assets/')

# add loading="lazy"
$text = [regex]::Replace(
  $text,
  '<img(?![^>]*\bloading=)([^>]*?)>',
  '<img loading="lazy"$1>',
  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

[System.IO.File]::WriteAllText($HtmlPath, $text, $encOut)
exit 0
