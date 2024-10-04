class_name ItemsGrid
extends GridContainer

## Сеточный контейнер с предметами.
##
## Этот контейнер может отобразить все предметы одного типа с помощью [method list_items].

## Этот сигнал издаётся, когда один из отображённых предметов нажат. Сигнал содержит
## тип предмета в [param type] и ID предмета в [param id].
signal item_selected(type: ItemsDB.Item, id: int)
var _item_environment_scene: PackedScene = preload("uid://ck5uq0aa1ov56")
var _item_equip_scene: PackedScene = preload("uid://c07pym82q5utt")


## Очищает существующие предметы и отображает новые того типа, который указан в [param type].
## Опционально можно предоставить [param selected], чтобы выделить зелёным выбранный предмет.
## Если [param type] это [constant ItemsDB.SKILL], то необходимо предоставить
## [param selected_event], из которого будут бряться карты.
func list_items(type: ItemsDB.Item, selected: int = -1, selected_event: int = 0) -> void:
	for i: Node in get_children():
		i.queue_free()
	
	var counter: int = 0
	match type:
		ItemsDB.Item.EVENT:
			columns = 1
			for i: EventData in Globals.items_db.events:
				var item: TextureRect = _item_environment_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Container/Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Container/Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Container/Description") as Label).text = i.brief_description
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.MAP:
			columns = 1
			for i: MapData in Globals.items_db.events[selected_event].maps:
				var item: TextureRect = _item_environment_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Container/Name") as Label).text = i.name
				if selected == counter:
					
					(item.get_node(^"Container/Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Container/Description") as Label).text = i.brief_description
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.SKIN:
			columns = 3
			for i: SkinData in Globals.items_db.skins:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Description") as Label).text = i.brief_description
				(item.get_node(^"Description") as Label).horizontal_alignment = \
						HORIZONTAL_ALIGNMENT_CENTER
				(item.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.WEAPON_LIGHT:
			columns = 3
			for i: WeaponData in Globals.items_db.weapons_light:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Description") as Label).text = i.ammo_text + '\n' + i.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.WEAPON_HEAVY:
			columns = 3
			for i: WeaponData in Globals.items_db.weapons_heavy:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Description") as Label).text = i.ammo_text + '\n' + i.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.WEAPON_SUPPORT:
			columns = 3
			for i: WeaponData in Globals.items_db.weapons_support:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Description") as Label).text = i.ammo_text + '\n' + i.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.WEAPON_MELEE:
			columns = 3
			for i: WeaponData in Globals.items_db.weapons_melee:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Description") as Label).text = i.ammo_text + '\n' + i.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		ItemsDB.Item.SKILL:
			columns = 3
			for i: SkillData in Globals.items_db.skills:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(i.image_path)
				(item.get_node(^"Name") as Label).text = i.name
				if selected == counter:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							"font_color", Color.GREEN
					)
				(item.get_node(^"Description") as Label).text = \
						i.usage_text + '\n' + i.brief_description
				(item.get_node(^"RarityFill") as ColorRect).color = ItemsDB.RARITY_COLORS[i.rarity]
				(item.get_node(^"Click") as Button).pressed.connect(
						_on_item_pressed.bind(type, counter)
				)
				add_child(item)
				counter += 1
		_:
			push_error("Invalid type specified: %d!" % type)


func _on_item_pressed(type: ItemsDB.Item, id: int) -> void:
	item_selected.emit(type, id)
