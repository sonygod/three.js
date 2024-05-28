package three.renderers.shaders.ShaderChunk;

public class ColorSpaceParsFragment {

    // http://www.russellcottrell.com/photo/matrixCalculator.htm

    // Linear sRGB => XYZ => Linear Display P3
    static inline var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Mat3 = new Mat3(
        new Vec3(0.8224621, 0.177538, 0.0),
        new Vec3(0.0331941, 0.9668058, 0.0),
        new Vec3(0.0170827, 0.0723974, 0.9105199)
    );

    // Linear Display P3 => XYZ => Linear sRGB
    static inline var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Mat3 = new Mat3(
        new Vec3(1.2249401, -0.2249404, 0.0),
        new Vec3(-0.0420569, 1.0420571, 0.0),
        new Vec3(-0.0196376, -0.0786361, 1.0982735)
    );

    // Linear sRGB to Linear Display P3
    public static function linearSRGBToLinearDisplayP3(value:Vec4):Vec4 {
        return new Vec4(value.rgb.multMat3(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3), value.a);
    }

    // Linear Display P3 to Linear sRGB
    public static function linearDisplayP3ToLinearSRGB(value:Vec4):Vec4 {
        return new Vec4(value.rgb.multMat3(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB), value.a);
    }

    // Linear Transfer OETF
    public static function linearTransferOETF(value:Vec4):Vec4 {
        return value;
    }

    // sRGB Transfer OETF
    public static function sRGBTransferOETF(value:Vec4):Vec4 {
        var powValue = pow(value.rgb, new Vec3(0.41666));
        var mixValue = mix(powValue.mult(new Vec3(1.055)).sub(new Vec3(0.055)), value.rgb.mult(12.92), new Vec3(lessThanEqual(value.rgb, new Vec3(0.0031308)))));
        return new Vec4(mixValue, value.a);
    }

    // @deprecated, r156
    public static function linearToLinear(value:Vec4):Vec4 {
        return value;
    }

    // @deprecated, r156
    public static function linearToSRGB(value:Vec4):Vec4 {
        return sRGBTransferOETF(value);
    }
}