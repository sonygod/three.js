package three.test.unit.src.objects;

import haxe.unit.TestCase;
import three.core.Object3D;
import three.materials.Material;
import three.objects.Points;

class PointsTests {

    public function new() { }

    public function testExtending() {
        var points = new Points();
        assertTrue(points instanceof Object3D, 'Points extends from Object3D');
    }

    public function testInstancing() {
        var object = new Points();
        assertNotNull(object, 'Can instantiate a Points.');
    }

    public function testType() {
        var object = new Points();
        assertEquals(object.type, 'Points', 'Points.type should be Points');
    }

    public function todoGeometry() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoMaterial() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsPoints() {
        var object = new Points();
        assertTrue(object.isPoints, 'Points.isPoints should be true');
    }

    public function todoCopy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCopyMaterial() {
        // Material arrays are cloned
        var mesh1 = new Points();
        mesh1.material = [new Material()];

        var copy1 = mesh1.clone();
        assertNotEquals(mesh1.material, copy1.material);

        // Non arrays are not cloned
        var mesh2 = new Points();
        mesh1.material = new Material();
        var copy2 = mesh2.clone();
        assertEquals(mesh2.material, copy2.material);
    }

    public function todoRaycast() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoUpdateMorphTargets() {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}