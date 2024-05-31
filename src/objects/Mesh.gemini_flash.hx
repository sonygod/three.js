import three.core.Object3D;
import three.math.Vector3;
import three.math.Vector2;
import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.math.Triangle;
import three.core.BufferGeometry;
import three.materials.MeshBasicMaterial;
import three.objects.Mesh;
import three.core.Face;
import three.core.Intersection;
import three.materials.Side;

class Mesh extends Object3D {

    public static var _inverseMatrix:Matrix4 = new Matrix4();
    public static var _ray:Ray = new Ray();
    public static var _sphere:Sphere = new Sphere();
    public static var _sphereHitAt:Vector3 = new Vector3();

    public static var _vA:Vector3 = new Vector3();
    public static var _vB:Vector3 = new Vector3();
    public static var _vC:Vector3 = new Vector3();

    public static var _tempA:Vector3 = new Vector3();
    public static var _morphA:Vector3 = new Vector3();

    public static var _uvA:Vector2 = new Vector2();
    public static var _uvB:Vector2 = new Vector2();
    public static var _uvC:Vector2 = new Vector2();

    public static var _normalA:Vector3 = new Vector3();
    public static var _normalB:Vector3 = new Vector3();
    public static var _normalC:Vector3 = new Vector3();

    public static var _intersectionPoint:Vector3 = new Vector3();
    public static var _intersectionPointWorld:Vector3 = new Vector3();

	public var isMesh:Bool = true;

	public var geometry(default, null):BufferGeometry;
	public var material(default, null):Dynamic; // can be Material or Array<Material>

	public var morphTargetInfluences:Array<Float>;
	public var morphTargetDictionary:Map<String, Int>;

	public function new( geometry:BufferGeometry = null, material:Dynamic = null ) {

		super();

		this.geometry = ( geometry != null ) ? geometry : new BufferGeometry();
		this.material = ( material != null ) ? material : new MeshBasicMaterial();

		this.updateMorphTargets();

	}

	override public function copy( source:Mesh, recursive:Bool = true ):Mesh {

		super.copy( source, recursive );

		if ( source.morphTargetInfluences != null ) {

			this.morphTargetInfluences = source.morphTargetInfluences.slice(0);

		}

		if ( source.morphTargetDictionary != null ) {

			this.morphTargetDictionary = new Map<String, Int>();
            for (key in source.morphTargetDictionary.keys()) {
                this.morphTargetDictionary.set(key, source.morphTargetDictionary.get(key));
            }

		}

		this.material = ( Std.isOfType(source.material, Array) ) ? ( source.material as Array<Dynamic>).slice(0) : source.material;
		this.geometry = source.geometry;

		return this;

	}

	public function updateMorphTargets():Void {

		var geometry = this.geometry;

		var morphAttributes = geometry.morphAttributes;
        if (morphAttributes != null) {
            var keys = morphAttributes.keys();
    
            if ( keys.length > 0 ) {
    
                var morphAttribute = morphAttributes.get(keys[0]);
    
                if ( morphAttribute != null ) {
    
                    this.morphTargetInfluences = [];
                    this.morphTargetDictionary = new Map<String, Int>();
    
                    for ( m in 0...morphAttribute.length ) {
    
                        var name:String = ( morphAttribute[ m ].name != null ) ? morphAttribute[ m ].name : Std.string(m);
    
                        this.morphTargetInfluences.push( 0 );
                        this.morphTargetDictionary.set( name, m );
    
                    }
    
                }
    
            }
        }

	}

	public function getVertexPosition( index:Int, target:Vector3 ):Vector3 {

		var geometry:BufferGeometry = this.geometry;
		var position = geometry.attributes.get("position");
		var morphPosition = ( geometry.morphAttributes != null ) ? geometry.morphAttributes.get("position") : null;
		var morphTargetsRelative = geometry.morphTargetsRelative;

        if (position != null) {
            target.fromBufferAttribute( position, index );
        }

		var morphInfluences = this.morphTargetInfluences;

		if ( morphPosition != null && morphInfluences != null ) {

			_morphA.set( 0, 0, 0 );

			for ( i in 0...morphPosition.length ) {

				var influence = morphInfluences[ i ];
				var morphAttribute = morphPosition[ i ];

				if ( influence == 0 ) continue;

				_tempA.fromBufferAttribute( morphAttribute, index );

				if ( morphTargetsRelative ) {

					_morphA.addScaledVector( _tempA, influence );

				} else {

					_morphA.addScaledVector( _tempA.sub( target ), influence );

				}

			}

			target.add( _morphA );

		}

		return target;

	}

