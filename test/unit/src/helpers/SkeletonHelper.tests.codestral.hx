import three.helpers.SkeletonHelper;
import three.objects.LineSegments;
import three.objects.Bone;

class SkeletonHelperTest {
    public function new() {
        // INHERITANCE
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        trace(Std.is(object, LineSegments), "SkeletonHelper extends from LineSegments");

        // INSTANCING
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        trace(object != null, "Can instantiate a SkeletonHelper.");

        // PROPERTIES
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        trace(object.type == "SkeletonHelper", "SkeletonHelper.type should be SkeletonHelper");

        // PUBLIC
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        trace(object.isSkeletonHelper, "SkeletonHelper.isSkeletonHelper should be true");

        // dispose
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        object.dispose();
    }
}