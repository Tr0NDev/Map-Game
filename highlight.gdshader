shader_type canvas_item;

uniform vec3 target_color = vec3(0.0);
uniform float tolerance : hint_range(0.0, 0.3) = 0.08;
uniform bool active = false;

// jusqu'à 13 pays annexés
uniform vec3 extra_colors[13];
uniform int extra_count = 0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float diff = abs(col.r - target_color.r) + abs(col.g - target_color.g) + abs(col.b - target_color.b);
	bool is_target = col.a > 0.01 && diff < tolerance;
	
	// vérifier aussi les couleurs annexées
	if (!is_target) {
		for (int i = 0; i < extra_count; i++) {
			float d = abs(col.r - extra_colors[i].r) + abs(col.g - extra_colors[i].g) + abs(col.b - extra_colors[i].b);
			if (d < tolerance) {
				is_target = true;
				break;
			}
		}
	}
	
	float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = (!active || is_target) ? col : vec4(vec3(grey), col.a);
}