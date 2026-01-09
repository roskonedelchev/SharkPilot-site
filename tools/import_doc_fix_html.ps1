param(
  [Parameter(Mandatory=$true)][string]$HtmlPath,
  [Parameter(Mandatory=$true)][string]$OldFolder,
  [int]$ForceWebp = 0
)

if (!(Test-Path -LiteralPath $HtmlPath)) { exit 1 }

$encIn  = [System.Text.Encoding]::Default
$encOut = New-Object System.Text.UTF8Encoding($false)

$text = [System.IO.File]::ReadAllText($HtmlPath, $encIn)

# charset -> utf-8 (safe for Bulgarian)
$text = $text -replace '(?i)charset\s*=\s*windows-1251', 'charset=utf-8'
$text = $text -replace '(?i)charset\s*=\s*iso-8859-1', 'charset=utf-8'

# *_files/ -> assets/
$escaped = [regex]::Escape($OldFolder)
$text = [regex]::Replace($text, $escaped + '[\\/]', 'assets/', 'IgnoreCase')

# add loading="lazy"
$text = [regex]::Replace(
  $text,
  '<img(?![^>]*\bloading=)([^>]*?)>',
  '<img loading="lazy"$1>',
  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

if ($ForceWebp -eq 1) {
  $text = [regex]::Replace(
    $text,
    '(?i)assets/([^"''>\s]+?)\.(png|jpe?g|gif|bmp|tif|tiff)',
    'assets/$1.webp'
  )
}

[System.IO.File]::WriteAllText($HtmlPath, $text, $encOut)
exit 0
