package three.test.unit.src.helpers;

import three.helpers.AxesHelper;
import three.objects.LineSegments;

class AxesHelperTests {
    public function new() {}

    public function test() {
        #if (js && qunit)
        QUnit.module("Helpers", () => {
            QUnit.module("AxesHelper", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new AxesHelper();
                    assert.ok(Std.is(object, LineSegments), "AxesHelper extends from LineSegments");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new AxesHelper();
                    assert.ok(object != null, "Can instantiate an AxesHelper.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new AxesHelper();
                    assert.ok(object.type == "AxesHelper", "AxesHelper.type should be AxesHelper");
                });

                // PUBLIC
                QUnit.todo("setColors", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("dispose", (assert) => {
                    assert.expect(0);

                    var object = new AxesHelper();
                    object.dispose();
                });
            });
        });
        #end
    }
}