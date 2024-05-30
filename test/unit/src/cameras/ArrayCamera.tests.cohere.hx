import js.QUnit;

import js.cameras.ArrayCamera;
import js.cameras.PerspectiveCamera;

class _Main {
    static function main() {
        QUnit.module('Cameras', function() {
            QUnit.module('ArrayCamera', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new ArrayCamera();
                    assert.strictEqual(
                        Std.is(object, PerspectiveCamera), true,
                        'ArrayCamera extends from PerspectiveCamera'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new ArrayCamera();
                    assert.ok(object, 'Can instantiate an ArrayCamera.');
                });

                // PROPERTIES
                QUnit.todo('cameras', function(assert) {
                    // array
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isArrayCamera', function(assert) {
                    var object = new ArrayCamera();
                    assert.ok(
                        object.isArrayCamera,
                        'ArrayCamera.isArrayCamera should be true'
                    );
                });
            });
        });
    }
}