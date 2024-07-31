shader_type canvas_item;

uniform sampler2D backgroundImage : filter_nearest, repeat_enable;
const float backgroundImageRatio = (96.0f / 640.0f) / (128.0f / 360.0f);

uniform float movementSpeed = 0.01;

void fragment() {
	if (COLOR.r == 0.0 && COLOR.g == 0.0 && COLOR.b == 0.0) {
		vec2 offset = vec2(TIME, TIME) * movementSpeed;
		vec2 uv = SCREEN_UV * 5.0;
		uv *= vec2(1.0, backgroundImageRatio);
		uv += offset;
		
		uv.y += floor(uv.x) * 0.25 * 2.0;
		
		
		COLOR = texture(backgroundImage, uv);
	}
}