uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{
    vec4 color = texture2D(u_Tex0, v_TexCoord);
    color.x = 0.0;
    color.y = 0.0;
    color.z = 0.0;
    gl_FragColor = color;
}
