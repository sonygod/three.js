import haxe.unit.TestCase;
import three.helpers.SkeletonHelper;
import three.objects.Bone;
import three.objects.LineSegments;

class SkeletonHelperTests
{
    public function new()
    {
    }

    public function testExtending():Void
    {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        assertEquals(True, Std.is(object, LineSegments), 'SkeletonHelper extends from LineSegments');
    }

    public function testInstancing():Void
    {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        assertNotNull(object, 'Can instantiate a SkeletonHelper.');
    }

    public function testType():Void
    {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        assertEquals('SkeletonHelper', object.type, 'SkeletonHelper.type should be SkeletonHelper');
    }

    public function todoRoot():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoBones():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoMatrix():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoMatrixAutoUpdate():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testIsSkeletonHelper():Void
    {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        assertTrue(object.isSkeletonHelper, 'SkeletonHelper.isSkeletonHelper should be true');
    }

    public function todoUpdateMatrixWorld():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testDispose():Void
    {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        object.dispose();
        assertTrue(true); // no assertions, just test that dispose doesn't throw
    }
}