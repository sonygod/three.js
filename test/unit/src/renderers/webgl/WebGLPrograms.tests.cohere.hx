package;

import js.QUnit;

class WebGLProgramsTest {
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
            QUnit.module('WebGLPrograms', function() {
                // INSTANCING
                QUnit.todo('Instancing', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC STUFF
                QUnit.todo('getParameters', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getProgramCode', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('acquireProgram', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('releaseProgram', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('programs', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}