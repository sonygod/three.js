package three.src.renderers.shaders.ShaderChunk;

import three.src.math.Vector3;
import three.src.math.Vector4;
import three.src.math.Matrix3;

class colorspace_pars_fragment {
    static var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Matrix3;
    static var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Matrix3;

    static function LinearSRGBToLinearDisplayP3(value:Vector4):Vector4 {
        return new Vector4(value.xyz * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3, value.w);
    }

    static function LinearDisplayP3ToLinearSRGB(value:Vector4):Vector4 {
        return new Vector4(value.xyz * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB, value.w);
    }

    static function LinearTransferOETF(value:Vector4):Vector4 {
        return value;
    }

    static function sRGBTransferOETF(value:Vector4):Vector4 {
        var rgb = value.xyz;
        var a = value.w;
        var mixValue = rgb.map(function(v) return (v <= 0.0031308) ? 1.0 : 0.0);
        return new Vector4(rgb.map(function(v) return Math.pow(v, 0.41666) * 1.055 - 0.055).mul(1.0 - mixValue).add(rgb.mul(12.92).mul(mixValue)), a);
    }

    static function LinearToLinear(value:Vector4):Vector4 {
        return value;
    }

    static function LinearTosRGB(value:Vector4):Vector4 {
        return sRGBTransferOETF(value);
    }

    static function _() {
        LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = new Matrix3(
            new Vector3(0.8224621, 0.177538, 0.0),
            new Vector3(0.0331941, 0.9668058, 0.0),
            new Vector3(0.0170827, 0.0723974, 0.9105199)
        );

        LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = new Matrix3(
            new Vector3(1.2249401, -0.2249404, 0.0),
            new Vector3(-0.0420569, 1.0420571, 0.0),
            new Vector3(-0.0196376, -0.0786361, 1.0982735)
        );
    }
}