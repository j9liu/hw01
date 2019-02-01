#version 300 es
precision highp float;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting

in vec4 fs_Pos;
out vec4 out_Col;

float noise(float i) {
	return fract(sin(vec2(203.311f * float(i), float(i) * sin(0.324f + 140.0f * float(i))))).x;
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

void main() {
  out_Col = vec4(mix(fs_Pos.xyz / 5.0f, vec3(25.0f, 17.0f, 51.0f) / 255.0, vec3(104.0f, 12.0f, 69.0f)/255.0f), 1.0f);

  if(fs_Pos.y > 0.0f) {
	float stripe = pow(fbm(2.0f * fs_Pos.x + fs_Pos.y + fs_Pos.z), 5.0f);
	if(stripe > 1.0f && fs_Pos.y > 0.0f) {
		out_Col += vec4(0.05, 0.1, 0.08, max(0.0f, fs_Pos.y)) * fs_Pos.y;
	}
  }
 
  float star = pow(noise(noise(fs_Pos.y) * 323.433f * noise(fs_Pos.x)), 3.0f);
	if(star > 0.999f) {
	  	out_Col += vec4(0.7, 0.7, 0.6, max(0.0f, fs_Pos.y)) * fs_Pos.y;
  	}

  	if(star > 0.985f) {
	  	out_Col += vec4(0.4, 0.4, 0.3, max(0.0f, fs_Pos.y)) * abs(fs_Pos.y);
  	}
  	
  float zigzag = pow(noise(fs_Pos.x + 4.31 * fs_Pos.y), 3.0f);
  if(zigzag < 0.00001f) {
  	out_Col += vec4(0.5, 0.5, 0.3, max(0.0f, fs_Pos.y)) * .2f;
  }

}
