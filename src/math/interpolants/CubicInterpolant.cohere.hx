import js.Browser.window;
import js.html.CanvasElement;
import js.html.Document;

class CubicInterpolant {
    public function new(parameterPositions: Array<Float>, sampleValues: Array<Float>, sampleSize: Int, resultBuffer: Array<Float>) {
        this._weightPrev = -0.0;
        this._offsetPrev = -0;
        this._weightNext = -0.0;
        this._offsetNext = -0;

        this.DefaultSettings_ = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        this.parameterPositions = parameterPositions;
        this.sampleValues = sampleValues;
        this.sampleSize = sampleSize;
        this.resultBuffer = resultBuffer;
    }

    private inline function intervalChanged_(i1: Int, t0: Float, t1: Float): Void {
        var pp = parameterPositions;
        var iPrev = i1 - 2;
        var iNext = i1 + 1;
        var tPrev = pp[iPrev];
        var tNext = pp[iNext];

        if (tPrev == null) {
            switch (getSettings_().endingStart) {
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
            switch (getSettings_().endingEnd) {
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
        var stride = sampleSize;

        _weightPrev = halfDt / (t0 - tPrev);
        _weightNext = halfDt / (tNext - t1);
        _offsetPrev = iPrev * stride;
        _offsetNext = iNext * stride;
    }

    private inline function interpolate_(i1: Int, t0: Float, t: Float, t1: Float): Array<Float> {
        var result = resultBuffer;
        var values = sampleValues;
        var stride = sampleSize;
        var o1 = i1 * stride;
        var o0 = o1 - stride;
        var oP = _offsetPrev;
        var oN = _offsetNext;
        var wP = _weightPrev;
        var wN = _weightNext;
        var p = (t - t0) / (t1 - t0);
        var pp = p * p;
        var ppp = pp * p;

        // evaluate polynomials
        var sP = -wP * ppp + 2 * wP * pp - wP * p;
        var s0 = (1 + wP) * ppp + (-1.5 - 2 * wP) * pp + (-0.5 + wP) * p + 1;
        var s1 = (-1 - wN) * ppp + (1.5 + wN) * pp + 0.5 * p;
        var sN = wN * ppp - wN * pp;

        // combine data linearly
        var i: Int;
        for (i = 0; i < stride; i++) {
            result[i] = (sP * values[oP + i] + s0 * values[o0 + i] + s1 * values[o1 + i] + sN * values[oN + i]);
        }

        return result;
    }

    private var _weightPrev: Float;
    private var _offsetPrev: Int;
    private var _weightNext: Float;
    private var _offsetNext: Int;
    private var DefaultSettings_: { endingStart: Int, endingEnd: Int };

    private var parameterPositions: Array<Float>;
    private var sampleValues: Array<Float>;
    private var sampleSize: Int;
    private var resultBuffer: Array<Float>;
}

enum ZeroCurvatureEnding {
    case Zero;
    case WrapAround;
    case ZeroSlope;
}

class Interpolant {
    public function new(parameterPositions: Array<Float>, sampleValues: Array<Float>, sampleSize: Int, resultBuffer: Array<Float>) { }
}

class Main {
    static public function main() {
        var parameterPositions: Array<Float> = [1, 2, 3, 4, 5];
        var sampleValues: Array<Float> = [10, 20, 30, 40, 50];
        var sampleSize: Int = 5;
        var resultBuffer: Array<Float> = [];

        var cubicInterpolant = CubicInterpolant(parameterPositions, sampleValues, sampleSize, resultBuffer);
        var result = cubicInterpolant.interpolate_(0, 1.0, 2.0, 3.0);

        window.alert("Result: " + result.join(", "));
    }
}