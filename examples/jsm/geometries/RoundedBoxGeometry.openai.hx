package three.js.examples.jm.geometries;

import three.js.lib.Vector3;
import three.js.lib.BoxGeometry;

class RoundedBoxGeometry extends BoxGeometry {
  public function new(width:Float = 1, height:Float = 1, depth:Float = 1, segments:Int = 2, radius:Float = 0.1) {
    segments = segments * 2 + 1;
    radius = Math.min(width / 2, height / 2, depth / 2, radius);

    super(1, 1, 1, segments, segments, segments);

    if (segments == 1) return;

    var geometry2 = toNonIndexed();

    index = null;
    attributes.position = geometry2.attributes.position;
    attributes.normal = geometry2.attributes.normal;
    attributes.uv = geometry2.attributes.uv;

    var position = new Vector3();
    var normal = new Vector3();

    var box = new Vector3(width, height, depth).divideScalar(2).subScalar(radius);

    var positions = attributes.position.array;
    var normals = attributes.normal.array;
    var uvs = attributes.uv.array;

    var faceTris = positions.length / 6;
    var faceDirVector = new Vector3();
    var halfSegmentSize = 0.5 / segments;

    for (i in 0...positions.length step 3) {
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
          faceDirVector.set(1, 0, 0);
          uvs[i + 0] = getUv(faceDirVector, normal, 'z', 'y', radius, depth);
          uvs[i + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
          break;

        case 1: // left
          faceDirVector.set(-1, 0, 0);
          uvs[i + 0] = 1.0 - getUv(faceDirVector, normal, 'z', 'y', radius, depth);
          uvs[i + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
          break;

        case 2: // top
          faceDirVector.set(0, 1, 0);
          uvs[i + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
          uvs[i + 1] = getUv(faceDirVector, normal, 'z', 'x', radius, depth);
          break;

        case 3: // bottom
          faceDirVector.set(0, -1, 0);
          uvs[i + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
          uvs[i + 1] = 1.0 - getUv(faceDirVector, normal, 'z', 'x', radius, depth);
          break;

        case 4: // front
          faceDirVector.set(0, 0, 1);
          uvs[i + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'y', radius, width);
          uvs[i + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
          break;

        case 5: // back
          faceDirVector.set(0, 0, -1);
          uvs[i + 0] = getUv(faceDirVector, normal, 'x', 'y', radius, width);
          uvs[i + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
          break;
      }
    }
  }

  static function getUv(faceDirVector:Vector3, normal:Vector3, uvAxis:String, projectionAxis:String, radius:Float, sideLength:Float):Float {
    var totArcLength = 2 * Math.PI * radius / 4;
    var centerLength = Math.max(sideLength - 2 * radius, 0);
    var halfArc = Math.PI / 4;

    var _tempNormal = new Vector3();
    _tempNormal.copy(normal);
    _tempNormal[projectionAxis] = 0;
    _tempNormal.normalize();

    var arcUvRatio = 0.5 * totArcLength / (totArcLength + centerLength);
    var arcAngleRatio = 1.0 - (_tempNormal.angleTo(faceDirVector) / halfArc);

    if (Math.sign(_tempNormal[uvAxis]) == 1) {
      return arcAngleRatio * arcUvRatio;
    } else {
      var lenUv = centerLength / (totArcLength + centerLength);
      return lenUv + arcUvRatio + arcUvRatio * (1.0 - arcAngleRatio);
    }
  }
}