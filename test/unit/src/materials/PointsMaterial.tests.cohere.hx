import js.QUnit;
import js.PointsMaterial;
import js.Material;

class PointsMaterialTest {
    static function main() {
        QUnit.module( 'Materials', function() {
            QUnit.module( 'PointsMaterial', function() {
                // INHERITANCE
                QUnit.test( 'Extending', function( assert ) {
                    var object = new PointsMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'PointsMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test( 'Instancing', function( assert ) {
                    var object = new PointsMaterial();
                    assert.ok( object, 'Can instantiate a PointsMaterial.' );
                });

                // PROPERTIES
                QUnit.test( 'type', function( assert ) {
                    var object = new PointsMaterial();
                    assert.equal(
                        object.type, 'PointsMaterial',
                        'PointsMaterial.type should be PointsMaterial'
                    );
                });

                QUnit.todo( 'color', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                QUnit.todo( 'map', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                QUnit.todo( 'alphaMap', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                QUnit.todo( 'size', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                QUnit.todo( 'sizeAttenuation', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                QUnit.todo( 'fog', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });

                // PUBLIC
                QUnit.test( 'isPointsMaterial', function( assert ) {
                    var object = new PointsMaterial();
                    assert.ok(
                        object.isPointsMaterial,
                        'PointsMaterial.isPointsMaterial should be true'
                    );
                });

                QUnit.todo( 'copy', function( assert ) {
                    assert.ok( false, 'everything\'s gonna be alright' );
                });
            });
        });
    }
}