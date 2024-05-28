package three.math;

/**
 * Abstract base class of interpolants over parametric samples.
 *
 * The parameter domain is one dimensional, typically the time or a path
 * along a curve defined by the data.
 *
 * The sample values can have any dimensionality and derived classes may
 * apply special interpretations to the data.
 *
 * This class provides the interval seek in a Template Method, deferring
 * the actual interpolation to derived classes.
 *
 * Time complexity is O(1) for linear access crossing at most two points
 * and O(log N) for random access, where N is the number of positions.
 *
 * References:
 *
 * 		http://www.oodesign.com/template-method-pattern.html
 *
 */
abstract class Interpolant {

    var parameterPositions:Array<Float>;
    var _cachedIndex:Int;
    var resultBuffer:Array<Float>;
    var sampleValues:Array<Float>;
    var valueSize:Int;
    var settings:Dynamic;
    var DefaultSettings_:Dynamic;

    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, ?resultBuffer:Array<Float>) {
        this.parameterPositions = parameterPositions;
        this._cachedIndex = 0;
        this.resultBuffer = if (resultBuffer != null) resultBuffer else new Array<Float>(sampleSize);
        this.sampleValues = sampleValues;
        this.valueSize = sampleSize;
        this.settings = null;
        this.DefaultSettings_ = {};
    }

    public function evaluate(t:Float):Array<Float> {
        var pp:Array<Float> = parameterPositions;
        var i1:Int = _cachedIndex;
        var t1:Float = pp[i1];
        var t0:Float = pp[i1 - 1];

        validate_interval: {
            seek: {
                var right:Int;

                linear_scan: {
                    if (t >= t1 || t1 == Math.POSITIVE_INFINITY) {
                        forward_scan: {
                            for (giveUpAt in i1 + 2...Int.MAX) {
                                if (t1 == Math.POSITIVE_INFINITY) {
                                    if (t < t0) break forward_scan;
                                    i1 = pp.length;
                                    _cachedIndex = i1;
                                    return copySampleValue_(i1 - 1);
                                }

                                t0 = t1;
                                t1 = pp[++i1];

                                if (t < t1) {
                                    break seek;
                                }
                            }

                            right = pp.length;
                            break linear_scan;
                        }
                    } else {
                        // slower code:
                        // if (t < t0 || t0 == Math.NEGATIVE_INFINITY) {
                        if (t <= t0) {
                            // looping?
                            var t1global:Float = pp[1];
                            if (t < t1global) {
                                i1 = 2;
                                t0 = t1global;
                            }

                            // linear reverse scan
                            for (giveUpAt in i1 - 2...0) {
                                if (t0 == Math.NEGATIVE_INFINITY) {
                                    // before start
                                    _cachedIndex = 0;
                                    return copySampleValue_(0);
                                }

                                t1 = t0;
                                t0 = pp[--i1 - 1];

                                if (t >= t0) {
                                    break seek;
                                }
                            }

                            right = i1;
                            i1 = 0;
                            break linear_scan;
                        }
                    }

                    // binary search
                    while (i1 < right) {
                        var mid:Int = (i1 + right) >>> 1;
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
                        _cachedIndex = 0;
                        return copySampleValue_(0);
                    }

                    if (t1 == Math.POSITIVE_INFINITY) {
                        i1 = pp.length;
                        _cachedIndex = i1;
                        return copySampleValue_(i1 - 1);
                    }
                } // seek

                _cachedIndex = i1;

                intervalChanged_(i1, t0, t1);
            } // validate_interval

            return interpolate_(i1, t0, t, t1);
        }

        public function getSettings_():Dynamic {
            return settings != null ? settings : DefaultSettings_;
        }

        public function copySampleValue_(index:Int):Array<Float> {
            var result:Array<Float> = resultBuffer;
            var values:Array<Float> = sampleValues;
            var stride:Int = valueSize;
            var offset:Int = index * stride;

            for (i in 0...stride) {
                result[i] = values[offset + i];
            }

            return result;
        }

        // Template methods for derived classes:

        public abstract function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float>;

        public function intervalChanged_(i1:Int, t0:Float, t1:Float) {
            // empty
        }
}