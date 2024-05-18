package three.shaderlib.ShaderChunk;

class ClippingPlanesParsVertex {
  public static var shader: String = '
#if NUM_CLIPPING_PLANES > 0

	varying vec3 vClipPosition;

#endif
';
}