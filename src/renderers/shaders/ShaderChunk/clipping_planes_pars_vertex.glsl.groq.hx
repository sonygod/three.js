package three.renderers.shaders.ShaderChunk;

@:glsl("
#if NUM_CLIPPING_PLANES > 0

varying vec3 vClipPosition;

#endif
")
class ClippingPlanesParsVertex {}