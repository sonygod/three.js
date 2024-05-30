package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("alphahash_fragment.glsl"))
class AlphahashFragment {

  static var source =
#ifdef USE_ALPHAHASH

	"if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;"

#end
;

}