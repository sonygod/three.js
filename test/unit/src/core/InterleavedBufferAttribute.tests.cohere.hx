import js.QUnit;

import js.Three.InterleavedBufferAttribute;
import js.Three.InterleavedBuffer;

class InterleavedBufferAttributeTest {
    static function main() {
        QUnit.module('Core', {
            beforeEach: function() {
                // ...
            }
        });

        QUnit.module('InterleavedBufferAttribute', function() {
            // INSTANCING
            QUnit.test('Instancing', function(assert) {
                var object = new InterleavedBufferAttribute();
                assert.ok(object, 'Can instantiate an InterleavedBufferAttribute.');
            });

            // PROPERTIES
            QUnit.todo('name', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('data', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('itemSize', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('offset', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('normalized', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.test('count', function(assert) {
                var buffer = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);
                var instance = new InterleavedBufferAttribute(buffer, 2, 0);

                assert.ok(instance.count == 2, 'count is calculated via array length / stride');
            });

            QUnit.todo('array', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('needsUpdate', function(assert) {
                // set needsUpdate( value )
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // PUBLIC
            QUnit.test('isInterleavedBufferAttribute', function(assert) {
                var object = new InterleavedBufferAttribute();
                assert.ok(
                    object.isInterleavedBufferAttribute,
                    'InterleavedBufferAttribute.isInterleavedBufferAttribute should be true'
                );
            });

            QUnit.todo('applyMatrix4', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('applyNormalMatrix', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('transformDirection', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // setY, setZ and setW are calculated in the same way so not QUnit.testing this
            // TODO: ( you can't be sure that will be the case in future, or a mistake was introduce in one off them ! )
            QUnit.test('setX', function(assert) {
                var buffer = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);
                var instance = new InterleavedBufferAttribute(buffer, 2, 0);

                instance.setX(0, 123);
                instance.setX(1, 321);

                assert.ok(
                    instance.data.array[0] == 123 && instance.data.array[3] == 321,
                    'x was calculated correct based on index and default offset'
                );

                buffer = new InterleavedBuffer(new js.Float32Array([1, 2, 3, 7, 8, 9]), 3);
                instance = new InterleavedBufferAttribute(buffer, 2, 1);

                instance.setX(0, 123);
                instance.setX(1, 321);

                // the offset was defined as 1, so go one step further in the array
                assert.ok(
                    instance.data.array[1] == 123 && instance.data.array[4] == 321,
                    'x was calculated correct based on index and default offset'
                );
            });

            QUnit.todo('setY', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('setZ', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('setW', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('getX', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('getY', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('getZ', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('getW', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('setXY', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('setXYZ', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('setXYZW', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('clone', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo('toJSON', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });
        });
    }
}

// Run the test
InterleavedBufferAttributeTest.main();