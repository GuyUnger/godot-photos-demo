extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var level: Node3D
@export var game: Node3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var photo
var locked := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	level = get_parent()
	game = level.get_parent()

func _physics_process(delta: float) -> void:
	# Don't allow movement when transitioning
	if locked: return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if locked: return
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / 500.0
		$Camera3D.rotation.x -= event.relative.y / 500.0
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if photo:
				drop_photo()
			else:
				var ray: RayCast3D = $Camera3D/RayCast3D
				ray.force_raycast_update()
				if ray.is_colliding():
					enter_photo(ray.get_collider().get_parent())
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			take_photo()

func enter_photo(photo):
	locked = true
	
	var tween = create_tween()
	var transform_to = photo.get_node("CameraTarget").global_transform
	tween.tween_property($Camera3D, "global_transform", transform_to, 0.5)
	await tween.finished
	
	game.remove_child(level)
	game.add_child(game.scenes[photo.scene_id])

func drop_photo():
	var photo_transform = photo.global_transform
	photo.get_parent().remove_child(photo)
	get_parent().add_child(photo)
	photo.global_transform = photo_transform
	photo = null

func take_photo():
	if photo:
		return
	var texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	photo = load("res://photo.tscn").instantiate()
	
	var scene_copy = level.duplicate()
	game.scenes.push_back(scene_copy)
	
	photo.init(texture, game.scenes.size() - 1)
	$Camera3D/PhotoAttach.add_child(photo)
	$AnimationPlayer.play("take_photo")

