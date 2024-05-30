import js.QUnit;
import js.geom.ExtrudeGeometry;
import js.core.BufferGeometry;

class ExtrudeGeometryTest {
    static function extending() {
        var object = new ExtrudeGeometry();
        QUnit.strictEqual(Std.is(object, BufferGeometry), true, "ExtrudeGeometry extends from BufferGeometry");
    }

    static function instantiating() {
        var object = new ExtrudeGeometry();
        QUnit.ok(object != null, "Can instantiate an ExtrudeGeometry.");
    }

    static function type() {
        var object = new ExtrudeGeometry();
        QUnit.equal(object.getType(), "ExtrudeGeometry", "ExtrudeGeometry.type should be ExtrudeGeometry");
    }

    static function parameters() {
        QUnit.ok(false, "Test not implemented yet");
    }

    static function toJSON() {
        QUnit.ok(false, "Test not implemented yet");
    }

    static function fromJSON() {
        QUnit.ok(false, "Test not implemented yet");
    }

    public static function main() {
        QUnit.module("Geometries", {
            setup:function() {}, teardown:function() {}
        });

        QUnit.module("ExtrudeGeometry", {
            setup:function() {}, teardown:function() {}
        });

        QUnit.test("Extending", ExtrudeGeometryTest.extending);
        QUnit.test("Instancing", ExtrudeGeometryTest.instantiating);
        QUnit.test("Type", ExtrudeGeometryTest.type);
        QUnit.test("Parameters", ExtrudeGeometryTest.parameters);
        QUnit.test("toJSON", ExtrudeGeometryTest.toJSON);
        QUnit.test("fromJSON", ExtrudeGeometryTest.fromJSON);
    }
}