@tool
extends Node

# Asset holder scenes
const AssetHolder = preload("res://addons/asset_placer_with_physics/scripts/asset_holder.gd")

var min_linear_velocity_length_squared_threshold: float 
var min_angular_velocity_length_squared_threshold: float 

var _active_asset_holder_to_remaining_simulation_time: Dictionary[AssetHolder,float]
var _just_activated_asset_holders: Array[AssetHolder]
var _deactivated_asset_holders: Array[AssetHolder]

func _enter_tree() -> void:
	_active_asset_holder_to_remaining_simulation_time = {}
	_deactivated_asset_holders = []
	_just_activated_asset_holders = []
	
func _exit_tree() -> void:
	for active_asset_holder: AssetHolder in _active_asset_holder_to_remaining_simulation_time.keys():
		active_asset_holder.queue_free()
	for deactivated_asset_holder: AssetHolder in _deactivated_asset_holders:
		deactivated_asset_holder.queue_free()
	_active_asset_holder_to_remaining_simulation_time.clear()
	_just_activated_asset_holders.clear()
	_deactivated_asset_holders.clear()

func add_asset_holder(asset_holder_instance: AssetHolder, remaining_simulation_time: float) -> void:
	_active_asset_holder_to_remaining_simulation_time[asset_holder_instance] = remaining_simulation_time
	_just_activated_asset_holders.append(asset_holder_instance)
	
func on_physics_simulation_updated(delta: float) -> void:
	if _active_asset_holder_to_remaining_simulation_time.size() == 0:
		return
	
	var asset_holders_to_deactivate: Array[AssetHolder] = []
	for active_asset_holder: AssetHolder in _active_asset_holder_to_remaining_simulation_time.keys():
		_active_asset_holder_to_remaining_simulation_time[active_asset_holder] -= delta
		if _just_activated_asset_holders.has(active_asset_holder):
			continue
		if _active_asset_holder_to_remaining_simulation_time[active_asset_holder] <= 0.0:
			asset_holders_to_deactivate.append(active_asset_holder)
			continue
		if active_asset_holder.linear_velocity.length_squared() <= min_linear_velocity_length_squared_threshold and active_asset_holder.angular_velocity.length_squared() <= min_angular_velocity_length_squared_threshold:
			asset_holders_to_deactivate.append(active_asset_holder)
			continue

	_just_activated_asset_holders.clear()
	for instance_to_deactivate in asset_holders_to_deactivate:
		_active_asset_holder_to_remaining_simulation_time.erase(instance_to_deactivate)
		instance_to_deactivate.deactivate()
		_deactivated_asset_holders.append(instance_to_deactivate)

func on_physics_simulation_completed() -> Dictionary[String,Transform3D]:
	var instance_name_to_global_transform_3d: Dictionary[String,Transform3D] = {}
	
	for active_asset_holder: AssetHolder in _active_asset_holder_to_remaining_simulation_time.keys():
		active_asset_holder.deactivate()
		_deactivated_asset_holders.append(active_asset_holder)
	_active_asset_holder_to_remaining_simulation_time.clear()

	for deactivated_asset_holder: AssetHolder in _deactivated_asset_holders:
		instance_name_to_global_transform_3d[deactivated_asset_holder.instance.name] = deactivated_asset_holder.instance.global_transform
		deactivated_asset_holder.queue_free()
	_deactivated_asset_holders.clear()
	
	return instance_name_to_global_transform_3d
