package three.js.geomtries;

import three.js.BufferAttribute;
import three.js.Box3;
import three.js.Float32BufferAttribute;
import three.js.InstancedBufferAttribute;
import three.js.InstancedBufferGeometry;
import three.js.Sphere;
import three.js.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {
    public var isInstancedPointsGeometry:Bool = true;
    public var type:String = 'InstancedPointsGeometry';

    public function new() {
        super();
        var positions:Array<Float> = [-1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
        var uvs:Array<Float> = [-1, 1, 1, 1, -1, -1, 1, -1];
        var index:Array<Int> = [0, 2, 1, 2, 3, 1];

        this.setIndex(index);
        this.setAttribute('position', new Float32BufferAttribute(positions, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function applyMatrix4(matrix:Matrix4):InstancedPointsGeometry {
        var pos:InstancedBufferAttribute = this.attributes.get('instancePosition');
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
        var points:Array<Float>;
        if (Std.is(array, Float32Array)) {
            points = array;
        } else {
            points = new Float32Array(array);
        }
        this.setAttribute('instancePosition', new InstancedBufferAttribute(points, 3));
        this.computeBoundingBox();
        this.computeBoundingSphere();
        return this;
    }

    public function setColors(array:Array<Float>):InstancedPointsGeometry {
        var colors:Array<Float>;
        if (Std.is(array, Float32Array)) {
            colors = array;
        } else {
            colors = new Float32Array(array);
        }
        this.setAttribute('instanceColor', new InstancedBufferAttribute(colors, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }
        var pos:InstancedBufferAttribute = this.attributes.get('instancePosition');
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
        var pos:InstancedBufferAttribute = this.attributes.get('instancePosition');
        if (pos != null) {
            var center:Vector3 = this.boundingSphere.center;
            this.boundingBox.getCenter(center);
            var maxRadiusSq:Float = 0;
            for (i in 0...pos.count) {
                var vector:Vector3 = _vector.fromBufferAttribute(pos, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(vector));
            }
            this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
            if (Math.isNaN(this.boundingSphere.radius)) {
                trace('THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this);
            }
        }
    }

    public function toJSON():Dynamic {
        // todo
        return null;
    }
}