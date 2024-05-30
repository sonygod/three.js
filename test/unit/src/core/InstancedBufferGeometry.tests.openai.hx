import haxe.unit.TestCase;
import three.core.InstancedBufferGeometry;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class InstancedBufferGeometryTests {

    public function new() {}

    public static function main():Void {
        TestCase.createTestSuite(InstancedBufferGeometryTests);
    }

    public function testExtending():Void {
        var object = new InstancedBufferGeometry();
        Assert.isTrue(Std.is(object, BufferGeometry), 'InstancedBufferGeometry extends from BufferGeometry');
    }

    public function testInstancing():Void {
        var object = new InstancedBufferGeometry();
        Assert.notNull(object, 'Can instantiate an InstancedBufferGeometry.');
    }

    public function testType():Void {
        var object = new InstancedBufferGeometry();
        Assert.equals(object.type, 'InstancedBufferGeometry', 'InstancedBufferGeometry.type should be InstancedBufferGeometry');
    }

    public function testIsInstancedBufferGeometry():Void {
        var object = new InstancedBufferGeometry();
        Assert.isTrue(object.isInstancedBufferGeometry, 'InstancedBufferGeometry.isInstancedBufferGeometry should be true');
    }

    public function testCopy():Void {
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

        Assert.isTrue(Std.is(copiedInstance, InstancedBufferGeometry), 'the clone has the correct type');

        Assert.equals(copiedInstance.index, indexMock, 'index was copied');
        Assert.equals(copiedInstance.index.callCount, 1, 'index.clone was called once');

        Assert.isTrue(Std.is(copiedInstance.attributes['defaultAttribute1'], BufferAttribute), 'attribute was created');
        Assert.arrayEquals(copiedInstance.attributes['defaultAttribute1'].array, defaultAttribute1.array, 'attribute was copied');
        Assert.arrayEquals(copiedInstance.attributes['defaultAttribute2'].array, defaultAttribute2.array, 'attribute was copied');

        Assert.equals(copiedInstance.groups[0].start, 0, 'group was copied');
        Assert.equals(copiedInstance.groups[0].count, 10, 'group was copied');
        Assert.equals(copiedInstance.groups[0].materialIndex, instanceMock1, 'group was copied');

        Assert.equals(copiedInstance.groups[1].start, 10, 'group was copied');
        Assert.equals(copiedInstance.groups[1].count, 5, 'group was copied');
        Assert.equals(copiedInstance.groups[1].materialIndex, instanceMock2, 'group was copied');
    }

    function createClonableMock():Dynamic {
        return {
            callCount: 0,
            clone: function() {
                this.callCount++;
                return this;
            }
        };
    }
}