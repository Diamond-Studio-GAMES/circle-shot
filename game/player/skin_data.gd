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
@export_file("*.tscn") var scene_path: String
## Путь до картинки скина.
@export_file("*.png") var image_path: String
