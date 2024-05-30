import js.QUnit;

import js.THREE.Object3D;
import js.THREE.Sprite;

class SpriteTest {
    static function main() {
        QUnit.module('Objects', {
            setup: function() {}, teardown: function() {}
        });

        QUnit.module('Sprite', {
            setup: function() {}, teardown: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var sprite = new Sprite();
            assert.strictEqual(
                sprite instanceof Object3D, true,
                'Sprite extends from Object3D'
            );
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new Sprite();
            assert.ok(object, 'Can instantiate a Sprite.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
            var object = new Sprite();
            assert.strictEqual(
                object.type, 'Sprite',
                'Sprite.type should be Sprite'
            );
        });

        QUnit.test('geometry', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('material', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('center', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isSprite', function(assert) {
            var object = new Sprite();
            assert.ok(
                object.isSprite,
                'Sprite.isSprite should be true'
            );
        });

        QUnit.test('raycast', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('copy', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}