extends Node3D

class_name GodotPlushSkin

@onready var godot_plush_mesh = $GodotPlushModel/Rig/Skeleton3D/GodotPlushMesh
@onready var physical_bone_simulator_3d = %PhysicalBoneSimulator3D
@onready var animation_tree : AnimationTree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

var ragdoll : bool = false : set = set_ragdoll
var squash_and_stretch = 1.0 : set = set_squash_and_stretch

signal footstep(intensity : float)
signal waved

func _ready():
	set_ragdoll(ragdoll)

func set_ragdoll(value : bool) -> void:
	#manage the ragdoll appliements to the model, to call when wanting to go in/out ragdoll mode
	ragdoll = value
	if !is_inside_tree(): return
	physical_bone_simulator_3d.active = ragdoll
	animation_tree.active = !ragdoll
	if ragdoll: physical_bone_simulator_3d.physical_bones_start_simulation()
	else: physical_bone_simulator_3d.physical_bones_stop_simulation()
	
func set_state(state_name : String) -> void:
	#set current state of the model state machine (which manage the differents animations)
	state_machine.travel(state_name)
	
func set_squash_and_stretch(value : float) -> void:
	#squash and stretch the model
	squash_and_stretch = value
	var negative = 1.0 + (1.0 - squash_and_stretch)
	godot_plush_mesh.scale = Vector3(negative, squash_and_stretch, negative)

func emit_footstep(intensity : float = 1.0) -> void:
	#call foostep signal in charge of emitting the footstep audio effects
	footstep.emit(intensity)
