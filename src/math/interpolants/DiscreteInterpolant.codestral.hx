import Interpolant;

class DiscreteInterpolant extends Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override public function interpolate_(i1:Int):Array<Float> {
        return this.copySampleValue_(i1 - 1);
    }
}