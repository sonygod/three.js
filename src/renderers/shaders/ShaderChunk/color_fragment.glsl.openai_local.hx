// File path: three.js/src/renderers/shaders/ShaderChunk/color_fragment.glsl.hx

package three.renderers.shaders.ShaderChunk;

class ColorFragmentGLSL {
    public static inline var code: String = "
#if defined( USE_COLOR_ALPHA )

    diffuseColor *= vColor;

#elif defined( USE_COLOR )

    diffuseColor.rgb *= vColor;

#endif
    ";
}