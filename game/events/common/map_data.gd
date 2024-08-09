class_name MapData
extends Resource

## Ресурс с данными карты события.
## 
## Содержит данные карты события, такие как имя, описание, путь к карте и картинке.

## Имя карты.
@export var name: String
## Краткое описание карты.
@export var brief_description: String
## Путь до сцены с картой.
@export_file("*.tscn") var scene_path: String
## Путь до картинки-обложки карты. Рекомендуемое разрешение: 392 на 80.
@export_file("*.png") var image_path: String
