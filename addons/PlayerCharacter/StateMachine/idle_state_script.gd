extends State

class_name IdleState

var state_name : String = "Idle"

var play_char : CharacterBody3D

func enter(char_ref : CharacterBody3D) -> void:
	#pass play char reference
	play_char = char_ref
	
	verifications()
	
func verifications() -> void:
	#manage the appliements that need to be set at the start of the state
	play_char.godot_plush_skin.set_state("idle")
	play_char.floor_snap_length = 1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_cut_jump: play_char.has_cut_jump = false
	if play_char.movement_dust.emitting: play_char.movement_dust.emitting = false
	
func physics_update(delta : float) -> void:
	applies()
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies() -> void:
	#manage the appliements and state transitions that needs to be sets/checked/performed
	#every time the play char pass through one of the following : floor-inair-onwall
	if !play_char.is_on_floor() and !play_char.is_on_wall():
		transitioned.emit(self, "InairState")
	if play_char.is_on_floor():
		if play_char.jump_buff_on: 
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")
			
func input_management() -> void:
	#manage the state transitions depending on the actions inputs
	if Input.is_action_pressed(play_char.jump_action) if play_char.auto_jump else Input.is_action_just_pressed(play_char.jump_action):
		transitioned.emit(self, "JumpState")
		
	if Input.is_action_just_pressed(play_char.run_action):
		if play_char.walk_or_run == "WalkState": play_char.walk_or_run = "RunState"
		elif play_char.walk_or_run == "RunState": play_char.walk_or_run = "WalkState"
		
	if Input.is_action_just_pressed(play_char.ragdoll_action):
		if !play_char.godot_plush_skin.ragdoll:
			transitioned.emit(self, "RagdollState")
		
func move(delta : float) -> void:
	#manage the character movement
	
	#get the move direction depending on the input
	play_char.move_dir = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action).rotated(-play_char.cam_holder.global_rotation.y)
	
	if play_char.move_dir and play_char.is_on_floor():
		#transition to corresponding state
		transitioned.emit(self, play_char.walk_or_run)
	else:
		#apply smooth stop 
		play_char.velocity.x = lerp(play_char.velocity.x, 0.0, play_char.move_deccel * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, 0.0, play_char.move_deccel * delta)
