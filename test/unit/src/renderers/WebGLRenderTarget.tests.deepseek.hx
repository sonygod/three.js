package;

import js.Lib;
import js.Browser.window;

class WebGLRenderTargetTest {

    static function main() {
        var QUnit = Lib.require('qunit');

        QUnit.module('Renderers', function() {

            QUnit.module('WebGLRenderTarget', function() {

                // INHERITANCE
                QUnit.test('Extending', function(assert) {

                    var object = new WebGLRenderTarget();
                    assert.strictEqual(
                        object instanceof EventDispatcher, true,
                        'WebGLRenderTarget extends from EventDispatcher'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {

                    var object = new WebGLRenderTarget();
                    assert.ok(object, 'Can instantiate a WebGLRenderTarget.');

                });

                // PROPERTIES
                QUnit.todo('width', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('height', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('depth', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('scissor', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('scissorTest', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('viewport', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('texture', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('depthBuffer', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('stencilBuffer', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('depthTexture', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('samples', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('textures', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('isWebGLRenderTarget', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('setSize', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('clone', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('copy', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', function(assert) {

                    assert.expect(0);

                    var object = new WebGLRenderTarget();
                    object.dispose();

                });

            });

        });

    }

}