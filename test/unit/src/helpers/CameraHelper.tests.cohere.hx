import js.QUnit;

import js.CameraHelper;
import js.LineSegments;
import js.PerspectiveCamera;

class TestCameraHelper {
    static function extending() {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        trace(Std.is(object, LineSegments));
    }

    static function instancing() {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        trace(object != null);
    }

    static function type() {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        trace(object.getType() == "CameraHelper");
    }

    static function dispose() {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        object.dispose();
    }
}

QUnit.module('Helpers', function () {
    QUnit.module('CameraHelper', function () {
        QUnit.test('Extending', TestCameraHelper.extending);
        QUnit.test('Instancing', TestCameraHelper.instancing);
        QUnit.test('Type', TestCameraHelper.type);
        QUnit.test('Dispose', TestCameraHelper.dispose);
    });
});