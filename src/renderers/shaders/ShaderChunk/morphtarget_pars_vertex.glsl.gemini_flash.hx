class ShaderUtils {
  public static function getMorphTargets():String {
    var result = "";

    result += "#ifdef USE_MORPHTARGETS\n";

    result += "#ifndef USE_INSTANCING_MORPH\n";
    result += "  uniform float morphTargetBaseInfluence;\n";
    result += "  uniform float morphTargetInfluences[MORPHTARGETS_COUNT];\n";
    result += "#endif\n";

    result += "uniform sampler2DArray morphTargetsTexture;\n";
    result += "uniform ivec2 morphTargetsTextureSize;\n";

    result += "vec4 getMorph(const in int vertexIndex, const in int morphTargetIndex, const in int offset) {\n";
    result += "  int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;\n";
    result += "  int y = texelIndex / morphTargetsTextureSize.x;\n";
    result += "  int x = texelIndex - y * morphTargetsTextureSize.x;\n";
    result += "  ivec3 morphUV = ivec3(x, y, morphTargetIndex);\n";
    result += "  return texelFetch(morphTargetsTexture, morphUV, 0);\n";
    result += "}\n";

    result += "#endif\n";

    return result;
  }
}