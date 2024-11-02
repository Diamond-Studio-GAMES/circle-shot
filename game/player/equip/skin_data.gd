class_name SkinData
extends Resource

## Ресурс с данными о скине.
## 
## Содержит данные о скине для игрока, такие как имя, описание, редкость и различные пути.

## Имя скина.
@export var name: String
## Краткое описание скина.
@export var brief_description: String
## Редкость скина. Смотри [enum ItemsDB.Rarity].
@export var rarity := ItemsDB.Rarity.COMMON
## ID скина. Должно быть уникальным.
@export var id: String
@export_group("Paths")
## Путь до сцены со скином.
@export_file("PackedScene") var scene_path: String
## Путь до картинки скина, желательно с разрешением 256 на 256.
@export_file("Texture2D") var image_path: String
## Индекс скина в массиве [ItemsDB]. Равен -1 если его там нет.
## Задаётся при инициализации [ItemsDB].
var idx_in_db: int = -1
