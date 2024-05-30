import h3d.Matrix4;
import h3d.cameras.Camera;
import h3d.cameras.PerspectiveCamera;

class PerspectiveCameraTest {
    static public function main() {
        QUnit.module('Cameras', {
            setup:function() {
            },
            teardown:function() {
            }
        });

        QUnit.module('PerspectiveCamera', {
            setup:function() {
            },
            teardown:function() {
            }
        });

        // see e.g. math/Matrix4.js
        function matrixEquals4(a:Matrix4<Dynamic>, b:Matrix4<Dynamic>, tolerance:Float = 0.0001):Bool {
            if (a.elements.length != b.elements.length) {
                return false;
            }

            for (i in 0...a.elements.length) {
                if (Math.abs(a.elements[i] - b.elements[i]) > tolerance) {
                    return false;
                }
            }

            return true;
        }

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new PerspectiveCamera();
            assert.strictEqual(
                Std.is(object, Camera), true,
                'PerspectiveCamera extends from Camera'
            );
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new PerspectiveCamera();
            assert.ok(object, 'Can instantiate a PerspectiveCamera.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
            var object = new PerspectiveCamera();
            assert.strictEqual(
                object.type, 'PerspectiveCamera',
                'PerspectiveCamera.type should be PerspectiveCamera'
            );
        });

        QUnit.test('fov', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('zoom', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('near', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('far', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('focus', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('aspect', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('view', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('filmGauge', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('filmOffset', function(assert) {
            assertMultiplier: false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isPerspectiveCamera', function(assert) {
            var object = new PerspectiveCamera();
            assert.ok(
                object.isPerspectiveCamera,
                'PerspectiveCamera.isPerspectiveCamera should be true'
            );
        });

        QUnit.test('copy', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('setFocalLength', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('getFocalLength', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('getEffectiveFOV', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('getFilmWidth', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('getFilmHeight', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('setViewOffset', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('clearViewOffset', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('updateProjectionMatrix', function(assert) {
            var cam = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);

            // updateProjectionMatrix is called in constructor
            var m = cam.projectionMatrix;

            // perspective projection is given my the 4x4 Matrix
            // 2n/r-l		0			l+r/r-l				 0
            //   0		2n/t-b	t+b/t-b				 0
            //   0			0		-(f+n/f-n)	-(2fn/f-n)
            //   0			0				-1					 0

            // this matrix was calculated by hand via glMatrix.perspective(75, 16 / 9, 0.1, 300.0, pMatrix)
            // to get a reference matrix from plain WebGL
            var reference = new Matrix4<Dynamic>([
                0.7330642938613892, 0, 0, 0,
                0, 1.3032253980636597, 0, 0,
                0, 0, - 1.000666856765747, - 0.2000666856765747,
                0, 0, - 1, 0
            ]);

            assert.ok(matrixEquals4(reference, m, 0.000001));
        });

        QUnit.test('toJSON', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // OTHERS
        // TODO: clone is a camera methods that relied to copy method
        QUnit.test('clone', function(assert) {
            var near = 1,
                far = 3,
                aspect = 16 / 9,
                fov = 90;

            var cam = new PerspectiveCamera(fov, aspect, near, far);

            var clonedCam = cam.clone();

            assert.strictEqual(cam.fov, clonedCam.fov, 'fov is equal');
            assert.strictEqual(cam.aspect, clonedCam.aspect, 'aspect is equal');
            assert.strictEqual(cam.near, clonedCam.near, 'near is equal');
            assert.strictEqual(cam.far, clonedCam.far, 'far is equal');
            assert.strictEqual(cam.zoom, clonedCam.zoom, 'zoom is equal');
            assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
        });
    }
}