import js.Interpolant;
import js.Quaternion;

class QuaternionLinearInterpolant extends Interpolant {

	public function new(parameterPositions:Float32Array, sampleValues:Float32Array, sampleSize:Int, resultBuffer:Float32Array) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Float32Array {
		var result = resultBuffer;
		var values = sampleValues;
		var stride = valueSize;
		var alpha = (t - t0) / (t1 - t0);

		var offset = i1 * stride;
		var end = offset + stride;

		while (offset < end) {
			Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);
			offset += 4;
		}

		return result;
	}

}