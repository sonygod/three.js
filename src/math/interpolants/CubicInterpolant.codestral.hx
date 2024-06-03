import three.constants.ZeroCurvatureEnding;
import three.constants.WrapAroundEnding;
import three.constants.ZeroSlopeEnding;
import three.math.Interpolant;

class CubicInterpolant extends Interpolant {

    private var _weightPrev: Float = -0;
    private var _offsetPrev: Int = -0;
    private var _weightNext: Float = -0;
    private var _offsetNext: Int = -0;

    private var DefaultSettings_: Dynamic = {
        endingStart: ZeroCurvatureEnding,
        endingEnd: ZeroCurvatureEnding
    };

    public function new(parameterPositions: Array<Float>, sampleValues: Array<Float>, sampleSize: Int, resultBuffer: Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override function intervalChanged_(i1: Int, t0: Float, t1: Float): Void {
        var pp: Array<Float> = this.parameterPositions;
        var iPrev: Int = i1 - 2;
        var iNext: Int = i1 + 1;
        var tPrev: Float = pp[iPrev];
        var tNext: Float = pp[iNext];

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

        var halfDt: Float = (t1 - t0) * 0.5;
        var stride: Int = this.valueSize;

        this._weightPrev = halfDt / (t0 - tPrev);
        this._weightNext = halfDt / (tNext - t1);
        this._offsetPrev = iPrev * stride;
        this._offsetNext = iNext * stride;
    }

    override function interpolate_(i1: Int, t0: Float, t: Float, t1: Float): Array<Float> {
        var result: Array<Float> = this.resultBuffer;
        var values: Array<Float> = this.sampleValues;
        var stride: Int = this.valueSize;

        var o1: Int = i1 * stride;
        var o0: Int = o1 - stride;
        var oP: Int = this._offsetPrev;
        var oN: Int = this._offsetNext;
        var wP: Float = this._weightPrev;
        var wN: Float = this._weightNext;

        var p: Float = (t - t0) / (t1 - t0);
        var pp: Float = p * p;
        var ppp: Float = pp * p;

        var sP: Float = -wP * ppp + 2 * wP * pp - wP * p;
        var s0: Float = (1 + wP) * ppp + (-1.5 - 2 * wP) * pp + (-0.5 + wP) * p + 1;
        var s1: Float = (-1 - wN) * ppp + (1.5 + wN) * pp + 0.5 * p;
        var sN: Float = wN * ppp - wN * pp;

        for (var i: Int = 0; i < stride; i++) {
            result[i] = sP * values[oP + i] + s0 * values[o0 + i] + s1 * values[o1 + i] + sN * values[oN + i];
        }

        return result;
    }
}