extends GPUParticles3D

class_name SelfDestroyParticles


func _ready() -> void:
	emitting = true
	one_shot = true
	finished.connect(queue_free)
