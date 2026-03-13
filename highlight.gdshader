shader_type canvas_item;
uniform vec3 target_color = vec3(0.0);
uniform vec3 player_color = vec3(0.0);
uniform float tolerance : hint_range(0.0, 0.3) = 0.08;
uniform bool active = false;
uniform vec3 extra_colors[13];
uniform int extra_count = 0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	float diff = abs(col.r - target_color.r) + abs(col.g - target_color.g) + abs(col.b - target_color.b);
	bool is_selected = col.a > 0.01 && diff < tolerance;
	
	if (!is_selected) {
		for (int i = 0; i < extra_count; i++) {
			float d = abs(col.r - extra_colors[i].r) + abs(col.g - extra_colors[i].g) + abs(col.b - extra_colors[i].b);
			if (d < tolerance) {
				is_selected = true;
				break;
			}
		}
	}
	
	float player_diff = abs(col.r - player_color.r) + abs(col.g - player_color.g) + abs(col.b - player_color.b);
	bool is_player = col.a > 0.01 && player_diff < tolerance;
	
	float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	
	if (!active) {
		COLOR = col;
	} else if (is_selected) {
		COLOR = vec4(col.r * 0.5, col.g * 0.8, col.b * 1.4, col.a);
	} else if (is_player) {
		COLOR = vec4(col.r * 0.5, col.g * 1.4, col.b * 0.5, col.a);
	} else {
		COLOR = vec4(vec3(grey), col.a);
	}
}