@tool
extends EditorPlugin

const ASSET_PLACER_WITH_PHYSICS = "AssetPlacerWithPhysics"
const AssetPlacerWithPhysics = preload("res://addons/asset_placer_with_physics/scripts/asset_placer_with_physics.gd")
const ASSET_PLACER_WITH_PHYSICS_ICON = preload("res://addons/asset_placer_with_physics/icons/Falling3DAssetIcon.svg")


var _mouse_position: Vector2
var _is_simulating_physics: bool
var _interrupt_physics_simulation: bool
var _remaining_physics_simulation_time: float

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		return
	add_to_group(AssetPlacerConstants.ASSET_PLACER_WITH_PHYSICS_PLUGIN_GROUP)
	add_custom_type(ASSET_PLACER_WITH_PHYSICS,"Node3D",AssetPlacerWithPhysics,ASSET_PLACER_WITH_PHYSICS_ICON)
	
	scene_changed.connect(_on_scene_changed)

func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		return
	
	remove_from_group(AssetPlacerConstants.ASSET_PLACER_WITH_PHYSICS_PLUGIN_GROUP)
	remove_custom_type(ASSET_PLACER_WITH_PHYSICS)
	
	scene_changed.disconnect(_on_scene_changed)

func _ready() -> void:
	if !Engine.is_editor_hint():
		return
	_is_simulating_physics = false
	_interrupt_physics_simulation = false
	_remaining_physics_simulation_time = 0.0
	
func on_asset_placer_with_physics_ready(asset_placer_with_physics: AssetPlacerWithPhysics) -> void:
	asset_placer_with_physics.editor_undo_redo_manager = get_undo_redo()

func _handles(object: Object) -> bool:
	return true

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseMotion:
		_mouse_position = event.position
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventKey and event.pressed and !event.echo:
		var global_position: Vector3 = _mouse_to_3d_global_position(viewport_camera,_mouse_position)
		get_tree().call_group(AssetPlacerConstants.ACTIVE_ASSET_PLACERS_WITH_PHYSICS_GROUP,AssetPlacerConstants.TRY_PLACE_ASSET_METHOD,event.keycode,global_position)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _mouse_to_3d_global_position(viewport_camera: Camera3D, mouse_position: Vector2) -> Vector3:
	var global_position: Vector3 = Vector3.ZERO
	var raycast_origin: Vector3 = viewport_camera.project_ray_origin(mouse_position)
	var raycast_target: Vector3 = raycast_origin + AssetPlacerConstants.MOUSE_TO_GLOBAL_POSITION_RAYCAST_DISTANCE*viewport_camera.project_ray_normal(mouse_position)
	
	var space_state: PhysicsDirectSpaceState3D = get_tree().edited_scene_root.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(raycast_origin,raycast_target)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if !result.is_empty():
		global_position = result.position
		
	return global_position

func on_asset_spawned(max_simulation_time: float) -> void:
	_remaining_physics_simulation_time = max(_remaining_physics_simulation_time,max_simulation_time)
	if _is_simulating_physics:
		return
	else:
		_simulate_physics()

func _simulate_physics() -> void:
	_is_simulating_physics = true
	_interrupt_physics_simulation = false
	
	var all_rigid_bodies_3d_in_scene: Array[RigidBody3D] = _get_all_rigid_bodies_3d_in_children(get_tree().edited_scene_root)
	var rigid_body_3d_in_scene_to_freeze: Array[bool] = []
	for physics_body_3d in all_rigid_bodies_3d_in_scene:
		if physics_body_3d:
			rigid_body_3d_in_scene_to_freeze.append(physics_body_3d.freeze)
			physics_body_3d.freeze = true
	PhysicsServer3D.set_active(true)
	
	while _remaining_physics_simulation_time >= 0.0 and !_interrupt_physics_simulation:
		await get_tree().physics_frame
		if _interrupt_physics_simulation:
			break
		var delta: float = get_physics_process_delta_time()
		_remaining_physics_simulation_time -= delta
		get_tree().call_group(AssetPlacerConstants.ACTIVE_ASSET_PLACERS_WITH_PHYSICS_GROUP,AssetPlacerConstants.ON_PHYSICS_SIMULATION_UPDATED_METHOD,delta)

	PhysicsServer3D.set_active(false)
	for i in all_rigid_bodies_3d_in_scene.size():
		if all_rigid_bodies_3d_in_scene[i]:
			all_rigid_bodies_3d_in_scene[i].freeze = rigid_body_3d_in_scene_to_freeze[i]
	get_tree().call_group(AssetPlacerConstants.ACTIVE_ASSET_PLACERS_WITH_PHYSICS_GROUP,AssetPlacerConstants.ON_PHYSICS_SIMULATION_COMPLETED_METHOD)
		
	_remaining_physics_simulation_time = 0.0
	_is_simulating_physics = false
	_interrupt_physics_simulation = false
	
func _on_scene_changed(new_scene_root: Node) -> void:
	if _is_simulating_physics:
		_interrupt_physics_simulation = true

func _get_all_rigid_bodies_3d_in_children(node: Node, array : Array[RigidBody3D]= []) -> Array[RigidBody3D]:
	if node is RigidBody3D:
		array.append(node)
	for child in node.get_children():
		array = _get_all_rigid_bodies_3d_in_children(child,array)
	return array
