extends CharacterBody2D

var speed = 300.0
var jump_speed = -530.0
var friction = 1400
var acceleration = 1200

var is_ledge_grabbing = false
var can_ledge_grab = true

var is_facing = 1

@onready var wall_check_right = $WallCheckRight
@onready var ledge_check_right = $LedgeCheckRight
@onready var wall_check_left = $WallCheckLeft
@onready var ledge_check_left = $LedgeCheckLeft

@onready var tilemap = $"../TileMap"


func get_direction():
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		is_facing = direction
	
	if not is_ledge_grabbing:
		if is_facing > 0:
			$AnimatedSprite2D.flip_h = false
		if is_facing < 0:
			$AnimatedSprite2D.flip_h = true
	
	return direction


func _physics_process(delta):
	var direction = get_direction()
	
	if not is_ledge_grabbing:
		# Apply gravity
		velocity += get_gravity() * delta

		# Handle jumping
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_speed

		# Jump animation while in the air
		if not is_on_floor():
			$AnimatedSprite2D.play("jump")
		
		# For horizontal movement
		var current_speed = direction * speed
		
		if direction != 0:
			velocity.x = move_toward(velocity.x, current_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, current_speed, friction * delta)
		
		# Horizontal movement and idle animation
		if is_on_floor():
			if ((velocity.x < 0 or velocity.x > 0)) and not is_on_wall():
				$AnimatedSprite2D.play("run")
			else:
				$AnimatedSprite2D.play("idle")
		
		move_and_slide()

		# Allow to grab again after landing
		if is_on_floor():
			can_ledge_grab = true

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

		# Get down from ledge
		elif Input.is_action_just_pressed("down"):
			velocity.y = jump_speed * -0.5
			is_ledge_grabbing = false
			can_ledge_grab = false

		# Stay on ledge
		else:
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("ledge")

		move_and_slide()
		return


func can_grab_ledge():
	var wall_check
	var ledge_check

	if is_facing > 0:
		wall_check = wall_check_right
		ledge_check = ledge_check_right
	elif is_facing < 0:
		wall_check = wall_check_left
		ledge_check = ledge_check_left
	else:
		return false

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
