shader_type canvas_item;

// uniforms are received from gdscripts
uniform bool flash_white_on = false;

// const list
const vec4 white = vec4(1.0);

void vertex() {
	//VERTEX.y += abs(sin(TIME * 20.0));
}

// Called for every pixel the material is visible on.
void fragment() {
	//COLOR = texture(TEXTURE, UV);
	if (flash_white_on){
		vec4 color_of_player_sprite = texture(TEXTURE, UV);
		if (color_of_player_sprite.a > 0.0) {
			COLOR = white;
		} else {
			COLOR.a = 0.0;
		}
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
