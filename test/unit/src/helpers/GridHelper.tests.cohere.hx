import js.QUnit;
import GridHelper from "../../../../src/helpers/GridHelper.hx";
import LineSegments from "../../../../src/objects/LineSegments.hx";

class GridHelperTest {
    static function extending() {
        var object = new GridHelper();
        QUnit.strictEqual(Std.is(object, LineSegments), true, "GridHelper extends from LineSegments");
    }

    static function instancing() {
        var object = new GridHelper();
        QUnit.ok(object, "Can instantiate a GridHelper.");
    }

    static function type() {
        var object = new GridHelper();
        QUnit.equal(object.getType(), "GridHelper", "GridHelper.type should be GridHelper");
    }

    static function dispose() {
        var object = new GridHelper();
        object.dispose();
    }
}

QUnit.module("Helpers", {
    afterEach: function() {},
    beforeEach: function() {},
    after: function() {},
    before: function() {}
});

QUnit.module("GridHelper", {
    afterEach: function() {},
    beforeEach: function() {},
    after: function() {},
    before: function() {}
});

QUnit.test("Extending", GridHelperTest.extending);
QUnit.test("Instancing", GridHelperTest.instancing);
QUnit.test("Type", GridHelperTest.type);
QUnit.test("Dispose", GridHelperTest.dispose);