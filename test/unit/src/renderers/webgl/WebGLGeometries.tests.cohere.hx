package;

import js.QUnit;

class WebGLGeometriesTest {
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
            QUnit.module('WebGLGeometries', function() {
                // INSTANCING
                QUnit.todo('Instancing', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC STUFF
                QUnit.todo('get', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('update', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getWireframeAttribute', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}