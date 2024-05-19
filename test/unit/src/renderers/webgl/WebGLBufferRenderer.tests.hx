package three.js.test.unit.src.renderers.webgl;

import utest Runner;
import utest.ITest;

class WebGLBufferRendererTests {
  public function new() {}

  public static function main() {
    var runner = new Runner();
    runner.describe('Renderers', () -> {
      runner.describe('WebGL', () -> {
        runner.describe('WebGLBufferRenderer', () -> {
          // INSTANCING
          runner.it('Instancing', () -> {
            Assert.isTrue(false, 'everything\'s gonna be alright');
          });

          // PUBLIC STUFF
          runner.it('setMode', () -> {
            Assert.isTrue(false, 'everything\'s gonna be alright');
          });

          runner.it('render', () -> {
            Assert.isTrue(false, 'everything\'s gonna be alright');
          });

          runner.it('renderInstances', () -> {
            Assert.isTrue(false, 'everything\'s gonna be alright');
          });
        });
      });
    });
    runner.run();
  }
}