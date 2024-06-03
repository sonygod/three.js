import three.core.BufferGeometry;
import three.core.InstancedBufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.InstancedBufferAttribute;
import three.math.Box3;
import three.math.Sphere;
import three.math.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {

    public var isInstancedPointsGeometry:Bool = true;
    public var type:String = "InstancedPointsGeometry";

    public function new() {
        super();
        var positions = [-1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var uvs = [-1, 1, 1, 1, -1, -1, 1, -1];
        var index = [0, 2, 1, 2, 3, 1];

        this.setIndex(index);
        this.setAttribute('position', new Float32BufferAttribute(positions, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function applyMatrix4(matrix:three.math.Matrix4):InstancedPointsGeometry {
        var pos = this.getAttribute('instancePosition');
        if (pos != null) {
            pos.applyMatrix4(matrix);
            pos.needsUpdate = true;
        }
        if (this.boundingBox != null) {
            this.computeBoundingBox();
        }
        if (this.boundingSphere != null) {
            this.computeBoundingSphere();
        }
        return this;
    }

    public function setPositions(array:Dynamic):InstancedPointsGeometry {
        var points:Float32Array;
        if (Std.is(array, Float32Array)) {
            points = array;
        } else if (Std.is(array, Array)) {
            points = new Float32Array(cast array);
        }
        this.setAttribute('instancePosition', new InstancedBufferAttribute(points, 3));
        this.computeBoundingBox();
        this.computeBoundingSphere();
        return this;
    }

    public function setColors(array:Dynamic):InstancedPointsGeometry {
        var colors:Float32Array;
        if (Std.is(array, Float32Array)) {
            colors = array;
        } else if (Std.is(array, Array)) {
            colors = new Float32Array(cast array);
        }
        this.setAttribute('instanceColor', new InstancedBufferAttribute(colors, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }
        var pos = this.getAttribute('instancePosition');
        if (pos != null) {
            this.boundingBox.setFromBufferAttribute(pos);
        }
    }

    public function computeBoundingSphere():Void {
        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }
        if (this.boundingBox == null) {
            this.computeBoundingBox();
        }
        var pos = this.getAttribute('instancePosition');
        if (pos != null) {
            var center = this.boundingSphere.center;
            this.boundingBox.getCenter(center);
            var maxRadiusSq:Float = 0;
            for (i in 0...pos.count) {
                var _vector = new Vector3();
                _vector.fromBufferAttribute(pos, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }
            this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
            if (Math.isNaN(this.boundingSphere.radius)) {
                console.error('THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this);
            }
        }
    }

    public function toJSON():Dynamic {
        // todo
        return null;
    }
}