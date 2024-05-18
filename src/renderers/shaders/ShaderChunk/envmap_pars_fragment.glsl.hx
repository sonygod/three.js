package three.renderers.shaders.ShaderChunk;

class EnvmapParsFragment {
    @:glsl(" vert ")
    @:glsl(" frag ")
    public static var shader: String = "

#ifdef USE_ENVMAP

    uniform float reflectivity;

    #if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )

        #define ENV_WORLDPOS

    #endif

    #ifdef ENV_WORLDPOS

        varying vec3 vWorldPosition;
        uniform float refractionRatio;
    #else
        varying vec3 vReflect;
    #endif

#endif
";
}