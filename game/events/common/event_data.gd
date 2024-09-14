class_name EventData
extends Resource

## Ресурс с данными события.
##
## Этот ресурс содержит в себе данные о событии, такие как имя, описание, пути к картинке,
## сцене и другое.

## Имя события.
@export var name: String
## Краткое описание события.
@export var brief_description: String
## Минимальное число игроков (от 2 до 10).
@export_range(2, 10, 1) var min_players: int = 2
## Максимальное число игроков (от 2 до 10).
@export_range(2, 10, 1) var max_players: int = 10
## Допустимый делитель числа игроков.
## Например, если игроков 3, а делитель - 2, то игру начать будет невозможно,
## так как 3 не делится нацело на 2.
@export_range(1, 5, 1) var players_divider: int = 1
## Путь до сцены с событием.
@export_file("PackedScene") var scene_path: String
## Путь до картинки-обложки события. Рекомендуемое разрешение: 392 на 80.
@export_file("Texture2D") var image_path: String
## Массив карт данного события.
@export var maps: Array[MapData]
