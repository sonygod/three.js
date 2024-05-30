package three.js.test.unit.src.renderers;

import js.Lib;
import js.QUnit;
import three.js.src.renderers.WebGL3DRenderTarget;
import three.js.src.renderers.WebGLRenderTarget;

class WebGL3DRenderTargetTests {

    static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGL3DRenderTarget', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new WebGL3DRenderTarget();
                    assert.strictEqual(
                        Std.is(object, WebGLRenderTarget), true,
                        'WebGL3DRenderTarget extends from WebGLRenderTarget'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new WebGL3DRenderTarget();
                    assert.ok(object, 'Can instantiate a WebGL3DRenderTarget.');

                });

                // PROPERTIES
                QUnit.todo('depth', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('texture', (assert) -> {

                    // must be Data3DTexture
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('isWebGL3DRenderTarget', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}