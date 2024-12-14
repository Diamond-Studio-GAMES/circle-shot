class_name Attack
extends Node2D

## Узел атаки.
##
## Узел, отвечающий за нанесения урона сущностям. Для работы добавьте дочерний
## узел типа [AreaDetector], [ShapeDetector] или [RayDetector].

## Урон, который будет нанесён сущности.
@export var damage: int
## Множитель наносимого урона для удобства. При перемножение используется стандартное округление.
var damage_multiplier := 1.0
## [Entity.id] сущности, которой принадлежит эта атака. Если меньше либо равен 0, в сообщении о
## смерти не будет указано имя убийцы.
var who: int = -1
## Команда, которой принадлежит эта атака. Урон сущности не будет нанесён, если её команда
## совпадает с командой атаки.
var team: int = -1


## Наносит урон сущности [param entity]. Опционально можно изменить количество наносимого урона
## с помощью [param amount], НО [member damage_multiplier] все равно будет учтён.[br]
## Возвращает [code]true[/code], если урон был успешно нанесён, иначе [code]false[/code].
func deal_damage(entity: Entity, amount: int = damage) -> bool:
	if not can_deal_damage(entity):
		return false
	entity.damage(roundi(amount * damage_multiplier), who)
	_deal_damage(entity)
	return true


## Определяет, можно ли нанести урон сущности [param entity]. Возвращает [code]true[/code]
## если можно, иначе возвращает [code]false[/code].
func can_deal_damage(entity: Entity) -> bool:
	return entity.team != team and _can_deal_damage(entity)


## Переопредели этот метод в дочернем классе, чтобы добавить логику при успешном нанесении урона.
func _deal_damage(_entity: Entity) -> void:
	pass


## Переопредели этот метод в дочернем классе, чтобы добавить условия для нанесения урона.
## Возвращай [code]true[/code] если можно, иначе возвращай [code]false[/code].
func _can_deal_damage(_entity: Entity) -> bool:
	return true
