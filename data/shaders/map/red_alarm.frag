uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{
    vec4 color = texture2D(u_Tex0, v_TexCoord);
    float d = u_Time * 2.0;
    color.x += (1.0 + sin(d)) * 0.1;
    gl_FragColor = color;
}
