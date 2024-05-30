package;

import three.js.test.unit.src.helpers.SkeletonHelper;
import three.js.test.unit.src.objects.LineSegments;
import three.js.test.unit.src.objects.Bone;

class SkeletonHelperTests {

    static function main() {
        // INHERITANCE
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        unittest.assert(object instanceof LineSegments);

        // INSTANCING
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        unittest.assert(object != null);

        // PROPERTIES
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        unittest.assert(object.type == "SkeletonHelper");

        // PUBLIC
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        unittest.assert(object.isSkeletonHelper);

        // DISPOSE
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        object.dispose();
    }
}