extends CharacterBody2D

var speed = 300.0
var jump_speed = -530.0

var is_ledge_grabbing = false
var can_ledge_grab = true

@onready var wall_check = $WallCheckRight
@onready var ledge_check = $LedgeCheckRight

@onready var tilemap = $"../TileMap"


func _physics_process(delta):
	if not is_ledge_grabbing:
		# Apply gravity
		velocity += get_gravity() * delta

		# Handle jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_speed

		# Jump animation while in the air
		if not is_on_floor():
			$AnimatedSprite2D.play("jump")

		move_and_slide()

		# Allow to grab again after landing
		if is_on_floor():
			can_ledge_grab = true
			$AnimatedSprite2D.play("idle")

		# Check for ledge while falling
		if velocity.y > 0 and can_ledge_grab and can_grab_ledge():
			start_ledge_grab()

		# Stop upward movement when hitting something
		if is_on_ceiling() and velocity.y < 0:
			velocity.y = 0

	else:
		# Jump up from ledge
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_speed
			is_ledge_grabbing = false
			can_ledge_grab = false

		# get down from ledge
		elif Input.is_action_just_pressed("down"):
			velocity.y = jump_speed * -0.5
			is_ledge_grabbing = false
			can_ledge_grab = false

		# Stay on ledge
		else:
			velocity = Vector2.ZERO

		move_and_slide()
		return


func can_grab_ledge():
	if wall_check.is_colliding() and not ledge_check.is_colliding():
		if can_grab_wall(wall_check):
			return true

	return false


func start_ledge_grab():
	is_ledge_grabbing = true
	velocity = Vector2.ZERO


func can_grab_wall(ray: RayCast2D) -> bool:
	var collision_point = ray.get_collision_point()
	var direction = ray.target_position.normalized()

	# Move into the wall to get correct tile
	collision_point += direction * 2.0

	var local_point = tilemap.to_local(collision_point)
	var cell = tilemap.local_to_map(local_point)

	for layer in range(tilemap.get_layers_count()):
		var tile_data = tilemap.get_cell_tile_data(layer, cell)

		if tile_data:
			return tile_data.get_custom_data("can_be_grabbed") == true

	return false
