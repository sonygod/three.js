import three.cameras.CubeCamera;
import three.core.Object3D;

class CubeCameraTests {
    public function new() {}

    public function testAll() {
        // INHERITANCE
        UT.Helper.test("CubeCamera extends from Object3D", function(assert) {
            var object = new CubeCamera();
            assert.isTrue(Std.is(object, Object3D), 'CubeCamera extends from Object3D');
        });

        // INSTANCING
        UT.Helper.test("Can instantiate a CubeCamera.", function(assert) {
            var object = new CubeCamera();
            assert.notNull(object, 'Can instantiate a CubeCamera.');
        });

        // PROPERTIES
        UT.Helper.test("CubeCamera.type should be CubeCamera", function(assert) {
            var object = new CubeCamera();
            assert.equals(object.type, 'CubeCamera', 'CubeCamera.type should be CubeCamera');
        });

        // TODO: renderTarget
        UT.Helper.todo("RendererTarget", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        UT.Helper.todo("update", function(assert) {
            // update( renderer, scene )
            assert.fail("everything's gonna be alright");
        });
    }
}