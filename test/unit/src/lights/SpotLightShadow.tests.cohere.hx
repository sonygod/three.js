import js.QUnit;
import js.Object;

import js.Three.SpotLightShadow;
import js.Three.LightShadow;
import js.Three.SpotLight;
import js.Three.ObjectLoader;

class SpotLightShadowTest {
    public static function runTests() {
        QUnit.module( 'Lights', function() {
            QUnit.module( 'SpotLightShadow', function() {
                // INHERITANCE
                QUnit.test( 'Extending', function( assert ) {
                    var object = new SpotLightShadow();
                    assert.strictEqual(
                        Std.is(object, LightShadow), true,
                        'SpotLightShadow extends from LightShadow'
                    );
                });

                // INSTANCING
                QUnit.test( 'Instancing', function( assert ) {
                    var object = new SpotLightShadow();
                    assert.ok( object, 'Can instantiate a SpotLightShadow.' );
                });

                // PROPERTIES
                QUnit.todo( 'focus', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                // PUBLIC
                QUnit.test( 'isSpotLightShadow', function( assert ) {
                    var object = new SpotLightShadow();
                    assert.ok(
                        object.isSpotLightShadow,
                        'SpotLightShadow.isSpotLightShadow should be true'
                    );
                });

                QUnit.todo( 'updateMatrices', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                QUnit.todo( 'copy', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                // OTHERS
                QUnit.test( 'clone/copy', function( assert ) {
                    var a = new SpotLightShadow();
                    var b = new SpotLightShadow();

                    assert.notDeepEqual( a, b, 'Newly instanced shadows are not equal' );

                    var c = a.clone();
                    assert.smartEqual( a, c, 'Shadows are identical after clone()' );

                    c.mapSize.set( 256, 256 );
                    assert.notDeepEqual( a, c, 'Shadows are different again after change' );

                    b.copy( a );
                    assert.smartEqual( a, b, 'Shadows are identical after copy()' );

                    b.mapSize.set( 512, 512 );
                    assert.notDeepEqual( a, b, 'Shadows are different again after change' );
                });

                QUnit.test( 'toJSON', function( assert ) {
                    var light = new SpotLight();
                    var shadow = new SpotLightShadow();

                    shadow.bias = 10;
                    shadow.radius = 5;
                    shadow.mapSize.set( 128, 128 );
                    light.shadow = shadow;

                    var json = light.toJSON();
                    var newLight = new ObjectLoader().parse( json );

                    assert.smartEqual( newLight.shadow, light.shadow, 'Reloaded shadow is equal to the original one' );
                });
            });
        });
    }
}

SpotLightShadowTest.runTests();