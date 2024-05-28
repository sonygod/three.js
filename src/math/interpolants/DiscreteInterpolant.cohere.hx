class DiscreteInterpolant extends Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Float) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    public function interpolate_(i1:Int):Float {
        return copySampleValue_(i1 - 1);
    }
}