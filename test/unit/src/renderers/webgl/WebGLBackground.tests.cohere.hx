package;

import js.QUnit;

class WebGLBackgroundTest {
    static function main() {
        QUnit.module('Renderers', function() {
            QUnit.module('WebGL', function() {
                QUnit.module('WebGLBackground', function() {
                    // INSTANCING
                    QUnit.todo('Instancing', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC STUFF
                    QUnit.todo('getClearColor', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('setClearColor', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getClearAlpha', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('setClearAlpha', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('render', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}