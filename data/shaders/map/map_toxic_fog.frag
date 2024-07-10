uniform float u_Time;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1;
varying vec2 v_TexCoord;
uniform mat3 u_TextureMatrix;
uniform vec2 u_MapCoords;

vec2 direction = vec2(1.0,0.3);
float speed = 0.05;
float pressure = 0.9;
float zoom = 0.5;

vec3 toxicEffect(vec3 color)
{
    return vec3(color.x * 0.15,
                color.y * 0.6,
                color.z * 0.15);
}

void main(void)
{
    vec2 b = vec2(-u_TextureMatrix[1][1]/u_TextureMatrix[0][0], 1.0);

    vec2 offset = (u_MapCoords + (v_TexCoord * b) + (direction * u_Time * speed)) / zoom;
    vec3 bgcol = texture2D(u_Tex0, v_TexCoord).xyz;
    vec3 fogcol = texture2D(u_Tex1, offset).xyz;
    fogcol = toxicEffect(fogcol);
    vec3 col = bgcol + fogcol*pressure;
    gl_FragColor = vec4(col,1.0);
}
