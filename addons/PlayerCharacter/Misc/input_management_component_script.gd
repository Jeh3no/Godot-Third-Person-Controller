extends Node

class_name InputManagementComponent

#instead of setting up keybinds in 3 differents scripts, it's centralized in this one only

@export_group("Keybind variables")
@export_subgroup("Player character variables")
@export var move_forward_action : StringName = "play_char_move_forward_action"
@export var move_backward_action : StringName = "play_char_move_backward_action"
@export var move_left_action : StringName = "play_char_move_left_action"
@export var move_right_action : StringName = "play_char_move_right_action"
@export var run_action : StringName = "play_char_run_action"
@export var jump_action : StringName = "play_char_jump_action"
@export var ragdoll_action : StringName = "play_char_ragdoll_action"
@export_subgroup("Camera variables")
@export var mouse_mode_action : StringName = "play_char_mouse_mode_action"
@export var aim_cam_action : StringName = "play_char_aim_cam_action"
@export var aim_cam_side_action : StringName = "play_char_aim_cam_side_action"
@export var cam_zoom_in_action : StringName = "play_char_cam_zoom_in_action"
@export var cam_zoom_out_action : StringName = "play_char_cam_zoom_out_action"

@onready var input_actions_list : Array[StringName] = [
	move_forward_action,
	move_backward_action,
	move_left_action,
	move_right_action,
	run_action,
	jump_action,
	ragdoll_action,
	mouse_mode_action,
	aim_cam_action,
	aim_cam_side_action,
	cam_zoom_in_action,
	cam_zoom_out_action
	]
	
@export_group("Checker variables")
@export var check_on_ready_if_inputs_registered : bool = true
var default_input_actions : Dictionary

#references variables
@onready var play_char_ref : PlayerCharacter = $".."
@onready var cam_holder_ref : CameraHolder = %CameraHolder

func _ready() -> void:
	attribute_keybinds()
	build_default_keybinding()
	input_actions_check()
	
func attribute_keybinds() -> void:
	play_char_ref.move_forward_action = move_forward_action
	play_char_ref.move_backward_action = move_backward_action
	play_char_ref.move_left_action = move_left_action
	play_char_ref.move_right_action = move_right_action
	play_char_ref.run_action = run_action
	play_char_ref.jump_action = jump_action
	play_char_ref.ragdoll_action = ragdoll_action
	
	cam_holder_ref.mouse_mode_action = mouse_mode_action
	cam_holder_ref.aim_cam_action = aim_cam_action
	cam_holder_ref.aim_cam_side_action = aim_cam_side_action
	cam_holder_ref.cam_zoom_in_action = cam_zoom_in_action
	cam_holder_ref.cam_zoom_out_action = cam_zoom_out_action
	
func build_default_keybinding() -> void:
	#build it in runtime to ensure that export variables have been set
	default_input_actions = {
		move_forward_action : [
			{ "type": "key", "code": Key.KEY_W },
			{ "type": "key", "code": Key.KEY_UP }
		],
		move_backward_action : [
			{ "type": "key", "code": Key.KEY_S },
			{ "type": "key", "code": Key.KEY_DOWN }
		],
		move_left_action : [
			{ "type": "key", "code": Key.KEY_A },
			{ "type": "key", "code": Key.KEY_LEFT }
		],
		move_right_action : [
			{ "type": "key", "code": Key.KEY_D },
			{ "type": "key", "code": Key.KEY_RIGHT }
		],
		run_action : [
			{ "type": "key", "code": Key.KEY_SHIFT }
		],
		jump_action : [
			{ "type": "key", "code": Key.KEY_SPACE }
		],
		ragdoll_action : [
			{ "type": "key", "code": Key.KEY_R }
		],
		mouse_mode_action : [
			{ "type": "key", "code": Key.KEY_CTRL }
		],
		aim_cam_action : [
			{ "type": "mouse", "code": MouseButton.MOUSE_BUTTON_RIGHT }
		],
		aim_cam_side_action : [
			{ "type": "key", "code": Key.KEY_G }
		],
		cam_zoom_in_action : [
			{ "type": "mouse", "code": MouseButton.MOUSE_BUTTON_WHEEL_UP },
			{ "type": "key", "code": Key.KEY_V }
		],
		cam_zoom_out_action : [
			{ "type": "mouse", "code": MouseButton.MOUSE_BUTTON_WHEEL_DOWN },
			{ "type": "key", "code": Key.KEY_B }
		]
	}
	
func input_actions_check() -> void:
	#check if the input actions written in the editor are the same as the ones registered in the Input map, and if they are written correctly
	#if not, add it to runtime Input map with default keybindings
	if check_on_ready_if_inputs_registered:
		var registered_input_actions: Array[StringName] = []
		for input_action in InputMap.get_actions():
			if input_action.begins_with(&"play_char_"):
				registered_input_actions.append(input_action)
				
		for input_action in input_actions_list:
			if input_action == &"":
				assert(false, "There's an undefined input action")
				
			if not registered_input_actions.has(input_action):
				var key_names = default_input_actions[input_action].map(func(entry):
					match entry["type"]:
						"key":
							return OS.get_keycode_string(entry["code"])

						"mouse":
							return get_mouse_button_name(entry["code"])

						_:
							return "Unknown"
				)
				
				push_warning("'{input}' missing in InputMap, or input action wrongly named in the editor.\nAdding the '{input}' to runtime InputMap temporarily with the key(s): {keys}"
				.format({"input": input_action, "keys": String(", ").join(key_names)}))
				
				InputMap.add_action(input_action)
				for key_data in default_input_actions[input_action]:
					match key_data["type"]:
						"key":
							var key_event := InputEventKey.new()
							key_event.physical_keycode = key_data["code"]
							InputMap.action_add_event(input_action, key_event)

						"mouse":
							var mouse_event := InputEventMouseButton.new()
							mouse_event.button_index = key_data["code"]
							InputMap.action_add_event(input_action, mouse_event)

						_:
							push_error("keycode %s doesn't match Key or MouseButton types" % str(key_data["code"]))
					
func get_mouse_button_name(button_index: int) -> String:
	#Godot doesn't have a native function for that, so i created my own
	
	match button_index:
		MouseButton.MOUSE_BUTTON_LEFT:
			return "Mouse Left"
		MouseButton.MOUSE_BUTTON_RIGHT:
			return "Mouse Right"
		MouseButton.MOUSE_BUTTON_MIDDLE:
			return "Mouse Middle"
		MouseButton.MOUSE_BUTTON_WHEEL_UP:
			return "Wheel Up"
		MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			return "Wheel Down"
		MouseButton.MOUSE_BUTTON_WHEEL_LEFT:
			return "Wheel Left"
		MouseButton.MOUSE_BUTTON_WHEEL_RIGHT:
			return "Wheel Right"
		_:
			return "Mouse Button %d" % button_index
