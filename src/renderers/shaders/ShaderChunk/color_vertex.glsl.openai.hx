@:glsl
class ColorVertex {
  @:.glsl('vColor') var vColor:Vec4;

  public function new() {
    #if (defined USE_COLOR_ALPHA)
      vColor = new Vec4(1.0, 1.0, 1.0, 1.0);
    #elseif (defined USE_COLOR || defined USE_INSTANCING_COLOR || defined USE_BATCHING_COLOR)
      vColor = new Vec3(1.0, 1.0, 1.0);
    #end

    #if (defined USE_COLOR)
      vColor *= color;
    #end

    #if (defined USE_INSTANCING_COLOR)
      vColor.xyz *= instanceColor.xyz;
    #end

    #if (defined USE_BATCHING_COLOR)
      var batchingColor:Vec3 = getBatchingColor(batchId);
      vColor.xyz *= batchingColor.xyz;
    #end
  }
}