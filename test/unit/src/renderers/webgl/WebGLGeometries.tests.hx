import utest.Runner;
import utest.ui.Report;

class WebGLGeometriesTests {
    public static function addTests(runner:Runner) {
        runner.describe('Renderers', () => {
            runner.describe('WebGL', () => {
                runner.describe('WebGLGeometries', () => {
                    // INSTANCING
                    runner.test('Instancing', () => {
                        assert(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC STUFF
                    runner.test('get', () => {
                        assert(false, 'everything\'s gonna be alright');
                    });

                    runner.test('update', () => {
                        assert(false, 'everything\'s gonna be alright');
                    });

                    runner.test('getWireframeAttribute', () => {
                        assert(false, 'everything\'s gonna be alright');
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