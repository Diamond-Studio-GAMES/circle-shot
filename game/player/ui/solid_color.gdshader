shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float power = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, color.rgb, power);
}