	public function raycast( raycaster:Dynamic, intersects:Array<Intersection> ):Void {

		var geometry = this.geometry;
		var material = this.material;
		var matrixWorld = this.matrixWorld;

		if ( material == null ) return;

		// test with bounding sphere in world space

		if ( geometry.boundingSphere == null ) geometry.computeBoundingSphere();

		_sphere.copy( geometry.boundingSphere );
		_sphere.applyMatrix4( matrixWorld );

		// check distance from ray origin to bounding sphere

		_ray.copy( raycaster.ray ).recast( raycaster.near );

		if ( !_sphere.containsPoint( _ray.origin ) ) {

			if ( _ray.intersectSphere( _sphere, _sphereHitAt ) == null ) return;

			if ( _ray.origin.distanceToSquared( _sphereHitAt ) > ( raycaster.far - raycaster.near ) * ( raycaster.far - raycaster.near ) ) return;

		}

		// convert ray to local space of mesh

		_inverseMatrix.copy( matrixWorld ).invert();
		_ray.copy( raycaster.ray ).applyMatrix4( _inverseMatrix );

		// test with bounding box in local space

		if ( geometry.boundingBox != null ) {

			if ( !_ray.intersectsBox( geometry.boundingBox ) ) return;

		}

		// test for intersections with geometry

		this._computeIntersections( raycaster, intersects, _ray );

	}

