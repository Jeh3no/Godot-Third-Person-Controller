extends CanvasLayer

class_name HUD


@export var play_char : PlayerCharacter

@onready var current_state_label_text = %CurrentStateLabelText
@onready var velocity_label_text = %VelocityLabelText
@onready var velocity_vector_label_text: Label = %VelocityVectorLabelText
@onready var is_on_floor_label_text: Label = %IsOnfloorLabelText
@onready var nb_jumps_inAir_allowed_label_text = %NbJumpsInAirAllowedLabelText
@onready var jump_buffer_label_text = %JumpBufferLabelText
@onready var coyote_time_label_text = %CoyoteTimeLabelText
@onready var model_orientation_label_text = %ModelOrientationLabelText
@onready var camera_mode_label_text = %CameraModeLabelText
@onready var frames_per_second_label_text = %FramesPerSecondLabelText

func _process(_delta : float) -> void:
	display_frames_per_second()
	
	display_play_char_properties()
		
func display_play_char_properties() -> void:
	current_state_label_text.set_text(str(play_char.state_machine.curr_state_name))
	velocity_label_text.set_text(str("%.3f" % play_char.velocity.length()))
	velocity_vector_label_text.set_text(str("[ ", ("%.3f" % play_char.velocity.x)," ", ("%.3f" % play_char.velocity.y)," ", ("%.3f" % play_char.velocity.z), " ]"))
	is_on_floor_label_text.set_text(str(play_char.is_on_floor()))
	nb_jumps_inAir_allowed_label_text.set_text(str(play_char.nb_jumps_in_air_allowed))
	jump_buffer_label_text.set_text(str(play_char.jump_buff_on))
	coyote_time_label_text.set_text(str("%.3f" % play_char.coyote_jump_cooldown))
	model_orientation_label_text.set_text(str("cam follower" if (play_char.cam_holder.cam_aimed and play_char.follow_cam_pos_when_aimed) else "independant"))
	camera_mode_label_text.set_text(str("aim" if play_char.cam_holder.cam_aimed else "default"))
	
func display_frames_per_second() -> void:
	frames_per_second_label_text.set_text(str("%.1f" % Engine.get_frames_per_second()))
	
	
	
	
