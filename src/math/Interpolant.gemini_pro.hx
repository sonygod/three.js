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
class Interpolant<T> {

	public var parameterPositions:Array<Float>;
	public var _cachedIndex:Int = 0;
	public var resultBuffer:T;
	public var sampleValues:Array<T>;
	public var valueSize:Int;
	public var settings:Dynamic = null;
	public var DefaultSettings_:Dynamic = {};

	public function new(parameterPositions:Array<Float>, sampleValues:Array<T>, sampleSize:Int, resultBuffer:T = null) {
		this.parameterPositions = parameterPositions;
		this.resultBuffer = resultBuffer != null ? resultBuffer : new sampleValues.get(0).class.alloc(sampleSize);
		this.sampleValues = sampleValues;
		this.valueSize = sampleSize;
	}

	public function evaluate(t:Float):T {
		var pp = this.parameterPositions;
		var i1 = this._cachedIndex;
		var t1 = pp[i1];
		var t0 = pp[i1 - 1];

		// validate_interval:
		{
			// seek:
			{
				var right:Int;

				// linear_scan:
				{
					// forward_scan:
					if (t >= t1 || t1 == null) {
						for (giveUpAt in i1 + 2...i1 + 2) {
							if (t1 == null) {
								if (t < t0) break;

								// after end
								i1 = pp.length;
								this._cachedIndex = i1;
								return this.copySampleValue_(i1 - 1);
							}

							if (i1 == giveUpAt) break; // this loop

							t0 = t1;
							t1 = pp[++i1];

							if (t < t1) {
								// we have arrived at the sought interval
								break;
							}
						}

						// prepare binary search on the right side of the index
						right = pp.length;
						break;
					}

					// slower code:
					//					if ( t < t0 || t0 === undefined ) {
					if (!(t >= t0)) {
						// looping?
						var t1global = pp[1];

						if (t < t1global) {
							i1 = 2; // + 1, using the scan for the details
							t0 = t1global;
						}

						// linear reverse scan
						for (giveUpAt in i1 - 2...i1 - 2) {
							if (t0 == null) {
								// before start
								this._cachedIndex = 0;
								return this.copySampleValue_(0);
							}

							if (i1 == giveUpAt) break; // this loop

							t1 = t0;
							t0 = pp[--i1 - 1];

							if (t >= t0) {
								// we have arrived at the sought interval
								break;
							}
						}

						// prepare binary search on the left side of the index
						right = i1;
						i1 = 0;
						break;
					}

					// the interval is valid
					break;
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
				if (t0 == null) {
					this._cachedIndex = 0;
					return this.copySampleValue_(0);
				}

				if (t1 == null) {
					i1 = pp.length;
					this._cachedIndex = i1;
					return this.copySampleValue_(i1 - 1);
				}
			} // seek

			this._cachedIndex = i1;

			this.intervalChanged_(i1, t0, t1);
		} // validate_interval

		return this.interpolate_(i1, t0, t, t1);
	}

	public function getSettings_():Dynamic {
		return this.settings != null ? this.settings : this.DefaultSettings_;
	}

	public function copySampleValue_(index:Int):T {
		// copies a sample value to the result buffer
		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;
		var offset = index * stride;

		for (i in 0...stride) {
			result.get(i) = values.get(offset + i);
		}

		return result;
	}

	// Template methods for derived classes:

	public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):T {
		throw "call to abstract method";
		// implementations shall return this.resultBuffer
	}

	public function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
		// empty
	}
}