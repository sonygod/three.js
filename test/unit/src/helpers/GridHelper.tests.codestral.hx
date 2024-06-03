import js.JQuery;
import js.Browser.document;
import three.src.helpers.GridHelper;
import three.src.objects.LineSegments;
import three.test.unit.src.Assert;

class GridHelperTests {
    public function new() {
        JQuery.module("Helpers", () -> {
            JQuery.module("GridHelper", () -> {
                // INHERITANCE
                JQuery.test("Extending", ( assert ) -> {
                    var object:GridHelper = new GridHelper();
                    Assert.strictEqual(Std.is(object, LineSegments), true, 'GridHelper extends from LineSegments');
                });

                // INSTANCING
                JQuery.test("Instancing", ( assert ) -> {
                    var object:GridHelper = new GridHelper();
                    Assert.ok(object, 'Can instantiate a GridHelper.');
                });

                // PROPERTIES
                JQuery.test("type", ( assert ) -> {
                    var object:GridHelper = new GridHelper();
                    Assert.ok(object.type == "GridHelper", 'GridHelper.type should be GridHelper');
                });

                // PUBLIC
                JQuery.test("dispose", ( assert ) -> {
                    var object:GridHelper = new GridHelper();
                    object.dispose();
                });
            });
        });
    }
}