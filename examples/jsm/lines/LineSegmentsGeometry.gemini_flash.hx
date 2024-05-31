package ;

import three.Box3;
import three.Float32BufferAttribute;
import three.InstancedBufferGeometry;
import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Sphere;
import three.Vector3;
import three.WireframeGeometry;

class LineSegmentsGeometry extends InstancedBufferGeometry {

    public function new() {
        super();

        this.isLineSegmentsGeometry = true;

        this.type = 'LineSegmentsGeometry';

        var positions = [ - 1, 2, 0, 1, 2, 0, - 1, 1, 0, 1, 1, 0, - 1, 0, 0, 1, 0, 0, - 1, - 1, 0, 1, - 1, 0 ];
        var uvs = [ - 1, 2, 1, 2, - 1, 1, 1, 1, - 1, - 1, 1, - 1, - 1, - 2, 1, - 2 ];
        var index = [ 0, 2, 1, 2, 3, 1, 2, 4, 3, 4, 5, 3, 4, 6, 5, 6, 7, 5 ];

        this.setIndex( index );
        this.setAttribute( 'position', new Float32BufferAttribute( positions, 3 ) );
        this.setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );

    }

    public function applyMatrix4( matrix : three.Matrix4 ) : LineSegmentsGeometry {

        var start : InterleavedBufferAttribute = cast this.attributes.instanceStart;
        var end : InterleavedBufferAttribute = cast this.attributes.instanceEnd;

        if ( start != null ) {

            start.applyMatrix4( matrix );

            end.applyMatrix4( matrix );

            start.needsUpdate = true;

        }

        if ( this.boundingBox != null ) {

            this.computeBoundingBox();

        }

        if ( this.boundingSphere != null ) {

            this.computeBoundingSphere();

        }

        return this;

    }

    public function setPositions( array : Dynamic ) : LineSegmentsGeometry {

        var lineSegments : Float32Array;

        if ( array is Float32Array ) {

            lineSegments = cast array;

        } else if ( array is Array ) {

            lineSegments = new Float32Array( array );

        }

        var instanceBuffer = new InstancedInterleavedBuffer( lineSegments, 6, 1 ); // xyz, xyz

        this.setAttribute( 'instanceStart', new InterleavedBufferAttribute( instanceBuffer, 3, 0 ) ); // xyz
        this.setAttribute( 'instanceEnd', new InterleavedBufferAttribute( instanceBuffer, 3, 3 ) ); // xyz

        //

        this.computeBoundingBox();
        this.computeBoundingSphere();

        return this;

    }

    public function setColors( array : Dynamic ) : LineSegmentsGeometry {

        var colors : Float32Array;

        if ( array is Float32Array ) {

            colors = cast array;

        } else if ( array is Array ) {

            colors = new Float32Array( array );

        }

        var instanceColorBuffer = new InstancedInterleavedBuffer( colors, 6, 1 ); // rgb, rgb

        this.setAttribute( 'instanceColorStart', new InterleavedBufferAttribute( instanceColorBuffer, 3, 0 ) ); // rgb
        this.setAttribute( 'instanceColorEnd', new InterleavedBufferAttribute( instanceColorBuffer, 3, 3 ) ); // rgb

        return this;

    }

    public function fromWireframeGeometry( geometry : WireframeGeometry ) : LineSegmentsGeometry {

        this.setPositions( geometry.attributes.position.array );

        return this;

    }

    public function fromEdgesGeometry( geometry : Dynamic ) : LineSegmentsGeometry {

        this.setPositions( geometry.attributes.position.array );

        return this;

    }

    public function fromMesh( mesh : Dynamic ) : LineSegmentsGeometry {

        this.fromWireframeGeometry( new WireframeGeometry( mesh.geometry ) );

        // set colors, maybe

        return this;

    }

    public function fromLineSegments( lineSegments : Dynamic ) : LineSegmentsGeometry {

        var geometry = lineSegments.geometry;

        this.setPositions( geometry.attributes.position.array ); // assumes non-indexed

        // set colors, maybe

        return this;

    }

    override public function computeBoundingBox() : Void {

        if ( this.boundingBox == null ) {

            this.boundingBox = new Box3();

        }

        var start : InterleavedBufferAttribute = cast this.attributes.instanceStart;
        var end : InterleavedBufferAttribute = cast this.attributes.instanceEnd;

        if ( start != null && end != null ) {

            this.boundingBox.setFromBufferAttribute( start );

            _box.setFromBufferAttribute( end );

            this.boundingBox.union( _box );

        }

    }

    override public function computeBoundingSphere() : Void {

        if ( this.boundingSphere == null ) {

            this.boundingSphere = new Sphere();

        }

        if ( this.boundingBox == null ) {

            this.computeBoundingBox();

        }

        var start : InterleavedBufferAttribute = cast this.attributes.instanceStart;
        var end : InterleavedBufferAttribute = cast this.attributes.instanceEnd;

        if ( start != null && end != null ) {

            var center = this.boundingSphere.center;

            this.boundingBox.getCenter( center );

            var maxRadiusSq = 0.0;

            var il = start.count;
            for ( i in 0...il ) {

                _vector.fromBufferAttribute( start, i );
                maxRadiusSq = Math.max( maxRadiusSq, center.distanceToSquared( _vector ) );

                _vector.fromBufferAttribute( end, i );
                maxRadiusSq = Math.max( maxRadiusSq, center.distanceToSquared( _vector ) );

            }

            this.boundingSphere.radius = Math.sqrt( maxRadiusSq );

            if ( Math.isNaN( this.boundingSphere.radius ) ) {

                trace( 'THREE.LineSegmentsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this );

            }

        }

    }
    
    public function toJSON() : Dynamic {

        // todo
        return null;

    }

    public function applyMatrix( matrix : three.Matrix4 ) : LineSegmentsGeometry {

        trace( 'THREE.LineSegmentsGeometry: applyMatrix() has been renamed to applyMatrix4().' );

        return this.applyMatrix4( matrix );

    }

    static var _box = new Box3();
    static var _vector = new Vector3();

}