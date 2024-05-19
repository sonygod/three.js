package three.math.interpolants;

import haxe.unit.TestCase;

class QuaternionLinearInterpolantTests {

    public function new() { }

    @Test
    public function testExtending() {
        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertTrue(object instanceof Interpolant, 'QuaternionLinearInterpolant extends from Interpolant');
    }

    @Test
    public function testInstancing() {
        // parameterPositions, sampleValues, sampleSize, resultBuffer
        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertNotNull(object, 'Can instantiate a QuaternionLinearInterpolant.');
    }

    @Test
    public function testInterpolate_() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }
}