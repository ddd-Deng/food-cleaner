shader_type canvas_item;

uniform float init_phase = 0.0;
uniform float strength : hint_range(0.0, 0.1) = 0.02; // 摆动强度
uniform float speed = 1.0;                           // 摆动速度

void fragment() {
    vec2 uv = UV;
    // 核心公式：用正弦波偏移X轴，偏移量随UV.y(高度)增加而变大
    uv.x += sin(init_phase + UV.y * 10.0 + TIME * speed) * strength * UV.y;
    COLOR = texture(TEXTURE, uv);
}