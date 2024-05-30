import js.QUnit;
import js.StereoCamera;

class TestStereoCamera {
    static function main() {
        QUnit.module( "Cameras", function() {
            QUnit.module( "StereoCamera", function() {
                // INSTANCING
                QUnit.test( "Instancing", function( assert ) {
                    var object = new StereoCamera();
                    assert.ok( object, "Can instantiate a StereoCamera." );
                } );

                // PROPERTIES
                QUnit.test( "type", function( assert ) {
                    var object = new StereoCamera();
                    assert.ok(
                        object.type == "StereoCamera",
                        "StereoCamera.type should be StereoCamera"
                    );
                } );

                QUnit.todo( "aspect", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );

                QUnit.todo( "eyeSep", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );

                QUnit.todo( "cameraL", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );

                QUnit.todo( "cameraR", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );

                // PUBLIC
                QUnit.todo( "update", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );
            } );
        } );
    }
}

TestStereoCamera.main();