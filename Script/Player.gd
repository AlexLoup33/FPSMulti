extends CharacterBody3D

signal health_changed(health_value)
signal score_changed(score_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var flash = $Camera3D/Pistol/flash
@onready var raycast = $Camera3D/RayCast3D

var health = 5
var score = 0

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20

func _ready():
	if not is_multiplayer_authority(): return
	
	var material = $MeshInstance3D.get_active_material(0)
	var r = randi_range(0, 255)
	var g = randi_range(0, 255)
	var b = randi_range(0, 255)
	material.albedo_color = Color(r, g, b, 1)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_dmg.rpc_id(hit_player.get_multiplayer_authority())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if anim_player.current_animation == "shoot":
		pass
	else:
		if input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("Move")
		else:
			anim_player.play("Idle")
	
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	if not is_multiplayer_authority(): return
	
	anim_player.stop()
	anim_player.play("shoot")
	flash.restart()
	flash.emitting = true

@rpc("any_peer")
func receive_dmg():
	health -= 1
	if health <= 0:
		health = 5
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("Idle")
