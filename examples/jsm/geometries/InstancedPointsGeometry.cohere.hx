import js.three.Box3;
import js.three.BufferAttribute;
import js.three.Float32BufferAttribute;
import js.three.InstancedBufferAttribute;
import js.three.InstancedBufferGeometry;
import js.three.Sphere;
import js.three.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {
    public var isInstancedPointsGeometry:Bool = true;
    public var type:String = 'InstancedPointsGeometry';

    public function new() {
        super();

        var positions:Array<Float> = [-1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var uvs:Array<Float> = [-1, 1, 1, 1, -1, -1, 1, -1];
        var index:Array<Int> = [0, 2, 1, 2, 3, 1];

        setIndex(new js.three.BufferAttribute(index, 1));
        setAttribute('position', new Float32BufferAttribute(positions, 3));
        setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function applyMatrix4(matrix:Matrix4):InstancedPointsGeometry {
        var pos = getAttribute('instancePosition') as InstancedBufferAttribute;

        if (pos != null) {
            pos.applyMatrix4(matrix);
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

    public function setPositions(array:Float32Array):InstancedPointsGeometry {
        var points:Float32Array;

        if (array instanceof Float32Array) {
            points = array;
        } else if (Type.enumIndex(array) == Array<Float>) {
            points = new Float32Array(array);
        }

        setAttribute('instancePosition', new InstancedBufferAttribute(points, 3));

        computeBoundingBox();
        computeBoundingSphere();

        return this;
    }

    public function setColors(array:Float32Array):InstancedPointsGeometry {
        var colors:Float32Array;

        if (array instanceof Float32Array) {
            colors = array;
        } else if (Type.enumIndex(array) == Array<Float>) {
            colors = new Float32Array(array);
        }

        setAttribute('instanceColor', new InstancedBufferAttribute(colors, 3));

        return this;
    }

    public function computeBoundingBox():Void {
        if (boundingBox == null) {
            boundingBox = new Box3();
        }

        var pos = getAttribute('instancePosition') as InstancedBufferAttribute;

        if (pos != null) {
            boundingBox.setFromBufferAttribute(pos);
        }
    }

    public function computeBoundingSphere():Void {
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }

        if (boundingBox == null) {
            computeBoundingBox();
        }

        var pos = getAttribute('instancePosition') as InstancedBufferAttribute;

        if (pos != null) {
            var center = boundingSphere.center;
            boundingBox.getCenter(center);

            var maxRadiusSq:Float = 0.0;
            var _vector = new Vector3();

            for (i in 0...pos.count) {
                _vector.fromBufferAttribute(pos, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }

            boundingSphere.radius = Math.sqrt(maxRadiusSq);

            if (isNaN(boundingSphere.radius)) {
                trace('InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.');
            }
        }
    }

    public function toJSON():Dynamic {
        // TODO: Implement toJSON()
    }
}

class Export {
    static public function __init__() {
        #if js
        js.three.InstancedPointsGeometry = InstancedPointsGeometry;
        #end
    }
}