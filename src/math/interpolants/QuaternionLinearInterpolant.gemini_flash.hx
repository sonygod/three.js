package ;

import kha.math.Quaternion;
import kha.math.FastMatrix4;

class QuaternionLinearInterpolant extends Interpolant {

	public function new(parameterPositions : Array<Float>, sampleValues : Array<Float>, sampleSize : Int, resultBuffer : Array<Float>) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	override public function interpolate_(i1 : Int, t0 : Float, t : Float, t1 : Float) : Array<Float> {
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;

		var alpha = (t - t0) / (t1 - t0);

		var offset = i1 * stride;

		var end = offset + stride;
		while (offset != end) {
			Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);
			offset += 4;
		}

		return result;
	}

}