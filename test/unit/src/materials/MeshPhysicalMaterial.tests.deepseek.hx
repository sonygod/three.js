package three.test.unit.src.materials;

import three.src.materials.MeshPhysicalMaterial;
import three.src.materials.Material;
import js.Lib;

class MeshPhysicalMaterialTest {
    static function main() {
        QUnit.module('Materials', () -> {
            QUnit.module('MeshPhysicalMaterial', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new MeshPhysicalMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'MeshPhysicalMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new MeshPhysicalMaterial();
                    assert.ok(object, 'Can instantiate a MeshPhysicalMaterial.');
                });

                // PROPERTIES
                QUnit.todo('defines', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('type', (assert) -> {
                    var object = new MeshPhysicalMaterial();
                    assert.ok(
                        object.type == 'MeshPhysicalMaterial',
                        'MeshPhysicalMaterial.type should be MeshPhysicalMaterial'
                    );
                });

                QUnit.todo('clearcoatMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('clearcoatRoughness', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('clearcoatRoughnessMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('clearcoatNormalScale', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('clearcoatNormalMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('ior', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('reflectivity', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('iridescenceMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('iridescenceIOR', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('iridescenceThicknessRange', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('iridescenceThicknessMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sheenColor', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sheenColorMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sheenRoughness', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sheenRoughnessMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('transmissionMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('thickness', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('thicknessMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('attenuationDistance', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('attenuationColor', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('specularIntensity', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('specularIntensityMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('specularColor', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('specularColorMap', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sheen', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('clearcoat', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('iridescence', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('transmission', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isMeshPhysicalMaterial', (assert) -> {
                    var object = new MeshPhysicalMaterial();
                    assert.ok(
                        object.isMeshPhysicalMaterial,
                        'MeshPhysicalMaterial.isMeshPhysicalMaterial should be true'
                    );
                });

                QUnit.todo('copy', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }

    static public function todo(name:String, callback:QUnit.TestCallback) {
        QUnit.test(name, (assert) -> {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}