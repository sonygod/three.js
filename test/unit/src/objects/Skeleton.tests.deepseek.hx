package three.js.test.unit.src.objects;

import js.Lib.QUnit;
import three.js.src.objects.Skeleton;

class SkeletonTests {

    public static function main() {

        QUnit.module('Objects', () -> {

            QUnit.module('Skeleton', () -> {

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new Skeleton();
                    assert.ok(object, 'Can instantiate a Skeleton.');

                });

                // PROPERTIES
                QUnit.todo('uuid', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('bones', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('boneInverses', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('boneMatrices', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('boneTexture', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('frame', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('init', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('calculateInverses', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('pose', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('update', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('clone', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('computeBoneTexture', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('getBoneByName', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new Skeleton();
                    object.dispose();

                });

                QUnit.todo('fromJSON', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('toJSON', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}