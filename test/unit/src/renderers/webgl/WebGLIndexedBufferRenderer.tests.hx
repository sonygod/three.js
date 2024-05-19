package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;

class WebGLIndexedBufferRendererTests {

    public static function addTests(runner:Runner) {
        runner.describe("Renderers", () => {
            runner.describe("WebGL", () => {
                runner.describe("WebGLIndexedBufferRenderer", () => {
                    // INSTANCING
                    runner.it("Instancing", () => {
                        throw "Not implemented";
                    });

                    // PUBLIC STUFF
                    runner.it("setMode", () => {
                        throw "Not implemented";
                    });

                    runner.it("setIndex", () => {
                        throw "Not implemented";
                    });

                    runner.it("render", () => {
                        throw "Not implemented";
                    });

                    runner.it("renderInstances", () => {
                        throw "Not implemented";
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