shader_type spatial;

uniform float progress : hint_range(0.0, 1.0) = 1;
uniform vec4 color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Green

void fragment() {
    vec2 uv = UV * 2.0 - 1.0; // UV from center (-1 to 1)
    float angle = atan(uv.y, uv.x);
    if (angle < 0.0) {
        angle += TAU;
    }
    float radius = length(uv);
    float ring_inner = 0.8;
    float ring_outer = 0.9;
    float progress_angle = progress * TAU;

    if (radius > ring_inner && radius < ring_outer && angle < progress_angle) {
        ALBEDO = color.rgb;
        ALPHA = color.a;
    } else {
        discard;
    }
}
