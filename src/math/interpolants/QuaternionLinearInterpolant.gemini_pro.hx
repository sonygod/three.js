import haxe.io.Bytes;
import interpolant.Interpolant;
import three.math.Quaternion;

/**
 * Spherical linear unit quaternion interpolant.
 */
class QuaternionLinearInterpolant extends Interpolant {

	public function new(parameterPositions:Array<Float>, sampleValues:Bytes, sampleSize:Int, resultBuffer:Bytes) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	override function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Bytes {
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