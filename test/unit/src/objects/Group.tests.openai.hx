package three.test.unit.src.objects;

import three.objects.Group;
import three.core.Object3D;

class GroupTests {
    public function new() {}

    public static function main() {
        utest.RunTests([
            new GroupTests(),
        ]);
    }

    public function testExtending() {
        var group = new Group();
        utest.Assert.isTrue(group instanceof Object3D, "Group extends from Object3D");
    }

    public function testInstancing() {
        var object = new Group();
        utest.Assert.notNull(object, "Can instantiate a Group.");
    }

    public function testType() {
        var object = new Group();
        utest.Assert.equals(object.type, "Group", "Group.type should be Group");
    }

    public function testIsGroup() {
        var object = new Group();
        utest.Assert.isTrue(object.isGroup, "Group.isGroup should be true");
    }
}