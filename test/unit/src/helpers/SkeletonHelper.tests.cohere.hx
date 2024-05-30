import js.QUnit;

import js.Three.helpers.SkeletonHelper;
import js.Three.objects.LineSegments;
import js.Three.objects.Bone;

class SkeletonHelperTest {
    static function extending() {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        var isLineSegments = (object instanceof LineSegments);
        QUnit.strictEqual(isLineSegments, true, "SkeletonHelper extends from LineSegments");
    }

    static function instancing() {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        QUnit.ok(object, "Can instantiate a SkeletonHelper");
    }

    static function type() {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        QUnit.ok(object.type == "SkeletonHelper", "SkeletonHelper.type should be SkeletonHelper");
    }

    static function isSkeletonHelper() {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        QUnit.ok(object.isSkeletonHelper, "SkeletonHelper.isSkeletonHelper should be true");
    }

    static function dispose() {
        var bone = new Bone();
        var object = new SkeletonHelper(bone);
        object.dispose();
    }
}

QUnit.module("Helpers", {
    setup: function() {},
    teardown: function() {}
});

QUnit.module("SkeletonHelper", {
    setup: function() {},
    teardown: function() {}
});

QUnit.test("Extending", SkeletonHelperTest.extending);
QUnit.test("Instancing", SkeletonHelperTest.instancing);
QUnit.test("Type", SkeletonHelperTest.type);
QUnit.test("IsSkeletonHelper", SkeletonHelperTest.isSkeletonHelper);
QUnit.test("Dispose", SkeletonHelperTest.dispose);