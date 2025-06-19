@tool
extends Node3D

class_name AssetPlacerWithPhysics

# Asset holder scenes
const ASSET_HOLDER = preload("res://addons/asset_placer_with_physics/scenes/asset_holder.tscn")
const AssetHolderPhysics = preload("res://addons/asset_placer_with_physics/scripts/asset_holder_physics.gd")
const ASSET_HOLDER_PHYSICS = preload("res://addons/asset_placer_with_physics/scenes/asset_holder_physics.tscn")

# Static classes
const InstanceNamer = preload("res://addons/asset_placer_with_physics/scripts/instance_namer.gd")
const Instancer = preload("res://addons/asset_placer_with_physics/scripts/instancer.gd")

# Prop placer parameters
@export_category("Prop Parameters")
@export var asset_packed_scene: PackedScene:
	set(value):
		_on_asset_packed_scene_changed(value)
	get:
		return _asset_packed_scene
@export var asset_shape_3d: Shape3D:
	set(value):
		_on_asset_shape_3d_changed(value)
	get:
		return _asset_shape_3d

func _on_asset_packed_scene_changed(new_packed_scene: PackedScene) -> void:
	_try_instantiate_asset_holder_preview()
	_asset_holder_instance_preview.set_packed_scene(new_packed_scene)
	if _asset_holder_instance_preview.instance:
		_asset_instance_base_name = _asset_holder_instance_preview.instance.name
	_asset_packed_scene = new_packed_scene
	
func _on_asset_shape_3d_changed(new_shape_3d: Shape3D) -> void:
	_try_instantiate_asset_holder_preview()
	_asset_holder_instance_preview.shape_3d = new_shape_3d
	_asset_shape_3d = new_shape_3d


@export_range(0.0,10.0,0.1) var _asset_gravity_scale: float = 5.0
@export_flags_2d_physics var _asset_collision_layer: int
@export_flags_2d_physics var _asset_collision_mask: int

@export_category("Prop Spawner Parameters")
@export var _enabled = false
@export var _spawn_asset_key: Key = KEY_P
@export var _spawned_assets_parent: Node

@export_category("Spawn Position Parameters")
@export_range(0.0,100.0,0.1) var spawned_asset_height: float = 1.0:
	set(value):
		_on_spawned_asset_height_changed(value)
	get:
		return _spawned_asset_height


func _on_spawned_asset_height_changed(new_asset_height: float) -> void:
	_try_instantiate_asset_holder_preview()
	_spawned_asset_height = new_asset_height
	_asset_holder_instance_preview.position.y = _spawned_asset_height


@export_category("Spawn Rotation Parameters")
@export var _randomize_rotation: bool = true
@export_range(0.0,180.0,1.0, "radians_as_degrees") var _random_x_rotation_range: float = deg_to_rad(180.0)
@export_range(0.0,180.0,1.0, "radians_as_degrees") var _random_y_rotation_range: float = deg_to_rad(180.0)
@export_range(0.0,180.0,1.0, "radians_as_degrees") var _random_z_rotation_range: float = deg_to_rad(180.0)

@export_category("Physics Deactivation Parameters")
@export_range(0.05,10.0,0.05) var _max_physics_simulation_time: float = 1.25
@export_range(0.0,10.0,0.001) var min_linear_velocity_length_threshold: float = 0.025:
	get: 
		return _min_linear_velocity_length_threshold
	set(value):
		_min_linear_velocity_length_threshold = value
		_min_linear_velocity_length_squared_threshold = value*value
		_asset_holder_physics.min_linear_velocity_length_squared_threshold = _min_linear_velocity_length_squared_threshold
		
@export_range(0.0,10.0,0.001) var min_angular_velocity_length_threshold: float = 0.025:
	get: 
		return _min_angular_velocity_length_threshold
	set(value):
		_min_angular_velocity_length_threshold = value
		_min_angular_velocity_length_squared_threshold = value*value
		_asset_holder_physics.min_angular_velocity_length_squared_threshold = _min_angular_velocity_length_squared_threshold
		




# Prop placer variables
var editor_undo_redo_manager: EditorUndoRedoManager
var _asset_holder_physics: AssetHolderPhysics
var _asset_holder_instance_preview: AssetHolder

var _asset_packed_scene: PackedScene
var _asset_shape_3d: Shape3D
var _asset_instance_base_name: String
var _spawned_asset_height: float = 1.0

