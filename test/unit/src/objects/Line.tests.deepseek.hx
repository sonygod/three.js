package;

import three.js.test.unit.src.objects.Line;
import three.js.test.unit.src.core.Object3D;
import three.js.test.unit.src.materials.Material;

class LineTests {

    static function main() {

        QUnit.module('Objects', () -> {

            QUnit.module('Line', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var line = new Line();
                    assert.strictEqual(
                        Std.is(line, Object3D), true,
                        'Line extends from Object3D'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new Line();
                    assert.ok(object, 'Can instantiate a Line.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new Line();
                    assert.ok(
                        object.type == 'Line',
                        'Line.type should be Line'
                    );

                });

                QUnit.todo('geometry', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('material', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isLine', (assert) -> {

                    var object = new Line();
                    assert.ok(
                        object.isLine,
                        'Line.isLine should be true'
                    );

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('copy/material', (assert) -> {

                    // Material arrays are cloned
                    var mesh1 = new Line();
                    mesh1.material = [new Material()];

                    var copy1 = mesh1.clone();
                    assert.notStrictEqual(mesh1.material, copy1.material);

                    // Non arrays are not cloned
                    var mesh2 = new Line();
                    mesh1.material = new Material();
                    var copy2 = mesh2.clone();
                    assert.strictEqual(mesh2.material, copy2.material);

                });

                QUnit.todo('computeLineDistances', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('raycast', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('updateMorphTargets', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('clone', (assert) -> {

                    // inherited from Object3D, test instance specific behaviour.
                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}