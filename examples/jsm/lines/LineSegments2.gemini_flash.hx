import three.Box3;
import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Line3;
import three.MathUtils;
import three.Matrix4;
import three.Mesh;
import three.Sphere;
import three.Vector3;
import three.Vector4;
import three.cameras.Camera;
import three.core.Object3D;
import three.geometries.LineSegmentsGeometry;
import three.materials.LineMaterial;
import three.math.Ray;
import three.renderers.WebGLRenderer;

class LineSegments2 extends Mesh {

	static var _viewport = new Vector4();

	static var _start = new Vector3();
	static var _end = new Vector3();

	static var _start4 = new Vector4();
	static var _end4 = new Vector4();

	static var _ssOrigin = new Vector4();
	static var _ssOrigin3 = new Vector3();
	static var _mvMatrix = new Matrix4();
	static var _line = new Line3();
	static var _closestPoint = new Vector3();

	static var _box = new Box3();
	static var _sphere = new Sphere();
	static var _clipToWorldVector = new Vector4();

	static var _ray:Ray;
	static var _lineWidth:Float;

	// Returns the margin required to expand by in world space given the distance from the camera,
	// line width, resolution, and camera projection
	static function getWorldSpaceHalfWidth( camera:Camera, distance:Float, resolution:Vector2 ):Float {

		// transform into clip space, adjust the x and y values by the pixel width offset, then
		// transform back into world space to get world offset. Note clip space is [-1, 1] so full
		// width does not need to be halved.
		_clipToWorldVector.set( 0, 0, - distance, 1.0 ).applyMatrix4( camera.projectionMatrix );
		_clipToWorldVector.multiplyScalar( 1.0 / _clipToWorldVector.w );
		_clipToWorldVector.x = _lineWidth / resolution.x;
		_clipToWorldVector.y = _lineWidth / resolution.y;
		_clipToWorldVector.applyMatrix4( camera.projectionMatrixInverse );
		_clipToWorldVector.multiplyScalar( 1.0 / _clipToWorldVector.w );

		return Math.abs( Math.max( _clipToWorldVector.x, _clipToWorldVector.y ) );

	}

	static function raycastWorldUnits( lineSegments:LineSegments2, intersects:Array<Dynamic> ) {

		var matrixWorld = lineSegments.matrixWorld;
		var geometry:LineSegmentsGeometry = cast lineSegments.geometry;
		var instanceStart = geometry.attributes.instanceStart;
		var instanceEnd = geometry.attributes.instanceEnd;
		var segmentCount = Math.min( geometry.instanceCount, instanceStart.count );

		for ( i in 0...segmentCount ) {

			_line.start.fromBufferAttribute( instanceStart, i );
			_line.end.fromBufferAttribute( instanceEnd, i );

			_line.applyMatrix4( matrixWorld );

			var pointOnLine = new Vector3();
			var point = new Vector3();

			_ray.distanceSqToSegment( _line.start, _line.end, point, pointOnLine );
			var isInside = point.distanceTo( pointOnLine ) < _lineWidth * 0.5;

			if ( isInside ) {

				intersects.push( {
					point: point,
					pointOnLine: pointOnLine,
					distance: _ray.origin.distanceTo( point ),
					object: lineSegments,
					face: null,
					faceIndex: i,
					uv: null,
					uv1: null,
				} );

			}

		}

	}