var _min_linear_velocity_length_threshold: float = 0.025
var _min_linear_velocity_length_squared_threshold: float
var _min_angular_velocity_length_threshold: float = 0.025
var _min_angular_velocity_length_squared_threshold: float

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		return
	add_to_group(AssetPlacerConstants.ACTIVE_ASSET_PLACERS_WITH_PHYSICS_GROUP)
	
	_try_instantiate_asset_holder_preview()
	_on_asset_packed_scene_changed(_asset_packed_scene)
	_on_asset_shape_3d_changed(_asset_shape_3d)
	_on_spawned_asset_height_changed(_spawned_asset_height)
	
	if !_asset_holder_physics:
		_asset_holder_physics = Instancer.instantiate(ASSET_HOLDER_PHYSICS,self,self)

func _try_instantiate_asset_holder_preview() -> void:
	if !_asset_holder_instance_preview:
		_asset_holder_instance_preview = Instancer.instantiate(ASSET_HOLDER,self,self)

func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		return
	remove_from_group(AssetPlacerConstants.ACTIVE_ASSET_PLACERS_WITH_PHYSICS_GROUP)
	
	if _asset_holder_instance_preview:
		remove_child(_asset_holder_instance_preview)
		_asset_holder_instance_preview.queue_free()
		_asset_holder_instance_preview = null
		
	if _asset_holder_physics:
		remove_child(_asset_holder_physics)
		_asset_holder_physics.queue_free()
		_asset_holder_physics = null
	
func _ready() -> void:
	if !Engine.is_editor_hint():
		return
	get_tree().call_group(AssetPlacerConstants.ASSET_PLACER_WITH_PHYSICS_PLUGIN_GROUP,AssetPlacerConstants.ON_ASSET_PLACER_WITH_PHYSICS_READY_METHOD,self)

func try_place_asset(keycode: Key, global_position: Vector3) -> void:
	if !_enabled or _spawn_asset_key != keycode:
		return
	
	var error: bool = false
	if !_asset_packed_scene:
		push_error("No packed scene was assigned to this AssetPlacerWithPhysics instance.")
		error = true
	if !_spawned_assets_parent:
		push_error("No spawned assets parent was assigned to this AssetPlacerWithPhysics instance.")
		error = true
	if error:
		return
		
	get_tree().call_group(AssetPlacerConstants.ASSET_PLACER_WITH_PHYSICS_PLUGIN_GROUP,AssetPlacerConstants.ON_ASSET_SPAWNED_METHOD,_max_physics_simulation_time)

	var asset_holder_instance: AssetHolder = Instancer.instantiate(ASSET_HOLDER,self,self)
	asset_holder_instance.set_packed_scene(_asset_packed_scene)
	asset_holder_instance.shape_3d =_asset_shape_3d 
	asset_holder_instance.gravity_scale = _asset_gravity_scale
	asset_holder_instance.collision_layer = _asset_collision_layer
	asset_holder_instance.collision_mask = _asset_collision_mask
	asset_holder_instance.instance.name = InstanceNamer.get_valid_instance_name(_asset_instance_base_name,_spawned_assets_parent)
	asset_holder_instance.global_position = global_position + _spawned_asset_height*Vector3.UP
	if _randomize_rotation:
		asset_holder_instance.global_rotation = Vector3(_random_x_rotation_range*randf_range(-1.0,1.0),_random_y_rotation_range*randf_range(-1.0,1.0),_random_z_rotation_range*randf_range(-1.0,1.0))
	
	_asset_holder_physics.add_asset_holder(asset_holder_instance, _max_physics_simulation_time)

func on_physics_simulation_updated(delta: float) -> void:
	_asset_holder_physics.on_physics_simulation_updated(delta)

func on_physics_simulation_completed() -> void:
	var instance_name_to_global_transform_3d: Dictionary[String,Transform3D] = _asset_holder_physics.on_physics_simulation_completed()
	
	for instance_name in instance_name_to_global_transform_3d:
		editor_undo_redo_manager.create_action("Create %s in %s " % [instance_name,_spawned_assets_parent.name])
		editor_undo_redo_manager.add_do_method(Instancer,"add_instance_to",_asset_packed_scene,_spawned_assets_parent,get_tree().edited_scene_root,instance_name,instance_name_to_global_transform_3d[instance_name])
		editor_undo_redo_manager.add_undo_method(Instancer,"try_free_instance_from", instance_name,_spawned_assets_parent)
		editor_undo_redo_manager.commit_action(true)
