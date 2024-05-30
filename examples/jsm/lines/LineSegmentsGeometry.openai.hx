package three.js.examples.jsm.lines;

import three.Box3;
import three.Float32BufferAttribute;
import three.InstancedBufferGeometry;
import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Sphere;
import three.Vector3;
import three.WireframeGeometry;

class LineSegmentsGeometry extends InstancedBufferGeometry {
    public var isLineSegmentsGeometry:Bool = true;
    public var type:String = 'LineSegmentsGeometry';

    public function new() {
        super();
        var positions:Array<Float> = [
            -1, 2, 0, 1, 2, 0, -1, 1, 0, 1, 1, 0, -1, 0, 0, 1, 0, 0, -1, -1, 0, 1, -1, 0
        ];
        var uvs:Array<Float> = [
            -1, 2, 1, 2, -1, 1, 1, 1, -1, -1, 1, -1, -1, -2, 1, -2
        ];
        var index:Array<Int> = [
            0, 2, 1, 2, 3, 1, 2, 4, 3, 4, 5, 3, 4, 6, 5, 6, 7, 5
        ];

        setIndex(index);
        setAttribute('position', new Float32BufferAttribute(positions, 3));
        setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function applyMatrix4(matrix:Matrix4):LineSegmentsGeometry {
        var start:InstancedBufferAttribute = attributes.get('instanceStart');
        var end:InstancedBufferAttribute = attributes.get('instanceEnd');

        if (start != null) {
            start.applyMatrix4(matrix);
            end.applyMatrix4(matrix);
            start.needsUpdate = true;
        }

        if (boundingBox != null) {
            computeBoundingBox();
        }

        if (boundingSphere != null) {
            computeBoundingSphere();
        }

        return this;
    }

    public function setPositions(array:Array<Float>):LineSegmentsGeometry {
        var lineSegments:Float32Array;
        if (Std.isOfType(array, Float32Array)) {
            lineSegments = array;
        } else if (Std.isOfType(array, Array<Float>)) {
            lineSegments = new Float32Array(array);
        }

        var instanceBuffer:InstancedInterleavedBuffer = new InstancedInterleavedBuffer(lineSegments, 6, 1);
        setAttribute('instanceStart', new InterleavedBufferAttribute(instanceBuffer, 3, 0));
        setAttribute('instanceEnd', new InterleavedBufferAttribute(instanceBuffer, 3, 3));

        computeBoundingBox();
        computeBoundingSphere();

        return this;
    }

    public function setColors(array:Array<Float>):LineSegmentsGeometry {
        var colors:Float32Array;
        if (Std.isOfType(array, Float32Array)) {
            colors = array;
        } else if (Std.isOfType(array, Array<Float>)) {
            colors = new Float32Array(array);
        }

        var instanceColorBuffer:InstancedInterleavedBuffer = new InstancedInterleavedBuffer(colors, 6, 1);
        setAttribute('instanceColorStart', new InterleavedBufferAttribute(instanceColorBuffer, 3, 0));
        setAttribute('instanceColorEnd', new InterleavedBufferAttribute(instanceColorBuffer, 3, 3));

        return this;
    }

    public function fromWireframeGeometry(geometry:WireframeGeometry):LineSegmentsGeometry {
        setPositions(geometry.attributes.position.array);
        return this;
    }

    public function fromEdgesGeometry(geometry:Geometry):LineSegmentsGeometry {
        setPositions(geometry.attributes.position.array);
        return this;
    }

    public function fromMesh(mesh:Mesh):LineSegmentsGeometry {
        fromWireframeGeometry(new WireframeGeometry(mesh.geometry));
        return this;
    }

    public function fromLineSegments(lineSegments:LineSegments):LineSegmentsGeometry {
        var geometry:Geometry = lineSegments.geometry;
        setPositions(geometry.attributes.position.array);
        return this;
    }

    public function computeBoundingBox():Void {
        if (boundingBox == null) {
            boundingBox = new Box3();
        }

        var start:InstancedBufferAttribute = attributes.get('instanceStart');
        var end:InstancedBufferAttribute = attributes.get('instanceEnd');

        if (start != null && end != null) {
            boundingBox.setFromBufferAttribute(start);
            _box.setFromBufferAttribute(end);
            boundingBox.union(_box);
        }
    }

    public function computeBoundingSphere():Void {
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }

        if (boundingBox == null) {
            computeBoundingBox();
        }

        var start:InstancedBufferAttribute = attributes.get('instanceStart');
        var end:InstancedBufferAttribute = attributes.get('instanceEnd');

        if (start != null && end != null) {
            var center:Vector3 = boundingSphere.center;
            boundingBox.getCenter(center);

            var maxRadiusSq:Float = 0;

            for (i in 0...start.count) {
                _vector.fromBufferAttribute(start, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));

                _vector.fromBufferAttribute(end, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }

            boundingSphere.radius = Math.sqrt(maxRadiusSq);

            if (Math.isNaN(boundingSphere.radius)) {
                trace('THREE.LineSegmentsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.', this);
            }
        }
    }

    public function toJSON():Void {
        // todo
    }

    public function applyMatrix(matrix:Matrix4):LineSegmentsGeometry {
        trace('THREE.LineSegmentsGeometry: applyMatrix() has been renamed to applyMatrix4().');
        return applyMatrix4(matrix);
    }
}