import js.QUnit;

import js.ShadowMaterial;
import js.Material;

class _Main {
    static function main() {
        QUnit.module('Materials', function() {
            QUnit.module('ShadowMaterial', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new ShadowMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'ShadowMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new ShadowMaterial();
                    assert.ok(object, 'Can instantiate a ShadowMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new ShadowMaterial();
                    assert.ok(
                        object.type == 'ShadowMaterial',
                        'ShadowMaterial.type should be ShadowMaterial'
                    );
                });

                QUnit.todo('color', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('transparent', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('fog', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isShadowMaterial', function(assert) {
                    var object = new ShadowMaterial();
                    assert.ok(
                        object.isShadowMaterial,
                        'ShadowMaterial.isShadowMaterial should be true'
                    );
                });

                QUnit.todo('copy', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}