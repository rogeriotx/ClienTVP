uniform float u_Time;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1;
uniform sampler2D u_Tex2;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2; // for the auxiliar texture
uniform mat3 u_TextureMatrix;
uniform vec2 u_MapCoords;
uniform vec2 u_Resolution;
const float PI = 3.1415926535897932;

float speed = 3.0;
float intensity = 0.75;
float delta = 0.15;

const float sampleDist = 0.8;
const float sampleStrength = 1.1;

float breathingImageCut = 0.2;

const float heatSpeed = 0.05;
const float speed_x = 0.04;
const float speed_y = 0.03;

// geometry
const float heatIntensity = 20.;
const int steps = 2;
const float frequency = 3.0;
const int angle = 20; // better when a prime

// reflection and emboss
const float heatDelta = 350.;
const float intence = 100.0;
const float emboss = 0.8;

vec4 purplescale(vec4 color)
{
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return mix(vec4(gray, 0, gray, 1), color, 0.4);
}

//---------- crystals effect
float col(vec2 coord)
{
    float delta_theta = 2.0 * PI / float(angle);
    float col = 0.0;
    float theta = 0.0;
    for(int i = 0; i < steps; i++) {
        vec2 adjc = coord;
        theta = delta_theta*float(i);
        adjc.x += cos(theta)*u_Time*heatSpeed + u_Time * speed_x;
        adjc.y -= sin(theta)*u_Time*heatSpeed - u_Time * speed_y;
        col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*frequency)*heatIntensity;
    }
    return cos(col);
}

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

    vec3 bgcol = purplescale(texture2D(u_Tex0, v_TexCoord)).xyz;
    vec3 icycol = texture2D(u_Tex1, auxTexCoord2).xyz;

    float t = dist * sampleStrength;
    t = clamp(t ,0.0,1.0); //0 &lt;= t &lt;= 1

    vec2 p = auxTexCoord2, c1 = p, c2 = p;
    float cc1 = col(c1);

    c2.x += u_Resolution.x/heatDelta;
    float dx = emboss*(cc1-col(c2))/heatDelta;

    c2.x = p.x;
    c2.y += u_Resolution.y/heatDelta;
    float dy = emboss*(cc1-col(c2))/heatDelta;

    c1.x += dx;
    c1.y += dy;

    vec3 shadercol = texture2D(u_Tex1, c1).xyz;

    intensity += sin(speed * u_Time) * delta;
    vec3 col = mix(bgcol, shadercol, t * intensity);
    
    gl_FragColor = vec4(col, 1.0);
}
