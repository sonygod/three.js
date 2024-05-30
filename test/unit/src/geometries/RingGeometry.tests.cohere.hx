import js.QUnit.*;
import js.QUnit.QUnitTest;

import js.Three.BufferGeometry;
import js.Three.RingGeometry;

import js.qunit.utils.qunit_utils.runStdGeometryTests;

class _RingGeometryTest {
    static function beforeEach(assert:QUnitAssert, done:Dynamic) {
        var parameters = { innerRadius: 10, outerRadius: 60, thetaSegments: 12, phiSegments: 14, thetaStart: 0.1, thetaLength: 2.0 };

        var geometries = [
            new RingGeometry(),
            new RingGeometry(parameters.innerRadius),
            new RingGeometry(parameters.innerRadius, parameters.outerRadius),
            new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments),
            new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments),
            new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments, parameters.thetaStart),
            new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments, parameters.thetaStart, parameters.thetaLength)
        ];
    }

    static function testExtending(assert:QUnitAssert, done:Dynamic) {
        var object = new RingGeometry();
        assert.strictEqual(Std.is(object, BufferGeometry), true, "RingGeometry extends from BufferGeometry");
    }

    static function testInstancing(assert:QUnitAssert, done:Dynamic) {
        var object = new RingGeometry();
        assert.ok(object, "Can instantiate a RingGeometry");
    }

    static function testType(assert:QUnitAssert, done:Dynamic) {
        var object = new RingGeometry();
        assert.ok(object.type == "RingGeometry", "RingGeometry.type should be RingGeometry");
    }

    static function testParameters(assert:QUnitAssert, done:Dynamic) {
        assert.ok(false, "everything's gonna be alright");
    }

    static function testFromJSON(assert:QUnitAssert, done:Dynamic) {
        assert.ok(false, "everything's gonna be alright");
    }

    static function testStandardGeometryTests(assert:QUnitAssert, done:Dynamic) {
        runStdGeometryTests(assert, geometries);
    }
}

@:build(QUnitTest.build)
class RingGeometryTest {
    static var moduleName = "Geometries";
    static var moduleDescription = "RingGeometry";

    static function beforeEach(assert:QUnitAssert, done:Dynamic) {
        done();
    }

    static function afterEach(assert:QUnitAssert, done:Dynamic) {
        done();
    }

    static function test(assert:QUnitAssert, done:Dynamic) {
        _RingGeometryTest.beforeEach(assert, function() {
            _RingGeometryTest.testExtending(assert, function() {
                _RingGeometryTest.testInstancing(assert, function() {
                    _RingGeometryTest.testType(assert, function() {
                        _RingGeometryTest.testParameters(assert, function() {
                            _RingGeometryTest.testFromJSON(assert, function() {
                                _RingGeometryTest.testStandardGeometryTests(assert, done);
                            });
                        });
                    });
                });
            });
        });
    }
}