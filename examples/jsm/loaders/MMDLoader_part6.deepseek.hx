class CubicBezierInterpolation extends Interpolant {

	public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>, params:Array<Float>) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
		this.interpolationParams = params;
	}

	public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;
		var params = this.interpolationParams;

		var offset1 = i1 * stride;
		var offset0 = offset1 - stride;

		var weight1 = (t1 - t0) < 1 / 30 * 1.5 ? 0.0 : (t - t0) / (t1 - t0);

		if (stride == 4) {
			var x1 = params[i1 * 4 + 0];
			var x2 = params[i1 * 4 + 1];
			var y1 = params[i1 * 4 + 2];
			var y2 = params[i1 * 4 + 3];

			var ratio = this._calculate(x1, x2, y1, y2, weight1);

			Quaternion.slerpFlat(result, 0, values, offset0, values, offset1, ratio);

		} else if (stride == 3) {
			for (i in 0...stride) {
				var x1 = params[i1 * 12 + i * 4 + 0];
				var x2 = params[i1 * 12 + i * 4 + 1];
				var y1 = params[i1 * 12 + i * 4 + 2];
				var y2 = params[i1 * 12 + i * 4 + 3];

				var ratio = this._calculate(x1, x2, y1, y2, weight1);

				result[i] = values[offset0 + i] * (1 - ratio) + values[offset1 + i] * ratio;
			}

		} else {
			var x1 = params[i1 * 4 + 0];
			var x2 = params[i1 * 4 + 1];
			var y1 = params[i1 * 4 + 2];
			var y2 = params[i1 * 4 + 3];

			var ratio = this._calculate(x1, x2, y1, y2, weight1);

			result[0] = values[offset0] * (1 - ratio) + values[offset1] * ratio;
		}

		return result;
	}

	private function _calculate(x1:Float, x2:Float, y1:Float, y2:Float, x:Float):Float {
		var c = 0.5;
		var t = c;
		var s = 1.0 - t;
		var loop = 15;
		var eps = 1e-5;
		var math = Math;

		var sst3:Float;
		var stt3:Float;
		var ttt:Float;

		for (i in 0...loop) {
			sst3 = 3.0 * s * s * t;
			stt3 = 3.0 * s * t * t;
			ttt = t * t * t;

			var ft = (sst3 * x1) + (stt3 * x2) + (ttt) - x;

			if (math.abs(ft) < eps) break;

			c /= 2.0;

			t += (ft < 0) ? c : - c;
			s = 1.0 - t;
		}

		return (sst3 * y1) + (stt3 * y2) + ttt;
	}
}