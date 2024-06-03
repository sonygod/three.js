package three.math;

import haxe.ds.Vector;

class Interpolant {
    public var parameterPositions: Vector<Float>;
    public var _cachedIndex: Int = 0;
    public var resultBuffer: Vector<Float>;
    public var sampleValues: Vector<Float>;
    public var valueSize: Int;
    public var settings: Dynamic = null;
    public var DefaultSettings_: Dynamic = {};

    public function new(parameterPositions: Vector<Float>, sampleValues: Vector<Float>, sampleSize: Int, resultBuffer: Vector<Float> = null) {
        this.parameterPositions = parameterPositions;
        this.sampleValues = sampleValues;
        this.valueSize = sampleSize;

        if (resultBuffer != null) {
            this.resultBuffer = resultBuffer;
        } else {
            this.resultBuffer = new Vector<Float>(sampleSize);
        }
    }

    public function evaluate(t: Float): Vector<Float> {
        var pp = this.parameterPositions;
        var i1: Int = this._cachedIndex;
        var t1: Float = pp.get(i1);
        var t0: Float = pp.get(i1 - 1);

        if (t >= t1 || t1 == null) {
            if (t < t0 || t0 == null) {
                // Implement the remaining part of this function based on the JavaScript version
            } else {
                // Implement the remaining part of this function based on the JavaScript version
            }
        } else {
            // Implement the remaining part of this function based on the JavaScript version
        }

        return this.resultBuffer;
    }

    public function getSettings_(): Dynamic {
        return this.settings != null ? this.settings : this.DefaultSettings_;
    }

    public function copySampleValue_(index: Int): Vector<Float> {
        var result = this.resultBuffer;
        var values = this.sampleValues;
        var stride = this.valueSize;
        var offset = index * stride;

        for (var i: Int = 0; i < stride; i++) {
            result.set(i, values.get(offset + i));
        }

        return result;
    }

    public function interpolate_(i1: Int, t0: Float, t: Float, t1: Float): Vector<Float> {
        throw "call to abstract method";
    }

    public function intervalChanged_(i1: Int, t0: Float, t1: Float): Void {
        // empty
    }
}