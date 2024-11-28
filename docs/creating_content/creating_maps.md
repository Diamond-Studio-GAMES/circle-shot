# Создание карты

В этом руководстве описан процесс создания карты для события.

## Основная инструкция

1. Определитесь с событием, для которого Вы будете создавать карту.
2. Создайте папку `game/maps/<выбранное событие>/<имя карты>`. Название папки карты должно быть написано в *snake_case*.
3. Унаследуйтесь от сцены `game/events/<выбранное событие>/base_map.tscn` и сохраните новую сцену в `game/maps/<выбранное событие>/<имя карты>/<имя карты>.tscn`.
4. Сделайте эту сцену из прототипа непосредственно картой. Для этого хорошо подойдут `TileMapLayer`. Границы, в пределах которой нужно разместить контент, будут видны в качестве фиолетовых полос в редакторе.
    - Для примера построения вы можете посмотреть структуру других карт, и даже скопировать `TileMapLayer` в сцену своей карты, а `TileSet` - в её папку. Не забудьте отредактировать зависимости скопированных ресурсов!
5. Скорее всего в `base_map.tscn` были расположены дополнительные узлы - точки появления игроков, лечилок, т. д. Не забудьте их передвинуть под нужды Вашей карты.
6. После того, как карта будет создана, отредактируйте `MinimapTiles`, чтобы он реплицировал Вашу карту на её мини-версии. Самый светлый блок из TileSet - стена, чуть темнее - простреливаемая стена, ещё немного темнее - пол, черный тайл - граница карты.
7. Запустите сцену карты (клавиша F6) и сделайте её скришот в разрешении 784 на 160.
    - Для удобства постановки кадра Вы можете *переопределить камеру игры* с помощью кнопки в виде камеры на панели инструментов в редакторе. После её нажатия камера в игре будет в том же положения и зуме, что и камера редактора.
    - Также для удобства непосредственного создания скриншота Вы можете поменять размер окна через `Настройки проекта -> Display -> Window -> Window Width/Height Override`, а потом просто сделать снимок активного окна игры с картой.
8. Получив скриншот, положите его в папку карты и назовите его `image.png`.
9. Создайте ресурс типа `MapData`. Заполните название и краткое описание карты. В поле `Scene Path` перетащите сцену Вашей карты, а в `Image Path` - `image.png`.
10. Откройте `*.tres` файл события, для которого эта карта предназначена. В массив `Maps` добавьте файл `*.tres` Вашей карты.
11. Готово! Теперь карта доступна для выбора в игре.

## Детали

- Для создания форм столкновений карты предусмотрено 3 физических слоя: `world`, `fence` и `boundary`.
    - `world`: основной слой столкновения, использующийся чаще всего. Игрок и обычные пули не могут проходить через объекты с этим слоем.
    - `fence`: через объекты с этим слоем не может проходить игрок, однако пули могут свободно пролетать.
    - `boundary`: через объекты с этим слоем НИЧЕГО не должно проходить. Чаще всего используется вместе с `world`. Служит границей карты.
- Рекомендуемая структура `TileMapLayer`:
    - `Floor`: чаще всего содержит тайлы без физической формы, служит как бы фоном карты.
    - `Walls`: скелет карты, её основной каркас, нарисованный тайлами стен.
    - `Top`: декорации, что будут поверх происходящего. Использование тайлов с физическими формами на этом слою не рекомендуется.
- Создавайте границу из блоков с слоем физики `boundary` **за** границей карты так, чтобы игрок и пули не могли выйти за указанные в базовой карте границы.
- Размещение точек появления должно учитывать размер игрока и небольшую случайность их размещения (смотри `Event.SPAWN_POINT_RANDOMNESS`).