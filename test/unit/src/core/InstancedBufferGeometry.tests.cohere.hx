import js.QUnit;
import js.core.InstancedBufferGeometry;
import js.core.BufferGeometry;
import js.core.BufferAttribute;

class TestInstancedBufferGeometry {
    static function main() {
        QUnit.module('Core', function () {
            QUnit.module('InstancedBufferGeometry', function () {
                function createClonableMock() {
                    var mock = { callCount: 0 };
                    mock.clone = function () {
                        mock.callCount++;
                        return mock;
                    };
                    return mock;
                }

                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new InstancedBufferGeometry();
                    assert.strictEqual(object instanceof BufferGeometry, true, 'InstancedBufferGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new InstancedBufferGeometry();
                    assert.ok(object, 'Can instantiate an InstancedBufferGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new InstancedBufferGeometry();
                    assert.ok(object.type == 'InstancedBufferGeometry', 'InstancedBufferGeometry.type should be InstancedBufferGeometry');
                });

                QUnit.todo('instanceCount', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isInstancedBufferGeometry', function (assert) {
                    var object = new InstancedBufferGeometry();
                    assert.ok(object.isInstancedBufferGeometry, 'InstancedBufferGeometry.isInstancedBufferGeometry should be true');
                });

                QUnit.test('copy', function (assert) {
                    var instanceMock1 = {};
                    var instanceMock2 = {};
                    var indexMock = createClonableMock();
                    var defaultAttribute1 = new BufferAttribute(new Float32Array([1]));
                    var defaultAttribute2 = new BufferAttribute(new Float32Array([2]));

                    var instance = new InstancedBufferGeometry();
                    instance.addGroup(0, 10, instanceMock1);
                    instance.addGroup(10, 5, instanceMock2);
                    instance.setIndex(indexMock);
                    instance.setAttribute('defaultAttribute1', defaultAttribute1);
                    instance.setAttribute('defaultAttribute2', defaultAttribute2);

                    var copiedInstance = new InstancedBufferGeometry().copy(instance);

                    assert.ok(copiedInstance instanceof InstancedBufferGeometry, 'the clone has the correct type');
                    assert.equal(copiedInstance.index, indexMock, 'index was copied');
                    assert.equal(copiedInstance.index.callCount, 1, 'index.clone was called once');
                    assert.ok(copiedInstance.attributes['defaultAttribute1'] instanceof BufferAttribute, 'attribute was created');
                    assert.deepEqual(copiedInstance.attributes['defaultAttribute1'].array, defaultAttribute1.array, 'attribute was copied');
                    assert.deepEqual(copiedInstance.attributes['defaultAttribute2'].array, defaultAttribute2.array, 'attribute was copied');
                    assert.equal(copiedInstance.groups[0].start, 0, 'group was copied');
                    assert.equal(copiedInstance.groups[0].count, 10, 'group was copied');
                    assert.equal(copiedInstance.groups[0].materialIndex, instanceMock1, 'group was copied');
                    assert.equal(copiedInstance.groups[1].start, 10, 'group was copied');
                    assert.equal(copiedInstance.groups[1].count, 5, 'group was copied');
                    assert.equal(copiedInstance.groups[1].materialIndex, instanceMock2, 'group was copied');
                });

                QUnit.todo('toJSON', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}

TestInstancedBufferGeometry.main();