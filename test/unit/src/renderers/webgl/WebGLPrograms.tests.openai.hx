package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;
import utest.TestCase;

class WebGLProgramsTest {

    public function new() {}

    public static function addTests(runner:Runner) {
        var testCase = new WebGLProgramsTest();

        runner.addCase(testCase, WebGLProgramsTestcases);
    }

    static function WebGLProgramsTestcases(testCase:TestCase) {
        testCase.describe("Renderers", {
            tearDown: null
        }, function() {
            testCase.describe("WebGL", {
                tearDown: null
            }, function() {
                testCase.describe("WebGLPrograms", {
                    tearDown: null
                }, function() {
                    // INSTANCING
                    testCase.test("Instancing", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    testCase.test("getParameters", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    testCase.test("getProgramCode", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    testCase.test("acquireProgram", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    testCase.test("releaseProgram", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    testCase.test("programs", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}