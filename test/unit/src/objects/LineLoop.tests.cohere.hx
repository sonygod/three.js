import js.QUnit;
import js.Object3D;
import js.Line;
import js.LineLoop;

class _Main {
    static function main() {
        QUnit.module('Objects', function() {
            QUnit.module('LineLoop', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var lineLoop = new LineLoop();
                    assert.strictEqual(lineLoop instanceof Object3D, true, 'LineLoop extends from Object3D');
                    assert.strictEqual(lineLoop instanceof Line, true, 'LineLoop extends from Line');
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new LineLoop();
                    assert.ok(object, 'Can instantiate a LineLoop.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new LineLoop();
                    assert.strictEqual(object.type, 'LineLoop', 'LineLoop.type should be LineLoop');
                });

                // PUBLIC
                QUnit.test('isLineLoop', function(assert) {
                    var object = new LineLoop();
                    assert.ok(object.isLineLoop, 'LineLoop.isLineLoop should be true');
                });
            });
        });
    }
}