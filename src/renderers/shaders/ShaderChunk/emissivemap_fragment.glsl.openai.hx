package three.shaderlib.ShaderChunk;

class EmissiveMapFragment {
  public static inline function main() {
    #if USE_EMISSIVEMAP
    var emissiveColor:Vec4 = texture2D(emissiveMap, vEmissiveMapUv);
    totalEmissiveRadiance *= emissiveColor.rgb;
    #end
  }
}