package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.fragment)
class ClearcoatNormalFragmentBegin {

  static function build() {
    #if useClearcoat
      var clearcoatNormal = nonPerturbedNormal;
    #end
    return [];
  }

  static var fragment = build();

}