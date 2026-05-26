extends Node3D

class_name ParticlesManager

func display_particles(particle_ref : PackedScene, play_char_ref : PlayerCharacter) -> void:
	var particles : GPUParticles3D = particle_ref.instantiate()
	play_char_ref.add_sibling(particles)
	particles.global_transform = play_char_ref.global_transform
	particles.emitting = true
