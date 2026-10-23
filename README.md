# Карты (офлайн, без слежки)
1. Репозиторий должен быть публичным. В Sources/Cities.swift замените OWNER/REPO в baseURL.
2. Actions → "Make map packs" → Run workflow (вырежет города, создаст Release "packs").
3. Actions → "Build IPA" → Run workflow → скачайте артефакт Maps-ipa, подпишите в Feather.
Новый город: добавьте строку в City.all и в список LIST в packs.yml (id совпадает).
