import haxe.io.Bytes;
import interpolant.Interpolant;
import interpolant.constants.ZeroCurvatureEnding;
import interpolant.constants.WrapAroundEnding;
import interpolant.constants.ZeroSlopeEnding;

/**
 * Fast and simple cubic spline interpolant.
 *
 * It was derived from a Hermitian construction setting the first derivative
 * at each sample position to the linear slope between neighboring positions
 * over their parameter interval.
 */
class CubicInterpolant extends Interpolant {
	public var _weightPrev:Float;
	public var _offsetPrev:Int;
	public var _weightNext:Float;
	public var _offsetNext:Int;

	public function new(parameterPositions:Array<Float>, sampleValues:Bytes, sampleSize:Int, resultBuffer:Bytes) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
		this._weightPrev = -0;
		this._offsetPrev = -0;
		this._weightNext = -0;
		this._offsetNext = -0;
	}

	override function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
		var pp = this.parameterPositions;
		var iPrev = i1 - 2;
		var iNext = i1 + 1;
		var tPrev = pp[iPrev];
		var tNext = pp[iNext];
		if (tPrev == null) {
			switch (this.getSettings_().endingStart) {
				case ZeroSlopeEnding:
					iPrev = i1;
					tPrev = 2 * t0 - t1;
					break;
				case WrapAroundEnding:
					iPrev = pp.length - 2;
					tPrev = t0 + pp[iPrev] - pp[iPrev + 1];
					break;
				default:
					iPrev = i1;
					tPrev = t1;
			}
		}
		if (tNext == null) {
			switch (this.getSettings_().endingEnd) {
				case ZeroSlopeEnding:
					iNext = i1;
					tNext = 2 * t1 - t0;
					break;
				case WrapAroundEnding:
					iNext = 1;
					tNext = t1 + pp[1] - pp[0];
					break;
				default:
					iNext = i1 - 1;
					tNext = t0;
			}
		}
		var halfDt = (t1 - t0) * 0.5;
		var stride = this.valueSize;
		this._weightPrev = halfDt / (t0 - tPrev);
		this._weightNext = halfDt / (tNext - t1);
		this._offsetPrev = iPrev * stride;
		this._offsetNext = iNext * stride;
	}

	override function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Bytes {
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;
		var o1 = i1 * stride;
		var o0 = o1 - stride;
		var oP = this._offsetPrev;
		var oN = this._offsetNext;
		var wP = this._weightPrev;
		var wN = this._weightNext;
		var p = (t - t0) / (t1 - t0);
		var pp = p * p;
		var ppp = pp * p;
		var sP = -wP * ppp + 2 * wP * pp - wP * p;
		var s0 = (1 + wP) * ppp + (-1.5 - 2 * wP) * pp + (-0.5 + wP) * p + 1;
		var s1 = (-1 - wN) * ppp + (1.5 + wN) * pp + 0.5 * p;
		var sN = wN * ppp - wN * pp;
		for (i in 0...stride) {
			result.set(i, sP * values.get(oP + i) + s0 * values.get(o0 + i) + s1 * values.get(o1 + i) + sN * values.get(oN + i));
		}
		return result;
	}
}