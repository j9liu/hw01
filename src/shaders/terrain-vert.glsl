#version 300 es
#define cell_size 8.0f

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
                     fbm2( p + vec2(4.8,-1.3) ) );

      vec2 r = vec2( fbm2( p + 4.0*q + vec2(1.4,9.2) ),
                     fbm2( p + 4.0*q + vec2(2.5,7.8) ) );

      return fbm2( p + 4.0*r );
  }


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

vec2 worleyPoint(vec2 pixel) {
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
                point = npoint;
            }
        }
    }

    return point;
}

vec3 smoothstep3(vec3 edge0, vec3 edge1, vec3 v) {
  return vec3(smoothstep(edge0.x, edge1.x, v.x),
              smoothstep(edge0.y, edge1.y, v.y),
              smoothstep(edge0.z, edge1.z, v.z));
} 

float sawtooth_wave(float x, float freq, float amplitude) {
	return (x * freq - floor(x * freq)) * amplitude;
}

void main()
{

  fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));
  
  // Calculate initial mountains.
  vec4 modelposition = vec4(0.5 * vs_Pos.x + .4f * fbm(vs_Pos.x), 0.8 * pow(fbm2(0.05 * vs_Pos.x + u_PlanePos.x, 0.1 * vs_Pos.z + u_PlanePos.y), 6.0f), vs_Pos.z, 1.0);

  /*// Texture the mountains
  vec4 newpos = modelposition + 0.07f * perturbedFbm(vec2(modelposition.y, modelposition.y));
  if(modelposition.y > 0.0f) {
    vec3 interp = mix(newpos.xyz, modelposition.xyz, modelposition.y);
    modelposition += 0.6f * vec4(interp.x, interp.y, interp.z, 1.0f);
  }
  
  // Deform for marsh-like streams
  if(modelposition.y > 0.4f && modelposition.y < 0.78f) {
    modelposition.y = 0.0f;
  }

  // Make plateaus
  if(modelposition.y > 0.14f && modelposition.y < 2.0f) {
    vec2 point = worleyPoint(modelposition.xz);
    if(fbm2(point) > 0.9f) {
      modelposition.y = 1.5f + (modelposition.y / .80f) * (worleyNoise(point) + random1(point, point));
    }
  }*/

  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
  fs_Pos = modelposition.xyz;
  
}