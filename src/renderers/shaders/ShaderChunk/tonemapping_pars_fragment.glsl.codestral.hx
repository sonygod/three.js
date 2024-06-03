class ShaderChunkToneMappingParsFragment {
    static var toneMappingExposure:Float = 1.0;

    static function LinearToneMapping(color:Array<Float>):Array<Float> {
        var result:Array<Float> = [0.0, 0.0, 0.0];
        for (i in 0...3) {
            result[i] = Math.min(Math.max(toneMappingExposure * color[i], 0.0), 1.0);
        }
        return result;
    }

    static function ReinhardToneMapping(color:Array<Float>):Array<Float> {
        var result:Array<Float> = [0.0, 0.0, 0.0];
        for (i in 0...3) {
            color[i] *= toneMappingExposure;
            result[i] = Math.min(Math.max(color[i] / (1.0 + color[i]), 0.0), 1.0);
        }
        return result;
    }

    static function OptimizedCineonToneMapping(color:Array<Float>):Array<Float> {
        var result:Array<Float> = [0.0, 0.0, 0.0];
        for (i in 0...3) {
            color[i] *= toneMappingExposure;
            color[i] = Math.max(0.0, color[i] - 0.004);
            result[i] = Math.pow((color[i] * (6.2 * color[i] + 0.5)) / (color[i] * (6.2 * color[i] + 1.7) + 0.06), 2.2);
        }
        return result;
    }

    static function RRTAndODTFit(v:Array<Float>):Array<Float> {
        var a:Array<Float> = [0.0, 0.0, 0.0];
        var b:Array<Float> = [0.0, 0.0, 0.0];
        var result:Array<Float> = [0.0, 0.0, 0.0];
        for (i in 0...3) {
            a[i] = v[i] * (v[i] + 0.0245786) - 0.000090537;
            b[i] = v[i] * (0.983729 * v[i] + 0.4329510) + 0.238081;
            result[i] = a[i] / b[i];
        }
        return result;
    }

    static function ACESFilmicToneMapping(color:Array<Float>):Array<Float> {
        var ACESInputMat:Array<Array<Float>> = [
            [0.59719, 0.35458, 0.04823],
            [0.07600, 0.90834, 0.01566],
            [0.02840, 0.13383, 0.83777]
        ];

        var ACESOutputMat:Array<Array<Float>> = [
            [1.60475, -0.10208, -0.00327],
            [-0.53108, 1.10813, -0.07276],
            [-0.07367, -0.00605, 1.07602]
        ];

        for (i in 0...3) {
            color[i] *= toneMappingExposure / 0.6;
        }

        color = multiplyMatrixVector(ACESInputMat, color);

        color = RRTAndODTFit(color);

        color = multiplyMatrixVector(ACESOutputMat, color);

        for (i in 0...3) {
            color[i] = Math.min(Math.max(color[i], 0.0), 1.0);
        }

        return color;
    }

    static function LINEAR_REC2020_TO_LINEAR_SRGB(color:Array<Float>):Array<Float> {
        var matrix:Array<Array<Float>> = [
            [1.6605, -0.1246, -0.0182],
            [-0.5876, 1.1329, -0.1006],
            [-0.0728, -0.0083, 1.1187]
        ];

        return multiplyMatrixVector(matrix, color);
    }

    static function LINEAR_SRGB_TO_LINEAR_REC2020(color:Array<Float>):Array<Float> {
        var matrix:Array<Array<Float>> = [
            [0.6274, 0.0691, 0.0164],
            [0.3293, 0.9195, 0.0880],
            [0.0433, 0.0113, 0.8956]
        ];

        return multiplyMatrixVector(matrix, color);
    }

    static function agxDefaultContrastApprox(x:Array<Float>):Array<Float> {
        var result:Array<Float> = [0.0, 0.0, 0.0];
        var x2:Array<Float> = [0.0, 0.0, 0.0];
        var x4:Array<Float> = [0.0, 0.0, 0.0];

        for (i in 0...3) {
            x2[i] = x[i] * x[i];
            x4[i] = x2[i] * x2[i];

            result[i] = +15.5 * x4[i] * x2[i] - 40.14 * x4[i] * x[i] + 31.96 * x4[i] - 6.868 * x2[i] * x[i] + 0.4298 * x2[i] + 0.1191 * x[i] - 0.00232;
        }

        return result;
    }

    static function AgXToneMapping(color:Array<Float>):Array<Float> {
        var AgXInsetMatrix:Array<Array<Float>> = [
            [0.856627153315983, 0.0951212405381588, 0.0482516061458583],
            [0.137318972929847, 0.761241990602591, 0.101439036467562],
            [0.11189821299995, 0.0767994186031903, 0.016493938717834573]
        ];

        var AgXOutsetMatrix:Array<Array<Float>> = [
            [1.1271005818144368, -0.11060664309660323, -0.016493938717834573],
            [-0.1413297634984383, 1.157823702216272, -0.016493938717834257],
            [-0.14132976349843826, -0.11060664309660294, 1.2519364065950405]
        ];

        var AgxMinEv:Float = -12.47393;
        var AgxMaxEv:Float = 4.026069;

        for (i in 0...3) {
            color[i] *= toneMappingExposure;
        }

        color = LINEAR_SRGB_TO_LINEAR_REC2020(color);

        color = multiplyMatrixVector(AgXInsetMatrix, color);

        for (i in 0...3) {
            color[i] = Math.max(color[i], 1e-10);
            color[i] = Math.log2(color[i]);
            color[i] = (color[i] - AgxMinEv) / (AgxMaxEv - AgxMinEv);
            color[i] = Math.min(Math.max(color[i], 0.0), 1.0);
        }

        color = agxDefaultContrastApprox(color);

        color = multiplyMatrixVector(AgXOutsetMatrix, color);

        for (i in 0...3) {
            color[i] = Math.pow(Math.max(0.0, color[i]), 2.2);
        }

        color = LINEAR_REC2020_TO_LINEAR_SRGB(color);

        for (i in 0...3) {
            color[i] = Math.min(Math.max(color[i], 0.0), 1.0);
        }

        return color;
    }

    static function NeutralToneMapping(color:Array<Float>):Array<Float> {
        var StartCompression:Float = 0.8 - 0.04;
        var Desaturation:Float = 0.15;

        for (i in 0...3) {
            color[i] *= toneMappingExposure;
        }

        var x:Float = Math.min(color[0], Math.min(color[1], color[2]));

        var offset:Float = x < 0.08 ? x - 6.25 * x * x : 0.04;

        for (i in 0...3) {
            color[i] -= offset;
        }

        var peak:Float = Math.max(color[0], Math.max(color[1], color[2]));

        if (peak < StartCompression) return color;

        var d:Float = 1.0 - StartCompression;

        var newPeak:Float = 1.0 - d * d / (peak + d - StartCompression);

        for (i in 0...3) {
            color[i] *= newPeak / peak;
        }

        var g:Float = 1.0 - 1.0 / (Desaturation * (peak - newPeak) + 1.0);

        for (i in 0...3) {
            color[i] = (1.0 - g) * color[i] + g * newPeak;
        }

        return color;
    }

    static function CustomToneMapping(color:Array<Float>):Array<Float> {
        return color;
    }

    static function multiplyMatrixVector(matrix:Array<Array<Float>>, vector:Array<Float>):Array<Float> {
        var result:Array<Float> = [0.0, 0.0, 0.0];

        for (i in 0...3) {
            for (j in 0...3) {
                result[i] += matrix[i][j] * vector[j];
            }
        }

        return result;
    }
}