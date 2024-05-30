import haxe.unit.TestCase;
import Interpolant;

class InterpolantTest extends TestCase {

    override public function setup() {
        // Initialize Mock.calls to null
        Mock.calls = null;
    }

    public function testInstancing() {
        var interpolant = new Mock(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertTrue(interpolant instanceof Interpolant, 'Mock extends from Interpolant');
    }

    // PROPERTIES
    public function todoParameterPositions() {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoResultBuffer() {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoSampleValues() {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoValueSize() {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoSettings() {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    // PUBLIC
    public function todoEvaluate() {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    // PRIVATE
    public function testCopySampleValue() {
        var interpolant = new Mock(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertEquals(interpolant.copySampleValue_(0), [1, 11], 'sample fetch (0)');
        assertEquals(interpolant.copySampleValue_(1), [2, 22], 'sample fetch (1)');
        assertEquals(interpolant.copySampleValue_(2), [3, 33], 'first sample (2)');
    }

    public function testEvaluateIntervalChangedInterpolate() {
        var interpolant = new Mock([11, 22, 33, 44, 55, 66, 77, 88, 99], null, 0, null);
        Mock.calls = [];

        interpolant.evaluate(11);
        var actual = Mock.calls[0];
        assertEquals(actual, {func: 'intervalChanged', args: [1, 11, 22]});
        actual = Mock.calls[1];
        assertEquals(actual, {func: 'interpolate', args: [1, 11, 11, 22]});
        assertTrue(Mock.calls.length == 2);

        // ... and so on, implement the rest of the tests ...
    }
}

class Mock extends Interpolant {
    public static var calls:Array<Dynamic>;

    override public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    override public function intervalChanged_(i1:Int, t0:Float, t1:Float) {
        if (Mock.calls != null) {
            Mock.calls.push({func: 'intervalChanged', args: [i1, t0, t1]});
        }
    }

    override public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float) {
        if (Mock.calls != null) {
            Mock.calls.push({func: 'interpolate', args: [i1, t0, t, t1]});
        }
        return copySampleValue_(i1 - 1);
    }
}