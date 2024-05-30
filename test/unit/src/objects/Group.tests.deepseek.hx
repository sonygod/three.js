package three.js.test.unit.src.objects;

import three.js.src.objects.Group;
import three.js.src.core.Object3D;
import js.Lib.QUnit;

class GroupTests {

    public static function main() {

        QUnit.module('Objects', () -> {

            QUnit.module('Group', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var group = new Group();
                    assert.strictEqual(
                        Std.is(group, Object3D), true,
                        'Group extends from Object3D'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new Group();
                    assert.ok(object, 'Can instantiate a Group.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new Group();
                    assert.ok(
                        object.type == 'Group',
                        'Group.type should be Group'
                    );

                });

                // PUBLIC
                QUnit.test('isGroup', (assert) -> {

                    var object = new Group();
                    assert.ok(
                        object.isGroup,
                        'Group.isGroup should be true'
                    );

                });

            });

        });

    }

}