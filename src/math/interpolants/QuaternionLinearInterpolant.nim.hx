import Interpolant.Interpolant;
import Quaternion.Quaternion;

/**
 * Spherical linear unit quaternion interpolant.
 */
class QuaternionLinearInterpolant extends Interpolant {

  public function new(parameterPositions:Array<Dynamic>, sampleValues:Array<Dynamic>, sampleSize:Int, resultBuffer:Array<Dynamic>) {

    super(parameterPositions, sampleValues, sampleSize, resultBuffer);

  }

  public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Dynamic> {

    var result = this.resultBuffer;
    var values = this.sampleValues;
    var stride = this.valueSize;

    var alpha = (t - t0) / (t1 - t0);

    var offset = i1 * stride;

    for (end in offset..offset + stride) {

      Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);

    }

    return result;

  }

}

export class Main {
  static function main() {
    // Your code here
  }
}