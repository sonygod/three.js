package three.renderers.shaders.ShaderChunk;

@:glsl("vert")
class EnvmapParsVertex {

    #if (defined(USE_BUMPMAP) || defined(USE_NORMALMAP) || defined(PHONG) || defined(LAMBERT))

        #define ENV_WORLDPOS

    #end

    #ifdef ENV_WORLDPOS

        @:varying var vWorldPosition:Vec3;

    #else

        @:varying var vReflect:Vec3;
        @:uniform var refractionRatio:Float;

    #end

}