	static function raycastScreenSpace( lineSegments:LineSegments2, camera:Camera, intersects:Array<Dynamic> ) {

		var projectionMatrix = camera.projectionMatrix;
		var material:LineMaterial = cast lineSegments.material;
		var resolution = material.resolution;
		var matrixWorld = lineSegments.matrixWorld;

		var geometry:LineSegmentsGeometry = cast lineSegments.geometry;
		var instanceStart = geometry.attributes.instanceStart;
		var instanceEnd = geometry.attributes.instanceEnd;
		var segmentCount = Math.min( geometry.instanceCount, instanceStart.count );

		var near = - camera.near;

		//

		// pick a point 1 unit out along the ray to avoid the ray origin
		// sitting at the camera origin which will cause "w" to be 0 when
		// applying the projection matrix.
		_ray.at( 1, _ssOrigin );

		// ndc space [ - 1.0, 1.0 ]
		_ssOrigin.w = 1;
		_ssOrigin.applyMatrix4( camera.matrixWorldInverse );
		_ssOrigin.applyMatrix4( projectionMatrix );
		_ssOrigin.multiplyScalar( 1 / _ssOrigin.w );

		// screen space
		_ssOrigin.x *= resolution.x / 2;
		_ssOrigin.y *= resolution.y / 2;
		_ssOrigin.z = 0;

		_ssOrigin3.copy( _ssOrigin );

		_mvMatrix.multiplyMatrices( camera.matrixWorldInverse, matrixWorld );

		for ( i in 0...segmentCount ) {

			_start4.fromBufferAttribute( instanceStart, i );
			_end4.fromBufferAttribute( instanceEnd, i );

			_start4.w = 1;
			_end4.w = 1;

			// camera space
			_start4.applyMatrix4( _mvMatrix );
			_end4.applyMatrix4( _mvMatrix );

			// skip the segment if it's entirely behind the camera
			var isBehindCameraNear = _start4.z > near && _end4.z > near;
			if ( isBehindCameraNear ) {

				continue;

			}

			// trim the segment if it extends behind camera near
			if ( _start4.z > near ) {

				var deltaDist = _start4.z - _end4.z;
				var t = ( _start4.z - near ) / deltaDist;
				_start4.lerp( _end4, t );

			} else if ( _end4.z > near ) {

				var deltaDist = _end4.z - _start4.z;
				var t = ( _end4.z - near ) / deltaDist;
				_end4.lerp( _start4, t );

			}

			// clip space
			_start4.applyMatrix4( projectionMatrix );
			_end4.applyMatrix4( projectionMatrix );

			// ndc space [ - 1.0, 1.0 ]
			_start4.multiplyScalar( 1 / _start4.w );
			_end4.multiplyScalar( 1 / _end4.w );

			// screen space
			_start4.x *= resolution.x / 2;
			_start4.y *= resolution.y / 2;

			_end4.x *= resolution.x / 2;
			_end4.y *= resolution.y / 2;

			// create 2d segment
			_line.start.copy( _start4 );
			_line.start.z = 0;

			_line.end.copy( _end4 );
			_line.end.z = 0;

			// get closest point on ray to segment
			var param = _line.closestPointToPointParameter( _ssOrigin3, true );
			_line.at( param, _closestPoint );

			// check if the intersection point is within clip space
			var zPos = MathUtils.lerp( _start4.z, _end4.z, param );
			var isInClipSpace = zPos >= - 1 && zPos <= 1;

			var isInside = _ssOrigin3.distanceTo( _closestPoint ) < _lineWidth * 0.5;

			if ( isInClipSpace && isInside ) {

				_line.start.fromBufferAttribute( instanceStart, i );
				_line.end.fromBufferAttribute( instanceEnd, i );

				_line.start.applyMatrix4( matrixWorld );
				_line.end.applyMatrix4( matrixWorld );

				var pointOnLine = new Vector3();
				var point = new Vector3();

				_ray.distanceSqToSegment( _line.start, _line.end, point, pointOnLine );

				intersects.push( {
					point: point,
					pointOnLine: pointOnLine,
					distance: _ray.origin.distanceTo( point ),
					object: lineSegments,
					face: null,
					faceIndex: i,
					uv: null,
					uv1: null,
				} );

			}

		}

	}

	public function new( geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial( { color: Math.random() * 0xffffff } ) ) {

		super( geometry, material );

		this.isLineSegments2 = true;

		this.type = 'LineSegments2';

	}

	// for backwards-compatibility, but could be a method of LineSegmentsGeometry...

