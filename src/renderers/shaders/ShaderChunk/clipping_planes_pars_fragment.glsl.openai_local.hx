package three.renderers.shaders.ShaderChunk;

class ClippingPlanesParsFragmentGlsl {
    public static inline var shader: String = "
        #if NUM_CLIPPING_PLANES > 0

            varying vec3 vClipPosition;

            uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];

        #endif
    ";
}