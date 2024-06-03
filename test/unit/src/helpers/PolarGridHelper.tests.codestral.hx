import qunit.QUnit;
import three.helpers.PolarGridHelper;
import three.objects.LineSegments;

class PolarGridHelperTests {
    public static function main() {
        QUnit.module("Helpers", () -> {
            QUnit.module("PolarGridHelper", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object:PolarGridHelper = new PolarGridHelper();
                    assert.strictEqual(Std.is(object, LineSegments), true, "PolarGridHelper extends from LineSegments");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object:PolarGridHelper = new PolarGridHelper();
                    assert.ok(object, "Can instantiate a PolarGridHelper.");
                });

                QUnit.test("type", (assert) -> {
                    var object:PolarGridHelper = new PolarGridHelper();
                    assert.ok(object.type == "PolarGridHelper", "PolarGridHelper.type should be PolarGridHelper");
                });

                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);
                    var object:PolarGridHelper = new PolarGridHelper();
                    object.dispose();
                });
            });
        });
    }
}