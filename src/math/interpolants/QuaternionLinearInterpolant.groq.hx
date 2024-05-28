package three.math.interpolants;

import three.math.Interpolant;
import three.math.Quaternion;

/**
 * Spherical linear unit quaternion interpolant.
 */

class QuaternionLinearInterpolant extends Interpolant {
    
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override private function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        var result:Array<Float> = this.resultBuffer,
            values:Array<Float> = this.sampleValues,
            stride:Int = this.valueSize,

            alpha:Float = (t - t0) / (t1 - t0);

        var offset:Int = i1 * stride;

        for (offset in offset...offset + stride) {
            Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);
        }

        return result;
    }
}