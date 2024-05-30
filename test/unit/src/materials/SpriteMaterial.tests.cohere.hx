import js.QUnit;

import SpriteMaterial from '../../../../../src/materials/SpriteMaterial.hx';
import Material from '../../../../../src/materials/Material.hx';

class _Main {
    static function main() {
        QUnit.module('Materials', () -> {
            QUnit.module('SpriteMaterial', () -> {
                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new SpriteMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'SpriteMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new SpriteMaterial();
                    assert.ok(object, 'Can instantiate a SpriteMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new SpriteMaterial();
                    assert.ok(
                        object.type == 'SpriteMaterial',
                        'SpriteMaterial.type should be SpriteMaterial'
                    );
                });

                QUnit.todo('color', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('map', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('alphaMap', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('rotation', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sizeAttenuation', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('transparent', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('fog', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isSpriteMaterial', function (assert) {
                    var object = new SpriteMaterial();
                    assert.ok(
                        object.isSpriteMaterial,
                        'SpriteMaterial.isSpriteMaterial should be true'
                    );
                });

                QUnit.todo('copy', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}