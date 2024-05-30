// 导入QUnit模块
import js.Lib.QUnit;

// 导入WebGLUniforms类
// import three.js.src.renderers.webgl.WebGLUniforms;

class WebGLUniformsTest {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL', () -> {

                QUnit.module('WebGLUniforms', () -> {

                    // INSTANCING
                    QUnit.todo('Instancing', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC STUFF
                    QUnit.todo('setValue', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('setOptional', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('upload', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('seqWithValue', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}