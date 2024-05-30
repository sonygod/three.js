import js.QUnit;
import js.geom.BufferGeometry;
import js.geom.WireframeGeometry;

class WireframeGeometryTest {
    static function run() {
        var geometries = [new WireframeGeometry()];

        // INHERITANCE
        QUnit.test("Extending", function() {
            var object = new WireframeGeometry();
            QUnit.strictEqual(object instanceof BufferGeometry, true, "WireframeGeometry extends from BufferGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", function() {
            var object = new WireframeGeometry();
            QUnit.ok(object, "Can instantiate a WireframeGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", function() {
            var object = new WireframeGeometry();
            QUnit.ok(object.type == "WireframeGeometry", "WireframeGeometry.type should be WireframeGeometry");
        });

        QUnit.todo("parameters", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        QUnit.todo("Standard geometry tests", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });
    }
}

// Register the test
QUnit.module("Geometries", {
    beforeEach: function() {},
    afterEach: function() {}
});
QUnit.module("WireframeGeometry", {
    beforeEach: function() {},
    afterEach: function() {}
});
QUnit.test("WireframeGeometry Test", WireframeGeometryTest.run);