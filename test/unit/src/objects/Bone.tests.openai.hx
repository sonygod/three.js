import utest.Runner;
import utest.ui.Report;

import three.objects.Bone;
import three.core.Object3D;

class BoneTests {
    public static function main() {
        var runner = new Runner();
        runner.addCase(new BoneTestCase());
        Report.create(runner);
        runner.run();
    }
}

class BoneTestCase {
    public function new() {}

    @Test
    public function testExtending() {
        var bone = new Bone();
        assertTrue(bone instanceof Object3D, "Bone extends from Object3D");
    }

    @Test
    public function testInstancing() {
        var object = new Bone();
        assertNotNull(object, "Can instantiate a Bone.");
    }

    @Test
    public function testType() {
        var object = new Bone();
        assertEquals(object.type, "Bone", "Bone.type should be Bone");
    }

    @Test
    public function testIsBone() {
        var object = new Bone();
        assertTrue(object.isBone, "Bone.isBone should be true");
    }
}