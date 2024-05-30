import three.constants.ZeroCurvatureEnding;
import three.constants.WrapAroundEnding;
import three.constants.ZeroSlopeEnding;
import three.math.Interpolant;

/**
 * Fast and simple cubic spline interpolant.
 *
 * It was derived from a Hermitian construction setting the first derivative
 * at each sample position to the linear slope between neighboring positions
 * over their parameter interval.
 */

class CubicInterpolant extends Interpolant {

    public var _weightPrev:Float = -0;
    public var _offsetPrev:Float = -0;
    public var _weightNext:Float = -0;
    public var _offsetNext:Float = -0;

    public var DefaultSettings_:Dynamic = {
        endingStart: ZeroCurvatureEnding,
        endingEnd: ZeroCurvatureEnding
    };

    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, ?resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
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
                    // f'(t0) = 0
                    iPrev = i1;
                    tPrev = 2 * t0 - t1;
                    break;
                case WrapAroundEnding:
                    // use the other end of the curve
                    iPrev = pp.length - 2;
                    tPrev = t0 + pp[iPrev] - pp[iPrev + 1];
                    break;
                default: // ZeroCurvatureEnding
                    // f''(t0) = 0 a.k.a. Natural Spline
                    iPrev = i1;
                    tPrev = t1;
            }
        }

        if (tNext == null) {
            switch (this.getSettings_().endingEnd) {
                case ZeroSlopeEnding:
                    // f'(tN) = 0
                    iNext = i1;
                    tNext = 2 * t1 - t0;
                    break;
                case WrapAroundEnding:
                    // use the other end of the curve
                    iNext = 1;
                    tNext = t1 + pp[1] - pp[0];
                    break;
                default: // ZeroCurvatureEnding
                    // f''(tN) = 0, a.k.a. Natural Spline
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

    override function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
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

        // evaluate polynomials
        var sP = -wP * ppp + 2 * wP * pp - wP * p;
        var s0 = (1 + wP) * ppp + (-1.5 - 2 * wP) * pp + (-0.5 + wP) * p + 1;
        var s1 = (-1 - wN) * ppp + (1.5 + wN) * pp + 0.5 * p;
        var sN = wN * ppp - wN * pp;

        // combine data linearly
        for (i in 0...stride) {
            result[i] = sP * values[oP + i] +
                        s0 * values[o0 + i] +
                        s1 * values[o1 + i] +
                        sN * values[oN + i];
        }

        return result;
    }
}