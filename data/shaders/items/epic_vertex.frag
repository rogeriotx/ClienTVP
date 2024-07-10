attribute vec2 a_TexCoord;
attribute vec2 a_Vertex;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform mat3 u_TransformMatrix;
uniform mat3 u_ProjectionMatrix;
uniform float u_Depth;
uniform float u_Time;

vec2 effectTextureSize = vec2(256.0, 256.0);
vec2 direction = vec2(0.0, -1.0);
float speed = 80.0;

void main()
{
    vec2 offset = direction * speed * u_Time;
	gl_Position = vec4((u_ProjectionMatrix * u_TransformMatrix * vec3(a_Vertex.xy, 1.0)).xy, u_Depth / 12384.0, 1.0);
	v_TexCoord = (u_TextureMatrix * vec3(a_TexCoord, 1.0)).xy;
	v_TexCoord2 = ((a_TexCoord + offset) / effectTextureSize);

}