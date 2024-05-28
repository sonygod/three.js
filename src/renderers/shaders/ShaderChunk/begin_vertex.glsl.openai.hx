package three.shader;

class BeginVertexShaderChunk {
  public static var SOURCE:String = "
    vec3 transformed = vec3( position );

    #ifdef USE_ALPHAHASH

    vPosition = vec3( position );

    #endif
    ";
}