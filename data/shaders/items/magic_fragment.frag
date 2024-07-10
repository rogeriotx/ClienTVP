uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1;
uniform float u_Time;

#define R 136.0
#define G 136.0
#define B 255.0

#define OVERLAY_ALPHA 0.5

void main()
{
	vec4 color = texture2D(u_Tex0, v_TexCoord);
    vec4 effectColor = texture2D(u_Tex1, v_TexCoord2);
	
	vec4 c = vec4(effectColor.rgb, color.a);
	c.rgb *= vec3(R / 255.0, G / 255.0, B / 255.0);

    gl_FragColor = mix(color, c, OVERLAY_ALPHA);

	if(gl_FragColor.a < 0.01) {
		discard;
	}
}