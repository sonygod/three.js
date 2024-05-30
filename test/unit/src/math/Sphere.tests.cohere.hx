import js.QUnit;
import js.math.Box3;
import js.math.Vector3;
import js.math.Sphere;
import js.math.Plane;
import js.math.Matrix4;

class MathTest {
    public static function run():Void {
        QUnit.module( 'Maths' );

        QUnit.module( 'Sphere' );

        // INSTANCING
        QUnit.test( 'Instancing', function() {
            var a = new Sphere();
            QUnit.ok( a.center.equals( Vector3.zero() ), 'Passed!' );
            QUnit.ok( a.radius == -1, 'Passed!' );

            a = new Sphere( Vector3.one().clone(), 1 );
            QUnit.ok( a.center.equals( Vector3.one() ), 'Passed!' );
            QUnit.ok( a.radius == 1, 'Passed!' );
        } );

        // PUBLIC
        QUnit.test( 'isSphere', function() {
            var a = new Sphere();
            QUnit.ok( a.isSphere, 'Passed!' );

            var b = new Box3();
            QUnit.ok( !b.isSphere, 'Passed!' );
        } );

        QUnit.test( 'set', function() {
            var a = new Sphere();
            QUnit.ok( a.center.equals( Vector3.zero() ), 'Passed!' );
            QUnit.ok( a.radius == -1, 'Passed!' );

            a.set( Vector3.one(), 1 );
            QUnit.ok( a.center.equals( Vector3.one() ), 'Passed!' );
            QUnit.ok( a.radius == 1, 'Passed!' );
        } );

        QUnit.test( 'setFromPoints', function() {
            var a = new Sphere();
            var expectedCenter = new Vector3( 0.9330126941204071, 0, 0 );
            var expectedRadius = 1.3676668773461689;
            var optionalCenter = new Vector3( 1, 1, 1 );
            var points = [
                new Vector3( 1, 1, 0 ), new Vector3( 1, 1, 0 ),
                new Vector3( 1, 1, 0 ), new Vector3( 1, 1, 0 ),
                new Vector3( 1, 1, 0 ), new Vector3( 0.8660253882408142, 0.5, 0 ),
                new Vector3( 0, 0.5, 0.8660253882408142 ), new Vector3( 1.8660253882408142, 0.5, 0 ),
                new Vector3( 0, 0.5, -0.8660253882408142 ), new Vector3( 0.8660253882408142, 0.5, 0 ),
                new Vector3( 0.8660253882408142, -0.5, 0 ), new Vector3( 0, -0.5, 0.8660253882408142 ),
                new Vector3( 1.8660253882408142, -0.5, 0 ), new Vector3( 0, -0.5, -0.8660253882408142 ),
                new Vector3( 0.8660253882408142, -0.5, -0 ), new Vector3( 0, -1, 0 ),
                new Vector3( 0, -1, 0 ), new Vector3( 0, -1, 0 ),
                new Vector3( 0, -1, -0 ), new Vector3( 0, -1, -0 )
            ];

            a.setFromPoints( points );
            QUnit.ok( Math.abs(a.center.x - expectedCenter.x) <= Sphere.EPS, 'Default center: check center.x' );
            QUnit.ok( Math.abs(a.center.y - expectedCenter.y) <= Sphere.EPS, 'Default center: check center.y' );
            QUnit.ok( Math.abs(a.center.z - expectedCenter.z) <= Sphere.EPS, 'Default center: check center.z' );
            QUnit.ok( Math.abs(a.radius - expectedRadius) <= Sphere.EPS, 'Default center: check radius' );

            expectedRadius = 2.5946195770400102;
            a.setFromPoints( points, optionalCenter );
            QUnit.ok( Math.abs(a.center.x - optionalCenter.x) <= Sphere.EPS, 'Optional center: check center.x' );
            QUnit.ok( Math.abs(a.center.y - optionalCenter.y) <= Sphere.EPS, 'Optional center: check center.y' );
            QUnit.ok( Math.abs(a.center.z - optionalCenter.z) <= Sphere.EPS, 'Optional center: check center.z' );
            QUnit.ok( Math.abs(a.radius - expectedRadius) <= Sphere.EPS, 'Optional center: check radius' );
        } );

        QUnit.test( 'copy', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );
            var b = new Sphere().copy( a );

            QUnit.ok( b.center.equals( Vector3.one() ), 'Passed!' );
            QUnit.ok( b.radius == 1, 'Passed!' );

            // ensure that it is a true copy
            a.center = Vector3.zero();
            a.radius = 0;
            QUnit.ok( b.center.equals( Vector3.one() ), 'Passed!' );
            QUnit.ok( b.radius == 1, 'Passed!' );
        } );

        QUnit.test( 'isEmpty', function() {
            var a = new Sphere();
            QUnit.ok( a.isEmpty(), 'Passed!' );

            a.set( Vector3.one(), 1 );
            QUnit.ok( !a.isEmpty(), 'Passed!' );

            // Negative radius contains no points
            a.set( Vector3.one(), -1 );
            QUnit.ok( a.isEmpty(), 'Passed!' );

            // Zero radius contains only the center point
            a.set( Vector3.one(), 0 );
            QUnit.ok( !a.isEmpty(), 'Passed!' );
        } );

        QUnit.test( 'makeEmpty', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );

            QUnit.ok( !a.isEmpty(), 'Passed!' );

            a.makeEmpty();
            QUnit.ok( a.isEmpty(), 'Passed!' );
            QUnit.ok( a.center.equals( Vector3.zero() ), 'Passed!' );
        } );

        QUnit.test( 'containsPoint', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );

            QUnit.ok( !a.containsPoint( Vector3.zero() ), 'Passed!' );
            QUnit.ok( a.containsPoint( Vector3.one() ), 'Passed!' );

            a.set( Vector3.zero(), 0 );
            QUnit.ok( a.containsPoint( a.center ), 'Passed!' );
        } );

        QUnit.test( 'distanceToPoint', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );

            QUnit.ok( (a.distanceToPoint( Vector3.zero() ) - 0.7320) < 0.001, 'Passed!' );
            QUnit.ok( a.distanceToPoint( Vector3.one() ) == -1, 'Passed!' );
        } );

        QUnit.test( 'intersectsSphere', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );
            var b = new Sphere( Vector3.zero().clone(), 1 );
            var c = new Sphere( Vector3.zero().clone(), 0.25 );

            QUnit.ok( a.intersectsSphere( b ), 'Passed!' );
            QUnit.ok( !a.intersectsSphere( c ), 'Passed!' );
        } );

        QUnit.test( 'intersectsBox', function() {
            var a = new Sphere( Vector3.zero(), 1 );
            var b = new Sphere( new Vector3( -5, -5, -5 ), 1 );
            var box = new Box3( Vector3.zero(), Vector3.one() );

            QUnit.strictEqual( a.intersectsBox( box ), true, 'Check unit sphere' );
            QUnit.strictEqual( b.intersectsBox( box ), false, 'Check shifted sphere' );
        } );

        QUnit.test( 'intersectsPlane', function() {
            var a = new Sphere( Vector3.zero().clone(), 1 );
            var b = new Plane( new Vector3( 0, 1, 0 ), 1 );
            var c = new Plane( new Vector3( 0, 1, 0 ), 1.25 );
            var d = new Plane( new Vector3( 0, -1, 0 ), 1.25 );

            QUnit.ok( a.intersectsPlane( b ), 'Passed!' );
            QUnit.ok( !a.intersectsPlane( c ), 'Passed!' );
            QUnit.ok( !a.intersectsPlane( d ), 'Passed!' );
        } );

        QUnit.test( 'clampPoint', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );
            var point = new Vector3();

            a.clampPoint( new Vector3( 1, 1, 3 ), point );
            QUnit.ok( point.equals( new Vector3( 1, 1, 2 ) ), 'Passed!' );
            a.clampPoint( new Vector3( 1, 1, -3 ), point );
            QUnit.ok( point.equals( new Vector3( 1, 1, 0 ) ), 'Passed!' );
        } );

        QUnit.test( 'getBoundingBox', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );
            var aabb = new Box3();

            a.getBoundingBox( aabb );
            QUnit.ok( aabb.equals( new Box3( Vector3.zero(), Vector3.two() ) ), 'Passed!' );

            a.set( Vector3.zero(), 0 );
            a.getBoundingBox( aabb );
            QUnit.ok( aabb.equals( new Box3( Vector3.zero(), Vector3.zero() ) ), 'Passed!' );

            // Empty sphere produces empty bounding box
            a.makeEmpty();
            a.getBoundingBox( aabb );
            QUnit.ok( aabb.isEmpty(), 'Passed!' );
        } );

        QUnit.test( 'applyMatrix4', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );
            var m = new Matrix4().makeTranslation( 1, -2, 1 );
            var aabb1 = new Box3();
            var aabb2 = new Box3();

            a.clone().applyMatrix4( m ).getBoundingBox( aabb1 );
            a.getBoundingBox( aabb2 );

            QUnit.ok( aabb1.equals( aabb2.applyMatrix4( m ) ), 'Passed!' );
        } );

        QUnit.test( 'translate', function() {
            var a = new Sphere( Vector3.one().clone(), 1 );

            a.translate( Vector3.one().negate() );
            QUnit.ok( a.center.equals( Vector3.zero() ), 'Passed!' );
        } );

        QUnit.test( 'expandByPoint', function() {
            var a = new Sphere( Vector3.zero().clone(), 1 );
            var p = new Vector3( 2, 0, 0 );

            QUnit.ok( !a.containsPoint( p ), 'a does not contain p' );

            a.expandByPoint( p );

            QUnit.ok( a.containsPoint( p ), 'a does contain p' );
            QUnit.ok( a.center.equals( new Vector3( 0.5, 0, 0 ) ), 'Passed!' );
            QUnit.ok( a.radius == 1.5, 'Passed!' );
        } );

        QUnit.test( 'union', function() {
            var a = new Sphere( Vector3.zero().clone(), 1 );
            var b = new Sphere( new Vector3( 2, 0, 0 ), 1 );

            a.union( b );

            QUnit.ok( a.center.equals( new Vector3( 1, 0, 0 ) ), 'Passed!' );
            QUnit.ok( a.radius == 2, 'Passed!' );

            // d contains c (demonstrates why it is necessary to process two points in union)

            var c = new Sphere( new Vector3(), 1 );
            var d = new Sphere( new Vector3( 1, 0, 0 ), 4 );

            c.union( d );

            QUnit.ok( c.center.equals( new Vector3( 1, 0, 0 ) ), 'Passed!' );
            QUnit.ok( c.radius == 4, 'Passed!' );

            // edge case: both spheres have the same center point

            var e = new Sphere( new Vector3(), 1 );
            var f = new Sphere( new Vector3(), 4 );

            e.union( f );

            QUnit.ok( e.center.equals( new Vector3( 0, 0, 0 ) ), 'Passed!' );
            QUnit.ok( e.radius == 4, 'Passed!' );
        } );

        QUnit.test( 'equals', function() {
            var a = new Sphere();
            var b = new Sphere( new Vector3( 1, 0, 0 ) );
            var c = new Sphere( new Vector3( 1, 0, 0 ), 1.0 );

            QUnit.strictEqual( a.equals( b ), false, 'a does not equal b' );
            QUnit.strictEqual( a.equals( c ), false, 'a does not equal c' );
            QUnit.strictEqual( b.equals( c ), false, 'b does not equal c' );

            a.copy( b );
            QUnit.strictEqual( a.equals( b ), true, 'a equals b after copy()' );
        } );
    }
}

MathTest.run();