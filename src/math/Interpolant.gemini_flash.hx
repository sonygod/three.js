class Interpolant {
  public var parameterPositions:Array<Float>;
  private var _cachedIndex:Int = 0;
  public var resultBuffer:Dynamic;
  public var sampleValues:Dynamic;
  public var valueSize:Int;
  public var settings:Dynamic = null;
  public var DefaultSettings_:Dynamic = {};

  public function new(parameterPositions:Array<Float>, sampleValues:Dynamic, sampleSize:Int, resultBuffer:Dynamic = null) {
    this.parameterPositions = parameterPositions;
    this.resultBuffer = resultBuffer != null ? resultBuffer : Type.createInstance(Type.typeof(sampleValues), [sampleSize]);
    this.sampleValues = sampleValues;
    this.valueSize = sampleSize;
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
          if (t >= t1 || t1 == null) {
            forward_scan: {
              for (giveUpAt in i1 + 2) {
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
              // prepare binary search on the right side of the index
              right = pp.length;
              break linear_scan;
            }
          }
          if (t < t0 || t0 == null) {
            // looping?
            var t1global = pp[1];
            if (t < t1global) {
              i1 = 2; // + 1, using the scan for the details
              t0 = t1global;
            }
            // linear reverse scan
            for (giveUpAt in i1 - 2) {
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
            // prepare binary search on the left side of the index
            right = i1;
            i1 = 0;
            break linear_scan;
          }
          // the interval is valid
          break validate_interval;
        }

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
      }
      this._cachedIndex = i1;
      this.intervalChanged_(i1, t0, t1);
    }
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
    for (i in 0...stride) {
      result[i] = values[offset + i];
    }
    return result;
  }

  public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Dynamic {
    throw "call to abstract method";
  }

  public function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
    // empty
  }
}