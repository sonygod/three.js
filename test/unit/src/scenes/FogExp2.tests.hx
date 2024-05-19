import haxe.unit.TestCase;
import three-scenes.FogExp2;

class FogExp2Tests {
    public static function main() {
        var testCase = new TestCase();

        testCase.test("Instancing", function(assert) {
            // no params
            var object = new FogExp2();
            assert.isTrue(object != null, 'Can instantiate a FogExp2.');

            // color
            var object_color = new FogExp2(0xFFFFFF);
            assert.isTrue(object_color != null, 'Can instantiate a FogExp2 with color.');

            // color, density
            var object_all = new FogExp2(0xFFFFFF, 0.00030);
            assert.isTrue(object_all != null, 'Can instantiate a FogExp2 with color, density.');
        });

        testCase.test("name", function(assert) {
            assert.fail("not implemented");
        });

        testCase.test("color", function(assert) {
            assert.fail("not implemented");
        });

        testCase.test("density", function(assert) {
            assert.fail("not implemented");
        });

        testCase.test("isFogExp2", function(assert) {
            var object = new FogExp2();
            assert.isTrue(object.isFogExp2, 'FogExp2.isFogExp2 should be true');
        });

        testCase.test("clone", function(assert) {
            assert.fail("not implemented");
        });

        testCase.test("toJSON", function(assert) {
            assert.fail("not implemented");
        });
    }
}