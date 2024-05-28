package three.shaderlib.ShaderChunk;

class ClippingPlanesParsVertex {
  static function main() {
    #if NUM_CLIPPING_PLANES > 0
    public static var vClipPosition:Vec3;
    #end
  }
}