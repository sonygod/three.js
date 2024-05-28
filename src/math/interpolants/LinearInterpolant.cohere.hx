class LinearInterpolant extends Interpolant {
	public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	private inline function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
		var result = resultBuffer;
		var values = sampleValues;
		var stride = valueSize;

		var offset1 = i1 * stride;
		var offset0 = offset1 - stride;

		var weight1 = (t - t0) / (t1 - t0);
		var weight0 = 1 - weight1;

		var i:Int;
		for (i = 0; i < stride; ++i) {
			result[i] = values[offset0 + i] * weight0 + values[offset1 + i] * weight1;
		}

		return result;
	}
}