# SharkPilot-site (template)

Шаблон за статичен сайт (Home + 5 документа), готов за **Cloudflare Pages**.

## Структура
```
public/
  index.html
  assets/style.css
  doc-1/index.html
  doc-1/assets/
  doc-2/ ...
tools/
```

## Cloudflare Pages настройки
- Framework preset: **None**
- Build command: *(празно)*
- Build output directory: **public**
- Production branch: **main**

## Как да редактираш
- Редактирай `public/doc-X/index.html`
- Слагай снимки/файлове в `public/doc-X/assets/`
- Push към GitHub → Cloudflare деплойва автоматично.
