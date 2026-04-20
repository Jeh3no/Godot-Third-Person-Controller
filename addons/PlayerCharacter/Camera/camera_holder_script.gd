extends Node3D

class_name CameraHolder

var active : bool = true : set = set_active

@export_group("Camera variables")
@export_range(1.0, 179.0, 0.1) var fov_val : float = 50.0
@export_range(0.0, 0.02, 0.0001) var mouse_sensibility : float = 0.005
@export_range(-90.0, 90.0, 0.1) var min_limit_x : float = -80.0 #in degrees here for clearer lisibility, is converted in radians when needed
@export_range(-90.0, 90.0, 0.1) var max_limit_x : float = 10.0 #in degrees here for clearer lisibility, is converted in radians when needed

@export_group("Zoom variables")
@export var max_spring_length : float = 30.0
@export var min_spring_length : float = 3.0
@export var zoom_speed : float = 10.0

@export_group("Aim variables")
var cam_aimed : bool = false #if true, cam goes into "aim/shooter mode", above the play char shoulder
@export var aim_cam_pos : Vector3 = Vector3(1.4, 0.9, 0.0)
var aim_cam_pos_side : bool = true #false = left, true = right

#keybinding variables
var mouse_mode_action : StringName
var aim_cam_action : StringName
var aim_cam_side_action : StringName
var cam_zoom_in_action : StringName
var cam_zoom_out_action : StringName

#reference variables
@onready var spring_arm : SpringArm3D = %SpringArm3D
@onready var cam : Camera3D = %Camera3D

func _ready() -> void:
	#set fov, capture mouse cursor, and enable camera
	cam.fov = fov_val
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.set_use_accumulated_input(false)
	set_active(active)
	
func set_active(state : bool) -> void:
	#enable/disable play char camera
	active = state
	set_process_input(active)
	set_process(active)

func _input(event) -> void:
	#free/capture mouse cursor
	if event.is_action_pressed(mouse_mode_action):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: 
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: 
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	#if mouse cursor is free, can't rotate cam
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	
	#change cam mode (default, aim)
	if event.is_action_pressed(aim_cam_action):
		cam_aimed = !cam_aimed
		
	#change cam side when aimed (over left shoulder, or over right shoulder)
	if event.is_action_pressed(aim_cam_side_action):
		aim_cam_pos_side = !aim_cam_pos_side
		
	#rotate cam according to the mouse
	if event is InputEventMouseMotion: 
		var viewport_transform: Transform2D = get_tree().root.get_final_transform()
		var mouse_motion = event.xformed_by(viewport_transform).relative
		rotate_from_vector(mouse_motion * mouse_sensibility)
		
func _process(delta) -> void:
	#position the cam according to her mode (default, aim (with left or right side))
	if !cam_aimed: cam.position = Vector3(0.0, 0.0, spring_arm.spring_length)
	else: cam.position = Vector3(aim_cam_pos.x if aim_cam_pos_side else -aim_cam_pos.x, aim_cam_pos.y, spring_arm.spring_length)
	
	#handle zoom
	zoom_handling(delta)
	
func rotate_from_vector(vector : Vector2) -> void:
	#rotate cam by the vector's amount, and clamp the rotation between max up and max down values
	#(to avoid doing 360 degree turn with the cam for example)
	if vector.length() == 0: return
	rotation.y -= vector.x
	rotation.x -= vector.y
	rotation.x = clamp(rotation.x, deg_to_rad(min_limit_x), deg_to_rad(max_limit_x))
	
func zoom_handling(delta : float) -> void:
	#zoom in/out cam, and clamp zoom value between min and max zoom values
	spring_arm.spring_length += Input.get_axis(cam_zoom_in_action, cam_zoom_out_action) * zoom_speed * delta
	spring_arm.spring_length = clamp(spring_arm.spring_length, min_spring_length, max_spring_length)
	
	
