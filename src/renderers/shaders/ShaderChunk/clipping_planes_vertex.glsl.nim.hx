package three.renderers.shaders.ShaderChunk;

class clipping_planes_vertex {
    static public var code: String =
#if NUM_CLIPPING_PLANES > 0

	"vClipPosition = - mvPosition.xyz;"

#end
    ;
}