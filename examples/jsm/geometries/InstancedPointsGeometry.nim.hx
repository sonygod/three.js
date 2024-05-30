import three.js.extras.core.InstancedBufferGeometry;
import three.js.math.Vector3;
import three.js.math.Box3;
import three.js.math.Sphere;
import three.js.core.BufferAttribute;
import three.js.extras.core.InstancedBufferAttribute;

class InstancedPointsGeometry extends InstancedBufferGeometry {
    public var isInstancedPointsGeometry:Bool = true;
    public var type:String = 'InstancedPointsGeometry';

    public function new() {
        super();

        var positions:Array<Float> = [ -1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0 ];
        var uvs:Array<Float> = [ -1, 1, 1, 1, -1, -1, 1, -1 ];
        var index:Array<Int> = [ 0, 2, 1, 2, 3, 1 ];

        this.setIndex( index );
        this.setAttribute( 'position', new Float32BufferAttribute( positions, 3 ) );
        this.setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );
    }

    public function applyMatrix4( matrix:three.js.math.Matrix4 ) {
        var pos:BufferAttribute = this.attributes.instancePosition;

        if ( pos != null ) {
            pos.applyMatrix4( matrix );
            pos.needsUpdate = true;
        }

        if ( this.boundingBox != null ) {
            this.computeBoundingBox();
        }

        if ( this.boundingSphere != null ) {
            this.computeBoundingSphere();
        }

        return this;
    }

    public function setPositions( array:Array<Float> ) {
        var points:Float32Array;

        if ( array is Float32Array ) {
            points = array;
        } else if ( array is Array<Float> ) {
            points = new Float32Array( array );
        }

        this.setAttribute( 'instancePosition', new InstancedBufferAttribute( points, 3 ) ); // xyz

        this.computeBoundingBox();
        this.computeBoundingSphere();

        return this;
    }

    public function setColors( array:Array<Float> ) {
        var colors:Float32Array;

        if ( array is Float32Array ) {
            colors = array;
        } else if ( array is Array<Float> ) {
            colors = new Float32Array( array );
        }

        this.setAttribute( 'instanceColor', new InstancedBufferAttribute( colors, 3 ) ); // rgb

        return this;
    }

    public function computeBoundingBox() {
        if ( this.boundingBox == null ) {
            this.boundingBox = new Box3();
        }

        var pos:BufferAttribute = this.attributes.instancePosition;

        if ( pos != null ) {
            this.boundingBox.setFromBufferAttribute( pos );
        }
    }

    public function computeBoundingSphere() {
        if ( this.boundingSphere == null ) {
            this.boundingSphere = new Sphere();
        }

        if ( this.boundingBox == null ) {
            this.computeBoundingBox();
        }

        var pos:BufferAttribute = this.attributes.instancePosition;

        if ( pos != null ) {
            var center:Vector3 = this.boundingSphere.center;

            this.boundingBox.getCenter( center );

            var maxRadiusSq:Float = 0;

            for ( i in 0...pos.count ) {
                var _vector:Vector3 = new Vector3();
                _vector.fromBufferAttribute( pos, i );
                maxRadiusSq = Math.max( maxRadiusSq, center.distanceToSquared( _vector ) );
            }

            this.boundingSphere.radius = Math.sqrt( maxRadiusSq );

            if ( isNaN( this.boundingSphere.radius ) ) {
                trace( 'THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this );
            }
        }
    }

    public function toJSON() {
        // todo
    }
}