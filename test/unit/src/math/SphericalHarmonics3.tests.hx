package three.math;

import haxe.unit.TestCase;
import three.math.SphericalHarmonics3;

class SphericalHarmonics3Tests {
    public function new() {}

    public function testInstancing() {
        var object = new SphericalHarmonics3();
        TestCase.assertNotNull(object, 'Can instantiate a SphericalHarmonics3.');
    }

    public function testIsSphericalHarmonics3() {
        var object = new SphericalHarmonics3();
        TestCase.assertTrue(object.isSphericalHarmonics3, 'SphericalHarmonics3.isSphericalHarmonics3 should be true');
    }

    public function todo_coefficients() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_set() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_zero() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_getAt() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_getIrradianceAt() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_add() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_addScaledSH() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_scale() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_lerp() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_equals() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_copy() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_clone() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoFromArray() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_toArray() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todo_getBasisAt() {
        TestCase.fail('everything\'s gonna be alright');
    }
}