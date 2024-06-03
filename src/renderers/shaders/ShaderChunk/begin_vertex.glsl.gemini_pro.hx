class Shader {
  public static function main(): String {
    return 
    '
    vec3 transformed = vec3( position );

    #ifdef USE_ALPHAHASH

      vPosition = vec3( position );

    #endif
    ';
  }
}