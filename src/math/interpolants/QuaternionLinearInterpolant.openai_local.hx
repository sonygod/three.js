import three.math.Interpolant;
import three.math.Quaternion;

/**
 * Spherical linear unit quaternion interpolant.
 */

class QuaternionLinearInterpolant extends Interpolant {

    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        var result = this.resultBuffer;
        var values = this.sampleValues;
        var stride = this.valueSize;
        var alpha = (t - t0) / (t1 - t0);

        var offset = i1 * stride;

        while (offset != offset + stride) {
            Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);
            offset += 4;
        }

        return result;
    }
}