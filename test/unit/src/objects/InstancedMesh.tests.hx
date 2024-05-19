package three.test.unit.src.objects;

import haxe.unit.TestCase;
import three.objects.InstancedMesh;
import three.objects.Mesh;

class InstancedMeshTests extends TestCase {
    public function new() {
        super();
    }

    public function testExtending() {
        var object:InstancedMesh = new InstancedMesh();
        assertTrue(object instanceof Mesh, 'InstancedMesh extends from Mesh');
    }

    public function testInstancing() {
        var object:InstancedMesh = new InstancedMesh();
        assertNotNull(object, 'Can instantiate a InstancedMesh.');
    }

    public function todoInstanceMatrix() {
        // InstancedBufferAttribute
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoInstanceColor() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCount() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFrustumCulled() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsInstancedMesh() {
        var object:InstancedMesh = new InstancedMesh();
        assertTrue(object.isInstancedMesh, 'InstancedMesh.isInstancedMesh should be true');
    }

    public function todoCopy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetColorAt() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetMatrixAt() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoRaycast() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSetColorAt() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSetMatrixAt() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoUpdateMorphTargets() {
        // signature defined, no implementation
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDispose() {
        var object:InstancedMesh = new InstancedMesh();
        object.dispose();
        assertEquals(0, 0); // assert.expect(0) equivalent
    }
}