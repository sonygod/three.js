package three.math;

import haxe.ds.Vector;

class Interpolant {
    public var parameterPositions:Vector<Float>;
    public var _cachedIndex:Int;
    public var resultBuffer:Vector<Float>;
    public var sampleValues:Vector<Float>;
    public var valueSize:Int;
    public var settings:Dynamic;
    public var DefaultSettings_:Dynamic;

    public function new(parameterPositions:Vector<Float>, sampleValues:Vector<Float>, sampleSize:Int, ?resultBuffer:Vector<Float>) {
        this.parameterPositions = parameterPositions;
        this._cachedIndex = 0;

        this.resultBuffer = if (resultBuffer != null) resultBuffer else new Vector<Float>(sampleSize);
        this.sampleValues = sampleValues;
        this.valueSize = sampleSize;

        this.settings = null;
        this.DefaultSettings_ = {};
    }

    public function evaluate(t:Float):Vector<Float> {
        var pp = this.parameterPositions;
        var i1 = this._cachedIndex;
        var t1 = pp[i1];
        var t0 = pp[i1 - 1];

        validate_interval: {
            seek: {
                var right:Int;

                linear_scan: {
                    forward_scan: if (t >= t1 || t1 == Math.POSITIVE_INFINITY) {
                        for (giveUpAt in i1 + 2...Math.POSITIVE_INFINITY) {
                            if (t1 == Math.POSITIVE_INFINITY) {
                                if (t < t0) break forward_scan;
                                i1 = pp.length;
                                this._cachedIndex = i1;
                                return copySampleValue_(i1 - 1);
                            }

                            if (i1 == giveUpAt) break; // this loop

                            t0 = t1;
                            t1 = pp[++i1];

                            if (t < t1) {
                                break seek;
                            }
                        }

                        right = pp.length;
                        break linear_scan;
                    }

                    if (t < t0 || t0 == Math.NEGATIVE_INFINITY) {
                        // looping?

                        var t1global = pp[1];

                        if (t < t1global) {
                            i1 = 2; // + 1, using the scan for the details
                            t0 = t1global;
                        }

                        // linear reverse scan

                        for (giveUpAt in i1 - 2...0) {
                            if (t0 == Math.NEGATIVE_INFINITY) {
                                // before start

                                this._cachedIndex = 0;
                                return copySampleValue_(0);
                            }

                            if (i1 == giveUpAt) break; // this loop

                            t1 = t0;
                            t0 = pp[--i1 - 1];

                            if (t >= t0) {
                                // we have arrived at the sought interval
                                break seek;
                            }
                        }

                        right = i1;
                        i1 = 0;
                        break linear_scan;
                    }

                    // the interval is valid

                    break validate_interval;
                } // linear scan

                // binary search

                while (i1 < right) {
                    var mid = (i1 + right) >>> 1;

                    if (t < pp[mid]) {
                        right = mid;
                    } else {
                        i1 = mid + 1;
                    }
                }

                t1 = pp[i1];
                t0 = pp[i1 - 1];

                // check boundary cases, again

                if (t0 == Math.NEGATIVE_INFINITY) {
                    this._cachedIndex = 0;
                    return copySampleValue_(0);
                }

                if (t1 == Math.POSITIVE_INFINITY) {
                    i1 = pp.length;
                    this._cachedIndex = i1;
                    return copySampleValue_(i1 - 1);
                }
            } // seek

            this._cachedIndex = i1;

            intervalChanged_(i1, t0, t1);

        } // validate_interval

        return interpolate_(i1, t0, t, t1);
    }

    public function getSettings_():Dynamic {
        return settings != null ? settings : DefaultSettings_;
    }

    public function copySampleValue_(index:Int):Vector<Float> {
        // copies a sample value to the result buffer

        var result = resultBuffer;
        var values = sampleValues;
        var stride = valueSize;
        var offset = index * stride;

        for (i in 0...stride) {
            result[i] = values[offset + i];
        }

        return result;
    }

    // Template methods for derived classes:

    public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Vector<Float> {
        throw new Error('call to abstract method');
        // implementations shall return this.resultBuffer
    }

    public function intervalChanged_(i1:Int, t0:Float, t1:Float) {
        // empty
    }
}