package three.test.unit.src.objects;

import haxe.unit.TestCase;
import three.objects.Line;
import three.core.Object3D;
import three.materials.Material;

class LineTests {
    public function new() {}

    public function testExtending() {
        var line = new Line();
        assertTrue(line instanceof Object3D, 'Line extends from Object3D');
    }

    public function testInstancing() {
        var object = new Line();
        assertTrue(object != null, 'Can instantiate a Line.');
    }

    public function testType() {
        var object = new Line();
        assertEquals(object.type, 'Line', 'Line.type should be Line');
    }

    public function testGeometry() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testMaterial() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsLine() {
        var object = new Line();
        assertTrue(object.isLine, 'Line.isLine should be true');
    }

    public function testCopy() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCopyMaterial() {
        // Material arrays are cloned
        var mesh1 = new Line();
        mesh1.material = [new Material()];

        var copy1 = mesh1.clone();
        assertNotEquals(mesh1.material, copy1.material);

        // Non arrays are not cloned
        var mesh2 = new Line();
        mesh2.material = new Material();
        var copy2 = mesh2.clone();
        assertEquals(mesh2.material, copy2.material);
    }

    public function testComputeLineDistances() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testRaycast() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testUpdateMorphTargets() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testClone() {
        // Todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }
}