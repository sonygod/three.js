class GLTFCubicSplineInterpolant extends Interpolant {
    public function new(parameterPositions:Float32Array, sampleValues:Float32Array, sampleSize:Int, resultBuffer:Float32Array) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    private function copySampleValue_(index:Int):Float32Array {
        // Copies a sample value to the result buffer. See description of glTF
        // CUBICSPLINE values layout in interpolate_() function below.
        var result = resultBuffer;
        var values = sampleValues;
        var valueSize = valueSize;
        var offset = index * valueSize * 3 + valueSize;

        for (i in 0...valueSize) {
            result[i] = values[offset + i];
        }

        return result;
    }

    private function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Float32Array {
        var result = resultBuffer;
        var values = sampleValues;
        var stride = valueSize;

        var stride2 = stride * 2;
        var stride3 = stride * 3;

        var td = t1 - t0;

        var p = (t - t0) / td;
        var pp = p * p;
        var ppp = pp * p;

        var offset1 = i1 * stride3;
        var offset0 = offset1 - stride3;

        var s2 = -2 * ppp + 3 * pp;
        var s3 = ppp - pp;
        var s0 = 1 - s2;
        var s1 = s3 - pp + p;

        // Layout of keyframe output values for CUBICSPLINE animations:
        //   [inTangent_1, splineVertex_1, outTangent_1, inTangent_2, splineVertex_2, ...]
        for (i in 0...stride) {
            var p0 = values[offset0 + i + stride]; // splineVertex_k
            var m0 = values[offset0 + i + stride2] * td; // outTangent_k * (t_k+1 - t_k)
            var p1 = values[offset1 + i + stride]; // splineVertex_k+1
            var m1 = values[offset1 + i] * td; // inTangent_k+1 * (t_k+1 - t_k)

            result[i] = s0 * p0 + s1 * m0 + s2 * p1 + s3 * m1;
        }

        return result;
    }
}