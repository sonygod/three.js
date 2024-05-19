package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;
import utest.Assert;

class WebGLShaderTests {
    public static function addTests(runner:Runner) {
        runner.describe("Renderers", () => {
            runner.describe("WebGL", () => {
                runner.describe("WebGLShader", () => {
                    runner.test("Instancing", () => {
                        Assert.isTrue(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }

    public static function main() {
        var runner = new Runner();
        addTests(runner);
        Report.create(runner);
        runner.run();
    }
}