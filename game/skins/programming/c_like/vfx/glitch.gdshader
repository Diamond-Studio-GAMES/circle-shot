shader_type canvas_item;

uniform float glitch = 0.0;
uniform float shift_glitch = 0.0;
uniform sampler2D shift_glitch_texture;

void fragment() {
	vec2 uv = UV + vec2((texture(shift_glitch_texture, UV).r - 0.5) * shift_glitch, 0.0);
	COLOR.r = texture(TEXTURE, vec2(uv.x - glitch, uv.y)).r;
	COLOR.g = texture(TEXTURE, uv).g;
	COLOR.b = texture(TEXTURE, vec2(uv.x + glitch, uv.y)).b;
	COLOR.a = texture(TEXTURE, uv).a;
}