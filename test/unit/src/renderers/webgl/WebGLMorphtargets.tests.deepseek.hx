// 注意：Haxe没有内置的QUnit库，所以你需要自己实现或者使用其他的测试库。

// import three.js.test.unit.src.renderers.webgl.WebGLMorphtargets;

class WebGLMorphtargetsTest {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL', () -> {

                QUnit.module('WebGLMorphtargets', () -> {

                    // INSTANCING
                    QUnit.todo('Instancing', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC STUFF
                    QUnit.todo('update', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}