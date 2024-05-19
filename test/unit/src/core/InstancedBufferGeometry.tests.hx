package three.test.unit.src.core;

import haxe.unit.TestCase;
import three.core.InstancedBufferGeometry;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class InstancedBufferGeometryTests extends TestCase {

    function createClonableMock() : Dynamic {
        return {
            callCount: 0,
            clone: function() {
                this.callCount++;
                return this;
            }
        };
    }

    function testExtending() {
        var object = new InstancedBufferGeometry();
        assertEquals(Type.getClass(object), BufferGeometry, 'InstancedBufferGeometry extends from BufferGeometry');
    }

    function testInstancing() {
        var object = new InstancedBufferGeometry();
        assertNotNull(object, 'Can instantiate an InstancedBufferGeometry.');
    }

    function testType() {
        var object = new InstancedBufferGeometry();
        assertEquals(object.type, 'InstancedBufferGeometry', 'InstancedBufferGeometry.type should be InstancedBufferGeometry');
    }

    function testTodoInstanceCount() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    function testIsInstancedBufferGeometry() {
        var object = new InstancedBufferGeometry();
        assertTrue(object.isInstancedBufferGeometry, 'InstancedBufferGeometry.isInstancedBufferGeometry should be true');
    }

    function testCopy() {
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

        assertTrue(Std.is(copiedInstance, InstancedBufferGeometry), 'the clone has the correct type');

        assertEquals(copiedInstance.getIndex(), indexMock, 'index was copied');
        assertEquals(indexMock.callCount, 1, 'index.clone was called once');

        assertTrue(Std.is(copiedInstance.getAttribute('defaultAttribute1'), BufferAttribute), 'attribute was created');
        assertEquals(copiedInstance.getAttribute('defaultAttribute1').array, defaultAttribute1.array, 'attribute was copied');
        assertEquals(copiedInstance.getAttribute('defaultAttribute2').array, defaultAttribute2.array, 'attribute was copied');

        assertEquals(copiedInstance.groups[0].start, 0, 'group was copied');
        assertEquals(copiedInstance.groups[0].count, 10, 'group was copied');
        assertEquals(copiedInstance.groups[0].materialIndex, instanceMock1, 'group was copied');

        assertEquals(copiedInstance.groups[1].start, 10, 'group was copied');
        assertEquals(copiedInstance.groups[1].count, 5, 'group was copied');
        assertEquals(copiedInstance.groups[1].materialIndex, instanceMock2, 'group was copied');
    }

    function testTodoToJson() {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}