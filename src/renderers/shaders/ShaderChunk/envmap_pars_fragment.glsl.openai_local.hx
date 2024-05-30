class EnvmapParsFragment {
    public static inline var GLSL: String = '
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
';
}