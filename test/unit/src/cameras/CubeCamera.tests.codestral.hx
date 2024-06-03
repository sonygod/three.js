import js.Browser.document;
import qunit.QUnit;
import three.src.cameras.CubeCamera;
import three.src.core.Object3D;

QUnit.module("Cameras", function() {
    QUnit.module("CubeCamera", function() {

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var object = new CubeCamera(0.1, 1000, 512);
            assert.strictEqual(Std.is(object, Object3D), true, 'CubeCamera extends from Object3D');
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var object = new CubeCamera(0.1, 1000, 512);
            assert.ok(object != null, 'Can instantiate a CubeCamera.');
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var object = new CubeCamera(0.1, 1000, 512);
            assert.ok(object.type == "CubeCamera", 'CubeCamera.type should be CubeCamera');
        });

        // TODO: Uncomment when renderTarget property is implemented
        /*
        QUnit.todo("renderTarget", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
        */

        // TODO: Uncomment when update method is implemented
        /*
        QUnit.todo("update", function(assert) {
            // update( renderer, scene )
            assert.ok(false, 'everything\'s gonna be alright');
        });
        */
    });
});