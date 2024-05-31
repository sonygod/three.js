package three.math.interpolants;

import three.math.Interpolant;

/**
 * Interpolant that evaluates to the sample value at the position preceding
 * the parameter.
 */
class DiscreteInterpolant extends Interpolant {

    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, ?resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    public function interpolate_(i1:Int /*, t0:Float, t:Float, t1:Float */):Array<Float> {
        return this.copySampleValue_(i1 - 1);
    }
}