import js.QUnit.*;
import js.QUnit.QUnit.*;

import js.Three.IcosahedronGeometry;
import js.Three.PolyhedronGeometry;
import js.Three.utils.qunit.qunit_utils.runStdGeometryTests;

class _Main {
    static function main() {
        module("Geometries", {
            setup: function() {
                trace("Geometries module setup");
            },
            teardown: function() {
                trace("Geometries module teardown");
            }
        });

        module("IcosahedronGeometry", {
            beforeEach: function() {
                var parameters = { radius: 10, detail: null };
                var geometries = [
                    new IcosahedronGeometry(),
                    new IcosahedronGeometry(parameters.radius),
                    new IcosahedronGeometry(parameters.radius, parameters.detail)
                ];
            }
        });

        // INHERITANCE
        test("Extending", function(assert) {
            var object = new IcosahedronGeometry();
            assert.strictEqual(object instanceof PolyhedronGeometry, true, "IcosahedronGeometry extends from PolyhedronGeometry");
        });

        // INSTANCING
        test("Instancing", function(assert) {
            var object = new IcosahedronGeometry();
            assert.ok(object, "Can instantiate an IcosahedronGeometry.");
        });

        // PROPERTIES
        test("type", function(assert) {
            var object = new IcosahedronGeometry();
            assert.ok(object.type == "IcosahedronGeometry", "IcosahedronGeometry.type should be IcosahedronGeometry");
        });

        todo("parameters", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // STATIC
        todo("fromJSON", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        test("Standard geometry tests", function(assert) {
            runStdGeometryTests(assert, geometries);
        });
    }
}