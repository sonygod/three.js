package three.renderers.shaders.ShaderChunk;

class BeginVertex {
    public static function main() {
        return "
            vec3 transformed = vec3( position );

            #if (USE_ALPHAHASH)
                vPosition = vec3( position );
            #end
        ";
    }
}