package renderers.shaders.ShaderChunk;

class BeginVertex {
    public static var shader:String = "
        vec3 transformed = vec3( position );

        #ifdef USE_ALPHAHASH
            vPosition = vec3( position );
        #endif
    ";
}