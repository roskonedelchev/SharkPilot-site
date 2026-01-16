# Drive export prepare (no installs)

Този инструмент подготвя Google Drive "Download as HTML" export към формат удобен за Cloudflare Pages.

## Какво приема
- ZIP от Google Drive (съдържа *.html + папка images/)
или
- вече разархивирани: *.html + папка images/ (в една и съща папка)

## Какво прави
Създава изходна папка:
`<name>_web\`
вътре:
- `index.html` (винаги с малки букви)
- `assets\...` (снимки)

и оправя:
- `images/` → `assets/`
- charset → UTF-8
- добавя `loading="lazy"` към снимки

## Стартиране
### 1) Drag&Drop
Хвърли ZIP или HTML върху `prepare_drive_export.bat`

### 2) От CMD
`prepare_drive_export.bat "C:\path\file.zip"`
или
`prepare_drive_export.bat "C:\path\file.html"`

### 3) Без параметри
Ако в папката има точно 1 ZIP или точно 1 HTML, батчът сам го избира.

## След това
Копирай:
- `<name>_web\index.html` → `repo\public\doc-X\index.html`
- `<name>_web\assets\` → `repo\public\doc-X\assets\`
