package;

import js.QUnit;
import js.threelabs.materials.MeshDepthMaterial;
import js.threelabs.materials.Material;

class _Main {
    static function main() {
        QUnit.module('Materials', function () {
            QUnit.module('MeshDepthMaterial', function () {
                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new MeshDepthMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'MeshDepthMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new MeshDepthMaterial();
                    assert.ok(object, 'Can instantiate a MeshDepthMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new MeshDepthMaterial();
                    assert.ok(
                        object.type == 'MeshDepthMaterial',
                        'MeshDepthMaterial.type should be MeshDepthMaterial'
                    );
                });

                QUnit.todo('depthPacking', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('map', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('alphaMap', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('displacementMap', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('displacementScale', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('displacementBias', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wireframe', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wireframeLinewidth', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isMeshDepthMaterial', function (assert) {
                    var object = new MeshDepthMaterial();
                    assert.ok(
                        object.isMeshDepthMaterial,
                        'MeshDepthMaterial.isMeshDepthMaterial should be true'
                    );
                });

                QUnit.todo('copy', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}