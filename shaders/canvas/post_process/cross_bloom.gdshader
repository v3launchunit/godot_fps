shader_type canvas_item;

render_mode blend_add;

uniform float intensity : hint_range(0.0, 16.0, 0.1) = 1.0;
uniform float threshold : hint_range(0.0, 4.0, 0.01) = 0.9;
uniform int spread : hint_range(0, 100, 1) = 10;
uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_nearest;

bool is_above_threshold(vec3 in_col) {
	return in_col.x >= threshold || in_col.y >= threshold || in_col.z >= threshold;
}

void fragment() {
	vec3 col = max(texture(screen_texture, SCREEN_UV).xyz - threshold, 0);

	for (int i = 1; i < spread; i++) {
		float x_dist = float(i) * SCREEN_PIXEL_SIZE.x;
		float y_dist = float(i) * SCREEN_PIXEL_SIZE.y;
		vec3 col_up_left = max(texture(screen_texture, SCREEN_UV + vec2(-x_dist, y_dist)).xyz - threshold, 0);
		vec3 col_up_right = max(texture(screen_texture, SCREEN_UV + vec2(x_dist, y_dist)).xyz - threshold, 0);
		vec3 col_down_left = max(texture(screen_texture, SCREEN_UV + vec2(-x_dist, -y_dist)).xyz - threshold, 0);
		vec3 col_down_right = max(texture(screen_texture, SCREEN_UV + vec2(x_dist, -y_dist)).xyz - threshold, 0);

		col += col_up_left / (float(i) * 4.0);
		col += col_up_right / (float(i) * 4.0);
		col += col_down_left / (float(i) * 4.0);
		col += col_down_right / (float(i) * 4.0);
	}

	COLOR.xyz = col * intensity;
}
