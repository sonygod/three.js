import js.Browser.document;
import three.src.objects.Group;
import three.src.core.Object3D;

class GroupTests {
    public function new() {
        QUnitModule("Objects", () -> {
            QUnitModule("Group", () -> {

                // INHERITANCE
                QUnitTest("Extending", (assert) -> {
                    var group:Group = new Group();
                    assert.strictEqual(Std.is(group, Object3D), true, 'Group extends from Object3D');
                });

                // INSTANCING
                QUnitTest("Instancing", (assert) -> {
                    var object:Group = new Group();
                    assert.ok(object, 'Can instantiate a Group.');
                });

                // PROPERTIES
                QUnitTest("type", (assert) -> {
                    var object:Group = new Group();
                    assert.ok(object.type == "Group", 'Group.type should be Group');
                });

                // PUBLIC
                QUnitTest("isGroup", (assert) -> {
                    var object:Group = new Group();
                    assert.ok(object.isGroup, 'Group.isGroup should be true');
                });
            });
        });
    }

    private function QUnitModule(name:String, callback:Dynamic -> Void) {
        // Implementation for QUnit.module
    }

    private function QUnitTest(name:String, callback:Dynamic -> Void) {
        // Implementation for QUnit.test
    }
}