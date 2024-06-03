import haxe.macro.Context;
import haxe.macro.Expr;

class GlslConverter {
  static function convert(code:String):String {
    var lines = code.split("\n");
    var output = "";
    for (line in lines) {
      if (line.startsWith("#ifdef USE_INSTANCING_MORPH")) {
        output += "#if defined(USE_INSTANCING_MORPH)\n";
        continue;
      }
      if (line.startsWith("#endif")) {
        output += "#endif\n";
        continue;
      }
      if (line.contains("MORPHTARGETS_COUNT")) {
        output += line.replace("MORPHTARGETS_COUNT", "MORPH_TARGETS_COUNT") + "\n";
        continue;
      }
      output += line + "\n";
    }
    return output;
  }
}

class Main {
  static function main() {
    var code = """
    #ifdef USE_INSTANCING_MORPH

    float morphTargetInfluences[ MORPHTARGETS_COUNT ];

    float morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;

    for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {

      morphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;

    }
    #endif
    """;
    var haxeCode = GlslConverter.convert(code);
    trace(haxeCode);
  }
}