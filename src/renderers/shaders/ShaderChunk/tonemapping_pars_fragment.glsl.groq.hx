package three.renderers.shaders.ShaderChunk;

import haxe.ds.Vector;

class ToneMapping {
  static inline var TONE_MAPPING_EXPOSURE:Float = 1.0;

  static function linearToneMapping(color:Vector<Float>):Vector<Float> {
    return saturate(TONE_MAPPING_EXPOSURE * color);
  }

  static function reinhardToneMapping(color:Vector<Float>):Vector<Float> {
    color = color * TONE_MAPPING_EXPOSURE;
    return saturate(color / (Vector_Float.fromArray([1.0, 1.0, 1.0]) + color));
  }

  static function optimizedCineonToneMapping(color:Vector<Float>):Vector<Float> {
    color = color * TONE_MAPPING_EXPOSURE;
    color = max(Vector_Float.fromArray([0.0, 0.0, 0.0]), color - 0.004);
    return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), 2.2);
  }

  static function rrtAndODTFit(v:Vector<Float>):Vector<Float> {
    var a:Vector<Float> = v * (v + 0.0245786) - 0.000090537;
    var b:Vector<Float> = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
  }

  static function acesFilmicToneMapping(color:Vector<Float>):Vector<Float> {
    var ACESInputMat:Matrix3 = new Matrix3(
      [0.59719, 0.07600, 0.02840],
      [0.35458, 0.90834, 0.13383],
      [0.04823, 0.01566, 0.83777]
    );

    var ACESOutputMat:Matrix3 = new Matrix3(
      [1.60475, -0.10208, -0.00327],
      [-0.53108, 1.10813, -0.07276],
      [-0.07367, -0.00605, 1.07602]
    );

    color *= TONE_MAPPING_EXPOSURE / 0.6;
    color = ACESInputMat.multiplyVector(color);
    color = rrtAndODTFit(color);
    color = ACESOutputMat.multiplyVector(color);
    return saturate(color);
  }

  static function agxDefaultContrastApprox(x:Vector<Float>):Vector<Float> {
    var x2:Vector<Float> = x * x;
    var x4:Vector<Float> = x2 * x2;
    return 15.5 * x4 * x2 - 40.14 * x4 * x + 31.96 * x4 - 6.868 * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232;
  }

  static function agXToneMapping(color:Vector<Float>):Vector<Float> {
    var AgXInsetMatrix:Matrix3 = new Matrix3(
      [0.856627153315983, 0.137318972929847, 0.11189821299995],
      [0.0951212405381588, 0.761241990602591, 0.0767994186031903],
      [0.0482516061458583, 0.101439036467562, 0.811302368396859]
    );

    var AgXOutsetMatrix:Matrix3 = new Matrix3(
      [1.1271005818144368, -0.1413297634984383, -0.14132976349843826],
      [-0.11060664309660323, 1.157823702216272, -0.11060664309660294],
      [-0.016493938717834573, -0.016493938717834257, 1.2519364065950405]
    );

    var LINEAR_REC2020_TO_LINEAR_SRGB:Matrix3 = new Matrix3(
      [1.6605, -0.1246, -0.0182],
      [-0.5876, 1.1329, -0.1006],
      [-0.0728, -0.0083, 1.1187]
    );

    var LINEAR_SRGB_TO_LINEAR_REC2020:Matrix3 = new Matrix3(
      [0.6274, 0.0691, 0.0164],
      [0.3293, 0.9195, 0.0880],
      [0.0433, 0.0113, 0.8956]
    );

    color *= TONE_MAPPING_EXPOSURE;

    color = LINEAR_SRGB_TO_LINEAR_REC2020.multiplyVector(color);
    color = AgXInsetMatrix.multiplyVector(color);

    color = log2(max(color, 1e-10));
    color = (color - (-12.47393)) / (4.026069 + 12.47393);
    color = clamp(color, 0.0, 1.0);

    color = agxDefaultContrastApprox(color);
    color = AgXOutsetMatrix.multiplyVector(color);

    color = pow(max(Vector_Float.fromArray([0.0, 0.0, 0.0]), color), 2.2);
    color = LINEAR_REC2020_TO_LINEAR_SRGB.multiplyVector(color);
    color = clamp(color, 0.0, 1.0);

    return color;
  }

  static function neutralToneMapping(color:Vector<Float>):Vector<Float> {
    const StartCompression:Float = 0.8 - 0.04;
    const Desaturation:Float = 0.15;

    color *= TONE_MAPPING_EXPOSURE;

    var x:Float = Math.min(color.x, Math.min(color.y, color.z));
    var offset:Float = x < 0.08 ? x - 6.25 * x * x : 0.04;

    color -= offset;

    var peak:Float = Math.max(color.x, Math.max(color.y, color.z));

    if (peak < StartCompression) return color;

    var d:Float = 1. - StartCompression;
    var newPeak:Float = 1. - d * d / (peak + d - StartCompression);

    color *= newPeak / peak;

    var g:Float = 1. - 1. / (Desaturation * (peak - newPeak) + 1.);
    return mix(color, Vector_Float.fromArray([newPeak, newPeak, newPeak]), g);
  }

  static function customToneMapping(color:Vector<Float>):Vector<Float> {
    return color;
  }

  static function saturate(a:Vector<Float>):Vector<Float> {
    return clamp(a, 0.0, 1.0);
  }
}

class Matrix3 {
  public var elements:Array<Float>;

  public function new(elements:Array<Float>) {
    this.elements = elements;
  }

  public function multiplyVector(vector:Vector<Float>):Vector<Float> {
    // implement matrix-vector multiplication
  }
}

class Vector_Float {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float, y:Float, z:Float) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public static function fromArray(arr:Array<Float>):Vector_Float {
    return new Vector_Float(arr[0], arr[1], arr[2]);
  }
}