package three.js.src.renderers.shaders.ShaderChunk;

class NormalParsFragment {
    public static var glsl:String =
        #ifndef FLAT_SHADED

            varying vec3 vNormal;

            #ifdef USE_TANGENT

                varying vec3 vTangent;
                varying vec3 vBitangent;

            #endif

        #endif
    ;
}