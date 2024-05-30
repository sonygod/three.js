package;

import js.QUnit;

class WebGLTexturesTest {
    public static function main() {
        QUnit.module('Renderers', {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module('WebGL', function() {
            QUnit.module('WebGLTextures', function() {
                // INSTANCING
                QUnit.todo('Instancing', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC STUFF
                QUnit.todo('setTexture2D', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('setTextureCube', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('setTextureCubeDynamic', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('setupRenderTarget', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('updateRenderTargetMipmap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}