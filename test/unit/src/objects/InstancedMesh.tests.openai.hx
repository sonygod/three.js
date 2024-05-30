import haxe.unit.TestCase;
import three.objects.InstancedMesh;
import three.objects.Mesh;

class InstancedMeshTests {
    public function new() {}

    public function testExtending() {
        var object:InstancedMesh = new InstancedMesh();
        TestCase.assertEquals(true, Std.is(object, Mesh), 'InstancedMesh extends from Mesh');
    }

    public function testInstancing() {
        var object:InstancedMesh = new InstancedMesh();
        TestCase.assertNotNull(object, 'Can instantiate a InstancedMesh.');
    }

    // PROPERTIES
    public function todoInstanceMatrix() {
        // InstancedBufferAttribute
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoInstanceColor() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoCount() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoFrustumCulled() {
        TestCase.fail('everything\'s gonna be alright');
    }

    // PUBLIC STUFF
    public function testIsInstancedMesh() {
        var object:InstancedMesh = new InstancedMesh();
        TestCase.assertTrue(object.isInstancedMesh, 'InstancedMesh.isInstancedMesh should be true');
    }

    public function todoCopy() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoGetColorAt() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoGetMatrixAt() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoRaycast() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoSetColorAt() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoSetMatrixAt() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function todoUpdateMorphTargets() {
        // signature defined, no implementation
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testDispose() {
        TestCase.expect(0);
        var object:InstancedMesh = new InstancedMesh();
        object.dispose();
    }
}