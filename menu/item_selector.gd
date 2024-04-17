extends Window


signal item_selected(type: ItemsDB.Item, id: int)
var _variant_big: PackedScene = preload("uid://ck5uq0aa1ov56")
@onready var _variants: GridContainer = $ScrollContainer/Variants


func _ready() -> void:
	close_requested.connect(hide)


func open_selection(type: ItemsDB.Item, current: int, current_game := 0) -> void:
	for i: Node in _variants.get_children():
		i.queue_free()
	
	match type:
		ItemsDB.Item.GAME:
			_variants.columns = 1
			title = "Выбери режим игры"
			var counter := 0
			for i: GameConfig in Global.items_db.games:
				var variant: TextureRect = _variant_big.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Container/Name") as Label).text = i.game_name
				if current == counter:
					(variant.get_node(^"Container/Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				(variant.get_node(^"Container/Description") as Label).text = i.game_description
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
		ItemsDB.Item.MAP:
			_variants.columns = 1
			title = "Выбери карту"
			var counter := 0
			for i: MapConfig in Global.items_db.games[current_game].maps:
				var variant: TextureRect = _variant_big.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Container/Name") as Label).text = i.map_name
				if current == counter:
					(variant.get_node(^"Container/Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				(variant.get_node(^"Container/Description") as Label).text = i.map_description
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
	
	popup_centered()


func _on_variant_pressed(type: ItemsDB.Item, id: int) -> void:
	hide()
	item_selected.emit(type, id)
