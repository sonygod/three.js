package three.renderers.shaders.ShaderChunk;

class ClearcoatParsFragmentGLSL {
    public static inline var glsl:String = "
        #ifdef USE_CLEARCOATMAP

            uniform sampler2D clearcoatMap;

        #endif

        #ifdef USE_CLEARCOAT_NORMALMAP

            uniform sampler2D clearcoatNormalMap;
            uniform vec2 clearcoatNormalScale;

        #endif

        #ifdef USE_CLEARCOAT_ROUGHNESSMAP

            uniform sampler2D clearcoatRoughnessMap;

        #endif
    ";
}