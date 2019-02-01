#version 300 es
#define cell_size 8.0f
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

// Changeable
uniform float u_SeaLevel;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec2 generate_point(vec2 cell) {
    vec2 p = vec2(cell.x, cell.y);
    p += fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)) * 43758.5453)));
    return p * cell_size;
}

float worleyNoise(vec2 pixel) {
    vec2 cell = floor(pixel / cell_size);

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

    return shortest_distance / cell_size;
}

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float interpNoise2D(float x, float y) {
	float intX = floor(x);
	float fractX = fract(x);
	float intY = floor(y);
	float fractY = fract(y);

	float v1 = random1(vec2(intX, intY), vec2(0));
	float v2 = random1(vec2(intX + 1.0f, intY), vec2(0));
	float v3 = random1(vec2(intX, intY + 1.0f), vec2(0));
	float v4 = random1(vec2(intX + 1.0f, intY + 1.0f), vec2(0));

	float i1 = mix(v1, v2, fractX);
	float i2 = mix(v3, v4, fractX);
	return mix(i1, i2, fractY);
}

float fbm2(vec2 p) {
	float total = 0.0f;
	float persistence = 0.5f;
	int octaves = 8;

	for(int i = 0; i < octaves; i++) {
		float freq = pow(2.0f, float(i));
		float amp = pow(persistence, float(i));

		total += interpNoise2D(p.x * freq, p.y * freq) * amp;
	}

	return total;
}

float perturbedFbm(vec2 p)
  {
      vec2 q = vec2( fbm2( p + vec2(0.0,0.0) ),
                     fbm2( p + vec2(5.2,1.3) ) );

      vec2 r = vec2( fbm2( p + 4.0*q + vec2(9.7,9.2) ),
                     fbm2( p + 4.0*q + vec2(8.3,2.8) ) );

      return fbm2( p + 4.0*r );
  }


void main()
{
	float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
	
	// color mountains
	out_Col = vec4(perturbedFbm(fs_Pos.xz / max(fs_Pos.y, 4.0f)) * mix(vec3(119.0f, 46.0f, 84.0f) / 255.0f, vec3(204.0f, 80.0f, 53.0f) / 255.0f, fs_Pos.y / 10.0f), 1.0f);

	out_Col = vec4(out_Col.rgb / smoothstep(0.1f, 0.3f, fs_Pos.y), 1.0f);

	// color sealine
	if(out_Col.b > 0.7f) {
		out_Col = vec4(mix(vec3(131.0f, 37.0f, 150.0f)/255.0f, out_Col.rgb / 4.0f, fs_Pos.y / 0.7f), 1.0f);
	}

	// color "water"
	if(u_SeaLevel > 0.0 && abs(fs_Pos.y - u_SeaLevel) < 0.00001) {
		out_Col.rgb = vec3(100.0f, 170.0f, 131.0f) / 255.0f;
	} else if (fs_Pos.y < 0.1) {
		out_Col.rgb = mix(vec3(100.0f, 170.0f, 131.0f) / 255.0f, vec3(1.f, 1.f, 1.f), fs_Pos.y * 10.0);
	}

}
