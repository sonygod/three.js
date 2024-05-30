package three.src.renderers.shaders.ShaderChunk;

class Displacementmap_vertex {
    public static inline function get():String {
        #if use_displacementmap
        return "transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );\n";
        #else
        return "";
        #end
    }
}