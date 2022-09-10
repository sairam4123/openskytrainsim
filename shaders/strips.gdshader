shader_type spatial;

uniform vec4 color1: hint_color;
uniform vec4 color2: hint_color;
uniform float strip_count = 10;
uniform float direction = 1;
uniform float width_shift = 0.5;


void fragment() {
	float pos = mix(UV.x, UV.y, direction) * strip_count;
	float value = floor(fract(pos) + width_shift);
	ALBEDO = mix(color1, color2, value).rgb;
}