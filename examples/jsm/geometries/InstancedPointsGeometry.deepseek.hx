import three.Box3;
import three.Float32BufferAttribute;
import three.InstancedBufferGeometry;
import three.InstancedBufferAttribute;
import three.Sphere;
import three.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {

	var isInstancedPointsGeometry:Bool = true;
	var type:String = 'InstancedPointsGeometry';
	var _vector:Vector3 = new Vector3();

	public function new() {

		super();

		var positions = [ - 1, 1, 0, 1, 1, 0, - 1, - 1, 0, 1, - 1, 0 ];
		var uvs = [ - 1, 1, 1, 1, - 1, - 1, 1, - 1 ];
		var index = [ 0, 2, 1, 2, 3, 1 ];

		this.setIndex( index );
		this.setAttribute( 'position', new Float32BufferAttribute( positions, 3 ) );
		this.setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );

	}

	public function applyMatrix4( matrix:three.Matrix4 ):InstancedPointsGeometry {

		var pos = this.attributes.instancePosition;

		if ( pos !== null ) {

			pos.applyMatrix4( matrix );

			pos.needsUpdate = true;

		}

		if ( this.boundingBox !== null ) {

			this.computeBoundingBox();

		}

		if ( this.boundingSphere !== null ) {

			this.computeBoundingSphere();

		}

		return this;

	}

	public function setPositions( array:Array<Float> ):InstancedPointsGeometry {

		var points:Float32Array = array;

		this.setAttribute( 'instancePosition', new InstancedBufferAttribute( points, 3 ) ); // xyz

		this.computeBoundingBox();
		this.computeBoundingSphere();

		return this;

	}

	public function setColors( array:Array<Float> ):InstancedPointsGeometry {

		var colors:Float32Array = array;

		this.setAttribute( 'instanceColor', new InstancedBufferAttribute( colors, 3 ) ); // rgb

		return this;

	}

	public function computeBoundingBox():Void {

		if ( this.boundingBox === null ) {

			this.boundingBox = new Box3();

		}

		var pos = this.attributes.instancePosition;

		if ( pos !== null ) {

			this.boundingBox.setFromBufferAttribute( pos );

		}

	}

	public function computeBoundingSphere():Void {

		if ( this.boundingSphere === null ) {

			this.boundingSphere = new Sphere();

		}

		if ( this.boundingBox === null ) {

			this.computeBoundingBox();

		}

		var pos = this.attributes.instancePosition;

		if ( pos !== null ) {

			var center = this.boundingSphere.center;

			this.boundingBox.getCenter( center );

			var maxRadiusSq = 0;

			for ( i in 0...pos.count ) {

				_vector.fromBufferAttribute( pos, i );
				maxRadiusSq = Math.max( maxRadiusSq, center.distanceToSquared( _vector ) );

			}

			this.boundingSphere.radius = Math.sqrt( maxRadiusSq );

			if ( isNaN( this.boundingSphere.radius ) ) {

				trace( 'THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this );

			}

		}

	}

	public function toJSON():Dynamic {

		// todo

	}

}