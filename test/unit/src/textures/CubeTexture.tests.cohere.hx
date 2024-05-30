import js.QUnit;
import js.Browser.window;

import openfl.display.CubeTexture;
import openfl.display.Texture;

class TestCubeTexture {
    public static function main() {
        QUnit.module( "Textures", function() {
            QUnit.module( "CubeTexture", function() {
                // INHERITANCE
                QUnit.test( "Extending", function( assert ) {
                    var object = new CubeTexture();
                    assert.strictEqual( object instanceof Texture, true, "CubeTexture extends from Texture" );
                } );

                // INSTANCING
                QUnit.test( "Instancing", function( assert ) {
                    var object = new CubeTexture();
                    assert.ok( object, "Can instantiate a CubeTexture." );
                } );

                // PROPERTIES
                QUnit.todo( "images", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );

                QUnit.todo( "flipY", function( assert ) {
                    assert.ok( false, "everything's gonna be alright" );
                } );

                // PUBLIC
                QUnit.test( "isCubeTexture", function( assert ) {
                    var object = new CubeTexture();
                    assert.ok( object.isCubeTexture, "CubeTexture.isCubeTexture should be true" );
                } );
            } );
        } );
    }
}

TestCubeTexture.main();