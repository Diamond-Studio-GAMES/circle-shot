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
## Если [param type] это [constant ItemsDB.MAP], то необходимо предоставить
## [param selected_event], из которого будут браться карты.
func list_items(type: ItemsDB.Item, selected: int = -1, selected_event: int = 0) -> void:
	for i: Node in get_children():
		i.queue_free()
	
	var counter: int = 0
	match type:
		ItemsDB.Item.EVENT:
			columns = 1
			for event: EventData in Globals.items_db.events:
				var item: TextureRect = _item_environment_scene.instantiate()
				item.texture = load(event.image_path)
				(item.get_node(^"Container/Name") as Label).text = event.name
				if selected == counter:
					(item.get_node(^"Container/Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Container/Description") as Label).text = event.brief_description
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, counter))
				add_child(item)
				counter += 1
		ItemsDB.Item.MAP:
			columns = 1
			for map: MapData in Globals.items_db.events[selected_event].maps:
				var item: TextureRect = _item_environment_scene.instantiate()
				item.texture = load(map.image_path)
				(item.get_node(^"Container/Name") as Label).text = map.name
				if selected == counter:
					(item.get_node(^"Container/Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Container/Description") as Label).text = map.brief_description
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, counter))
				add_child(item)
				counter += 1
		ItemsDB.Item.SKIN:
			columns = 3
			var skins: Array[SkinData] = Globals.items_db.skins.duplicate()
			skins.sort_custom(_sort_rarity_skin)
			for skin: SkinData in skins:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(skin.image_path)
				(item.get_node(^"Name") as Label).text = skin.name
				if selected == skin.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = skin.brief_description
				(item.get_node(^"Description") as Label).horizontal_alignment = \
						HORIZONTAL_ALIGNMENT_CENTER
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[skin.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, skin.idx_in_db))
				add_child(item)
		ItemsDB.Item.WEAPON_LIGHT:
			columns = 3
			var weapons: Array[WeaponData] = Globals.items_db.weapons_light.duplicate()
			weapons.sort_custom(_sort_rarity_weapon)
			for weapon: WeaponData in weapons:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(weapon.image_path)
				(item.get_node(^"Name") as Label).text = weapon.name
				if selected == weapon.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = \
						weapon.ammo_text + '\n' + weapon.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[weapon.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, weapon.idx_in_db))
				add_child(item)
		ItemsDB.Item.WEAPON_HEAVY:
			columns = 3
			var weapons: Array[WeaponData] = Globals.items_db.weapons_heavy.duplicate()
			weapons.sort_custom(_sort_rarity_weapon)
			for weapon: WeaponData in weapons:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(weapon.image_path)
				(item.get_node(^"Name") as Label).text = weapon.name
				if selected == weapon.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = \
						weapon.ammo_text + '\n' + weapon.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[weapon.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, weapon.idx_in_db))
				add_child(item)
		ItemsDB.Item.WEAPON_SUPPORT:
			columns = 3
			var weapons: Array[WeaponData] = Globals.items_db.weapons_support.duplicate()
			weapons.sort_custom(_sort_rarity_weapon)
			for weapon: WeaponData in weapons:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(weapon.image_path)
				(item.get_node(^"Name") as Label).text = weapon.name
				if selected == weapon.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = \
						weapon.ammo_text + '\n' + weapon.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[weapon.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, weapon.idx_in_db))
				add_child(item)
		ItemsDB.Item.WEAPON_MELEE:
			columns = 3
			var weapons: Array[WeaponData] = Globals.items_db.weapons_melee.duplicate()
			weapons.sort_custom(_sort_rarity_weapon)
			for weapon: WeaponData in weapons:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(weapon.image_path)
				(item.get_node(^"Name") as Label).text = weapon.name
				if selected == weapon.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = \
						weapon.ammo_text + '\n' + weapon.damage_text
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[weapon.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, weapon.idx_in_db))
				add_child(item)
		ItemsDB.Item.SKILL:
			columns = 3
			var skills: Array[SkillData] = Globals.items_db.skills.duplicate()
			skills.sort_custom(_sort_rarity_skill)
			for skill: SkillData in skills:
				var item: TextureRect = _item_equip_scene.instantiate()
				item.texture = load(skill.image_path)
				(item.get_node(^"Name") as Label).text = skill.name
				if selected == skill.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = \
						skill.usage_text + '\n' + skill.brief_description
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[skill.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, skill.idx_in_db))
				add_child(item)
		_:
			push_error("Invalid type specified: %d." % type)


func _sort_rarity_weapon(first: WeaponData, second: WeaponData) -> bool:
	if first.rarity != second.rarity:
		return first.rarity < second.rarity
	return first.idx_in_db < second.idx_in_db


func _sort_rarity_skin(first: SkinData, second: SkinData) -> bool:
	if first.rarity != second.rarity:
		return first.rarity < second.rarity
	return first.idx_in_db < second.idx_in_db


func _sort_rarity_skill(first: SkillData, second: SkillData) -> bool:
	if first.rarity != second.rarity:
		return first.rarity < second.rarity
	return first.idx_in_db < second.idx_in_db


func _on_item_pressed(type: ItemsDB.Item, id: int) -> void:
	item_selected.emit(type, id)
