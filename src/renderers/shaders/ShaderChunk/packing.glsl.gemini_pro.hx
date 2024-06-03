package;

import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D.Shader;
import openfl.display3D.VertexBuffer;

class GlslUtils {

  public static function packNormalToRGB(normal:Vector3):Vector3 {
    return normal.normalize().multiply(0.5).add(0.5);
  }

  public static function unpackRGBToNormal(rgb:Vector3):Vector3 {
    return rgb.multiply(2.0).subtract(1.0);
  }

  private static var PackUpscale:Float = 256. / 255.;
  private static var UnpackDownscale:Float = 255. / 256.;

  private static var PackFactors:Vector3 = new Vector3(256. * 256. * 256., 256. * 256., 256.);
  private static var UnpackFactors:Vector4 = new Vector4(
    UnpackDownscale / PackFactors.x,
    UnpackDownscale / PackFactors.y,
    UnpackDownscale / PackFactors.z,
    UnpackDownscale
  );

  private static var ShiftRight8:Float = 1. / 256.;

  public static function packDepthToRGBA(v:Float):Vector4 {
    var r = new Vector4(
      Math.fract(v * PackFactors.x),
      Math.fract(v * PackFactors.y),
      Math.fract(v * PackFactors.z),
      v
    );
    r.y -= r.x * ShiftRight8;
    r.z -= r.y * ShiftRight8;
    r.w -= r.z * ShiftRight8;
    return r.multiply(PackUpscale);
  }

  public static function unpackRGBAToDepth(v:Vector4):Float {
    return v.dot(UnpackFactors);
  }

  public static function packDepthToRG(v:Float):Vector2 {
    return packDepthToRGBA(v).xy;
  }

  public static function unpackRGToDepth(v:Vector2):Float {
    return unpackRGBAToDepth(new Vector4(v.x, v.y, 0.0, 0.0));
  }

  public static function pack2HalfToRGBA(v:Vector2):Vector4 {
    return new Vector4(
      v.x - Math.fract(v.x * 255.0) / 255.0,
      Math.fract(v.x * 255.0),
      v.y - Math.fract(v.y * 255.0) / 255.0,
      Math.fract(v.y * 255.0)
    );
  }

  public static function unpackRGBATo2Half(v:Vector4):Vector2 {
    return new Vector2(
      v.x + (v.y / 255.0),
      v.z + (v.w / 255.0)
    );
  }

  public static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
    return (viewZ + near) / (near - far);
  }

  public static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
    return depth * (near - far) - near;
  }

  public static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
    return ((near + viewZ) * far) / ((far - near) * viewZ);
  }

  public static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
    return (near * far) / ((far - near) * depth - far);
  }
}

// Helper classes
class Vector2 {
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  public function multiply(scalar:Float):Vector2 {
    return new Vector2(this.x * scalar, this.y * scalar);
  }

  public function add(other:Vector2):Vector2 {
    return new Vector2(this.x + other.x, this.y + other.y);
  }

  public function subtract(other:Vector2):Vector2 {
    return new Vector2(this.x - other.x, this.y - other.y);
  }
}

class Vector3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function normalize():Vector3 {
    var length = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    return new Vector3(this.x / length, this.y / length, this.z / length);
  }

  public function multiply(scalar:Float):Vector3 {
    return new Vector3(this.x * scalar, this.y * scalar, this.z * scalar);
  }

  public function add(other:Vector3):Vector3 {
    return new Vector3(this.x + other.x, this.y + other.y, this.z + other.z);
  }

  public function subtract(other:Vector3):Vector3 {
    return new Vector3(this.x - other.x, this.y - other.y, this.z - other.z);
  }
}

class Vector4 {
  public var x:Float;
  public var y:Float;
  public var z:Float;
  public var w:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }

  public function dot(other:Vector4):Float {
    return this.x * other.x + this.y * other.y + this.z * other.z + this.w * other.w;
  }

  public function multiply(scalar:Float):Vector4 {
    return new Vector4(this.x * scalar, this.y * scalar, this.z * scalar, this.w * scalar);
  }
}