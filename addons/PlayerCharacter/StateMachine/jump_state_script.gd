extends State

class_name JumpState

var state_name : String = "Jump"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
	jump()
	
func verifications() -> void:
	play_char.godot_plush_skin.set_state("jump")
	if play_char.floor_snap_length != 0.0:  play_char.floor_snap_length = 0.0
	if play_char.jump_cooldown < play_char.jump_cooldown_ref: play_char.jump_cooldown = play_char.jump_cooldown_ref
	if play_char.movement_dust.emitting: play_char.movement_dust.emitting = false
	
func physics_update(delta : float) -> void:
	applies(delta)
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float) -> void:
	if !play_char.is_on_floor(): 
		if play_char.jump_cooldown > 0.0: play_char.jump_cooldown -= delta
		if play_char.coyote_jump_cooldown > 0.0: play_char.coyote_jump_cooldown -= delta
		if play_char.velocity.y < 0.0:
			transitioned.emit(self, "InairState")
		
	if play_char.is_on_floor():
		if play_char.move_dir: transitioned.emit(self, play_char.walk_or_run)
		else: transitioned.emit(self, "IdleState")
		
	if play_char.is_on_wall():
		#if enabled, cut velocity when the play char hit a wall
		if play_char.hit_wall_cut_velocity:
			play_char.velocity.x = 0.0
			play_char.velocity.z = 0.0
		
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		jump()
		
	if Input.is_action_just_released(play_char.jump_action):
		#cut jump in action, allow to manage jump height 
		#(the longer you press the button, the more high the play char goes, similar to the Mario Bros games)
		play_char.has_cut_jump = true
		transitioned.emit(self, "InairState")
		
	if Input.is_action_just_pressed(play_char.ragdoll_action):
		if !play_char.godot_plush_skin.ragdoll and !play_char.ragdoll_on_floor_only:
			transitioned.emit(self, "RagdollState")
			
func move(delta : float) -> void:
	play_char.move_dir = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action).rotated(-play_char.cam_holder.global_rotation.y)
	
	#depending on the previous grounded state (walk or run)
	#choose corresponding curve, to apply the correct in air values
	if play_char.move_dir and !play_char.is_on_floor():
		var in_air_move_speed_val : float
		var in_air_accel_val : float
		if play_char.walk_or_run == "WalkState":
			in_air_move_speed_val = play_char.in_air_move_speed[0].sample(play_char.velocity.length())
			in_air_accel_val = play_char.in_air_accel[0].sample(play_char.velocity.length())
		elif play_char.walk_or_run == "RunState":
			in_air_move_speed_val = play_char.in_air_move_speed[1].sample(play_char.velocity.length())
			in_air_accel_val = play_char.in_air_accel[1].sample(play_char.velocity.length())
			
		play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_dir.x * in_air_move_speed_val, in_air_accel_val * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_dir.y * in_air_move_speed_val, in_air_accel_val * delta)
		
func jump() -> void: 
	#manage the jump behaviour, depending of the different variables and states the character is
	
	var can_jump : bool = false #jump condition
	
	#in air jump
	if !play_char.is_on_floor():
		if play_char.coyote_jump_on:
			play_char.jump_cooldown = play_char.jump_cooldown_ref
			play_char.coyote_jump_cooldown = -1.0 #so that the character cannot immediately make another coyote jump
			play_char.coyote_jump_on = false
			can_jump = true 
		elif play_char.nb_jumps_in_air_allowed > 0:
			play_char.nb_jumps_in_air_allowed -= 1
			play_char.jump_cooldown = play_char.jump_cooldown_ref
			can_jump = true 
			
	#on floor jump
	if play_char.is_on_floor():
		play_char.jump_cooldown = play_char.jump_cooldown_ref
		can_jump = true 
		
	#jump buffering
	if play_char.buffered_jump:
		play_char.buffered_jump = false
		play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
		
	#apply jump
	if can_jump:
		play_char.velocity.y = -play_char.jump_velocity
		can_jump = false
		
		#play squash and strech effect, and display jump particles
		if play_char.is_on_floor(): 
			play_char.squash_and_strech(1.12, 0.1)
			play_char.particles_manager.display_particles(play_char.jump_particles, play_char)
		
		
