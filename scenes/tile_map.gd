extends TileMap

const all_layers: Array[String] = [
	"Room 0",
	"Room 1",
	"Room 2",
	"Room 3"
]

var current_layer: int = 0

# returns an error indicating if the layer was found or not
func set_layer(l: String) -> int:
	if all_layers.find(l) == -1:
		return FAILED
	for i in get_layers_count():
		set_layer_enabled(i, get_layer_name(i) == l)
		if get_layer_name(i) == l:
			current_layer = i
	return OK

# loops through all layers and returns the first that is enabled
func get_first_enabled_layer_index() -> int:
	for i in range(get_layers_count()):
		if is_layer_enabled(i):
			return i
	return -1  # None found

# returns all tiles that match a source (file), and atlas coordinates on the source
func get_tile_positions_by_id(target_source_id: int, target_atlas_coords: Vector2i, target_alt: int = 0) -> Array:
	var positions := []
	var layer := get_first_enabled_layer_index()
	if layer == -1:
		return positions  # No enabled layers

	for cell in get_used_cells(layer):
		var source_id = get_cell_source_id(layer, cell)
		var atlas_coords = get_cell_atlas_coords(layer, cell)
		var alt = get_cell_alternative_tile(layer, cell)

		if source_id == target_source_id and atlas_coords == target_atlas_coords and alt == target_alt:
			positions.append(cell)
	return positions

# currently the only used walkable terrain is source 2, atlas (20, 10)
func get_all_mob_spawnable_locations() -> Array:
	return get_tile_positions_by_id(2, Vector2i(20, 10), 0)
