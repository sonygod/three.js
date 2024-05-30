package three.js.src.renderers.shaders.ShaderChunk;

#if glsl
@:glslFile("iridescence_pars_fragment.glsl")
class IridescenceParsFragmentGLSL {
	#if USE_IRIDESCENCEMAP

	uniform sampler2D iridescenceMap;

	#end

	#if USE_IRIDESCENCE_THICKNESSMAP

	uniform sampler2D iridescenceThicknessMap;

	#end
}
#end