import js.Browser.document;
import js.JQuery;
import three.src.helpers.PlaneHelper;
import three.src.objects.Line;

class PlaneHelperTests {

    public function new() {
        var module = JQuery(document).module("Helpers", () -> {
            JQuery(document).module("PlaneHelper", () -> {
                testExtending();
                testInstancing();
                testType();
                testDispose();
            });
        });
    }

    private function testExtending() {
        JQuery(document).test("Extending", (assert) -> {
            var object = new PlaneHelper();
            assert.strictEqual(Std.is(object, Line), true, 'PlaneHelper extends from Line');
        });
    }

    private function testInstancing() {
        JQuery(document).test("Instancing", (assert) -> {
            var object = new PlaneHelper();
            assert.ok(object, 'Can instantiate a PlaneHelper.');
        });
    }

    private function testType() {
        JQuery(document).test("type", (assert) -> {
            var object = new PlaneHelper();
            assert.ok(object.type == 'PlaneHelper', 'PlaneHelper.type should be PlaneHelper');
        });
    }

    private function testDispose() {
        JQuery(document).test("dispose", (assert) -> {
            assert.expect(0);
            var object = new PlaneHelper();
            object.dispose();
        });
    }
}