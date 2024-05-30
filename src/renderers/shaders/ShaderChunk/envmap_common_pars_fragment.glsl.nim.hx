package three.renderers.shaders.ShaderChunk;

class EnvmapCommonParsFragment {
    public static inline function get() {
        #if use_envmap {
            var envMapIntensity:Float;
            var flipEnvMap:Float;
            var envMapRotation:Mat3;

            #if envmap_type_cube {
                var envMap:SamplerCube;
            #else
                var envMap:Sampler2D;
            #end
        }
        #end
    }
}