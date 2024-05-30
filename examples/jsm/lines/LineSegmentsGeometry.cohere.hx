import js.three.Box3;
import js.three.Float32BufferAttribute;
import js.three.InstancedBufferGeometry;
import js.three.InstancedInterleavedBuffer;
import js.three.InterleavedBufferAttribute;
import js.three.Sphere;
import js.three.Vector3;
import js.three.WireframeGeometry;

class LineSegmentsGeometry_ extends InstancedBufferGeometry {
    public var isLineSegmentsGeometry:Bool;
    public var type:String;

    public function new() {
        super();
        isLineSegmentsGeometry = true;
        type = "LineSegmentsGeometry";
        var positions:Array<Float> = [-1, 2, 0, 1, 2, 0, -1, 1, 0, 1, 1, 0, -1, 0, 0, 1, 0, 0, -1, -1, 0, 1, -1, 0];
        var uvs:Array<Float> = [-1, 2, 1, 2, -1, 1, 1, 1, -1, -1, 1, -1, -1, -2, 1, -2];
        var index:Array<Int> = [0, 2, 1, 2, 3, 1, 2, 4, 3, 4, 5, 3, 4, 6, 5, 6, 7, 5];
        setIndex(index);
        setAttribute("position", new Float32BufferAttribute(positions, 3));
        setAttribute("uv", new Float32BufferAttribute(uvs, 2));
    }

    public function applyMatrix4(matrix:Matrix4):InstancedBufferGeometry {
        var start = getAttribute("instanceStart");
        var end = getAttribute("instanceEnd");
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

    public function setPositions(array:Float32Array):InstancedBufferGeometry {
        var lineSegments:Float32Array;
        if (array instanceof Float32Array) {
            lineSegments = array;
        } else if (Array.isArray(array)) {
            lineSegments = new Float32Array(array);
        }
        var instanceBuffer = new InstancedInterleavedBuffer(lineSegments, 6, 1);
        setAttribute("instanceStart", new InterleavedBufferAttribute(instanceBuffer, 3, 0));
        setAttribute("instanceEnd", new InterleavedBufferAttribute(instanceBuffer, 3, 3));
        computeBoundingBox();
        computeBoundingSphere();
        return this;
    }

    public function setColors(array:Float32Array):InstancedBufferGeometry {
        var colors:Float32Array;
        if (array instanceof Float32Array) {
            colors = array;
        } else if (Array.isArray(array)) {
            colors = new Float32Array(array);
        }
        var instanceColorBuffer = new InstancedInterleavedBuffer(colors, 6, 1);
        setAttribute("instanceColorStart", new InterleavedBufferAttribute(instanceColorBuffer, 3, 0));
        setAttribute("instanceColorEnd", new InterleavedBufferAttribute(instanceColorBuffer, 3, 3));
        return this;
    }

    public function fromWireframeGeometry(geometry:WireframeGeometry):InstancedBufferGeometry {
        setPositions(geometry.getAttribute("position").array);
        return this;
    }

    public function fromEdgesGeometry(geometry:InstancedBufferGeometry):InstancedBufferGeometry {
        setPositions(geometry.getAttribute("position").array);
        return this;
    }

    public function fromMesh(mesh:InstancedBufferGeometry):InstancedBufferGeometry {
        fromWireframeGeometry(new WireframeGeometry(mesh.getAttribute("geometry")));
        return this;
    }

    public function fromLineSegments(lineSegments:InstancedBufferGeometry):InstancedBufferGeometry {
        var geometry = lineSegments.getAttribute("geometry");
        setPositions(geometry.getAttribute("position").array);
        return this;
    }

    public function computeBoundingBox():Void {
        if (boundingBox == null) {
            boundingBox = new Box3();
        }
        var start = getAttribute("instanceStart");
        var end = getAttribute("instanceEnd");
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
        var start = getAttribute("instanceStart");
        var end = getAttribute("instanceEnd");
        if (start != null && end != null) {
            var center = boundingSphere.center;
            boundingBox.getCenter(center);
            var maxRadiusSq:Float = 0.0;
            for (i in 0...start.count) {
                _vector.fromBufferAttribute(start, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
                _vector.fromBufferAttribute(end, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }
            boundingSphere.radius = Math.sqrt(maxRadiusSq);
            if (isNaN(boundingSphere.radius)) {
                trace("LineSegmentsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.");
            }
        }
    }

    public function toJSON():Dynamic {
        // TODO: Implement toJSON()
    }

    public function applyMatrix(matrix:Matrix):InstancedBufferGeometry {
        trace("LineSegmentsGeometry: applyMatrix() has been renamed to applyMatrix4().");
        return applyMatrix4(matrix);
    }
}

class LineSegmentsGeometry {
    public static function new():LineSegmentsGeometry_ {
        return new LineSegmentsGeometry_();
    }
}