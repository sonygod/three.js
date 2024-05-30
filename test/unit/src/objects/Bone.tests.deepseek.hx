package;

import js.Lib;
import three.js.test.unit.src.objects.Bone;
import three.js.test.unit.src.core.Object3D;

class BoneTests {

    static function main() {
        QUnit.module('Objects', () -> {
            QUnit.module('Bone', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var bone = new Bone();
                    assert.strictEqual(
                        Std.is(bone, Object3D), true,
                        'Bone extends from Object3D'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new Bone();
                    assert.ok(object, 'Can instantiate a Bone.');
                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {
                    var object = new Bone();
                    assert.ok(
                        object.type == 'Bone',
                        'Bone.type should be Bone'
                    );
                });

                // PUBLIC
                QUnit.test('isBone', (assert) -> {
                    var object = new Bone();
                    assert.ok(
                        object.isBone,
                        'Bone.isBone should be true'
                    );
                });
            });
        });
    }
}