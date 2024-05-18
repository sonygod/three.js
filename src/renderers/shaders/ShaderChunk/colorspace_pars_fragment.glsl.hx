package three.renderers.shaders.ShaderChunk;

// http://www.russellcottrell.com/photo/matrixCalculator.htm

class ColorSpaceParsFragment {
  // Linear sRGB => XYZ => Linear Display P3
  static inline var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = [
    [0.8224621, 0.177538, 0.0],
    [0.0331941, 0.9668058, 0.0],
    [0.0170827, 0.0723974, 0.9105199]
  ];

  // Linear Display P3 => XYZ => Linear sRGB
  static inline var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = [
    [1.2249401, -0.2249404, 0.0],
    [-0.0420569, 1.0420571, 0.0],
    [-0.0196376, -0.0786361, 1.0982735]
  ];

  static function linearSRGBToLinearDisplayP3(value:Vec4):Vec4 {
    return new Vec4(value.rgb.multMat3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3), value.a);
  }

  static function linearDisplayP3ToLinearSRGB(value:Vec4):Vec4 {
    return new Vec4(value.rgb.multMat3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB), value.a);
  }

  static function linearTransferOETF(value:Vec4):Vec4 {
    return value;
  }

  static function sRGBTransferOETF(value:Vec4):Vec4 {
    var powValue = value.rgb.pow(0.41666);
    var mixValue = powValue * 1.055 - 0.055;
    var cond = value.rgb.lessThanEqual(0.0031308);
    var rgb = cond.select(mixValue, value.rgb * 12.92);
    return new Vec4(rgb, value.a);
  }

  // @deprecated, r156
  static function linearToLinear(value:Vec4):Vec4 {
    return value;
  }

  // @deprecated, r156
  static function linearTosRGB(value:Vec4):Vec4 {
    return sRGBTransferOETF(value);
  }
}