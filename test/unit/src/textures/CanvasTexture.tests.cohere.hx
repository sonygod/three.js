import js.QUnit;
import js.CanvasTexture;
import js.Texture;

class TestCanvasTexture {
    static function run() {
        QUnit.module( 'Textures', function() {
            QUnit.module( 'CanvasTexture', function() {
                // INHERITANCE
                QUnit.test( 'Extending', function( assert ) {
                    var object = new CanvasTexture();
                    assert.strictEqual(
                        Std.is(object, Texture), true,
                        'CanvasTexture extends from Texture'
                    );
                } );

                // INSTANCING
                QUnit.test( 'Instancing', function( assert ) {
                    var object = new CanvasTexture();
                    assert.ok( object, 'Can instantiate a CanvasTexture.' );
                } );

                // PROPERTIES
                QUnit.todo( 'needsUpdate', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                } );

                // PUBLIC
                QUnit.test( 'isCanvasTexture', function( assert ) {
                    var object = new CanvasTexture();
                    assert.ok(
                        object.isCanvasTexture,
                        'CanvasTexture.isCanvasTexture should be true'
                    );
                } );
            } );
        } );
    }
}

TestCanvasTexture.run();