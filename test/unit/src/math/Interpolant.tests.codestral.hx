import three.math.Interpolant;

class Mock extends Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Dynamic>, sampleSize:Int, resultBuffer:Array<Dynamic>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override public function intervalChanged(i1:Int, t0:Float, t1:Float) {
        super.intervalChanged(i1, t0, t1);
    }

    override public function interpolate(i1:Int, t0:Float, t:Float, t1:Float):Array<Dynamic> {
        return this.copySampleValue(i1 - 1);
    }
}

class InterpolantTests {
    public static function main() {
        // Instancing
        var interpolant = new Mock(null, [1, 11, 2, 22, 3, 33], 2, []);
        // TODO: Assertion for instance checking

        // copySampleValue_
        var result = interpolant.copySampleValue(0);
        // TODO: Assertion for result

        // evaluate -> intervalChanged_ / interpolate_
        // TODO: Setup and assertions for this test
    }
}