// 导入QUnit模块
import js.Lib.QUnit;

// 导入WebGLProgram类
// import three.js.src.renderers.webgl.WebGLProgram;

class WebGLProgramTest {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL', () -> {

                QUnit.module('WebGLProgram', () -> {

                    // INSTANCING
                    QUnit.todo('Instancing', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PROPERTIES
                    QUnit.todo('uniforms', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('attributes', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC STUFF
                    QUnit.todo('getUniforms', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('getAttributes', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('destroy', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}