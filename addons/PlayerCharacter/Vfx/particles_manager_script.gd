extends Node3D

class_name ParticlesManager

func display_particles(particle_ref : PackedScene, char_ref : CharacterBody3D) -> void:
	var particles : GPUParticles3D = particle_ref.instantiate()
	char_ref.add_sibling(particles)
	particles.global_transform = char_ref.global_transform
	particles.emitting = true
