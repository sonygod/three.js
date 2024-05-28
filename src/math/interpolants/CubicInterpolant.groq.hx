package three.math.interpolants;

import three.math.constants.ZeroCurvatureEnding;
import three.math.constants.WrapAroundEnding;
import three.math.constants.ZeroSlopeEnding;
import three.math.Interpolant;

/**
 * Fast and simple cubic spline interpolant.
 *
 * It was derived from a Hermitian construction setting the first derivative
 * at each sample position to the linear slope between neighboring positions
 * over their parameter interval.
 */

class CubicInterpolant extends Interpolant {

	var _weightPrev:Float = -0;
	var _offsetPrev:Int;
	var _weightNext:Float = -0;
	var _offsetNext:Int;

	var defaultSettings:Dynamic = {
		endingStart: ZeroCurvatureEnding,
		endingEnd: ZeroCurvatureEnding
	};

	public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	function intervalChanged_(i1:Int, t0:Float, t1:Float) {
		var pp:Array<Float> = parameterPositions;
		var iPrev:Int = i1 - 2;
		var iNext:Int = i1 + 1;
		var tPrev:Float = pp[iPrev];
		var tNext:Float = pp[iNext];

		if (tPrev == null) {
			switch (getSettings().endingStart) {
				case ZeroSlopeEnding:
					iPrev = i1;
					tPrev = 2 * t0 - t1;
				case WrapAroundEnding:
					iPrev = pp.length - 2;
					tPrev = t0 + pp[iPrev] - pp[iPrev + 1];
				default: // ZeroCurvatureEnding
					iPrev = i1;
					tPrev = t1;
			}
		}

		if (tNext == null) {
			switch (getSettings().endingEnd) {
				case ZeroSlopeEnding:
					iNext = i1;
					tNext = 2 * t1 - t0;
				case WrapAroundEnding:
					iNext = 1;
					tNext = t1 + pp[1] - pp[0];
				default: // ZeroCurvatureEnding
					iNext = i1 - 1;
					tNext = t0;
			}
		}

		var halfDt:Float = (t1 - t0) * 0.5;
		var stride:Int = valueSize;

		_weightPrev = halfDt / (t0 - tPrev);
		_weightNext = halfDt / (tNext - t1);
		_offsetPrev = iPrev * stride;
		_offsetNext = iNext * stride;
	}

	function interpolate_(i1:Int, t0:Float, t:Float, t1:Float) {
		var result:Array<Float> = resultBuffer;
		var values:Array<Float> = sampleValues;
		var stride:Int = valueSize;

		var o1:Int = i1 * stride;
		var o0:Int = o1 - stride;
		var oP:Int = _offsetPrev;
		var oN:Int = _offsetNext;
		var wP:Float = _weightPrev;
		var wN:Float = _weightNext;

		var p:Float = (t - t0) / (t1 - t0);
		var pp:Float = p * p;
		var ppp:Float = pp * p;

		// evaluate polynomials

		var sP:Float = -wP * ppp + 2 * wP * pp - wP * p;
		var s0:Float = (1 + wP) * ppp + (-1.5 - 2 * wP) * pp + (-0.5 + wP) * p + 1;
		var s1:Float = (-1 - wN) * ppp + (1.5 + wN) * pp + 0.5 * p;
		var sN:Float = wN * ppp - wN * pp;

		// combine data linearly

		for (i in 0...stride) {
			result[i] =
				sP * values[oP + i] +
				s0 * values[o0 + i] +
				s1 * values[o1 + i] +
				sN * values[oN + i];
		}

		return result;
	}
}