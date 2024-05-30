package three.objects;

import three.objects.Skeleton;

class SkeletonTests {

    public function new() {}

    public function test() {
        // INSTANCING
        utest.Assert.isTrue(new Skeleton() != null, "Can instantiate a Skeleton.");

        // PROPERTIES
        todo("uuid", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("bones", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("boneInverses", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("boneMatrices", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("boneTexture", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("frame", () -> utest.Assert.fail("everything's gonna be alright"));

        // PUBLIC
        todo("init", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("calculateInverses", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("pose", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("update", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("clone", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("computeBoneTexture", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("getBoneByName", () -> utest.Assert.fail("everything's gonna be alright"));

        // dispose
        utest.Ignore("dispose", () -> {
            var object = new Skeleton();
            object.dispose();
        });

        todo("fromJSON", () -> utest.Assert.fail("everything's gonna be alright"));
        todo("toJSON", () -> utest.Assert.fail("everything's gonna be alright"));
    }

    private function todo(name:String, callback:Void->Void) {
        utest.Test.todo(name, callback);
    }
}