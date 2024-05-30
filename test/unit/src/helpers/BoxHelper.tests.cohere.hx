import js.QUnit;
import js.QUnit.QUnitModule;

import js.THREE.BoxHelper;
import js.THREE.LineSegments;
import js.THREE.BoxGeometry;
import js.THREE.SphereGeometry;
import js.THREE.Mesh;

class BoxHelperTest {
    static function beforeEach() {
        var boxGeometry = new BoxGeometry();
        var box = new Mesh(boxGeometry);
        var boxHelper = new BoxHelper(box);

        var sphereGeometry = new SphereGeometry();
        var sphere = new Mesh(sphereGeometry);
        var sphereBoxHelper = new BoxHelper(sphere);
    }

    static function testExtending() {
        var object = new BoxHelper();
        var assert = js.QUnit.test.assert;
        assert.strictEqual(object instanceof LineSegments, true, 'BoxHelper extends from LineSegments');
    }

    static function testInstancing() {
        var object = new BoxHelper();
        var assert = js.QUnit.test.assert;
        assert.ok(object, 'Can instantiate a BoxHelper');
    }

    static function testType() {
        var object = new BoxHelper();
        var assert = js.QUnit.test.assert;
        assert.ok(object.type == 'BoxHelper', 'BoxHelper.type should be BoxHelper');
    }

    static function testDispose() {
        var object = new BoxHelper();
        var assert = js.QUnit.test.assert;
        assert.expect(0);
        object.dispose();
    }

    static function testStandardGeometryTests() {
        var assert = js.QUnit.test.assert;
        runStdGeometryTests(assert, null);
    }
}

@:jsRequire(js.QUnit.QUnitModule.exportDefault(js.QUnit.module('Helpers', {
    'BoxHelper': function(hooks) {
        BoxHelperTest.beforeEach();
        hooks.beforeEach(BoxHelperTest.beforeEach);
        hooks.addTest('Extending', BoxHelperTest.testExtending);
        hooks.addTest('Instancing', BoxHelperTest.testInstancing);
        hooks.addTest('type', BoxHelperTest.testType);
        hooks.addTest('dispose', BoxHelperTest.testDispose);
        hooks.addTest('Standard geometry tests', BoxHelperTest.testStandardGeometryTests);
    }
})));