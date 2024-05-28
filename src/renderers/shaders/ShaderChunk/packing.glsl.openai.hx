@:glsl
class ShaderChunk {
  static function packNormalToRGB(normal:Vec3):Vec3 {
    return normalize(normal) * 0.5 + 0.5;
  }

  static function unpackRGBToNormal(rgb:Vec3):Vec3 {
    return 2.0 * rgb - 1.0;
  }

  static inline var PackUpscale:Float = 256. / 255.; // fraction -> 0..1 (including 1)
  static inline var UnpackDownscale:Float = 255. / 256.; // 0..1 -> fraction (excluding 1)

  static inline var PackFactors:Vec3 = new Vec3(256. * 256. * 256., 256. * 256., 256.);
  static inline var UnpackFactors:Vec4 = new Vec4(UnpackDownscale / PackFactors, 1.);

  static inline var ShiftRight8:Float = 1. / 256.;

  static function packDepthToRGBA(v:Float):Vec4 {
    var r:Vec4 = new Vec4(frac(v * PackFactors), v);
    r.yzw -= r.xyz * ShiftRight8; // tidy overflow
    return r * PackUpscale;
  }

  static function unpackRGBAToDepth(v:Vec4):Float {
    return dot(v, UnpackFactors);
  }

  static function packDepthToRG(v:Float):Vec2 {
    return packDepthToRGBA(v).yx;
  }

  static function unpackRGToDepth(v:Vec2):Float {
    return unpackRGBAToDepth(new Vec4(v.x, v.y, 0.0, 0.0));
  }

  static function pack2HalfToRGBA(v:Vec2):Vec4 {
    var r:Vec4 = new Vec4(v.x, frac(v.x * 255.0), v.y, frac(v.y * 255.0));
    return new Vec4(r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w);
  }

  static function unpackRGBATo2Half(v:Vec4):Vec2 {
    return new Vec2(v.x + (v.y / 255.0), v.z + (v.w / 255.0));
  }

  static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
    // -near maps to 0; -far maps to 1
    return (viewZ + near) / (near - far);
  }

  static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
    // maps orthographic depth in [ 0, 1 ] to viewZ
    return depth * (near - far) - near;
  }

  static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
    // -near maps to 0; -far maps to 1
    return ((near + viewZ) * far) / ((far - near) * viewZ);
  }

  static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
    // maps perspective depth in [ 0, 1 ] to viewZ
    return (near * far) / ((far - near) * depth - far);
  }
}