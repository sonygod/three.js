package three.math.interpolants;

import three.math.Interpolant;

class LinearInterpolant extends Interpolant {
    public function new(parameterPositions:Array<Dynamic>, sampleValues:Array<Dynamic>, sampleSize:Int, resultBuffer:Array<Dynamic>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    private function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Dynamic> {
        var result:Array<Dynamic> = this.resultBuffer;
        var values:Array<Dynamic> = this.sampleValues;
        var stride:Int = this.valueSize;

        var offset1:Int = i1 * stride;
        var offset0:Int = offset1 - stride;

        var weight1:Float = (t - t0) / (t1 - t0);
        var weight0:Float = 1 - weight1;

        for (i in 0...stride) {
            result[i] = values[offset0 + i] * weight0 + values[offset1 + i] * weight1;
        }

        return result;
    }
}