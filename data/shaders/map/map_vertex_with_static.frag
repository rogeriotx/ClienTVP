attribute vec2 a_TexCoord;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2; // for the auxiliar texture
uniform vec2 u_Offset;
uniform vec2 u_Resolution;
vec4 calculatePosition();
void main()
{
    gl_Position = calculatePosition();
    v_TexCoord = (u_TextureMatrix * vec3(a_TexCoord,1.0)).xy;

    // they are static
    v_TexCoord2 = gl_Position.xy;

    // fix the image to no longer be replicated
    v_TexCoord2 = vec2(v_TexCoord2.x/2.0, v_TexCoord2.y/2.0);
    v_TexCoord2.x += 0.5;
    v_TexCoord2.y += 0.5;
}

uniform mat3 u_TransformMatrix;
uniform mat3 u_ProjectionMatrix;
attribute vec2 a_Vertex;
vec4 calculatePosition() {
    return vec4(u_ProjectionMatrix * u_TransformMatrix * vec3(a_Vertex.xy, 1.0), 1.0);
}