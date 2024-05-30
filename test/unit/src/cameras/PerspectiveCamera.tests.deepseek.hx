package three.test.unit.src.cameras;

import three.src.cameras.PerspectiveCamera;
import three.src.cameras.Camera;
import three.src.math.Matrix4;
import js.Lib;

class PerspectiveCameraTests {

    static function main() {
        QUnit.module('Cameras', () -> {
            QUnit.module('PerspectiveCamera', () -> {
                var matrixEquals4 = function(a:Matrix4, b:Matrix4, tolerance:Float) {
                    tolerance = tolerance || 0.0001;
                    if (a.elements.length != b.elements.length) {
                        return false;
                    }
                    for (i in 0...a.elements.length) {
                        var delta = a.elements[i] - b.elements[i];
                        if (delta > tolerance) {
                            return false;
                        }
                    }
                    return true;
                };

                QUnit.test('Extending', (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.strictEqual(object instanceof Camera, true, 'PerspectiveCamera extends from Camera');
                });

                QUnit.test('Instancing', (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.ok(object, 'Can instantiate a PerspectiveCamera.');
                });

                QUnit.test('type', (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.ok(object.type === 'PerspectiveCamera', 'PerspectiveCamera.type should be PerspectiveCamera');
                });

                QUnit.todo('fov', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('zoom', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('near', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('far', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('focus', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('aspect', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('view', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('filmGauge', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('filmOffset', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('isPerspectiveCamera', (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.ok(object.isPerspectiveCamera, 'PerspectiveCamera.isPerspectiveCamera should be true');
                });

                QUnit.todo('copy', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setFocalLength', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getFocalLength', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getEffectiveFOV', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getFilmWidth', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getFilmHeight', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setViewOffset', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('clearViewOffset', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('updateProjectionMatrix', (assert) -> {
                    var cam = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);
                    var m = cam.projectionMatrix;
                    var reference = new Matrix4().set(
                        0.7330642938613892, 0, 0, 0,
                        0, 1.3032253980636597, 0, 0,
                        0, 0, -1.000666856765747, -0.2000666856765747,
                        0, 0, -1, 0
                    );
                    assert.ok(matrixEquals4(reference, m, 0.000001));
                });

                QUnit.todo('toJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('clone', (assert) -> {
                    var near = 1, far = 3, aspect = 16 / 9, fov = 90;
                    var cam = new PerspectiveCamera(fov, aspect, near, far);
                    var clonedCam = cam.clone();
                    assert.ok(cam.fov === clonedCam.fov, 'fov is equal');
                    assert.ok(cam.aspect === clonedCam.aspect, 'aspect is equal');
                    assert.ok(cam.near === clonedCam.near, 'near is equal');
                    assert.ok(cam.far === clonedCam.far, 'far is equal');
                    assert.ok(cam.zoom === clonedCam.zoom, 'zoom is equal');
                    assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
                });
            });
        });
    }
}