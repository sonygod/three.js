package three.test.unit.src.cameras;

import three.cameras.CubeCamera;
import three.core.Object3D;

class CubeCameraTests {
    public function new() {}

    public function test_cubeCamera() {
        // INHERITANCE
        UT.assertEqual(Type.enumEq(Type.getClass(new CubeCamera()), Object3D), true, 'CubeCamera extends from Object3D');

        // INSTANCING
        var object = new CubeCamera();
        UT.ok(object != null, 'Can instantiate a CubeCamera.');

        // PROPERTIES
        var object = new CubeCamera();
        UT.assertEqual(object.type, 'CubeCamera', 'CubeCamera.type should be CubeCamera');

        // TODO: renderTarget
        UT.fail('everything\'s gonna be alright');

        // PUBLIC
        // TODO: update
        UT.fail('everything\'s gonna be alright');
    }
}