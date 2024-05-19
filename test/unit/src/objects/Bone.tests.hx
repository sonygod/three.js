package three.objects;

import haxe.unit.TestCase;
import three.core.Object3D;
import three.objects.Bone;

class BoneTest {
    public function new() {}

    public function testExtending() {
        var bone = new Bone();
        TestCase.assertEquals(bone instanceof Object3D, true, 'Bone extends from Object3D');
    }

    public function testInstancing() {
        var object = new Bone();
        TestCase.assertNotNull(object, 'Can instantiate a Bone.');
    }

    public function testType() {
        var object = new Bone();
        TestCase.assertEquals(object.type, 'Bone', 'Bone.type should be Bone');
    }

    public function testIsBone() {
        var object = new Bone();
        TestCase.assertTrue(object.isBone, 'Bone.isBone should be true');
    }
}