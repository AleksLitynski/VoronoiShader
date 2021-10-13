shader_type spatial;

const bool show_debug = false;
uniform vec3 default_cell_color = vec3(0.2, 0.5, 0.6);
uniform vec3 edge_color = vec3(0.01, 0.1, 0.1);
uniform sampler2D points; // | x1, x2, x3, etc |
							// | y1, y2, y3, etc |
uniform float line_width = 0.0005;

vec2 get_point(int idx) {
	return texelFetch(points, ivec2(idx, 0), 0).xy;
}

vec3 get_point_color(int idx) {
	return texelFetch(points, ivec2(idx, 1), 0).rgb;
}

int get_point_count() {
	return int(textureSize(points, 0).x);
}

bool in_range(float x, float y, float range) {
	return x - range < y && x + range > y;
}

bool in_range_vec2(vec2 x, vec2 y, float range) {
	return in_range(x.x, y.x, range) && in_range(x.y, y.y, range);
}

bool is_ahead_of(vec2 self, vec2 other, vec2 to_test) {
	float dist = (distance(other, self) / 2.0) - line_width;
	vec2 normal = normalize(other - self);
	vec2 p = (normal * dist) + self;
	return dot(normal, (to_test - p)) > 0.0;
}

void fragment() {
	vec2 uv = UV; // VERTEX.xy to work in absolute coordinates instead of 0.0 - 1.0. Useful if I panned to scale the mesh

	vec2 nearest_1 = vec2(uintBitsToFloat(0x7F800000)); // positive infinity
	vec2 nearest_2 = vec2(uintBitsToFloat(0x7F800000));
	vec3 nearest_color = default_cell_color;
	
	// go through each point and get the two nearest the current pixel
	for(int i = 0; i < get_point_count(); i++) {
		vec2 point_new = get_point(i);
		float dist_new = distance(uv, point_new);
		float dist_1 = distance(uv, nearest_1);
		float dist_2 = distance(uv, nearest_2);
		if (dist_new < dist_1) {
			nearest_2 = nearest_1;
			nearest_1 = point_new;
			nearest_color = get_point_color(i);
		} else {
			// just in case we found the closest item on the first try
			if (dist_new < dist_2) {
				nearest_2 = point_new;
			}
		}
		if (show_debug && in_range_vec2(uv, point_new, 0.02)) {
			ALBEDO = get_point_color(i);
		}
	}

	// check if we're on the edge between the two points (with some window of error so the line is thicker than 1px)
	float dist_to_nearest_1 = distance(uv, nearest_1);
	float dist_to_nearest_2 = distance(uv, nearest_1);
	bool is_between = is_ahead_of(nearest_1, nearest_2, uv) && is_ahead_of(nearest_2, nearest_1, uv);
	if (in_range(dist_to_nearest_1, dist_to_nearest_2, line_width * 2.0) && is_between) {
		// either draw the edge's color or...
		ALBEDO = edge_color;
	} else {
		// draw the cell's color
		ALBEDO = nearest_color;
	}
	
	// form a bubble at the joints between edges
	// this doesn't work. Technically, it forms a bubble, but it's an unnatural hexagon shape
	//	if(distance(nearest_1, nearest_2) > 0.1) {
	//		int meniscus_close = 0;
	//		for (int i = 0; i < get_point_count(); i++) {
	//			if (abs(dist_to_nearest_1 - distance(UV, get_point(i))) < 0.04) {
	//				meniscus_close += 1;
	//			}
	//		}
	//		if (meniscus_close >= 4) {
	//			ALBEDO = edge_color;
	//			METALLIC = 0.0;
	//			ROUGHNESS = 0.0;
	//		}
	//	}

}
