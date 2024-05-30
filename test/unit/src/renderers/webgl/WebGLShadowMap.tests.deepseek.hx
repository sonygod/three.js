// 注意：Haxe没有内置的QUnit库，所以你需要自己实现或者使用其他的测试库。

// import three.js.test.unit.src.renderers.webgl.WebGLShadowMap;

class WebGLShadowMapTests {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL', () -> {

                QUnit.module('WebGLShadowMap', () -> {

                    // INSTANCING
                    QUnit.todo('Instancing', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC STUFF
                    QUnit.todo('render', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}