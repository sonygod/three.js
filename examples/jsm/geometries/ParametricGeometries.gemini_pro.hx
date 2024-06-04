import three.extras.core.Curve;
import three.math.Vector3;
import three.geometries.ParametricGeometry;

/**
 * Experimenting of primitive geometry creation using Surface Parametric equations
 */

class ParametricGeometries {

  public static function klein( v:Float, u:Float, target:Vector3 ) : Void {

    u *= Math.PI;
    v *= 2 * Math.PI;

    u = u * 2;
    var x:Float, z:Float;
    if ( u < Math.PI ) {

      x = 3 * Math.cos( u ) * ( 1 + Math.sin( u ) ) + ( 2 * ( 1 - Math.cos( u ) / 2 ) ) * Math.cos( u ) * Math.cos( v );
      z = - 8 * Math.sin( u ) - 2 * ( 1 - Math.cos( u ) / 2 ) * Math.sin( u ) * Math.cos( v );

    } else {

      x = 3 * Math.cos( u ) * ( 1 + Math.sin( u ) ) + ( 2 * ( 1 - Math.cos( u ) / 2 ) ) * Math.cos( v + Math.PI );
      z = - 8 * Math.sin( u );

    }

    var y:Float = - 2 * ( 1 - Math.cos( u ) / 2 ) * Math.sin( v );

    target.set( x, y, z );

  }

  public static function plane( width:Float, height:Float ) : ( u:Float, v:Float, target:Vector3 ) -> Void {

    return function ( u:Float, v:Float, target:Vector3 ) {

      var x:Float = u * width;
      var y:Float = 0;
      var z:Float = v * height;

      target.set( x, y, z );

    };

  }

  public static function mobius( u:Float, t:Float, target:Vector3 ) : Void {

    // flat mobius strip
    // http://www.wolframalpha.com/input/?i=M%C3%B6bius+strip+parametric+equations&lk=1&a=ClashPrefs_*Surface.MoebiusStrip.SurfaceProperty.ParametricEquations-
    u = u - 0.5;
    var v:Float = 2 * Math.PI * t;

    var a:Float = 2;

    var x:Float = Math.cos( v ) * ( a + u * Math.cos( v / 2 ) );
    var y:Float = Math.sin( v ) * ( a + u * Math.cos( v / 2 ) );
    var z:Float = u * Math.sin( v / 2 );

    target.set( x, y, z );

  }

  public static function mobius3d( u:Float, t:Float, target:Vector3 ) : Void {

    // volumetric mobius strip

    u *= Math.PI;
    t *= 2 * Math.PI;

    u = u * 2;
    var phi:Float = u / 2;
    var major:Float = 2.25, a:Float = 0.125, b:Float = 0.65;

    var x:Float = a * Math.cos( t ) * Math.cos( phi ) - b * Math.sin( t ) * Math.sin( phi );
    var z:Float = a * Math.cos( t ) * Math.sin( phi ) + b * Math.sin( t ) * Math.cos( phi );
    var y:Float = ( major + x ) * Math.sin( u );
    x = ( major + x ) * Math.cos( u );

    target.set( x, y, z );

  }

}


/*********************************************
 *
 * Parametric Replacement for TubeGeometry
 *
 *********************************************/

class TubeGeometry extends ParametricGeometry {

  public var tangents:Array<Vector3>;
  public var normals:Array<Vector3>;
  public var binormals:Array<Vector3>;

  public var path:Curve;
  public var segments:Int;
  public var radius:Float;
  public var segmentsRadius:Int;
  public var closed:Bool;

  public function new( path:Curve, segments:Int = 64, radius:Float = 1, segmentsRadius:Int = 8, closed:Bool = false ) {

    var numpoints:Int = segments + 1;

    var frames = path.computeFrenetFrames( segments, closed );
    tangents = frames.tangents;
    normals = frames.normals;
    binormals = frames.binormals;

    var position:Vector3 = new Vector3();

    function ParametricTube( u:Float, v:Float, target:Vector3 ):Void {

      v *= 2 * Math.PI;

      var i:Int = Math.floor( u * ( numpoints - 1 ) );

      path.getPointAt( u, position );

      var normal:Vector3 = normals[ i ];
      var binormal:Vector3 = binormals[ i ];

      var cx:Float = - radius * Math.cos( v ); // TODO: Hack: Negating it so it faces outside.
      var cy:Float = radius * Math.sin( v );

      position.x += cx * normal.x + cy * binormal.x;
      position.y += cx * normal.y + cy * binormal.y;
      position.z += cx * normal.z + cy * binormal.z;

      target.copy( position );

    }

    super( ParametricTube, segments, segmentsRadius );

    // proxy internals

    this.path = path;
    this.segments = segments;
    this.radius = radius;
    this.segmentsRadius = segmentsRadius;
    this.closed = closed;

  }

}


/*********************************************
  *
  * Parametric Replacement for TorusKnotGeometry
  *
  *********************************************/

class TorusKnotGeometry extends TubeGeometry {

  public var radius:Float;
  public var tube:Float;
  public var segmentsT:Int;
  public var segmentsR:Int;
  public var p:Int;
  public var q:Int;

