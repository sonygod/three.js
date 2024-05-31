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

	public var parameterPositions:Array<Float>;
	private var _cachedIndex:Int;
	public var resultBuffer:Array<Float>;
	public var sampleValues:Array<Float>;
	public var valueSize:Int;
	public var settings:Dynamic;
	private var DefaultSettings_:Dynamic;

	public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, ?resultBuffer:Array<Float>) {
		this.parameterPositions = parameterPositions;
		this._cachedIndex = 0;
		this.resultBuffer = resultBuffer != null ? resultBuffer : new Array<Float>(sampleSize);
		this.sampleValues = sampleValues;
		this.valueSize = sampleSize;
		this.settings = null;
		this.DefaultSettings_ = {};
	}

	public function evaluate(t:Float):Array<Float> {
		var pp = this.parameterPositions;
		var i1 = this._cachedIndex;
		var t1 = pp[i1];
		var t0 = pp[i1 - 1];

		validate_interval: {
			seek: {
				var right:Int;

				linear_scan: {
					forward_scan: if (!(t < t1)) {
						for (giveUpAt in i1 + 2...) {
							if (t1 == null) {
								if (t < t0) break forward_scan;

								// after end
								i1 = pp.length;
								this._cachedIndex = i1;
								return this.copySampleValue_(i1 - 1);
							}

							if (i1 == giveUpAt) break;

							t0 = t1;
							t1 = pp[++i1];

							if (t < t1) {
								// we have arrived at the sought interval
								break seek;
							}
						}
						right = pp.length;
						break linear_scan;
					}

					if (!(t >= t0)) {
						var t1global = pp[1];

						if (t < t1global) {
							i1 = 2;
							t0 = t1global;
						}

						for (giveUpAt in i1 - 2...) {
							if (t0 == null) {
								// before start
								this._cachedIndex = 0;
								return this.copySampleValue_(0);
							}

							if (i1 == giveUpAt) break;

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

					break validate_interval;
				}

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

				if (t0 == null) {
					this._cachedIndex = 0;
					return this.copySampleValue_(0);
				}

				if (t1 == null) {
					i1 = pp.length;
					this._cachedIndex = i1;
					return this.copySampleValue_(i1 - 1);
				}
			}

			this._cachedIndex = i1;
			this.intervalChanged_(i1, t0, t1);
		}

		return this.interpolate_(i1, t0, t, t1);
	}

	public function getSettings_():Dynamic {
		return this.settings != null ? this.settings : this.DefaultSettings_;
	}

	private function copySampleValue_(index:Int):Array<Float> {
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;
		var offset = index * stride;

		for (i in 0...stride) {
			result[i] = values[offset + i];
		}

		return result;
	}

	// Template methods for derived classes:

	private function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
		throw 'call to abstract method';
		// implementations shall return this.resultBuffer
	}

	private function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
		// empty
	}

}