uniform mat4 u_ColorMatrix;
uniform vec4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
varying vec2 v_Position;
uniform sampler2D u_Tex0;
uniform float u_Time;

float speed = 3.0;
float lasting = 5.0;

void main()
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
    
    if(texcolor.a > 0.9) {
        gl_FragColor.xyz *= max(1.0, 4.0 - abs(mod(u_Time * speed, lasting)));
    }

    gl_FragColor *= u_Color;
    if(gl_FragColor.a < 0.01) discard;
}