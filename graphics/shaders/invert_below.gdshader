shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 sample = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec3 blending = COLOR.rgb;
	vec3 result = mix(sample.rgb, vec3(1.0) - sample.rgb, blending);
	COLOR.rgb = result;
}
