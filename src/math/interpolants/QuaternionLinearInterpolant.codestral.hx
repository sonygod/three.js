import three.js.math.Interpolant;
import three.js.math.Quaternion;

typedef QuaternionLinearInterpolant = Interpolant;

class QuaternionLinearInterpolant {

    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        var result = this.resultBuffer;
        var values = this.sampleValues;
        var stride = this.valueSize;
        var alpha = (t - t0) / (t1 - t0);
        var offset = i1 * stride;

        for (var end = offset + stride; offset != end; offset += 4) {
            Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);
        }

        return result;
    }
}