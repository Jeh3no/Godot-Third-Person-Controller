extends Node

class_name State

signal transitioned

func enter(_char_reference : CharacterBody3D) -> void:
	#enter state
	pass
	
func exit() -> void:
	#exit state
	pass
	
func update(_delta : float) -> void:
	#process update
	pass
	
func physics_update(_delta : float) -> void:
	#physics_process update
	pass 
