extends CharacterBody3D

class_name PlayerCharacter

#movement variables
var move_speed : float
var move_accel : float
var move_deccel : float
var move_dir : Vector2
var target_angle : float
var last_input_dir : Vector2
var last_frame_position : Vector3
var last_frame_velocity : Vector3
var was_on_floor : bool = false
var walk_or_run : String = "WalkState" #keep in memory if play char was walking or running before being in the air

@export_group("Walk variables")
@export var walk_speed : float = 5.0
@export var walk_accel : float = 8.0
@export var walk_deccel : float = 7.5

@export_group("Run variables")
@export var run_speed : float = 9.0
@export var run_accel : float = 3.5
@export var run_deccel : float = 6.5
@export var continious_run : bool = false #if true, doesn't need to keep run button on to run

@export_group("Jump variables")
@export var jump_height : float = 3.0
@export var jump_time_to_peak : float = 0.35
@export var jump_time_to_descent : float = 0.29
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
var has_cut_jump : bool = false
@export var jump_cut_multiplier : float = 0.5
@export var jump_cooldown : float = 0.2
var jump_cooldown_ref : float 
@export var nb_jumps_in_air_allowed : int = 1
var nb_jumps_in_air_allowed_ref : int
var jump_buff_on : bool = false
var buffered_jump : bool = false
@export var coyote_jump_cooldown : float
var coyote_jump_cooldown_ref : float
var coyote_jump_on : bool = false
@export var auto_jump : bool = false
 
@export_group("In air variables")
@export var in_air_move_speed : Array[Curve] #one curve for if was walking before jumping/falling, one curve for if was running before jumping/falling
@export var in_air_accel : Array[Curve] #one curve for if was walking before jumping/falling, one curve for if was running before jumping/falling
@export var hit_wall_cut_velocity : bool = false

#gravity variables
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

#keybinding variables
var move_forward_action : StringName
var move_backward_action : StringName
var move_left_action : StringName
var move_right_action : StringName
var run_action : StringName
var jump_action : StringName
var ragdoll_action : StringName

@export_group("Model variables")
@export var model_rot_speed : float = 6.5
@export var ragdoll_gravity : float = 7.0
@export var ragdoll_on_floor_only : bool = false
@export var follow_cam_pos_when_aimed : bool = false

#references variables
@onready var visual_root = %VisualRoot
@onready var godot_plush_skin : GodotPlushSkin = %GodotPlushSkin
@onready var particles_manager : ParticlesManager = %ParticlesManager
@onready var cam_holder: CameraHolder = %CameraHolder
@onready var state_machine : StateMachine = %StateMachine
@onready var foot_step_audio = %FootStepAudio
@onready var impact_audio = %ImpactAudio
@onready var wave_audio = %WaveAudio
@onready var collision_shape_3d = %CollisionShape3D
@onready var floor_check : RayCast3D = %FloorRaycast

#particles variables
@onready var movement_dust = %MovementDust
@onready var jump_particles = preload("../../PlayerCharacter/Vfx/jump_particles_scene.tscn")
@onready var land_particles = preload("../..//PlayerCharacter/Vfx/land_particles_scene.tscn")

func _ready():
	#set move variables, and value references
	move_speed = walk_speed
	move_accel = walk_accel
	move_deccel = walk_deccel
	
	jump_cooldown_ref = jump_cooldown
	nb_jumps_in_air_allowed_ref = nb_jumps_in_air_allowed
	coyote_jump_cooldown_ref = coyote_jump_cooldown
	
	connect_footstep_audio_effect()
	
func _process(delta: float):
	modify_model_orientation(delta)
	
func _physics_process(_delta : float):
	modify_physics_properties()
	
	move_and_slide()
	
func modify_model_orientation(delta : float):
	#manage the model rotation depending on the camera mode + char parameters
	
	var dir_target_angle : float
	
	#follow mode (model must follow the camera rotation)
	#if the cam is in angled/aim mode
	if cam_holder.cam_aimed and follow_cam_pos_when_aimed and !godot_plush_skin.ragdoll:
		#get cam rotation on the y axis (+ PI to invert half circle, and be sure that the model is correctly oriented)
		dir_target_angle = (cam_holder.cam.global_rotation.y) + PI
		#rotate the model on the y axis
		visual_root.rotation.y = rotate_toward(visual_root.rotation.y, dir_target_angle, model_rot_speed * delta)
	
	#free mode (the model orientation is independant to the camera one)
	if (!cam_holder.cam_aimed or !follow_cam_pos_when_aimed) and move_dir != Vector2.ZERO:
		#get char move direction
		dir_target_angle = -move_dir.orthogonal().angle()
		#rotate the model on the y axis
		visual_root.rotation.y = rotate_toward(visual_root.rotation.y, dir_target_angle, model_rot_speed * delta)
		
func modify_physics_properties():
	last_frame_position = position #get play char position every frame
	last_frame_velocity = velocity #get play char velocity every frame
	was_on_floor = !is_on_floor() #get if play char is on floor or not
	
func gravity_apply(delta : float):
	#if play char goes up, apply jump gravity
	#otherwise, apply fall gravity
	if !is_on_floor():
		if velocity.y >= 0.0: velocity.y -= jump_gravity * delta
		elif velocity.y < 0.0: velocity.y -= fall_gravity * delta
	
func squash_and_strech(value : float, timing : float):
	#create a tween that simulate a compression of the model (squash and strech ones)
	#maily used to accentuate game feel/juice
	#call the squash_and_strech function of the model (it's this function that actually squash and strech the model)
	var sasTween : Tween = create_tween()
	sasTween.set_ease(Tween.EASE_OUT)
	sasTween.tween_property(godot_plush_skin, "squash_and_stretch", value, timing)
	sasTween.tween_property(godot_plush_skin, "squash_and_stretch", 1.0, timing * 1.8)
	
func connect_footstep_audio_effect() -> void:
	#set play char model audios effects
	godot_plush_skin.footstep.connect(func(intensity : float = 1.0):
		foot_step_audio.volume_db = linear_to_db(intensity)
		foot_step_audio.play()
		)
	
	
	
	
