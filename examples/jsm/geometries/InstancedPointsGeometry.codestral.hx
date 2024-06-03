import three.core.BufferAttribute;
import three.core.InstancedBufferAttribute;
import three.core.InstancedBufferGeometry;
import three.math.Box3;
import three.math.Sphere;
import three.math.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {

    private var _vector:Vector3 = new Vector3();

    public function new() {
        super();
        this.isInstancedPointsGeometry = true;
        this.type = 'InstancedPointsGeometry';

        var positions:Array<Float> = [-1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var uvs:Array<Float> = [-1, 1, 1, 1, -1, -1, 1, -1];
        var index:Array<Int> = [0, 2, 1, 2, 3, 1];

        this.setIndex(index);
        this.setAttribute('position', new BufferAttribute(positions, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));
    }

    public function applyMatrix4(matrix:Matrix4):InstancedPointsGeometry {
        var pos = this.attributes['instancePosition'];

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

    public function setPositions(array:Array<Float>):InstancedPointsGeometry {
        var points:Float32Array;

        if (Std.isOfType(array, Float32Array)) {
            points = array as Float32Array;
        } else if (Std.isOfType(array, Array)) {
            points = new Float32Array(array as Array<Float>);
        }

        this.setAttribute('instancePosition', new InstancedBufferAttribute(points, 3));

        this.computeBoundingBox();
        this.computeBoundingSphere();

        return this;
    }

    public function setColors(array:Array<Float>):InstancedPointsGeometry {
        var colors:Float32Array;

        if (Std.isOfType(array, Float32Array)) {
            colors = array as Float32Array;
        } else if (Std.isOfType(array, Array)) {
            colors = new Float32Array(array as Array<Float>);
        }

        this.setAttribute('instanceColor', new InstancedBufferAttribute(colors, 3));

        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }

        var pos = this.attributes['instancePosition'];

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

        var pos = this.attributes['instancePosition'];

        if (pos != null) {
            var center = this.boundingSphere.center;
            this.boundingBox.getCenter(center);

            var maxRadiusSq:Float = 0;

            for (var i:Int = 0; i < pos.count; i++) {
                _vector.fromBufferAttribute(pos, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }

            this.boundingSphere.radius = Math.sqrt(maxRadiusSq);

            if (isNaN(this.boundingSphere.radius)) {
                trace('THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.');
            }
        }
    }

    // TODO: toJSON method
}