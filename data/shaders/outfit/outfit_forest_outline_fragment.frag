uniform mat4 u_ColorMatrix;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
varying vec2 v_TexCoord3;
varying vec2 v_Position;
uniform sampler2D u_Tex0;
uniform float u_Time;
uniform vec2 u_Resolution;

const float offset = 0.1 / 128.0;

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

    if(gl_FragColor.a < 0.01) {
        float a = texture2D(u_Tex0, vec2(v_TexCoord.x + offset, v_TexCoord.y)).a +
            texture2D(u_Tex0, vec2(v_TexCoord.x, v_TexCoord.y - offset)).a +
            texture2D(u_Tex0, vec2(v_TexCoord.x - offset, v_TexCoord.y)).a +
            texture2D(u_Tex0, vec2(v_TexCoord.x, v_TexCoord.y + offset)).a;
            
      if (texcolor.a < 1.0 && a > 0.0) {
            gl_FragColor = vec4(0.1 + abs(0.5 - mod(u_Time, 1.0)), 0.5, 0.1, 1.0);
        } else {
            gl_FragColor = texcolor;
        }
    }
}
