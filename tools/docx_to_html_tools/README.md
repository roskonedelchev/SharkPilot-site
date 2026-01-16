# DOCX -> HTML + assets (Windows 10/11)

## Изискване
Инсталиран **Pandoc** (да е в PATH).

Пример:
- winget install --id JohnMacFarlane.Pandoc -e

## Употреба
```
convert_docx_to_html.bat "C:\Docs\Manual.docx"
```

## Резултат
Създава папка:
`C:\Docs\Manual_web\`

вътре:
- `index.html`
- `assets\...` (снимки)

## След това
Копирай в репото:
- `Manual_web\index.html` → `public\doc-X\index.html`
- `Manual_web\assets\` → `public\doc-X\assets\`
