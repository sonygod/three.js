package three.shader;

@:native("ToneMapping")
extern class ToneMapping {
  static var toneMappingExposure:Float;

  static function LinearToneMapping(color:Vec3):Vec3 {
    return saturate(toneMappingExposure * color);
  }

  static function ReinhardToneMapping(color:Vec3):Vec3 {
    color *= toneMappingExposure;
    return saturate(color / (Vec3.fromArray([1.0, 1.0, 1.0]) + color));
  }

  static function OptimizedCineonToneMapping(color:Vec3):Vec3 {
    color *= toneMappingExposure;
    color = max(Vec3.fromArray([0.0, 0.0, 0.0]), color - 0.004);
    return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), 2.2);
  }

  static function RRTAndODTFit(v:Vec3):Vec3 {
    var a = v * (v + 0.0245786) - 0.000090537;
    var b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
  }

  static function ACESFilmicToneMapping(color:Vec3):Vec3 {
    var ACESInputMat:Mat3 = new Mat3(
      [0.59719, 0.07600, 0.02840],
      [0.35458, 0.90834, 0.13383],
      [0.04823, 0.01566, 0.83777]
    );

    var ACESOutputMat:Mat3 = new Mat3(
      [1.60475, -0.10208, -0.00327],
      [-0.53108, 1.10813, -0.07276],
      [-0.07367, -0.00605, 1.07602]
    );

    color *= toneMappingExposure / 0.6;

    color = ACESInputMat.mult(color);

    color = RRTAndODTFit(color);

    color = ACESOutputMat.mult(color);

    return saturate(color);
  }

  static var LINEAR_REC2020_TO_LINEAR_SRGB:Mat3 = new Mat3(
    [1.6605, -0.1246, -0.0182],
    [-0.5876, 1.1329, -0.1006],
    [-0.0728, -0.0083, 1.1187]
  );

  static var LINEAR_SRGB_TO_LINEAR_REC2020:Mat3 = new Mat3(
    [0.6274, 0.0691, 0.0164],
    [0.3293, 0.9195, 0.0880],
    [0.0433, 0.0113, 0.8956]
  );

  static function agxDefaultContrastApprox(x:Vec3):Vec3 {
    var x2 = x * x;
    var x4 = x2 * x2;

    return (
      15.5 * x4 * x2 -
      40.14 * x4 * x +
      31.96 * x4 -
      6.868 * x2 * x +
      0.4298 * x2 +
      0.1191 * x -
      0.00232
    );
  }

  static function AgXToneMapping(color:Vec3):Vec3 {
    var AgXInsetMatrix:Mat3 = new Mat3(
      [0.856627153315983, 0.137318972929847, 0.11189821299995],
      [0.0951212405381588, 0.761241990602591, 0.0767994186031903],
      [0.0482516061458583, 0.101439036467562, 0.811302368396859]
    );

    var AgXOutsetMatrix:Mat3 = new Mat3(
      [1.1271005818144368, -0.1413297634984383, -0.14132976349843826],
      [-0.11060664309660323, 1.157823702216272, -0.11060664309660294],
      [-0.016493938717834573, -0.016493938717834257, 1.2519364065950405]
    );

    var AgxMinEv:Float = -12.47393;
    var AgxMaxEv:Float = 4.026069;

    color *= toneMappingExposure;

    color = LINEAR_SRGB_TO_LINEAR_REC2020.mult(color);

    color = AgXInsetMatrix.mult(color);

    color = max(Vec3.fromArray([1e-10, 1e-10, 1e-10]), color);
    color = log2(color);
    color = (color - AgxMinEv) / (AgxMaxEv - AgxMinEv);

    color = clamp(color, 0.0, 1.0);

    color = agxDefaultContrastApprox(color);

    color = AgXOutsetMatrix.mult(color);

    color = pow(max(Vec3.fromArray([0.0, 0.0, 0.0]), color), 2.2);

    color = LINEAR_REC2020_TO_LINEAR_SRGB.mult(color);

    color = clamp(color, 0.0, 1.0);

    return color;
  }

  static function NeutralToneMapping(color:Vec3):Vec3 {
    var StartCompression:Float = 0.8 - 0.04;
    var Desaturation:Float = 0.15;

    color *= toneMappingExposure;

    var x:Float = min(color.r, min(color.g, color.b));

    var offset:Float = x < 0.08 ? x - 6.25 * x * x : 0.04;

    color -= offset;

    var peak:Float = max(color.r, max(color.g, color.b));

    if (peak < StartCompression) return color;

    var d:Float = 1. - StartCompression;

    var newPeak:Float = 1. - d * d / (peak + d - StartCompression);

    color *= newPeak / peak;

    var g:Float = 1. - 1. / (Desaturation * (peak - newPeak) + 1.);

    return mix(color, Vec3.fromArray([newPeak, newPeak, newPeak]), g);
  }

  static function CustomToneMapping(color:Vec3):Vec3 {
    return color;
  }
}