	public function computeLineDistances():LineSegments2 {

		var geometry:LineSegmentsGeometry = cast this.geometry;

		var instanceStart = geometry.attributes.instanceStart;
		var instanceEnd = geometry.attributes.instanceEnd;
		var lineDistances = new Float32Array( 2 * instanceStart.count );

		var j = 0;
		for ( i in 0...instanceStart.count ) {

			_start.fromBufferAttribute( instanceStart, i );
			_end.fromBufferAttribute( instanceEnd, i );

			lineDistances[ j ] = ( j == 0 ) ? 0 : lineDistances[ j - 1 ];
			lineDistances[ j + 1 ] = lineDistances[ j ] + _start.distanceTo( _end );
			j += 2;
		}

		var instanceDistanceBuffer = new InstancedInterleavedBuffer( lineDistances, 2, 1 ); // d0, d1

		geometry.setAttribute( 'instanceDistanceStart', new InterleavedBufferAttribute( instanceDistanceBuffer, 1, 0 ) ); // d0
		geometry.setAttribute( 'instanceDistanceEnd', new InterleavedBufferAttribute( instanceDistanceBuffer, 1, 1 ) ); // d1

		return this;

	}

	public function raycast( raycaster:Raycaster, intersects:Array<Intersection> ) {

		var worldUnits = (cast this.material:LineMaterial).worldUnits;
		var camera = raycaster.camera;

		if ( camera == null && ! worldUnits ) {

			trace( 'LineSegments2: "Raycaster.camera" needs to be set in order to raycast against LineSegments2 while worldUnits is set to false.' );

		}

		var threshold = ( raycaster.params.Line2 != null ) ? raycaster.params.Line2.threshold : 0;

		_ray = raycaster.ray;

		var matrixWorld = this.matrixWorld;
		var geometry = this.geometry;
		var material:LineMaterial = cast this.material;

		_lineWidth = material.linewidth + threshold;

		// check if we intersect the sphere bounds
		if ( geometry.boundingSphere == null ) {

			geometry.computeBoundingSphere();

		}

		_sphere.copy( geometry.boundingSphere ).applyMatrix4( matrixWorld );

		// increase the sphere bounds by the worst case line screen space width
		var sphereMargin:Float;
		if ( worldUnits ) {

			sphereMargin = _lineWidth * 0.5;

		} else {

			var distanceToSphere = Math.max( camera.near, _sphere.distanceToPoint( _ray.origin ) );
			sphereMargin = getWorldSpaceHalfWidth( camera, distanceToSphere, material.resolution );

		}

		_sphere.radius += sphereMargin;

		if ( ! _ray.intersectsSphere( _sphere ) ) {

			return;

		}

		// check if we intersect the box bounds
		if ( geometry.boundingBox == null ) {

			geometry.computeBoundingBox();

		}

		_box.copy( geometry.boundingBox ).applyMatrix4( matrixWorld );

		// increase the box bounds by the worst case line width
		var boxMargin:Float;
		if ( worldUnits ) {

			boxMargin = _lineWidth * 0.5;

		} else {

			var distanceToBox = Math.max( camera.near, _box.distanceToPoint( _ray.origin ) );
			boxMargin = getWorldSpaceHalfWidth( camera, distanceToBox, material.resolution );

		}

		_box.expandByScalar( boxMargin );

		if ( ! _ray.intersectsBox( _box ) ) {

			return;

		}

		if ( worldUnits ) {

			raycastWorldUnits( this, intersects );

		} else {

			raycastScreenSpace( this, camera, intersects );

		}

	}

	public function onBeforeRender( renderer:WebGLRenderer, scene:Scene, camera:Camera, geometry:Geometry, material:Material, group:Group ) {

		var uniforms = (cast this.material:LineMaterial).uniforms;

		if ( uniforms != null && uniforms.resolution != null ) {

			renderer.getViewport( _viewport );
			uniforms.resolution.value.set( _viewport.z, _viewport.w );

		}

	}

}

typedef Intersection = {
	point:Vector3,
	pointOnLine:Vector3,
	distance:Float,
	object:Object3D,
	face:Null<Face3>,
	faceIndex:Int,
	uv:Null<Vector2>,
	uv1:Null<Vector2>
}