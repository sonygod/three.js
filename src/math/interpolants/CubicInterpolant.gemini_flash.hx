import haxe.ds.Option;
package;

using Lambda;

class CubicInterpolant extends Interpolant {

    public var _weightPrev(default, null):Float;
    public var _offsetPrev(default, null):Int;
    public var _weightNext(default, null):Float;
    public var _offsetNext(default, null):Int;

    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);

        this._weightPrev = -0;
        this._offsetPrev = -0;
        this._weightNext = -0;
        this._offsetNext = -0;

        this.DefaultSettings_ = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };
    }

    override public function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
        var pp = this.parameterPositions;
        var iPrev:Int = i1 - 2;
        var iNext:Int = i1 + 1;

        var tPrev:Float = (iPrev >= 0 && iPrev < pp.length) ? pp[iPrev] : Math.NaN;
        var tNext:Float = (iNext >= 0 && iNext < pp.length) ? pp[iNext] : Math.NaN;

        if (Math.isNaN(tPrev)) {
            switch (this.getSettings_().endingStart) {
                case ZeroSlopeEnding:
                    // f'(t0) = 0
                    iPrev = i1;
                    tPrev = 2 * t0 - t1;
                case WrapAroundEnding:
                    // use the other end of the curve
                    iPrev = pp.length - 2;
                    tPrev = t0 + pp[iPrev] - pp[iPrev + 1];
                case ZeroCurvatureEnding:
                    // f''(t0) = 0 a.k.a. Natural Spline
                    iPrev = i1;
                    tPrev = t1;
            }
        }

        if (Math.isNaN(tNext)) {
            switch (this.getSettings_().endingEnd) {
                case ZeroSlopeEnding:
                    // f'(tN) = 0
                    iNext = i1;
                    tNext = 2 * t1 - t0;
                case WrapAroundEnding:
                    // use the other end of the curve
                    iNext = 1;
                    tNext = t1 + pp[1] - pp[0];
                case ZeroCurvatureEnding:
                    // f''(tN) = 0, a.k.a. Natural Spline
                    iNext = i1 - 1;
                    tNext = t0;
            }
        }

        var halfDt:Float = (t1 - t0) * 0.5;
        var stride:Int = this.valueSize;

        this._weightPrev = halfDt / (t0 - tPrev);
        this._weightNext = halfDt / (tNext - t1);
        this._offsetPrev = iPrev * stride;
        this._offsetNext = iNext * stride;
    }

    override public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        var result = this.resultBuffer;
        var values = this.sampleValues;
        var stride = this.valueSize;

        var o1 = i1 * stride;
        var o0 = o1 - stride;
        var oP = this._offsetPrev;
        var oN = this._offsetNext;
        var wP = this._weightPrev;
        var wN = this._weightNext;

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

    // ... (rest of the class implementation, if any)
}