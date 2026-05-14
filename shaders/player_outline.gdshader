shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness = 2.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	COLOR = base;
	
	//float alpha = base.a > 0.0 ? 1.0 : 0.0;
//
	//if (alpha <= 0.0) {
		//vec2 pixel = TEXTURE_PIXEL_SIZE * outline_thickness;
		//vec2 offsets[8] = vec2[](
			//vec2(1.0, 0.0),
			//vec2(-1.0, 0.0),
			//vec2(0.0, 1.0),
			//vec2(0.0, -1.0),
			//vec2(1.0, 1.0),
			//vec2(-1.0, 1.0),
			//vec2(1.0, -1.0),
			//vec2(-1.0, -1.0)
		//);
//
		//float outline_alpha = 0.0;
		//for (int i = 0; i < 8; i++) {
			//vec2 sample_uv = UV + offsets[i] * pixel;
			//float sample_alpha = texture(TEXTURE, sample_uv).a;
			//outline_alpha = max(outline_alpha, sample_alpha > 0.0 ? 1.0 : 0.0);
		//}
//
		//COLOR = vec4(outline_color.rgb, outline_color.a * outline_alpha);
	//} else {
		//COLOR = vec4(base.rgb, 1.0);
	//}
}
