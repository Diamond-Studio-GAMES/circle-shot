class_name WeaponData
extends Resource

## Ресурс с данными оружия.
##
## Содержит данные об оружии, такие как редкость, имя, описание и прочее.

## Имя оружия.
@export var name: String
## Тип оружия. Смотри [enum Weapon.Type].
@export var type := Weapon.Type.LIGHT
## Редкость оружия. Смотри [enum ItemsDB.Rarity].
@export var rarity := ItemsDB.Rarity.COMMON
@export_group("Stats")
## Текст, кратко говорящий об уроне оружия. Чаще всего "Урон/с" или просто "Урон".
@export var damage_text: String
## Текст, кратко говорящий об боеприпасах оружия. Чаще всего в формате "ХХ/ХХХ"
@export var ammo_text: String
## Полное описание оружия, включающее в себя почти всю информацию о нём. Для форматирования можно
## использовать BBCode.
@export_multiline var description: String
## ID оружия. Должно быть уникальным.
@export var id: String
@export_group("Paths")
## Путь к сцене оружия.
@export_file("*.tscn") var scene_path: String
## Путь к картинке оружия, желательно с разрешением 256 пикселей по большей стороне. 
@export_file("*.png") var image_path: String
## Массив путей к сценам, относящихся конкретно к этому оружию, которые должны синхронизироваться
## при появлении. Например, сцена пули или гранаты.
@export_file("*.tscn") var spawnable_scenes_paths: Array[String]
