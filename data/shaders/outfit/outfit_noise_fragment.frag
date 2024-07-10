uniform mat4 u_ColorMatrix;
uniform vec4 u_Color;
uniform float u_Opacity;
uniform float u_Intensity;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform float u_Time;
uniform vec2 u_Resolution;
const float PI = 3.1415926535897932;

// speed
const float speed = 0.16;
const float speed_x = 0.13;
const float speed_y = 0.12;

// geometry
const float intensity = 100.;
const int steps = 3;
const float frequency = 100.0;
const int angle = 7; // better when a prime

// reflection and emboss
const float delta = 1000.;
const float intence = 10.2;
const float emboss = 1.;

//---------- crystals effect
float col(vec2 coord)
{
    float delta_theta = 2.0 * PI / float(angle);
    float col = 0.0;
    float theta = 0.0;

    for(int i = 0; i < steps; i++) {
        vec2 adjc = coord;
        theta = delta_theta*float(i);
        adjc.x += cos(theta)*u_Time*speed + u_Time * speed_x * u_Intensity;
        adjc.y -= sin(theta)*u_Time*speed - u_Time * speed_y * u_Intensity;
        col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*frequency) * intensity * u_Intensity;
    }
    return cos(col);
}

void main(void)
{
    gl_FragColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    if(texcolor.r > 0.9) {
        gl_FragColor *= texcolor.g > 0.9 ? u_ColorMatrix[0] : u_ColorMatrix[1];
    } else if(texcolor.g > 0.9) {
        gl_FragColor *= u_ColorMatrix[2];
    } else if(texcolor.b > 0.9) {
        gl_FragColor *= u_ColorMatrix[3];
    }

    // for normal outfit
    vec2 p = v_TexCoord, c1 = p, c2 = p;
    float cc1 = col(c1);

    c2.x += u_Resolution.x/delta;
    float dx = emboss*u_Intensity*(cc1-col(c2))/delta;

    c2.x = p.x;
    c2.y += u_Resolution.y/delta;
    float dy = emboss*u_Intensity*(cc1-col(c2))/delta;

    c1.x += dx;
    c1.y += dy;

    float alpha = 1.+dot(dx,dy)*intence*u_Intensity;

    vec4 textureColor = texture2D(u_Tex0, c1);
    vec4 textureColorMaskColor = texture2D(u_Tex0, v_TexCoord2);
    if(textureColorMaskColor.r > 0.9) {
        textureColor *= textureColorMaskColor.g > 0.9 ? u_ColorMatrix[0] : u_ColorMatrix[1];
    } else if(textureColorMaskColor.g > 0.9) {
        textureColor *= u_ColorMatrix[2];
    } else if(textureColorMaskColor.b > 0.9) {
        textureColor *= u_ColorMatrix[3];
    }
    gl_FragColor = textureColor*(alpha)*u_Color;
}
