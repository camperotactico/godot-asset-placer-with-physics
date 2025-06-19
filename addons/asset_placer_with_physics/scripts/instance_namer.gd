static func get_valid_instance_name(base_name: String, instance_parent: Node)-> String:
	var candidate_name: String = _get_random_name(base_name)
	var max_tries: int = AssetPlacerConstants.NUMBER_OF_RANDOM_VALID_NAMES_WARNING
	while instance_parent.has_node(candidate_name):
		max_tries -= 1
		if max_tries == 0:
			push_warning("Could not find a valid unique instance name for the prop after %d tries. Consider using a different parent or increasing the PropPlacerContants.MAX_NUMBER_IN_RANDOM_NAMES." % AssetPlacerConstants.NUMBER_OF_RANDOM_VALID_NAMES_WARNING)
			break
		candidate_name = _get_random_name(base_name)
	return candidate_name

static func _get_random_name(base_name: String) -> String:
	return "%s%d" % [base_name, randi()%AssetPlacerConstants.MAX_NUMBER_IN_RANDOM_NAMES]
