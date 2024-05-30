package three.js.test.unit.src.materials;

import three.js.src.materials.MeshMatcapMaterial;
import three.js.src.materials.Material;
import js.Lib.QUnit;

class MeshMatcapMaterialTest {

    public static function main() {

        QUnit.module('Materials', () -> {

            QUnit.module('MeshMatcapMaterial', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new MeshMatcapMaterial();

                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'MeshMatcapMaterial extends from Material'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new MeshMatcapMaterial();
                    assert.ok(object, 'Can instantiate a MeshMatcapMaterial.');

                });

                // PROPERTIES
                QUnit.test('defines', (assert) -> {

                    var actual = new MeshMatcapMaterial().defines;
                    var expected = { 'MATCAP': '' };
                    assert.deepEqual(actual, expected, 'Contains a MATCAP definition.');

                });

                QUnit.test('type', (assert) -> {

                    var object = new MeshMatcapMaterial();
                    assert.ok(
                        object.type == 'MeshMatcapMaterial',
                        'MeshMatcapMaterial.type should be MeshMatcapMaterial'
                    );

                });

                QUnit.todo('color', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('matcap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('map', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('bumpMap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('bumpScale', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('normalMap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('normalMapType', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('normalScale', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('displacementMap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('displacementScale', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('displacementBias', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('alphaMap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('flatShading', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('fog', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isMeshMatcapMaterial', (assert) -> {

                    var object = new MeshMatcapMaterial();
                    assert.ok(
                        object.isMeshMatcapMaterial,
                        'MeshMatcapMaterial.isMeshMatcapMaterial should be true'
                    );

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}