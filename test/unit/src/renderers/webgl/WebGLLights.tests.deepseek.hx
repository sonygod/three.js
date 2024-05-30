// 导入QUnit模块
import js.Lib.QUnit;

// 导入WebGLLights模块
// import three.js.src.renderers.webgl.WebGLLights;

class TestWebGLLights {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL', () -> {

                QUnit.module('WebGLLights', () -> {

                    // INSTANCING
                    QUnit.todo('Instancing', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC STUFF
                    QUnit.todo('setup', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('state', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}