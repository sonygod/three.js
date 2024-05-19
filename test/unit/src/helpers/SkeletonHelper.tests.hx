package three.helpers;

import haxe.unit.TestCase;
import three.objects.Bone;
import three.objects.LineSegments;
import three.helpers.SkeletonHelper;

class SkeletonHelperTest {
    public function new() {}

    public function testExtending():Void {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        TestCase.assertEquals(object instanceof LineSegments, true, "SkeletonHelper extends from LineSegments");
    }

    public function testInstancing():Void {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        TestCase.assertNotNull(object, "Can instantiate a SkeletonHelper.");
    }

    public function testType():Void {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        TestCase.assertEquals(object.type, "SkeletonHelper", "SkeletonHelper.type should be SkeletonHelper");
    }

    public function testTodoRoot():Void {
        TestCase.fail("todo: root");
    }

    public function testTodoBones():Void {
        TestCase.fail("todo: bones");
    }

    public function testTodoMatrix():Void {
        TestCase.fail("todo: matrix");
    }

    public function testTodoMatrixAutoUpdate():Void {
        TestCase.fail("todo: matrixAutoUpdate");
    }

    public function testIsSkeletonHelper():Void {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        TestCase.assertTrue(object.isSkeletonHelper, "SkeletonHelper.isSkeletonHelper should be true");
    }

    public function testTodoUpdateMatrixWorld():Void {
        TestCase.fail("todo: updateMatrixWorld");
    }

    public function testDispose():Void {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        object.dispose();
        // no assertions, just test that dispose doesn't throw
    }
}