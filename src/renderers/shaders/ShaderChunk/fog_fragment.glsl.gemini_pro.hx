class FogShader {
  static function main(fogDensity:Float, fogNear:Float, fogFar:Float, vFogDepth:Float, fogColor:hl.Vec3, fragColor:hl.Vec4):hl.Vec4 {
    var fogFactor:Float;
    if (Std.isOfType(fogDensity, Float)) {
      if (Std.isOfType(fogNear, Float) && Std.isOfType(fogFar, Float) && Std.isOfType(vFogDepth, Float)) {
        if (Std.isOfType(fogColor, hl.Vec3) && Std.isOfType(fragColor, hl.Vec4)) {
          if (Std.isOfType(fogDensity, Float)) {
            fogFactor = 1.0 - Math.exp(-fogDensity * fogDensity * vFogDepth * vFogDepth);
          } else {
            fogFactor = Math.smoothstep(fogNear, fogFar, vFogDepth);
          }
          fragColor.rgb = hl.Vec3.mix(fragColor.rgb, fogColor, fogFactor);
        } else {
          throw "Type mismatch: Expected hl.Vec3 and hl.Vec4 for fogColor and fragColor.";
        }
      } else {
        throw "Type mismatch: Expected Float for fogNear, fogFar, and vFogDepth.";
      }
    } else {
      throw "Type mismatch: Expected Float for fogDensity.";
    }
    return fragColor;
  }
}