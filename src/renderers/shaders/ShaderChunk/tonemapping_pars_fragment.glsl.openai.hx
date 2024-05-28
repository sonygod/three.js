package three.shader;

import haxe.ds.Matrix3;

// tone mapping functions
class ToneMapping {

    // uniforms
    public var toneMappingExposure:Float;

    // Reinhard tone mapping
    public function ReinhardToneMapping(color:Vector3):Vector3 {
        color *= toneMappingExposure;
        return saturate(color / (Vector3.one + color));
    }

    // Optimized Cineon tone mapping
    public function OptimizedCineonToneMapping(color:Vector3):Vector3 {
        color *= toneMappingExposure;
        color = Math.max(Vector3.zero, color - 0.004);
        return Math.pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), Vector3.twoPointTwo);
    }

    // RRT and ODT fit
    public function RRTAndODTFit(v:Vector3):Vector3 {
        var a = v * (v + 0.0245786) - 0.000090537;
        var b = v * (0.983729 * v + 0.4329510) + 0.238081;
        return a / b;
    }

    // ACES filmic tone mapping
    public function ACESFilmicToneMapping(color:Vector3):Vector3 {
        var ACESInputMat:Matrix3 = new Matrix3(
            0.59719, 0.07600, 0.02840,
            0.35458, 0.90834, 0.13383,
            0.04823, 0.01566, 0.83777
        );
        var ACESOutputMat:Matrix3 = new Matrix3(
            1.60475, -0.10208, -0.00327,
            -0.53108, 1.10813, -0.07276,
            -0.07367, -0.00605, 1.07602
        );

        color *= toneMappingExposure / 0.6;
        color = ACESInputMat.multiplyVector(color);
        color = RRTAndODTFit(color);
        color = ACESOutputMat.multiplyVector(color);
        return saturate(color);
    }

    // AgX tone mapping
    public function AgXToneMapping(color:Vector3):Vector3 {
        var AgXInsetMatrix:Matrix3 = new Matrix3(
            0.856627153315983, 0.137318972929847, 0.11189821299995,
            0.0951212405381588, 0.761241990602591, 0.0767994186031903,
            0.0482516061458583, 0.101439036467562, 0.811302368396859
        );
        var AgXOutsetMatrix:Matrix3 = new Matrix3(
            1.1271005818144368, -0.1413297634984383, -0.14132976349843826,
            -0.11060664309660323, 1.157823702216272, -0.11060664309660294,
            -0.016493938717834573, -0.016493938717834257, 1.2519364065950405
        );

        color *= toneMappingExposure;

        var LINEAR_SRGB_TO_LINEAR_REC2020:Matrix3 = new Matrix3(
            0.6274, 0.0691, 0.0164,
            0.3293, 0.9195, 0.0880,
            0.0433, 0.0113, 0.8956
        );
        var LINEAR_REC2020_TO_LINEAR_SRGB:Matrix3 = new Matrix3(
            1.6605, -0.1246, -0.0182,
            -0.5876, 1.1329, -0.1006,
            -0.0728, -0.0083, 1.1187
        );

        color = LINEAR_SRGB_TO_LINEAR_REC2020.multiplyVector(color);
        color = AgXInsetMatrix.multiplyVector(color);

        color = Math.max(color, 1e-10);
        color = Math.log2(color);
        color = (color - (-12.47393)) / (4.026069 - (-12.47393));
        color = clamp(color, 0.0, 1.0);

        color = agxDefaultContrastApprox(color);

        color = AgXOutsetMatrix.multiplyVector(color);
        color = Math.pow(Math.max(Vector3.zero, color), 2.2);
        color = LINEAR_REC2020_TO_LINEAR_SRGB.multiplyVector(color);

        return clamp(color, 0.0, 1.0);
    }

    // Neutral tone mapping
    public function NeutralToneMapping(color:Vector3):Vector3 {
        const StartCompression:Float = 0.8 - 0.04;
        const Desaturation:Float = 0.15;

        color *= toneMappingExposure;

        var x:Float = Math.min(color.r, Math.min(color.g, color.b));
        var offset:Float = x < 0.08 ? x - 6.25 * x * x : 0.04;
        color -= offset;

        var peak:Float = Math.max(color.r, Math.max(color.g, color.b));
        if (peak < StartCompression) return color;

        var d:Float = 1. - StartCompression;
        var newPeak:Float = 1. - d * d / (peak + d - StartCompression);
        color *= newPeak / peak;

        var g:Float = 1. - 1. / (Desaturation * (peak - newPeak) + 1.);
        return mix(color, Vector3.one * newPeak, g);
    }

    // Custom tone mapping
    public function CustomToneMapping(color:Vector3):Vector3 {
        return color;
    }

    // utility function
    function saturate(a:Vector3):Vector3 {
        return Math.min(Math.max(a, Vector3.zero), Vector3.one);
    }

    function agxDefaultContrastApprox(x:Vector3):Vector3 {
        var x2:Vector3 = x * x;
        var x4:Vector3 = x2 * x2;

        return 15.5 * x4 * x2 - 40.14 * x4 * x + 31.96 * x4
            - 6.868 * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232;
    }
}