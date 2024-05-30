import js.QUnit;
import js. Skeleton;

class SkeletonTest {
    public static function main() {
        QUnit.module( 'Objects', function() {
            QUnit.module( 'Skeleton', function() {
                // INSTANCING
                QUnit.test( 'Instancing', function() {
                    var object = new Skeleton();
                    QUnit.ok( object, 'Can instantiate a Skeleton.' );
                } );

                // PROPERTIES
                QUnit.todo( 'uuid', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'bones', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'boneInverses', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'boneMatrices', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'boneTexture', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'frame', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                // PUBLIC
                QUnit.todo( 'init', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'calculateInverses', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'pose', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'update', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'clone', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'computeBoneTexture', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'getBoneByName', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.test( 'dispose', function() {
                    QUnit.expect( 0 );
                    var object = new Skeleton();
                    object.dispose();
                } );

                QUnit.todo( 'fromJSON', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );

                QUnit.todo( 'toJSON', function() {
                    QUnit.ok( false, 'everything\'s gonna be alright' );
                } );
            } );
        } );
    }
}