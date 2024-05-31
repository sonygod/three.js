import three.math.Interpolant;

class LinearInterpolant extends Interpolant {

	public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	override public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;

		var offset1 = i1 * stride;
		var offset0 = offset1 - stride;

		var weight1 = (t - t0) / (t1 - t0);
		var weight0 = 1 - weight1;

		for (i in 0...stride) {
			result[i] = values[offset0 + i] * weight0 + values[offset1 + i] * weight1;
		}

		return result;
	}
}