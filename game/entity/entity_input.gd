class_name EntityInput
extends MultiplayerSynchronizer

## Узел с вводом для сущности.

## Направление движения сущности. Ограничивайте длину единицей при использовании.
var direction := Vector2():
    set(value):
        if not value.is_finite() or value.is_zero_approx():
            direction = Vector2.ZERO
        else:
            direction = value
