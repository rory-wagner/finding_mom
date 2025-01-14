extends TileMap

const all_layers: Array[String] = [
	"Room 0",
	"Room 1",
	"Room 2",
	"Room 3"
]

# returns an error indicating if the layer was found or not
func set_layer(l: String) -> int:
	if all_layers.find(l) == -1:
		return FAILED
	for i in get_layers_count():
		set_layer_enabled(i, get_layer_name(i) == l)
	return OK
