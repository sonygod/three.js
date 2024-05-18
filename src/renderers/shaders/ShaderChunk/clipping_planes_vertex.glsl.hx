package three.renderers.shaders.ShaderChunk;

class ClippingPlanesVertex {
    public static var shader:String = '
#if NUM_CLIPPING_PLANES > 0

	vClipPosition = - mvPosition.xyz;

#end
';
}