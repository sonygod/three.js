import js.QUnit;

import js.Object3D;

import js.Bone;

class Test {
    static public function main() {
        QUnit.module('Objects', {
            beforeEach: function() {
                trace('beforeEach');
            },
            afterEach: function() {
                trace('afterEach');
            }
        });

        QUnit.module('Bone', function() {
            QUnit.test('Extending', function(assert) {
                var bone = new Bone();
                assert.strictEqual(bone instanceof Object3D, true, 'Bone extends from Object3D');
            });

            QUnit.test('Instancing', function(assert) {
                var object = new Bone();
                assert.ok(object, 'Can instantiate a Bone.');
            });

            QUnit.test('type', function(assert) {
                var object = new Bone();
                assert.strictEqual(object.getType(), 'Bone', 'Bone.type should be Bone');
            });

            QUnit.test('isBone', function(assert) {
                var object = new Bone();
                assert.ok(object.isBone, 'Bone.isBone should be true');
            });
        });
    }
}