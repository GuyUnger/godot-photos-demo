shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 color : source_color = vec4(1.0);

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(mat3(MODEL_MATRIX) * NORMAL),vec3(0.5));
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz;
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

float checker(vec2 uv, vec3 vertex) {
	float line_width = 0.03;
	float lines = max(
			smoothstep(1.0 - line_width, 1.0 - line_width, mod(uv.x - line_width * 0.5, 1.0)),
			smoothstep(1.0 - line_width, 1.0 - line_width, mod(uv.y - line_width * 0.5, 1.0))
		);
	float checkers = mix(mod(floor(uv.x) + floor(uv.y), 2.0), mod(floor(uv.x * 2.0) + floor(uv.y * 2.0), 2.0), 0.15) * 0.5;
	return mix(checkers, 1.0, lines / max(length(vertex * 0.15) - 0.1, 1.0));
}

float triplanar_checker(vec3 p_weights, vec3 p_triplanar_pos, vec3 vertex) {
	float samp = 0.0;
	samp += checker(p_triplanar_pos.xy, vertex) * p_weights.z;
	samp += checker(p_triplanar_pos.xz, vertex) * p_weights.y;
	samp += checker(p_triplanar_pos.zy * vec2(-1.0,1.0), vertex) * p_weights.x;
	return samp;
}

void fragment() {
	float checker = triplanar_checker(uv1_power_normal, uv1_triplanar_pos, VERTEX);
	ALBEDO = vec3(mix(0.4, 1.0, checker)) * color.rgb;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	ROUGHNESS = mix(0.9, 0.6, checker);
}
