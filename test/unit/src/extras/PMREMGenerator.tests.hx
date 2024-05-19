package three.test.unit.src.extras;

import haxe.unit.TestCase;
import three.extras.PMREMGenerator;

class PMREMGeneratorTests {

    public function new() {}

    public function testAll() {
        // INSTANCING
        testCase("Instancing", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        testCase("fromScene", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });

        testCase("fromEquirectangular", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });

        testCase("fromCubemap", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });

        testCase("compileCubemapShader", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });

        testCase("compileEquirectangularShader", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });

        testCase("dispose", function(assert:TestCase) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}