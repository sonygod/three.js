package three.renderers.shaders.ShaderChunk;

@:glsl("
#ifdef USE_IRIDESCENCEMAP

	uniform sampler2D iridescenceMap;

#endif

#ifdef USE_IRIDESCENCE_THICKNESSMAP

	uniform sampler2D iridescenceThicknessMap;

#endif
")
class IridescenceParsFragment {}