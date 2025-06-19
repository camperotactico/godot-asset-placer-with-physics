static func add_instance_to(packed_scene: PackedScene, instance_parent: Node, instance_owner: Node,instance_name: String, instance_global_transform: Transform3D) -> void:
	var instance: Node3D = instantiate(packed_scene,instance_parent,instance_owner)
	instance.name = instance_name
	instance.global_transform = instance_global_transform
	
static func try_free_instance_from(instance_name: String, instance_parent: Node) -> void:
	var instance = instance_parent.get_node_or_null(instance_name)
	if instance:
		instance_parent.remove_child(instance)
		instance.queue_free()
		
static func instantiate(packed_scene: PackedScene, parent: Node, owner: Node) -> Node:
	var instance: Node = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	parent.add_child(instance)
	instance.owner = owner
	return instance
