#version 300 es
#define cell_size 1.0f
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec2 generate_point(vec2 cell) {
    vec2 p = vec2(cell.x * cell_size, cell.y * cell_size);
    return p + fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)) * 43758.5453)));
}

float worleyNoise(vec2 pixel) {
	pixel *= cell_size;

    vec2 cell = floor(pixel);

    vec2 point = generate_point(cell);

    float shortest_distance = length(pixel - point);

    // compute shortest distance from cell + neighboring cell points

    for(float i = -1.0f; i <= 1.0f; i += 1.0f) {
        float ncell_x = cell.x + i;
        for(float j = -1.0f; j <= 1.0f; j += 1.0f) {
            float ncell_y = cell.y + j;

            // get the point for that cell
            vec2 npoint = generate_point(vec2(ncell_x, ncell_y));

            // compare to previous distances
            float distance = length(pixel - npoint);
            if(distance < shortest_distance) {
                shortest_distance = distance;
            }
        }
    }

    return shortest_distance;
}


void main()
{
	//float gray = worleyNoise(vec2(fs_Pos.x, fs_Pos.z));
	//out_Col = vec4(gray, gray, gray, 1.0f);
	float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
	out_Col = vec4(mix(vec3(119.0f, 46.0f, 84.0f) / 255.0f,
					   vec3(204.0f, 80.0f, 53.0f) / 255.0f,
					   fs_Pos.y), 1.0f-t);
	float max = max(out_Col.r, max(out_Col.g, out_Col.b));
	if(max > 1.0f) {
		out_Col / max;
	}
    //out_Col = vec4(mix(vec3(0.5 * (fs_Sine + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}
