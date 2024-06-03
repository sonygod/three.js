class ColorspaceParsFragment {
    static function sRGBTransferOETF(value: Float4): Float4 {
        var condition = value.rgb.lessThanEqual(Float3.fromArray([0.0031308, 0.0031308, 0.0031308]));
        var result = Float4.zero;
        result.rgb = condition.select(value.rgb * 12.92, value.rgb.pow(Float3.fromArray([0.41666, 0.41666, 0.41666])) * 1.055 - Float3.fromArray([0.055, 0.055, 0.055]));
        result.a = value.a;
        return result;
    }

    static function LinearTransferOETF(value: Float4): Float4 {
        return value;
    }

    static function LinearSRGBToLinearDisplayP3(value: Float4): Float4 {
        var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3: Float3x3 = new Float3x3(
            Float3.fromArray([0.8224621, 0.177538, 0.0]),
            Float3.fromArray([0.0331941, 0.9668058, 0.0]),
            Float3.fromArray([0.0170827, 0.0723974, 0.9105199])
        );
        return Float4.fromArray([value.x * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m00 + value.y * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m01 + value.z * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m02,
                                 value.x * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m10 + value.y * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m11 + value.z * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m12,
                                 value.x * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m20 + value.y * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m21 + value.z * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3.m22,
                                 value.w]);
    }

    static function LinearDisplayP3ToLinearSRGB(value: Float4): Float4 {
        var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB: Float3x3 = new Float3x3(
            Float3.fromArray([1.2249401, -0.2249404, 0.0]),
            Float3.fromArray([-0.0420569, 1.0420571, 0.0]),
            Float3.fromArray([-0.0196376, -0.0786361, 1.0982735])
        );
        return Float4.fromArray([value.x * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m00 + value.y * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m01 + value.z * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m02,
                                 value.x * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m10 + value.y * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m11 + value.z * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m12,
                                 value.x * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m20 + value.y * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m21 + value.z * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB.m22,
                                 value.w]);
    }

    static function LinearToLinear(value: Float4): Float4 {
        return value;
    }

    static function LinearTosRGB(value: Float4): Float4 {
        return sRGBTransferOETF(value);
    }
}