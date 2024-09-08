class_name SkillData
extends Resource

## Ресурс с данными о навыке.
## 
## Содержит данные о навыке для игрока, такие как имя, описание, редкость и различные пути.

## Имя навыка.
@export var name: String
## Краткое описание навыка (что он делает).
@export var brief_description: String
## Текст с данными о том, сколько раз можно использовать навык и какой у него откат.
## Рекомендуемый формат: "X исп./YY с", где X - кол-во использований, YY - время отката.
## Если использование только одно, откат можно не писать.
@export var usage_text: String
## Редкость навыка. Смотри [enum ItemsDB.Rarity].
@export var rarity := ItemsDB.Rarity.COMMON
## ID навыка. Должно быть уникальным.
@export var id: String
@export_group("Paths")
## Путь до сцены с навыком.
@export_file("PackedScene") var scene_path: String
## Путь до картинки навыка.
@export_file("Texture2D") var image_path: String
## Массив путей к сценам, относящихся конкретно к этому навыка, которые должны синхронизироваться
## при появлении. Например, сцена удара об землю.
@export_file("PackedScene") var spawnable_scenes_paths: Array[String]
