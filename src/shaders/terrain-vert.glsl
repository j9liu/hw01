#version 300 es
#define cell_size 1.0f

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;

float noise(float i) {
	return fract(sin(vec2(203.311f * float(i), float(i) * sin(0.324f + 140.0f * float(i))))).x;
}

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}


float interpNoise1D(float x) {
	float intX = floor(x);	
	float fractX = fract(x);

	float v1 = noise(intX);
	float v2 = noise(intX + 1.0f);
	return mix(v1, v2, fractX);
}

float fbm(float x) {
	float total = 0.0f;
	float persistence = 0.5f;
	int octaves = 8;

	for(int i = 0; i < octaves; i++) {
		float freq = pow(2.0f, float(i));
		float amp = pow(persistence, float(i));

		total += interpNoise1D(x * freq) * amp;
	}

	return total;
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

float fbm2(float x, float y) {
	float total = 0.0f;
	float persistence = 0.5f;
	int octaves = 8;

	for(int i = 0; i < octaves; i++) {
		float freq = pow(2.0f, float(i));
		float amp = pow(persistence, float(i));

		total += interpNoise2D(x * freq, y * freq) * amp;
	}

	return total;
}


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
                shortest_distance = mix(distance, shortest_distance, pixel.x);
            }
        }
    }

    return -shortest_distance;
}

float cubeNoise(vec2 pixel) {
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
                shortest_distance = mix(distance, shortest_distance, pixel.x);
            }
        }
    }

    return -shortest_distance;
}

float sawtooth_wave(float x, float freq, float amplitude) {
	return (x * freq - floor(x * freq)) * amplitude;
}

void main()
{

  fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));
  //vec4 modelposition = vec4(vs_Pos.x, 5.0f * fbm(vs_Pos.z + fs_Sine), vs_Pos.z, 1.0); // weird waves
  vec4 modelposition = vec4(0.5 * vs_Pos.x + .4f * fbm(vs_Pos.x), 0.8 * pow(fbm2(0.05 * vs_Pos.x + u_PlanePos.x, 0.1 * vs_Pos.z + u_PlanePos.y), 6.0f), vs_Pos.z, 1.0);
  //vec4 modelposition = vec4(vs_Pos.x, u_PlanePos.y + fbm(worleyNoise(vec2(fbm2(u_PlanePos.x, u_PlanePos.y), vs_Pos.z))), vs_Pos.z, 1.0);	
  //vec4 modelposition = vec4(vs_Pos.x, vs_Pos.x + 3.0f * fs_Sine + sawtooth_wave(vs_Pos.x, 0.42f, 1.0f), vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
  fs_Pos = modelposition.xyz;
}