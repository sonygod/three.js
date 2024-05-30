package;

import js.Lib;
import three.core.InstancedBufferGeometry;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class InstancedBufferGeometryTest {

    static function main() {
        var module = Lib.QUnit.module("Core");
        module.module("InstancedBufferGeometry");

        function createClonableMock() {
            return {
                callCount: 0,
                clone: function () {
                    this.callCount ++;
                    return this;
                }
            };
        }

        // INHERITANCE
        Lib.QUnit.test("Extending", function(assert) {
            var object = new InstancedBufferGeometry();
            assert.strictEqual(object instanceof BufferGeometry, true, 'InstancedBufferGeometry extends from BufferGeometry');
        });

        // INSTANCING
        Lib.QUnit.test("Instancing", function(assert) {
            var object = new InstancedBufferGeometry();
            assert.ok(object, 'Can instantiate an InstancedBufferGeometry.');
        });

        // PROPERTIES
        Lib.QUnit.test("type", function(assert) {
            var object = new InstancedBufferGeometry();
            assert.ok(object.type == 'InstancedBufferGeometry', 'InstancedBufferGeometry.type should be InstancedBufferGeometry');
        });

        Lib.QUnit.todo("instanceCount", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        Lib.QUnit.test("isInstancedBufferGeometry", function(assert) {
            var object = new InstancedBufferGeometry();
            assert.ok(object.isInstancedBufferGeometry, 'InstancedBufferGeometry.isInstancedBufferGeometry should be true');
        });

        Lib.QUnit.test("copy", function(assert) {
            var instanceMock1 = {};
            var instanceMock2 = {};
            var indexMock = createClonableMock();
            var defaultAttribute1 = new BufferAttribute(new js.TypedArray([1]));
            var defaultAttribute2 = new BufferAttribute(new js.TypedArray([2]));

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

        Lib.QUnit.todo("toJSON", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}