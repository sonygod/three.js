package three.src.renderers.shaders.ShaderChunk;

class EnvmapParsFragment {
    #if use_envmap
    public var reflectivity:Float;

    #if use_bumpmap || use_normalmap || phong || lambert
        #define ENV_WORLDPOS
    #end

    #if ENV_WORLDPOS
        public var vWorldPosition:three.math.Vector3;
        public var refractionRatio:Float;
    #else
        public var vReflect:three.math.Vector3;
    #end

    #end
}