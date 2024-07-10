uniform float u_Time;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1;
uniform vec2 u_Resolution;
varying vec2 v_TexCoord;

#define LAYERS 7
#define DEPTH .8
#define WIDTH .3
#define SPEED .6

void main( )
{
	const mat3 p = mat3(13.323122,23.5112,21.71123,21.1212,28.7312,11.9312,21.8112,14.7212,61.3934);
	vec2 uv = v_TexCoord.xy;
    uv.x = uv.x * (u_Resolution.x / u_Resolution.y);
	vec3 acc = vec3(0.0);
	float dof = 5.*sin(u_Time*.1);
	for (int i=0;i<LAYERS;i++) {
		float fi = float(i);
		vec2 q = uv*(1.+fi*DEPTH);
		q += vec2(q.y*(WIDTH*mod(fi*7.238917,1.)-WIDTH*.5),SPEED*u_Time/(1.+fi*DEPTH*.03));
		vec3 n = vec3(floor(q),31.189+fi);
		vec3 m = floor(n)*.00001 + fract(n);
		vec3 mp = (31415.9+m)/fract(p*m);
		vec3 r = fract(mp);
		vec2 s = abs(mod(q,1.)-.5+.9*r.xy-.45);
		s += .01*abs(2.*fract(10.*q.yx)-1.); 
		float d = .6*max(s.x-s.y,s.x+s.y)+max(s.x,s.y)-.01;
		float edge = .005+.05*min(.5*abs(fi-5.-dof),1.);
		acc += vec3(smoothstep(edge,-edge,d)*(r.x/(1.+.02*fi*DEPTH)));
	}

    vec3 bgcol = texture2D(u_Tex0, v_TexCoord).xyz;
    vec3 col = bgcol + acc;
	gl_FragColor = vec4(vec3(col),1.0);
}