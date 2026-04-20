extends State

class_name InairState

var state_name : String = "Inair"

var play_char : CharacterBody3D

func enter(char_ref : CharacterBody3D) -> void:
	play_char = char_ref
	
	verifications()
	
func verifications() -> void:
	play_char.godot_plush_skin.set_state("fall")
	if play_char.floor_snap_length != 0.0:  play_char.floor_snap_length = 0.0
	if play_char.movement_dust.emitting: play_char.movement_dust.emitting = false
	
func physics_update(delta : float) -> void:
	applies(delta)
	
	if play_char.velocity.y > 0 and play_char.has_cut_jump: gravity_apply(delta)
	else: play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float) -> void:
	if !play_char.is_on_floor(): 
		if play_char.jump_cooldown > 0.0: play_char.jump_cooldown -= delta
		if play_char.coyote_jump_cooldown > 0.0: play_char.coyote_jump_cooldown -= delta
		
	if play_char.is_on_floor():
		if play_char.jump_buff_on: 
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")
			
		play_char.squash_and_strech(0.8, 0.08)
		play_char.particles_manager.display_particles(play_char.land_particles, play_char)
		
		impact_audio_playing()
			
		if play_char.move_dir: transitioned.emit(self, play_char.walk_or_run)
		else: transitioned.emit(self, "IdleState")
		
	if play_char.is_on_wall():
		if play_char.hit_wall_cut_velocity:
			play_char.velocity.x = 0.0
			play_char.velocity.z = 0.0
		
func gravity_apply(delta : float) -> void:
	if play_char.velocity.y >= 0.0: play_char.velocity.y -= play_char.jump_gravity / play_char.jump_cut_multiplier * delta
		
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		#check if can jump buffer
		if play_char.floor_check.is_colliding() and play_char.last_frame_position.y > play_char.position.y and play_char.nb_jumps_in_air_allowed <= 0: play_char.jump_buff_on = true
		#check if can coyote jump
		if play_char.was_on_floor and play_char.coyote_jump_cooldown > 0.0 and play_char.last_frame_position.y > play_char.position.y:
			play_char.coyote_jump_on = true
			transitioned.emit(self, "JumpState")
		transitioned.emit(self, "JumpState")
		
	if Input.is_action_just_pressed(play_char.ragdoll_action):
		if !play_char.godot_plush_skin.ragdoll and !play_char.ragdoll_on_floor_only:
			transitioned.emit(self, "RagdollState")
			
func move(delta : float) -> void:
	play_char.move_dir = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action).rotated(-play_char.cam_holder.global_rotation.y)
		
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
		
func impact_audio_playing() -> void:
	#audio played when play char touch the ground after being in air
	#the volume is calculated based on the velocity pre ground hit, plus the fall gravity
	var floor_impact_percent : float = clamp(abs(play_char.velocity.y), 0.0, play_char.fall_gravity) / play_char.fall_gravity
	play_char.impact_audio.volume_db = linear_to_db(remap(floor_impact_percent, 0.0, 1.0, 0.5, 2.0))
	play_char.impact_audio.play()
