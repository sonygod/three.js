import js.QUnit.*;
import js.QUnit.QUnitTest;

import js.WebGLGeometries.TorusGeometry;
import js.WebGLCore.BufferGeometry;
import js.WebGLUtils.QUnitUtils.runStdGeometryTests;

class _TorusGeometryTest {
    static function beforeEach(assert:Assert, done:js.Function1<Dynamic, Void>) {
        var parameters = { radius: 10, tube: 20, radialSegments: 30, tubularSegments: 10, arc: 2.0 };
        var geometries = [
            new TorusGeometry(),
            new TorusGeometry(parameters.radius),
            new TorusGeometry(parameters.radius, parameters.tube),
            new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments),
            new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments),
            new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments, parameters.arc)
        ];
    }

    static function extending(assert:Assert, done:js.Function1<Dynamic, Void>) {
        var object = new TorusGeometry();
        assert.strictEqual(Std.is(object, BufferGeometry), true, "TorusGeometry extends from BufferGeometry");
    }

    static function instancing(assert:Assert, done:js.Function1<Dynamic, Void>) {
        var object = new TorusGeometry();
        assert.ok(object, "Can instantiate a TorusGeometry.");
    }

    static function type(assert:Assert, done:js.Function1<Dynamic, Void>) {
        var object = new TorusGeometry();
        assert.ok(object.type == "TorusGeometry", "TorusGeometry.type should be TorusGeometry");
    }

    static function parameters(assert:Assert, done:js.Function1<Dynamic, Void>) {
        assert.ok(false, "everything's gonna be alright");
    }

    static function fromJSON(assert:Assert, done:js.Function1<Dynamic, Void>) {
        assert.ok(false, "everything's gonna be alright");
    }

    static function standardGeometryTests(assert:Assert, done:js.Function1<Dynamic, Void>) {
        runStdGeometryTests(assert, done, null);
    }
}

@:autoTest("Geometries")
class TorusGeometryTest extends QUnitTest {
    static function setupSuite() {
        super.setupSuite();
        beforeEach(_TorusGeometryTest.beforeEach);
        test("Extending", _TorusGeometryTest.extending);
        test("Instancing", _TorusGeometryTest.instancing);
        test("type", _TorusGeometryTest.type);
        todo("parameters", _TorusGeometryTest.parameters);
        todo("fromJSON", _TorusGeometryTest.fromJSON);
        test("Standard geometry tests", _TorusGeometryTest.standardGeometryTests);
    }
}