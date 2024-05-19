package three.test.unit.src.objects;

import three.objects.Skeleton;

class SkeletonTests {
    public function new() {}

    public function testObjects() {
        // INSTANCING
        testCase("Instancing", function(assert:Assert) {
            var object:Skeleton = new Skeleton();
            assert.ok(object, 'Can instantiate a Skeleton.');
        });

        // PROPERTIES
        todo("uuid", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("bones", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("boneInverses", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("boneMatrices", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("boneTexture", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("frame", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        todo("init", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("calculateInverses", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("pose", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("update", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("clone", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("computeBoneTexture", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("getBoneByName", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        testCase("dispose", function(assert:Assert) {
            assert.expect(0);
            var object:Skeleton = new Skeleton();
            object.dispose();
        });

        todo("fromJSON", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("toJSON", function(assert:Assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}