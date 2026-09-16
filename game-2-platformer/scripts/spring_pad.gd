extends Area2D

@export var bounce_velocity: float = -800.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.velocity.y >= 0.0:
		body.velocity.y = bounce_velocity
