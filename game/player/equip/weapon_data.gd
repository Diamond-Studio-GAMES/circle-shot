class_name WeaponData
extends Resource

## Ресурс с данными оружия.
##
## Содержит данные об оружии, такие как редкость, имя, описание и прочее.

## Имя оружия.
@export var name: String
## Редкость оружия. Смотри [enum ItemsDB.Rarity].
@export var rarity := ItemsDB.Rarity.COMMON
## ID оружия. Должно быть уникальным.
@export var id: String
@export_group("Stats")
## Текст, кратко говорящий об уроне оружия. Чаще всего "Урон/с" или просто "Урон".
@export var damage_text: String
## Текст, кратко говорящий об боеприпасах оружия. Чаще всего в формате "ХХ/ХХХ"
@export var ammo_text: String
## Полное описание оружия, включающее в себя почти всю информацию о нём. Для форматирования можно
## использовать BBCode.
@export_multiline var description: String
@export_group("Paths")
## Путь к сцене оружия.
@export_file("PackedScene") var scene_path: String
## Путь к картинке оружия, желательно с разрешением 256 пикселей по большей стороне. 
@export_file("Texture2D") var image_path: String
## Массив путей к сценам, относящихся конкретно к этому оружию, которые должны синхронизироваться
## при появлении. Например, сцена пули или гранаты.
@export_file("PackedScene") var spawnable_scenes_paths: Array[String]
## Индекс оружия в массиве [ItemsDB]. Равен -1 если его там нет.
## Задаётся при инициализации [ItemsDB].
var idx_in_db: int = -1
