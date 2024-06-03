import interpolant.Interpolant;

/**
 *
 * Interpolant that evaluates to the sample value at the position preceding
 * the parameter.
 */

class DiscreteInterpolant extends Interpolant {

	public function new(parameterPositions:Array<Float>, sampleValues:Array<Dynamic>, sampleSize:Int, resultBuffer:Array<Dynamic>) {
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	override function interpolate_(i1:Int /*, t0, t, t1 */):Void {
		this.copySampleValue_(i1 - 1);
	}

}

class DiscreteInterpolant {
	public static var Interpolant = DiscreteInterpolant;
}