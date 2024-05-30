package three.js.test.unit.src.core;

import three.js.src.core.UniformsGroup;
import three.js.src.core.EventDispatcher;
import js.QUnit;

class UniformsGroupTests {

    public static function main() {

        QUnit.module('Core', () -> {

            QUnit.module('UniformsGroup', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new UniformsGroup();
                    assert.strictEqual(
                        Std.is(object, EventDispatcher), true,
                        'UniformsGroup extends from EventDispatcher'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new UniformsGroup();
                    assert.ok(object, 'Can instantiate a UniformsGroup.');

                });

                // PROPERTIES
                QUnit.todo('id', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('name', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('usage', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('uniforms', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isUniformsGroup', (assert) -> {

                    var object = new UniformsGroup();
                    assert.ok(
                        object.isUniformsGroup,
                        'UniformsGroup.isUniformsGroup should be true'
                    );

                });

                QUnit.todo('add', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('remove', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('setName', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('setUsage', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new UniformsGroup();
                    object.dispose();

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('clone', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}