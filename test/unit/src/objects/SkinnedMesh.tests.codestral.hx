import three.core.Object3D;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.constants.AttachedBindMode;

class SkinnedMeshTests {

    public function new() {
        testExtending();
        testInstancing();
        testType();
        testBindMode();
        testIsSkinnedMesh();
    }

    private function testExtending() {
        var skinnedMesh = new SkinnedMesh();
        trace('SkinnedMesh extends from Object3D: ' + Std.is(skinnedMesh, Object3D));
        trace('SkinnedMesh extends from Mesh: ' + Std.is(skinnedMesh, Mesh));
    }

    private function testInstancing() {
        var object = new SkinnedMesh();
        trace('Can instantiate a SkinnedMesh: ' + (object != null));
    }

    private function testType() {
        var object = new SkinnedMesh();
        trace('SkinnedMesh.type should be SkinnedMesh: ' + (object.type == 'SkinnedMesh'));
    }

    private function testBindMode() {
        var object = new SkinnedMesh();
        trace('SkinnedMesh.bindMode should be AttachedBindMode: ' + (object.bindMode == AttachedBindMode));
    }

    private function testIsSkinnedMesh() {
        var object = new SkinnedMesh();
        trace('SkinnedMesh.isSkinnedMesh should be true: ' + object.isSkinnedMesh);
    }
}