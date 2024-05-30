import js.QUnit;
import js.three.materials.LineBasicMaterial;
import js.three.materials.Material;

class _Main {
    static function main() {
        QUnit.module('Materials', function () {
            QUnit.module('LineBasicMaterial', function () {
                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new LineBasicMaterial();
                    assert.strictEqual(
                        Std.is(object, Material),
                        true,
                        'LineBasicMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new LineBasicMaterial();
                    assert.ok(object, 'Can instantiate a LineBasicMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new LineBasicMaterial();
                    assert.ok(
                        object.type == 'LineBasicMaterial',
                        'LineBasicMaterial.type should be LineBasicMaterial'
                    );
                });

                QUnit.todo('color', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('linewidth', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('linecap', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('linejoin', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('fog', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isLineBasicMaterial', function (assert) {
                    var object = new LineBasicMaterial();
                    assert.ok(
                        object.isLineBasicMaterial,
                        'LineBasicMaterial.isLineBasicMaterial should be true'
                    );
                });

                QUnit.todo('copy', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}