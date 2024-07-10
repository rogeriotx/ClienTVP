uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;

void main()
{
  vec4 originalColor = texture2D(u_Tex0, v_TexCoord);
  if (originalColor.a > 0.0) {
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  } else {
    gl_FragColor = originalColor;
  }
}