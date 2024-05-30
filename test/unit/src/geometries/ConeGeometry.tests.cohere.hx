import js.QUnit;
import js.ConeGeometry;
import js.CylinderGeometry;
import js.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries = [new ConeGeometry()];

        // INHERITANCE
        QUnit.test("Extending", function() {
            var object = new ConeGeometry();
            QUnit.strictEqual(object instanceof CylinderGeometry, true, "ConeGeometry extends from CylinderGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", function() {
            var object = new ConeGeometry();
            QUnit.ok(object, "Can instantiate a ConeGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", function() {
            var object = new ConeGeometry();
            QUnit.ok(object.type == "ConeGeometry", "ConeGeometry.type should be ConeGeometry");
        });

        QUnit.todo("parameters", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        // STATIC
        QUnit.todo("fromJSON", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        QUnit.test("Standard geometry tests", function() {
            runStdGeometryTests(geometries);
        });
    }
}