import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class GlslConverter {

  public static function convert(js:String):String {
    var lines = js.split("\n");
    var result = "";

    for (line in lines) {
      if (line.startsWith("export default")) {
        result += line.replace("export default", "class Glsl { public static function main() { return ");
        result += line.replace("`", "\"");
      } else {
        result += line.replace("`", "\"");
      }
    }

    result += "\n\t}\n}";

    return result;
  }
}

class Glsl {
  public static function main():String {
    return """
      #ifdef USE_MORPHTARGETS

	  #ifndef USE_INSTANCING_MORPH

		  uniform float morphTargetBaseInfluence;
		  uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];

	  #endif

	  uniform sampler2DArray morphTargetsTexture;
	  uniform ivec2 morphTargetsTextureSize;

	  vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {

		  int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		  int y = texelIndex / morphTargetsTextureSize.x;
		  int x = texelIndex - y * morphTargetsTextureSize.x;

		  ivec3 morphUV = ivec3( x, y, morphTargetIndex );
		  return texelFetch( morphTargetsTexture, morphUV, 0 );

	  }

      #endif
    """;
  }
}