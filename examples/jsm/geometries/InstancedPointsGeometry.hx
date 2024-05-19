package three.js.examples.jm.geometries;

import three.js.lib.Box3;
import three.js.lib.Float32BufferAttribute;
import three.js.lib.InstancedBufferAttribute;
import three.js.lib.InstancedBufferGeometry;
import three.js.lib.Sphere;
import three.js.lib.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {

    public var isInstancedPointsGeometry:Bool = true;

    public var type:String = 'InstancedPointsGeometry';

    public function new() {
        super();

        var positions:Array<Float> = [ -1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0 ];
        var uvs:Array<Float> = [ -1, 1, 1, 1, -1, -1, 1, -1 ];
        var index:Array<Int> = [ 0, 2, 1, 2, 3, 1 ];

        setIndex( index );
        setAttribute( 'position', new Float32BufferAttribute( positions, 3 ) );
        setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );
    }

    public function applyMatrix4( matrix:Matrix4 ):InstancedPointsGeometry {
        var pos:InstancedBufferAttribute = attributes.get('instancePosition');

        if (pos != null) {
            pos.applyMatrix4( matrix );
            pos.needsUpdate = true;
        }

        if (boundingBox != null) {
            computeBoundingBox();
        }

        if (boundingSphere != null) {
            computeBoundingSphere();
        }

        return this;
    }

    public function setPositions( array:Array<Float> ):InstancedPointsGeometry {
        var points:Array<Float>;

        if (Std.isOfType(array, Float32Array)) {
            points = array;
        } else if (Std.isOfType(array, Array)) {
            points = Float32Array.fromArray(array);
        }

        setAttribute( 'instancePosition', new InstancedBufferAttribute( points, 3 ) );

        computeBoundingBox();
        computeBoundingSphere();

        return this;
    }

    public function setColors( array:Array<Float> ):InstancedPointsGeometry {
        var colors:Array<Float>;

        if (Std.isOfType(array, Float32Array)) {
            colors = array;
        } else if (Std.isOfType(array, Array)) {
            colors = Float32Array.fromArray(array);
        }

        setAttribute( 'instanceColor', new InstancedBufferAttribute( colors, 3 ) );

        return this;
    }

    public function computeBoundingBox():Void {
        if (boundingBox == null) {
            boundingBox = new Box3();
        }

        var pos:InstancedBufferAttribute = attributes.get('instancePosition');

        if (pos != null) {
            boundingBox.setFromBufferAttribute( pos );
        }
    }

    public function computeBoundingSphere():Void {
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }

        if (boundingBox == null) {
            computeBoundingBox();
        }

        var pos:InstancedBufferAttribute = attributes.get('instancePosition');

        if (pos != null) {
            var center:Vector3 = boundingSphere.center;
            boundingBox.getCenter( center );

            var maxRadiusSq:Float = 0;

            for (i in 0...pos.count) {
                _vector.fromBufferAttribute( pos, i );
                maxRadiusSq = Math.max( maxRadiusSq, center.distanceToSquared( _vector ) );
            }

            boundingSphere.radius = Math.sqrt( maxRadiusSq );

            if (Math.isNaN( boundingSphere.radius )) {
                trace( 'THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this );
            }
        }
    }

    public function toJSON():Void {
        // todo
    }

    static public function main() {
        // todo
    }
}