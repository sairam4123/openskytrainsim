shader_type spatial;

uniform vec4 color1: hint_color;
uniform vec4 color2: hint_color;
uniform sampler2D tex;
uniform float strip_count = 20;
uniform float direction = 1;
uniform float width_shift = 0.5;


float range_lerp(float v, float a, float b, float x, float y) {
	return x + (y - x) * ((v - a) / (b - a));
}

void fragment() {
	float pos = mix(UV.x, UV.y, direction) * strip_count;
	float value = floor((fract(pos) + width_shift) * 2.0);
	ALBEDO = texture(tex, vec2(range_lerp(value, 0.0, 2.0, 0.0, 1.0), UV.x)).rgb;
}