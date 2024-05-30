package three.js.examples.loaders;

import three.js.loaders.Interpolant;

class GLTFCubicSplineInterpolant extends Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    private function copySampleValue_(index:Int):Array<Float> {
        var result:Array<Float> = this.resultBuffer;
        var values:Array<Float> = this.sampleValues;
        var valueSize:Int = this.valueSize;
        var offset:Int = index * valueSize * 3 + valueSize;

        for (i in 0...valueSize) {
            result[i] = values[offset + i];
        }

        return result;
    }

    private function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        var result:Array<Float> = this.resultBuffer;
        var values:Array<Float> = this.sampleValues;
        var stride:Int = this.valueSize;

        var stride2:Int = stride * 2;
        var stride3:Int = stride * 3;

        var td:Float = t1 - t0;
        var p:Float = (t - t0) / td;
        var pp:Float = p * p;
        var ppp:Float = pp * p;

        var offset1:Int = i1 * stride3;
        var offset0:Int = offset1 - stride3;

        var s2:Float = -2 * ppp + 3 * pp;
        var s3:Float = ppp - pp;
        var s0:Float = 1 - s2;
        var s1:Float = s3 - pp + p;

        for (i in 0...stride) {
            var p0:Float = values[offset0 + i + stride]; // splineVertex_k
            var m0:Float = values[offset0 + i + stride2] * td; // outTangent_k * (t_k+1 - t_k)
            var p1:Float = values[offset1 + i + stride]; // splineVertex_k+1
            var m1:Float = values[offset1 + i] * td; // inTangent_k+1 * (t_k+1 - t_k)

            result[i] = s0 * p0 + s1 * m0 + s2 * p1 + s3 * m1;
        }

        return result;
    }
}