uniform float u_Time;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1;
uniform sampler2D u_Tex2;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2; // for the auxiliar texture
uniform mat3 u_TextureMatrix;
uniform vec2 u_MapCoords;
uniform vec2 u_Resolution;

float speed = 3.0;
float intensity = 0.75;
float delta = 0.15;

const float sampleDist = 0.8;
const float sampleStrength = 1.1;

float breathingImageCut = 0.2;

void main(void)
{
    vec2 auxTexCoord2 = v_TexCoord2;

    breathingImageCut *= abs(sin(speed * 0.5 * u_Time) * delta);

    // lets create a breathing effect
    // lets cut out breathingImageCut of the image
    auxTexCoord2.x *= (1.0 - breathingImageCut);
    auxTexCoord2.y *= (1.0 - breathingImageCut);

    auxTexCoord2.x += breathingImageCut/2.0;
    auxTexCoord2.y += breathingImageCut/2.0;

    // 0.5,0.5 is the center of the screen
    // so substracting v_TexCoord from it will result in
    // a vector pointing to the middle of the screen
    vec2 dir = 0.5 - auxTexCoord2;

    // calculate the distance to the center of the screen
    float dist = sqrt(dir.x*dir.x + dir.y*dir.y);

    // normalize the direction (reuse the distance)
    dir = dir/dist;

    vec3 bgcol = texture2D(u_Tex0, v_TexCoord).xyz;
    vec3 icycol = texture2D(u_Tex1, auxTexCoord2).xyz;

    vec3 shadercol = texture2D(u_Tex1, auxTexCoord2).xyz;

    float t = dist * sampleStrength;
    t = clamp(t ,0.0,1.0); //0 &lt;= t &lt;= 1

    intensity += sin(speed * u_Time) * delta;
    vec3 col = mix(bgcol, shadercol, t * intensity);
    
    gl_FragColor = vec4(col, 1.0);
}
