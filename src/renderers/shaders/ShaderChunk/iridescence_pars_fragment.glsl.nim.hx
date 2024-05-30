package three.src.renderers.shaders.ShaderChunk;

@:build(macro.Compiler.includeFile("three.js/src/renderers/shaders/ShaderChunk/iridescence_pars_fragment.glsl"))
class IridescenceParsFragment {

  public static var iridescenceMap(default, null):String = '';
  public static var iridescenceThicknessMap(default, null):String = '';

  public static macro function __build() {
    var content = sys.io.File.getContent("three.js/src/renderers/shaders/ShaderChunk/iridescence_pars_fragment.glsl");
    return macro $v{content};
  }
}