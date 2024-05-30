import js.QUnit;
import js.Object3D;

class Group {
    public var type: String;
    public var isGroup: Bool;

    public function new() {
        // ...
    }
}

class _Test {
    static function main() {
        var group = new Group();
        var object = new Group();

        QUnit.module("Objects -> Group", {
            beforeEach: function() { },
            afterEach: function() { }
        });

        QUnit.test("Extending", function(assert) {
            assert.strictEqual(group instanceof Object3D, true, "Group extends from Object3D");
        });

        QUnit.test("Instancing", function(assert) {
            assert.ok(object, "Can instantiate a Group");
        });

        QUnit.test("type", function(assert) {
            assert.ok(object.type == "Group", "Group.type should be Group");
        });

        QUnit.test("isGroup", function(assert) {
            assert.ok(object.isGroup, "Group.isGroup should be true");
        });
    }
}