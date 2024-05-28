package three.shader;

class BeginVertexShader {
  public static var source:String = "
    vec3 transformed = vec3( position );

    #ifdef USE_ALPHAHASH

    vPosition = vec3( position );

    #endif
  ";
}