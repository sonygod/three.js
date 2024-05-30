package three.js.test.unit.src.renderers;

import js.Lib.QUnit;
import three.js.src.renderers.WebGLArrayRenderTarget;
import three.js.src.renderers.WebGLRenderTarget;

class WebGLArrayRenderTargetTests {

    public static function main() {

        QUnit.module('Renderers', () -> {

            QUnit.module('WebGLArrayRenderTarget', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new WebGLArrayRenderTarget();
                    assert.strictEqual(
                        Std.instanceof(object, WebGLRenderTarget), true,
                        'WebGLArrayRenderTarget extends from WebGLRenderTarget'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new WebGLArrayRenderTarget();
                    assert.ok(object, 'Can instantiate a WebGLArrayRenderTarget.');

                });

                // PROPERTIES
                QUnit.todo('depth', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('texture', (assert) -> {

                    // must be DataArrayTexture
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('isWebGLArrayRenderTarget', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}