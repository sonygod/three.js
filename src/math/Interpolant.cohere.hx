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

class Interpolant {
	public var parameterPositions:Dynamic;
	public var _cachedIndex:Int;
	public var resultBuffer:Dynamic;
	public var sampleValues:Dynamic;
	public var valueSize:Int;
	public var settings:Dynamic;
	public var DefaultSettings_:Dynamic;

	public function new(parameterPositions:Dynamic, sampleValues:Dynamic, sampleSize:Int, ?resultBuffer:Dynamic) {
		this.parameterPositions = parameterPositions;
		this._cachedIndex = 0;
		this.resultBuffer = resultBuffer != null ? resultBuffer : new sampleValues.constructor(sampleSize);
		this.sampleValues = sampleValues;
		this.valueSize = sampleSize;
		this.settings = null;
		this.DefaultSettings_ = {};
	}

	public function evaluate(t:Float):Dynamic {
		var pp = this.parameterPositions;
		var i1 = this._cachedIndex;
		var t1 = pp[i1];
		var t0 = pp[i1 - 1];

		validate_interval: {
			seek: {
				var right:Int;
				linear_scan: {
					forward_scan: if (!(t < t1)) {
						var giveUpAt = i1 + 2;
						while (true) {
							if (t1 == null) {
								if (t < t0) break forward_scan;
								i1 = pp.length;
								this._cachedIndex = i1;
								return this.copySampleValue_(i1 - 1);
							}
							if (i1 == giveUpAt) break;
							t0 = t1;
							t1 = pp[++i1];
							if (t < t1) {
								break seek;
							}
						}
					}
					if (!(t >= t0)) {
						var t1global = pp[1];
						if (t < t1global) {
							i1 = 2;
							t0 = t1global;
						}
						var giveUpAt = i1 - 2;
						while (true) {
							if (t0 == null) {
								this._cachedIndex = 0;
								return this.copySampleValue_(0);
							}
							if (i1 == giveUpAt) break;
							t1 = t0;
							t0 = pp[--i1 - 1];
							if (t >= t0) {
								break seek;
							}
						}
						right = i1;
						i1 = 0;
					}
					break linear_scan;
				} // linear scan
				while (i1 < right) {
					var mid = (i1 + right) >> 1;
					if (t < pp[mid]) {
						right = mid;
					} else {
						i1 = mid + 1;
					}
				}
				t1 = pp[i1];
				t0 = pp[i1 - 1];
				if (t0 == null) {
					this._cachedIndex = 0;
					return this.copySampleValue_(0);
				}
				if (t1 == null) {
					i1 = pp.length;
					this._cachedIndex = i1;
					return this.copySampleValue_(i1 - 1);
				}
				break validate_interval;
			} // seek
			this._cachedIndex = i1;
			this.intervalChanged_(i1, t0, t1);
		} // validate_interval
		return this.interpolate_(i1, t0, t, t1);
	}

	public function getSettings_():Dynamic {
		return this.settings != null ? this.settings : this.DefaultSettings_;
	}

	public function copySampleValue_(index:Int):Dynamic {
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;
		var offset = index * stride;
		var i = 0;
		while (i < stride) {
			result[i] = values[offset + i];
			i++;
		}
		return result;
	}

	// Template methods for derived classes:

	public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Dynamic {
		throw new Error('call to abstract method');
	}

	public function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
		// empty
	}
}

class InterpolantType {
	public static var Interpolant:Dynamic;
}