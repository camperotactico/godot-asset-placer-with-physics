@tool
extends RigidBody3D

@export var _collision_shape_3d: CollisionShape3D

var shape_3d: Shape3D:
	get:
		return _collision_shape_3d.shape
	set(value):
		_collision_shape_3d.shape = value
var instance: Node3D

var _instance_process_mode: ProcessMode

func set_packed_scene(new_packed_scene: PackedScene) -> void:
	if instance:
		remove_child(instance)
		instance.queue_free()
		instance = null

	if new_packed_scene:
		instance = new_packed_scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
		add_child(instance)
		instance.owner = self
		_instance_process_mode = instance.process_mode
		instance.process_mode = Node.PROCESS_MODE_DISABLED

func deactivate() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
