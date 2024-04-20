class_name ItemSelector
extends Window


signal item_selected(type: ItemsDB.Item, id: int)
var _variant_environment: PackedScene = preload("uid://ck5uq0aa1ov56")
var _variant_skin: PackedScene = preload("uid://c07pym82q5utt")
var _variant_weapon: PackedScene = preload("uid://dq213xkmsonsl")
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
				var variant: TextureRect = _variant_environment.instantiate()
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
				var variant: TextureRect = _variant_environment.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Container/Name") as Label).text = i.map_name
				if current == counter:
					(variant.get_node(^"Container/Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				(variant.get_node(^"Container/Description") as Label).text = i.map_description
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
		ItemsDB.Item.SKIN:
			_variants.columns = 2
			title = "Выбери скин"
			var counter := 0
			for i: SkinConfig in Global.items_db.skins:
				var variant: TextureRect = _variant_skin.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Name") as Label).text = i.skin_name
				if current == counter:
					(variant.get_node(^"Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				(variant.get_node(^"Description") as Label).text = i.skin_description
				(variant.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
		ItemsDB.Item.WEAPON_LIGHT:
			_variants.columns = 2
			title = "Выбери лёгкое оружие"
			var counter := 0
			for i: WeaponConfig in Global.items_db.weapons_light:
				var variant: TextureRect = _variant_weapon.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Name") as Label).text = i.weapon_name
				if current == counter:
					(variant.get_node(^"Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				var damage_text := ""
				match i.damage_type:
					WeaponConfig.Damage.PER_SECOND:
						damage_text = "Урон/с: %d"
					WeaponConfig.Damage.INSTANT:
						damage_text = "Урон: %d"
				(variant.get_node(^"Damage") as Label).text = damage_text % i.damage
				(variant.get_node(^"Ammo") as Label).text = "%d/%d" % [i.ammo_per_charge, i.ammo_total]
				(variant.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
		ItemsDB.Item.WEAPON_HEAVY:
			_variants.columns = 2
			title = "Выбери тяжёлое оружие"
			var counter := 0
			for i: WeaponConfig in Global.items_db.weapons_heavy:
				var variant: TextureRect = _variant_weapon.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Name") as Label).text = i.weapon_name
				if current == counter:
					(variant.get_node(^"Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				var damage_text := ""
				match i.damage_type:
					WeaponConfig.Damage.PER_SECOND:
						damage_text = "Урон/с: %d"
					WeaponConfig.Damage.INSTANT:
						damage_text = "Урон: %d"
				(variant.get_node(^"Damage") as Label).text = damage_text % i.damage
				(variant.get_node(^"Ammo") as Label).text = "%d/%d" % [i.ammo_per_charge, i.ammo_total]
				(variant.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
		ItemsDB.Item.WEAPON_SUPPORT:
			_variants.columns = 2
			title = "Выбери оружие поддержки"
			var counter := 0
			for i: WeaponConfig in Global.items_db.weapons_support:
				var variant: TextureRect = _variant_weapon.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Name") as Label).text = i.weapon_name
				if current == counter:
					(variant.get_node(^"Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				var damage_text := ""
				match i.damage_type:
					WeaponConfig.Damage.PER_SECOND:
						damage_text = "Урон/с: %d"
					WeaponConfig.Damage.INSTANT:
						damage_text = "Урон: %d"
				(variant.get_node(^"Damage") as Label).text = damage_text % i.damage
				(variant.get_node(^"Ammo") as Label).text = "%d/%d" % [i.ammo_per_charge, i.ammo_total]
				(variant.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
		ItemsDB.Item.WEAPON_MELEE:
			_variants.columns = 2
			title = "Выбери ближнее оружие"
			var counter := 0
			for i: WeaponConfig in Global.items_db.weapons_melee:
				var variant: TextureRect = _variant_weapon.instantiate()
				variant.texture = load(i.image_path) as Texture2D
				(variant.get_node(^"Name") as Label).text = i.weapon_name
				if current == counter:
					(variant.get_node(^"Name") as Label).add_theme_color_override("font_color", Color.GREEN)
				var damage_text := ""
				match i.damage_type:
					WeaponConfig.Damage.PER_SECOND:
						damage_text = "Урон/с: %d"
					WeaponConfig.Damage.INSTANT:
						damage_text = "Урон: %d"
				(variant.get_node(^"Damage") as Label).text = damage_text % i.damage
				(variant.get_node(^"Ammo") as Label).text = "%d/%d" % [i.ammo_per_charge, i.ammo_total]
				(variant.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(variant.get_node(^"Click") as Button).pressed.connect(_on_variant_pressed.bind(type, counter))
				_variants.add_child(variant)
				counter += 1
	
	popup_centered()


func _on_variant_pressed(type: ItemsDB.Item, id: int) -> void:
	hide()
	item_selected.emit(type, id)
