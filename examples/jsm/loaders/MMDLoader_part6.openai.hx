package three.js.examples.jsm.loaders;

import three.js.Interpolant;

class CubicBezierInterpolation extends Interpolant {
  public var interpolationParams:Array<Float>;

  public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>, params:Array<Float>) {
    super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    interpolationParams = params;
  }

  override public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
    var result:Array<Float> = resultBuffer;
    var values:Array<Float> = sampleValues;
    var stride:Int = valueSize;
    var params:Array<Float> = interpolationParams;

    var offset1:Int = i1 * stride;
    var offset0:Int = offset1 - stride;

    // No interpolation if next key frame is in one frame in 30fps.
    // This is from MMD animation spec.
    // '1.5' is for precision loss. times are Float32 in Three.js Animation system.
    var weight1:Float = ((t1 - t0) < 1 / 30 * 1.5) ? 0.0 : (t - t0) / (t1 - t0);

    if (stride == 4) { // Quaternion
      var x1:Float = params[i1 * 4 + 0];
      var x2:Float = params[i1 * 4 + 1];
      var y1:Float = params[i1 * 4 + 2];
      var y2:Float = params[i1 * 4 + 3];

      var ratio:Float = _calculate(x1, x2, y1, y2, weight1);

      Quaternion.slerpFlat(result, 0, values, offset0, values, offset1, ratio);
    } else if (stride == 3) { // Vector3
      for (i in 0...stride) {
        var x1:Float = params[i1 * 12 + i * 4 + 0];
        var x2:Float = params[i1 * 12 + i * 4 + 1];
        var y1:Float = params[i1 * 12 + i * 4 + 2];
        var y2:Float = params[i1 * 12 + i * 4 + 3];

        var ratio:Float = _calculate(x1, x2, y1, y2, weight1);

        result[i] = values[offset0 + i] * (1 - ratio) + values[offset1 + i] * ratio;
      }
    } else { // Number
      var x1:Float = params[i1 * 4 + 0];
      var x2:Float = params[i1 * 4 + 1];
      var y1:Float = params[i1 * 4 + 2];
      var y2:Float = params[i1 * 4 + 3];

      var ratio:Float = _calculate(x1, x2, y1, y2, weight1);

      result[0] = values[offset0] * (1 - ratio) + values[offset1] * ratio;
    }

    return result;
  }

  private function _calculate(x1:Float, x2:Float, y1:Float, y2:Float, x:Float):Float {
    var c:Float = 0.5;
    var t:Float = c;
    var s:Float = 1.0 - t;
    var loop:Int = 15;
    var eps:Float = 1e-5;
    var math:Math = Math;

    var sst3:Float, stt3:Float, ttt:Float;

    for (i in 0...loop) {
      sst3 = 3.0 * s * s * t;
      stt3 = 3.0 * s * t * t;
      ttt = t * t * t;

      var ft:Float = (sst3 * x1) + (stt3 * x2) + (ttt) - x;

      if (Math.abs(ft) < eps) break;

      c /= 2.0;

      t += (ft < 0) ? c : -c;
      s = 1.0 - t;
    }

    return (sst3 * y1) + (stt3 * y2) + ttt;
  }
}