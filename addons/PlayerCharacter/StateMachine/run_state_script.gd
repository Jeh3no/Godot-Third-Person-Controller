extends State

class_name RunState

var state_name : String = "Run"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
func verifications() -> void:
	play_char.godot_plush_skin.set_state("run")
	play_char.move_speed = play_char.run_speed
	play_char.move_accel = play_char.run_accel
	play_char.move_deccel = play_char.run_deccel
	
	play_char.floor_snap_length = 1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_cut_jump: play_char.has_cut_jump = false
	if !play_char.movement_dust.emitting: play_char.movement_dust.emitting = true
	
func physics_update(delta : float) -> void:
	applies()
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies() -> void:
	if !play_char.is_on_floor():
		if play_char.velocity.y < 0.0:
			transitioned.emit(self, "InairState")
			
	if play_char.is_on_floor():
		if play_char.jump_buff_on:
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")
			
func input_management() -> void:
	if Input.is_action_pressed(play_char.jump_action) if play_char.auto_jump else Input.is_action_just_pressed(play_char.jump_action):
		transitioned.emit(self, "JumpState")
		
	if play_char.continious_run:
		#has to press run button once to run
		if Input.is_action_just_pressed(play_char.run_action):
			play_char.walk_or_run = "WalkState"
			transitioned.emit(self, "WalkState")
	else:
		#has to continuously press run button to run
		if !Input.is_action_pressed(play_char.run_action):
			play_char.walk_or_run = "WalkState"
			transitioned.emit(self, "WalkState")
			
	if Input.is_action_just_pressed(play_char.ragdoll_action):
		if !play_char.godot_plush_skin.ragdoll:
			transitioned.emit(self, "RagdollState")
		
		
func move(delta : float) -> void:
	play_char.move_dir = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action).rotated(-play_char.cam_holder.global_rotation.y)
	
	if play_char.move_dir and play_char.is_on_floor():
		play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_dir.x * play_char.move_speed, play_char.move_accel * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_dir.y * play_char.move_speed, play_char.move_accel * delta)
	else:
		transitioned.emit(self, "IdleState")
