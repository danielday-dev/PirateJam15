shader_type canvas_item;

uniform sampler2D screenTexture : hint_screen_texture, filter_linear_mipmap;

uniform float blurAmount : hint_range(0.0, 5.0) = 1.0;
uniform vec3 backgroundColor : source_color = vec3(1.0, 1.0, 1.0);
uniform float backgroundFactor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	COLOR.rgb = mix(textureLod(screenTexture, SCREEN_UV, blurAmount).rgb, backgroundColor, backgroundFactor);
}