	function _computeIntersections( raycaster:Dynamic, intersects:Array<Intersection>, rayLocalSpace:Ray ):Void {

		var intersection:Intersection = null;

		var geometry:BufferGeometry = this.geometry;
		var material = this.material;

		var index = geometry.index;
		var position = geometry.attributes.get( "position" );
		var uv = geometry.attributes.get( "uv" );
		var uv1 = geometry.attributes.get( "uv1" );
		var normal = geometry.attributes.get( "normal" );
		var groups = geometry.groups;
		var drawRange = geometry.drawRange;

		if ( index != null ) {

			// indexed buffer geometry

			if ( Std.isOfType(material, Array) ) {

                var materials:Array<Dynamic> = cast material;
				for ( i in 0...groups.length ) {

					var group = groups[ i ];
					var groupMaterial = materials[ group.materialIndex ];

					var start = Std.int(Math.max( group.start, drawRange.start ));
					var end = Std.int(Math.min( index.count, Math.min( ( group.start + group.count ), ( drawRange.start + drawRange.count ) ) ));

					for ( j in start...end step 3 ) {

						var a = index.getX( j );
						var b = index.getX( j + 1 );
						var c = index.getX( j + 2 );

						intersection = checkGeometryIntersection( this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

						if ( intersection != null ) {

                            intersection.faceIndex = Std.int(j / 3); // triangle number in indexed buffer semantics
							intersection.face.materialIndex = group.materialIndex;
							intersects.push( intersection );

						}

					}

				}

			} else {

				var start = Std.int(Math.max( 0, drawRange.start ));
				var end = Std.int(Math.min( index.count, ( drawRange.start + drawRange.count ) ));

				for ( i in start...end step 3 ) {

					var a = index.getX( i );
					var b = index.getX( i + 1 );
					var c = index.getX( i + 2 );

					intersection = checkGeometryIntersection( this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

					if ( intersection != null ) {

                        intersection.faceIndex = Std.int(i / 3); // triangle number in indexed buffer semantics
						intersects.push( intersection );

					}

				}

			}

		} else if ( position != null ) {

			// non-indexed buffer geometry

			if ( Std.isOfType(material, Array) ) {

                var materials:Array<Dynamic> = cast material;
				for ( i in 0...groups.length ) {

					var group = groups[ i ];
					var groupMaterial = materials[ group.materialIndex ];

					var start = Std.int(Math.max( group.start, drawRange.start ));
					var end = Std.int(Math.min( position.count, Math.min( ( group.start + group.count ), ( drawRange.start + drawRange.count ) ) ));

					for ( j in start...end step 3 ) {

						var a = j;
						var b = j + 1;
						var c = j + 2;

						intersection = checkGeometryIntersection( this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

						if ( intersection != null ) {

                            intersection.faceIndex = Std.int(j / 3); // triangle number in non-indexed buffer semantics
							intersection.face.materialIndex = group.materialIndex;
							intersects.push( intersection );

						}

					}

				}

			} else {

				var start = Std.int(Math.max( 0, drawRange.start ));
				var end = Std.int(Math.min( position.count, ( drawRange.start + drawRange.count ) ));

				for ( i in start...end step 3 ) {

					var a = i;
					var b = i + 1;
					var c = i + 2;

					intersection = checkGeometryIntersection( this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

					if ( intersection != null ) {

                        intersection.faceIndex = Std.int(i / 3); // triangle number in non-indexed buffer semantics
						intersects.push( intersection );

					}

				}

			}

		}

	}

	public static function checkIntersection( object:Mesh, material:Dynamic, raycaster:Dynamic, ray:Ray, pA:Vector3, pB:Vector3, pC:Vector3, point:Vector3 ):Intersection {

		var intersect:Vector3;

		if ( material.side == Side.BackSide ) {

			intersect = ray.intersectTriangle( pC, pB, pA, true, point );

		} else {

			intersect = ray.intersectTriangle( pA, pB, pC, ( material.side == Side.FrontSide ), point );

		}

		if ( intersect == null ) return null;

		_intersectionPointWorld.copy( point );
		_intersectionPointWorld.applyMatrix4( object.matrixWorld );

		var distance = raycaster.ray.origin.distanceTo( _intersectionPointWorld );

		if ( distance < raycaster.near || distance > raycaster.far ) return null;

		return {
			distance: distance,
			point: _intersectionPointWorld.clone(),
			object: object
		};

	}

	public static function checkGeometryIntersection( object:Mesh, material:Dynamic, raycaster:Dynamic, ray:Ray, uv:Dynamic, uv1:Dynamic, normal:Dynamic, a:Int, b:Int, c:Int ):Intersection {

		object.getVertexPosition( a, _vA );
		object.getVertexPosition( b, _vB );
		object.getVertexPosition( c, _vC );

		var intersection = checkIntersection( object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint );

		if ( intersection != null ) {

			if ( uv != null ) {

				_uvA.fromBufferAttribute( uv, a );
				_uvB.fromBufferAttribute( uv, b );
				_uvC.fromBufferAttribute( uv, c );

				intersection.uv = Triangle.getInterpolation( _intersectionPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2() );

			}

			if ( uv1 != null ) {

				_uvA.fromBufferAttribute( uv1, a );
				_uvB.fromBufferAttribute( uv1, b );
				_uvC.fromBufferAttribute( uv1, c );

				intersection.uv1 = Triangle.getInterpolation( _intersectionPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2() );

			}

			if ( normal != null ) {

				_normalA.fromBufferAttribute( normal, a );
				_normalB.fromBufferAttribute( normal, b );
				_normalC.fromBufferAttribute( normal, c );

				intersection.normal = Triangle.getInterpolation( _intersectionPoint, _vA, _vB, _vC, _normalA, _normalB, _normalC, new Vector3() );

				if ( intersection.normal.dot( ray.direction ) > 0 ) {

					intersection.normal.multiplyScalar( - 1 );

				}

			}

            intersection.face = new Face();
			Triangle.getNormal( _vA, _vB, _vC, intersection.face.normal );
            intersection.face.a = a;
            intersection.face.b = b;
            intersection.face.c = c;

		}

		return intersection;

	}

}