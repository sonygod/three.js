import three.js.examples.jsm.geometries.BoxGeometry;
import three.js.Vector3;

class RoundedBoxGeometry extends BoxGeometry {

  public function new(width:Float = 1, height:Float = 1, depth:Float = 1, segments:Int = 2, radius:Float = 0.1) {

    // ensure segments is odd so we have a plane connecting the rounded corners
    segments = segments * 2 + 1;

    // ensure radius isn't bigger than shortest side
    radius = Math.min(width / 2, height / 2, depth / 2, radius);

    super(1, 1, 1, segments, segments, segments);

    // if we just have one segment we're the same as a regular box
    if (segments == 1) return;

    var geometry2 = this.toNonIndexed();

    this.index = null;
    this.attributes.position = geometry2.attributes.position;
    this.attributes.normal = geometry2.attributes.normal;
    this.attributes.uv = geometry2.attributes.uv;

    //

    var position = new Vector3();
    var normal = new Vector3();

    var box = new Vector3(width, height, depth).divideScalar(2).subScalar(radius);

    var positions = this.attributes.position.array;
    var normals = this.attributes.normal.array;
    var uvs = this.attributes.uv.array;

    var faceTris = positions.length / 6;
    var faceDirVector = new Vector3();
    var halfSegmentSize = 0.5 / segments;

    for (i in 0...positions.length) {

      position.fromArray(positions, i);
      normal.copy(position);
      normal.x -= Math.sign(normal.x) * halfSegmentSize;
      normal.y -= Math.sign(normal.y) * halfSegmentSize;
      normal.z -= Math.sign(normal.z) * halfSegmentSize;
      normal.normalize();

      positions[i + 0] = box.x * Math.sign(position.x) + normal.x * radius;
      positions[i + 1] = box.y * Math.sign(position.y) + normal.y * radius;
      positions[i + 2] = box.z * Math.sign(position.z) + normal.z * radius;

      normals[i + 0] = normal.x;
      normals[i + 1] = normal.y;
      normals[i + 2] = normal.z;

      var side = Math.floor(i / faceTris);

      switch (side) {

        case 0: // right

          // generate UVs along Z then Y
          faceDirVector.set(1, 0, 0);
          uvs[j + 0] = getUv(faceDirVector, normal, 'z', 'y', radius, depth);
          uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
          break;

        case 1: // left

          // generate UVs along Z then Y
          faceDirVector.set(-1, 0, 0);
          uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'z', 'y', radius, depth);
          uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
          break;

        case 2: // top

          // generate UVs along X then Z
          faceDirVector.set(0, 1, 0);
          uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
          uvs[j + 1] = getUv(faceDirVector, normal, 'z', 'x', radius, depth);
          break;

        case 3: // bottom

          // generate UVs along X then Z
          faceDirVector.set(0, -1, 0);
          uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
          uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'z', 'x', radius, depth);
          break;

        case 4: // front

          // generate UVs along X then Y
          faceDirVector.set(0, 0, 1);
          uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'y', radius, width);
          uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
          break;

        case 5: // back

          // generate UVs along X then Y
          faceDirVector.set(0, 0, -1);
          uvs[j + 0] = getUv(faceDirVector, normal, 'x', 'y', radius, width);
          uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
          break;

      }

    }

  }

  private function getUv(faceDirVector:Vector3, normal:Vector3, uvAxis:String, projectionAxis:String, radius:Float, sideLength:Float):Float {

    var totArcLength = 2 * Math.PI * radius / 4;

    // length of the planes between the arcs on each axis
    var centerLength = Math.max(sideLength - 2 * radius, 0);
    var halfArc = Math.PI / 4;

    // Get the vector projected onto the Y plane
    var _tempNormal = new Vector3();
    _tempNormal.copy(normal);
    _tempNormal[projectionAxis] = 0;
    _tempNormal.normalize();

    // total amount of UV space alloted to a single arc
    var arcUvRatio = 0.5 * totArcLength / (totArcLength + centerLength);

    // the distance along one arc the point is at
    var arcAngleRatio = 1.0 - (_tempNormal.angleTo(faceDirVector) / halfArc);

    if (Math.sign(_tempNormal[uvAxis]) === 1) {

      return arcAngleRatio * arcUvRatio;

    } else {

      // total amount of UV space alloted to the plane between the arcs
      var lenUv = centerLength / (totArcLength + centerLength);
      return lenUv + arcUvRatio + arcUvRatio * (1.0 - arcAngleRatio);

    }

  }

}