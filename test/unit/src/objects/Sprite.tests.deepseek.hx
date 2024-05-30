package three.js.test.unit.src.objects;

import three.js.src.core.Object3D;
import three.js.src.objects.Sprite;
import js.QUnit;

class SpriteTests {

    public static function main() {
        QUnit.module('Objects', () -> {
            QUnit.module('Sprite', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var sprite = new Sprite();
                    assert.strictEqual(
                        Std.is(sprite, Object3D), true,
                        'Sprite extends from Object3D'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new Sprite();
                    assert.ok(object, 'Can instantiate a Sprite.');
                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {
                    var object = new Sprite();
                    assert.ok(
                        object.type == 'Sprite',
                        'Sprite.type should be Sprite'
                    );
                });

                QUnit.todo('geometry', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('material', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('center', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isSprite', (assert) -> {
                    var object = new Sprite();
                    assert.ok(
                        object.isSprite,
                        'Sprite.isSprite should be true'
                    );
                });

                QUnit.todo('raycast', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('copy', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}