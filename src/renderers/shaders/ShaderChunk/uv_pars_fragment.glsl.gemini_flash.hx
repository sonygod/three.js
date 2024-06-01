class ShaderData {

#if macro
  public static function build(): String {
    var str = "";

    str += "#if defined( USE_UV ) || defined( USE_ANISOTROPY )\n";
    str += "\tvarying vec2 vUv;\n";
    str += "#end\n";

    var uvs = [
      "MAP", "ALPHAMAP", "LIGHTMAP", "AOMAP", "BUMPMAP",
      "NORMALMAP", "EMISSIVEMAP", "METALNESSMAP", "ROUGHNESSMAP",
      "ANISOTROPYMAP", "CLEARCOATMAP", "CLEARCOAT_NORMALMAP",
      "CLEARCOAT_ROUGHNESSMAP", "IRIDESCENCEMAP",
      "IRIDESCENCE_THICKNESSMAP", "SHEEN_COLORMAP",
      "SHEEN_ROUGHNESSMAP", "SPECULARMAP", "SPECULAR_COLORMAP",
      "SPECULAR_INTENSITYMAP"
    ];
    for (uv in uvs) {
      str += "#ifdef USE_" + uv + "\n";
      str += "\tvarying vec2 v" + uv + "Uv;\n";
      str += "#end\n";
    }

    var transformUvs = [
      "TRANSMISSIONMAP", "THICKNESSMAP"
    ];
    for (uv in transformUvs) {
      str += "#ifdef USE_" + uv + "\n";
      str += "\tuniform mat3 " + uv.toLowerCase() + "Transform;\n";
      str += "\tvarying vec2 v" + uv + "Uv;\n";
      str += "#end\n";
    }

    return str;
  }
#end

  public static var glsl: String = ShaderData.build();
}