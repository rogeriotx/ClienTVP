uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
varying vec2 v_TexCoord3;
varying vec2 v_Position;
uniform sampler2D u_Tex0;
uniform float u_Time;
uniform vec2 u_Resolution;

void main()
{
  gl_FragColor = texture2D(u_Tex0, v_TexCoord);
  vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
  vec4 texcolor2 = texture2D(u_Tex0, v_TexCoord3);
  float d = u_Time * 2.0;
  texcolor.x += (1.0 + sin(d)) * 0.25;
  texcolor.y += (1.0 + sin(d * 2.0)) * 0.25;
  texcolor.z += (1.0 + sin(d * 4.0)) * 0.25;
  if(gl_FragColor.a < 0.01) {
        if(texcolor2.a > 0.01) {
            gl_FragColor = vec4(texcolor.x, texcolor.y, texcolor.z, 1.0);
        } else {
            discard;
        }
    }
}


