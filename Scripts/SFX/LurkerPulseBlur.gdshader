shader_type canvas_item;
render_mode blend_disabled, unshaded;

// A shader by The Gingerjam, thanks al1-ce for their rgb2hsv and hsv2rgb code: https://godotshaders.com/shader/hsv-adjustment/, the rest is by me
// You can also detect edges by hue or saturation by changing all .z in line 37 and 39 to .x or .y

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float inner_radius : hint_range(0.0, 0.5) = 0.25;
// Soft inner fade radius: distances < this will be fully transparent (show base).
// Values must be <= inner_radius. Set to 0 to preserve a hard inner cutout.
uniform float inner_fade_radius : hint_range(0.0, 0.5) = 0.0;
const vec2 center = vec2(0.5, 0.5);
const float outer_radius = 0.5;
uniform float blurLod = 1.0;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR; // preserve modulate (including alpha) for fragment
}

vec4 alpha_blend(vec4 base, vec4 new)
{
	float sum = clamp(new.a + base.a, 0.0001, 1.0);
	float rate = new.a / sum;

	vec4 res = mix(base, new, rate);
	res.a = clamp(new.a + base.a, 0.0, 1.0);

	return res;
}

void fragment()
{
	float inner = clamp(inner_radius, 0.0, outer_radius);
	// Keep fade radius in a sane range (<= inner)
	float inner_fade = clamp(inner_fade_radius, 0.0, inner - 0.001);
	float d = distance(UV, center);

	vec4 base = texture(screen_texture, SCREEN_UV);

	// If fully inside the faded center (show base) or outside outer radius, show base
	if (d < inner_fade || d > outer_radius) {
		COLOR = base;
	}
	else
	{
		// Compute linear alpha multiplier: 0 at inner_fade -> 1 at inner, 1 for d >= inner
		float alpha_mul = 1.0;
		if (d < inner) 
		{
			float span = inner - inner_fade;
			alpha_mul = clamp((d - inner_fade) / span, 0.0, 1.0);
		}

		vec3 color = textureLod(screen_texture, SCREEN_UV, blurLod).rgb;

		// Reapply node modulate alpha (preserve transparency) and apply inner fade multiplier
		float final_alpha = vertex_color.a * alpha_mul;
		COLOR = alpha_blend(base, vec4(color, final_alpha));
	}
}
    
