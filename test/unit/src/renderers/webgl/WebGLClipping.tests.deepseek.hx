// 导入QUnit模块
import js.Lib.QUnit;

// 导入WebGLClipping模块
// import three.js.src.renderers.webgl.WebGLClipping;

class TestWebGLClipping {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL', () -> {

                QUnit.module('WebGLClipping', () -> {

                    // INSTANCING
                    QUnit.todo('Instancing', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC STUFF
                    QUnit.todo('init', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('beginShadows', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('endShadows', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('setState', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}