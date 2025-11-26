shader_type canvas_item;
render_mode blend_disabled, unshaded;

// A shader by The Gingerjam, thanks al1-ce for their rgb2hsv and hsv2rgb code: https://godotshaders.com/shader/hsv-adjustment/, the rest is by me
// You can also detect edges by hue or saturation by changing all .z in line 37 and 39 to .x or .y

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float add : hint_range(0.0, 0.002, 0.0001);
uniform float threshold : hint_range(0.0, 1.0, 0.001);
uniform vec4 edgeColour : source_color;
uniform vec4 nonEdgeColour : source_color;

uniform float inner_radius : hint_range(0.0, 0.5) = 0.25;
uniform float inner_fade_radius : hint_range(0.0, 0.5) = 0.0;
const vec2 center = vec2(0.5, 0.5);
const float outer_radius = 0.5;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR; // preserve modulate (including alpha) for fragment
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
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
	// Ensure the fade radius is in a sane range (not greater than inner)
	float inner_fade = clamp(inner_fade_radius, 0.0, inner - 0.001);
	float d = distance(UV, center);

	vec4 base = texture(screen_texture, SCREEN_UV);

	// If we're fully inside the faded-out center, or outside the outer radius, show base
	if (d < inner_fade || d > outer_radius) {
		COLOR = base;
	}
	else
	{
		// Compute alpha multiplier based on distance. This creates a linear fade from
		// 0 at inner_fade to 1 at inner. For distances >= inner the multiplier is 1.
		float alpha_mul = 1.0;
		if (d < inner) 
		{
			float span = inner - inner_fade;
			alpha_mul = clamp((d - inner_fade) / span, 0.0, 1.0);
		}

		// Apply effect when inside the ring (inner_fade..outer_radius), with alpha scaled
		// by the computed multiplier
		{
			// Apply cool lurker effect
			vec3 up    = rgb2hsv((texture(screen_texture, vec2(SCREEN_UV.x, SCREEN_UV.y + add))).rgb);
			vec3 down  = rgb2hsv((texture(screen_texture, vec2(SCREEN_UV.x, SCREEN_UV.y - add))).rgb);
			vec3 left  = rgb2hsv((texture(screen_texture, vec2(SCREEN_UV.x - add, SCREEN_UV.y))).rgb);
			vec3 right = rgb2hsv((texture(screen_texture, vec2(SCREEN_UV.x + add, SCREEN_UV.y))).rgb);
			vec3 real  = rgb2hsv((texture(screen_texture, SCREEN_UV)).rgb);

			vec3 color;

			if(    abs(real.z - up.z   ) > threshold 
				|| abs(real.z - down.z ) > threshold 
				|| abs(real.z - left.z ) > threshold 
				|| abs(real.z - right.z) > threshold)
			{
				color = edgeColour.rgb;
			} 
			else {
				color = nonEdgeColour.rgb;
			}

			// Reapply node modulate alpha (preserve transparency) and apply inner fade multiplier
			float final_alpha = vertex_color.a * alpha_mul;
			COLOR = alpha_blend(base, vec4(color, final_alpha));
		}
	}
}

