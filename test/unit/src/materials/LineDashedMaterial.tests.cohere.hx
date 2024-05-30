import js.QUnit;
import js.threed.materials.LineDashedMaterial;
import js.threed.materials.Material;

class _Main {
    static function main() {
        QUnit.module('Materials', function () {
            QUnit.module('LineDashedMaterial', function () {
                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new LineDashedMaterial();
                    assert.strictEqual(
                        Std.is(object, Material),
                        true,
                        'LineDashedMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new LineDashedMaterial();
                    assert.ok(object, 'Can instantiate a LineDashedMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new LineDashedMaterial();
                    assert.ok(
                        object.type == 'LineDashedMaterial',
                        'LineDashedMaterial.type should be LineDashedMaterial'
                    );
                });

                QUnit.todo('scale', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('dashSize', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('gapSize', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isLineDashedMaterial', function (assert) {
                    var object = new LineDashedMaterial();
                    assert.ok(
                        object.isLineDashedMaterial,
                        'LineDashedMaterial.isLineDashedMaterial should be true'
                    );
                });

                QUnit.todo('copy', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}