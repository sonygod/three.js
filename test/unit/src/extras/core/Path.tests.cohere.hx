import js.QUnit;

import js.extras.core.Path;
import js.extras.core.CurvePath;

class TestExtras {
    public static function main() {
        QUnit.module( 'Extras', function() {
            QUnit.module( 'Core', function() {
                QUnit.module( 'Path', function() {
                    // INHERITANCE
                    QUnit.test( 'Extending', function( assert ) {
                        var object = new Path();
                        assert.strictEqual( Std.is(object, CurvePath), true, 'Path extends from CurvePath' );
                    } );

                    // INSTANCING
                    QUnit.test( 'Instancing', function( assert ) {
                        var object = new Path();
                        assert.ok( object, 'Can instantiate a Path.' );
                    } );

                    // PROPERTIES
                    QUnit.test( 'type', function( assert ) {
                        var object = new Path();
                        assert.ok( object.type == 'Path', 'Path.type should be Path' );
                    } );

                    QUnit.todo( 'currentPoint', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    // PUBLIC
                    QUnit.todo( 'setFromPoints', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'moveTo', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'lineTo', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'quadraticCurveTo', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'bezierCurveTo', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'splineThru', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'arc', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'absarc', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'ellipse', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'absellipse', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'copy', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'toJSON', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );

                    QUnit.todo( 'fromJSON', function( assert ) {
                        assert.ok( false, 'everything\'s gonna be alright' );
                    } );
                } );
            } );
        } );
    }
}