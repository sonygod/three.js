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
    var positions:Array<Float> = [-1, 2, 0, 1, 2, 0, -1, 1, 0, 1, 1, 0, -1, 0, 0, 1, 0, 0, -1, -1, 0, 1, -1, 0];
    var uvs:Array<Float> = [-1, 2, 1, 2, -1, 1, 1, 1, -1, -1, 1, -1, -1, -2, 1, -2];
    var index:Array<Int> = [0, 2, 1, 2, 3, 1, 2, 4, 3, 4, 5, 3, 4, 6, 5, 6, 7, 5];
    setIndex(index);
    setAttribute('position', new Float32BufferAttribute(positions, 3));
    setAttribute('uv', new Float32BufferAttribute(uvs, 2));
  }

  public function applyMatrix4(matrix:Matrix4) {
    var start = attributes.instanceStart;
    var end = attributes.instanceEnd;
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

  public function setPositions(array:Array<Float>) {
    var lineSegments:Array<Float>;
    if (Std.isOfType(array, Float32Array)) {
      lineSegments = array;
    } else if (Std.isOfType(array, Array)) {
      lineSegments = new Float32Array(array);
    }
    var instanceBuffer = new InstancedInterleavedBuffer(lineSegments, 6, 1); // xyz, xyz
    setAttribute('instanceStart', new InterleavedBufferAttribute(instanceBuffer, 3, 0)); // xyz
    setAttribute('instanceEnd', new InterleavedBufferAttribute(instanceBuffer, 3, 3)); // xyz
    computeBoundingBox();
    computeBoundingSphere();
    return this;
  }

  public function setColors(array:Array<Float>) {
    var colors:Array<Float>;
    if (Std.isOfType(array, Float32Array)) {
      colors = array;
    } else if (Std.isOfType(array, Array)) {
      colors = new Float32Array(array);
    }
    var instanceColorBuffer = new InstancedInterleavedBuffer(colors, 6, 1); // rgb, rgb
    setAttribute('instanceColorStart', new InterleavedBufferAttribute(instanceColorBuffer, 3, 0)); // rgb
    setAttribute('instanceColorEnd', new InterleavedBufferAttribute(instanceColorBuffer, 3, 3)); // rgb
    return this;
  }

  public function fromWireframeGeometry(geometry:WireframeGeometry) {
    setPositions(geometry.attributes.position.array);
    return this;
  }

  public function fromEdgesGeometry(geometry:Geometry) {
    setPositions(geometry.attributes.position.array);
    return this;
  }

  public function fromMesh(mesh:Mesh) {
    fromWireframeGeometry(new WireframeGeometry(mesh.geometry));
    // set colors, maybe
    return this;
  }

  public function fromLineSegments(lineSegments:LineSegments) {
    var geometry = lineSegments.geometry;
    setPositions(geometry.attributes.position.array); // assumes non-indexed
    // set colors, maybe
    return this;
  }

  public function computeBoundingBox() {
    if (boundingBox == null) {
      boundingBox = new Box3();
    }
    var start = attributes.instanceStart;
    var end = attributes.instanceEnd;
    if (start != null && end != null) {
      boundingBox.setFromBufferAttribute(start);
      _box.setFromBufferAttribute(end);
      boundingBox.union(_box);
    }
  }

  public function computeBoundingSphere() {
    if (boundingSphere == null) {
      boundingSphere = new Sphere();
    }
    if (boundingBox == null) {
      computeBoundingBox();
    }
    var start = attributes.instanceStart;
    var end = attributes.instanceEnd;
    if (start != null && end != null) {
      var center = boundingSphere.center;
      boundingBox.getCenter(center);
      var maxRadiusSq = 0.0;
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

  public function toJSON():Dynamic {
    // todo
    return null;
  }

  public function applyMatrix(matrix:Matrix4) {
    trace('THREE.LineSegmentsGeometry: applyMatrix() has been renamed to applyMatrix4().');
    return applyMatrix4(matrix);
  }
}