// Import necessary classes
import js.QUnit;
import threejs.src.objects.Bone;
import threejs.src.core.Object3D;

// Define the module and its tests
@:native("QUnit.module")
class BoneTests {

    public static function main(): Void {
        // INHERITANCE
        QUnit.test("Extending", function(assert: js.QUnit.Assert) {
            var bone = new Bone();
            assert.strictEqual(Std.is(bone, Object3D), true, 'Bone extends from Object3D');
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert: js.QUnit.Assert) {
            var object = new Bone();
            assert.ok(object != null, 'Can instantiate a Bone.');
        });

        // PROPERTIES
        QUnit.test("type", function(assert: js.QUnit.Assert) {
            var object = new Bone();
            assert.ok(object.type == "Bone", 'Bone.type should be Bone');
        });

        // PUBLIC
        QUnit.test("isBone", function(assert: js.QUnit.Assert) {
            var object = new Bone();
            assert.ok(object.isBone, 'Bone.isBone should be true');
        });
    }
}