  public function new( radius:Float = 200, tube:Float = 40, segmentsT:Int = 64, segmentsR:Int = 8, p:Int = 2, q:Int = 3 ) {

    class TorusKnotCurve extends Curve {

      public function getPoint( t:Float, optionalTarget:Vector3 = new Vector3() ) : Vector3 {

        var point:Vector3 = optionalTarget;

        t *= Math.PI * 2;

        var r:Float = 0.5;

        var x:Float = ( 1 + r * Math.cos( q * t ) ) * Math.cos( p * t );
        var y:Float = ( 1 + r * Math.cos( q * t ) ) * Math.sin( p * t );
        var z:Float = r * Math.sin( q * t );

        return point.set( x, y, z ).multiplyScalar( radius );

      }

    }

    var segments:Int = segmentsT;
    var radiusSegments:Int = segmentsR;
    var extrudePath:TorusKnotCurve = new TorusKnotCurve();

    super( extrudePath, segments, tube, radiusSegments, true, false );

    this.radius = radius;
    this.tube = tube;
    this.segmentsT = segmentsT;
    this.segmentsR = segmentsR;
    this.p = p;
    this.q = q;

  }

}

/*********************************************
  *
  * Parametric Replacement for SphereGeometry
  *
  *********************************************/

class SphereGeometry extends ParametricGeometry {

  public function new( size:Float, u:Int, v:Int ) {

    function sphere( u:Float, v:Float, target:Vector3 ):Void {

      u *= Math.PI;
      v *= 2 * Math.PI;

      var x:Float = size * Math.sin( u ) * Math.cos( v );
      var y:Float = size * Math.sin( u ) * Math.sin( v );
      var z:Float = size * Math.cos( u );

      target.set( x, y, z );

    }

    super( sphere, u, v );

  }

}


/*********************************************
  *
  * Parametric Replacement for PlaneGeometry
  *
  *********************************************/

class PlaneGeometry extends ParametricGeometry {

  public function new( width:Float, depth:Float, segmentsWidth:Int, segmentsDepth:Int ) {

    function plane( u:Float, v:Float, target:Vector3 ):Void {

      var x:Float = u * width;
      var y:Float = 0;
      var z:Float = v * depth;

      target.set( x, y, z );

    }

    super( plane, segmentsWidth, segmentsDepth );

  }

}

class ParametricGeometries {

  public static var TubeGeometry:Class<TubeGeometry> = TubeGeometry;
  public static var TorusKnotGeometry:Class<TorusKnotGeometry> = TorusKnotGeometry;
  public static var SphereGeometry:Class<SphereGeometry> = SphereGeometry;
  public static var PlaneGeometry:Class<PlaneGeometry> = PlaneGeometry;

  public static function klein( v:Float, u:Float, target:Vector3 ) : Void {

    u *= Math.PI;
    v *= 2 * Math.PI;

    u = u * 2;
    var x:Float, z:Float;
    if ( u < Math.PI ) {

      x = 3 * Math.cos( u ) * ( 1 + Math.sin( u ) ) + ( 2 * ( 1 - Math.cos( u ) / 2 ) ) * Math.cos( u ) * Math.cos( v );
      z = - 8 * Math.sin( u ) - 2 * ( 1 - Math.cos( u ) / 2 ) * Math.sin( u ) * Math.cos( v );

    } else {

      x = 3 * Math.cos( u ) * ( 1 + Math.sin( u ) ) + ( 2 * ( 1 - Math.cos( u ) / 2 ) ) * Math.cos( v + Math.PI );
      z = - 8 * Math.sin( u );

    }

    var y:Float = - 2 * ( 1 - Math.cos( u ) / 2 ) * Math.sin( v );

    target.set( x, y, z );

  }

  public static function plane( width:Float, height:Float ) : ( u:Float, v:Float, target:Vector3 ) -> Void {

    return function ( u:Float, v:Float, target:Vector3 ) {

      var x:Float = u * width;
      var y:Float = 0;
      var z:Float = v * height;

      target.set( x, y, z );

    };

  }

  public static function mobius( u:Float, t:Float, target:Vector3 ) : Void {

    // flat mobius strip
    // http://www.wolframalpha.com/input/?i=M%C3%B6bius+strip+parametric+equations&lk=1&a=ClashPrefs_*Surface.MoebiusStrip.SurfaceProperty.ParametricEquations-
    u = u - 0.5;
    var v:Float = 2 * Math.PI * t;

    var a:Float = 2;

    var x:Float = Math.cos( v ) * ( a + u * Math.cos( v / 2 ) );
    var y:Float = Math.sin( v ) * ( a + u * Math.cos( v / 2 ) );
    var z:Float = u * Math.sin( v / 2 );

    target.set( x, y, z );

  }

  public static function mobius3d( u:Float, t:Float, target:Vector3 ) : Void {

    // volumetric mobius strip

    u *= Math.PI;
    t *= 2 * Math.PI;

    u = u * 2;
    var phi:Float = u / 2;
    var major:Float = 2.25, a:Float = 0.125, b:Float = 0.65;

    var x:Float = a * Math.cos( t ) * Math.cos( phi ) - b * Math.sin( t ) * Math.sin( phi );
    var z:Float = a * Math.cos( t ) * Math.sin( phi ) + b * Math.sin( t ) * Math.cos( phi );
    var y:Float = ( major + x ) * Math.sin( u );
    x = ( major + x ) * Math.cos( u );

    target.set( x, y, z );

  }

}