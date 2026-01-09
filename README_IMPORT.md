# Import script (Windows 10/11)

## Какво прави
`tools/import_doc.bat` взима Word export:
- `SomeDoc.html`
- `SomeDoc_files\`

и го импортира в:
- `public\doc-X\index.html`
- `public\doc-X\assets\...`

После:
- поправя пътищата в HTML (`*_files/` → `assets/`)
- добавя `loading="lazy"`
- конвертира снимките към `.webp` (ако има cwebp / magick / ffmpeg)

## Употреба
```bat
tools\import_doc.bat 1 "C:\Docs\Manual.html"
```

Ако папката със снимки е с друго име:
```bat
tools\import_doc.bat 1 "C:\Docs\Manual.html" "C:\Docs\Manual_files"
```

## Настройки
```bat
set WEBP_QUALITY=82
set DELETE_ORIGINALS=1
```
