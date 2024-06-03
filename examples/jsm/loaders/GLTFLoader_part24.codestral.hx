import js.html.Interpolant;

class GLTFCubicSplineInterpolant extends Interpolant {

    public function new(parameterPositions: Array<Float>, sampleValues: Array<Float>, sampleSize: Int, resultBuffer: Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    protected function copySampleValue_(index: Int): Array<Float> {
        var result = this.resultBuffer;
        var values = this.sampleValues;
        var valueSize = this.valueSize;
        var offset = index * valueSize * 3 + valueSize;

        for (var i: Int = 0; i < valueSize; i++) {
            result[i] = values[offset + i];
        }

        return result;
    }

    protected function interpolate_(i1: Int, t0: Float, t: Float, t1: Float): Array<Float> {
        var result = this.resultBuffer;
        var values = this.sampleValues;
        var stride = this.valueSize;

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

        for (var i: Int = 0; i < stride; i++) {
            var p0 = values[offset0 + i + stride];
            var m0 = values[offset0 + i + stride2] * td;
            var p1 = values[offset1 + i + stride];
            var m1 = values[offset1 + i] * td;

            result[i] = s0 * p0 + s1 * m0 + s2 * p1 + s3 * m1;
        }

        return result;
    }
}