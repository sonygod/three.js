class ShaderUtils {
  public static function getMorphNormals():String {
    var result:String = "";

    #if USE_MORPHNORMALS
    result += "// morphTargetBaseInfluence is set based on BufferGeometry.morphTargetsRelative value:\n";
    result += "// When morphTargetsRelative is false, this is set to 1 - sum(influences); this results in normal = sum((target - base) * influence)\n";
    result += "// When morphTargetsRelative is true, this is set to 1; as a result, all morph targets are simply added to the base after weighting\n";
    result += "objectNormal *= morphTargetBaseInfluence;\n";
    result += "\n";
    result += "for (int i = 0; i < MORPHTARGETS_COUNT; i++) {\n";
    result += "\n";
    result += "  if (morphTargetInfluences[i] != 0.0) objectNormal += getMorph(gl_VertexID, i, 1).xyz * morphTargetInfluences[i];\n";
    result += "\n";
    result += "}\n";
    #end

    return result;
  }
}