import js.three.BoxGeometry;
import js.three.Vector3;

class RoundedBoxGeometry extends BoxGeometry {
    public function new(width:Float = 1.0, height:Float = 1.0, depth:Float = 1.0, segments:Int = 2, radius:Float = 0.1) {
        super(1, 1, 1, segments, segments, segments);

        if (segments == 1) {
            return;
        }

        var geometry2 = cast this.toNonIndexed();

        this.index = null;
        this.attributes.position = geometry2.attributes.position;
        this.attributes.normal = geometry2.attributes.normal;
        this.attributes.uv = geometry2.attributes.uv;

        var position = new Vector3();
        var normal = new Vector3();

        var box = new Vector3(width, height, depth).divideScalar(2.0).subScalar(radius);

        var positions = this.attributes.position.array;
        var normals = this.attributes.normal.array;
        var uvs = this.attributes.uv.array;

        var faceTris = Std.int(positions.length / 6);
        var faceDirVector = new Vector3();
        var halfSegmentSize = 0.5 / segments;

        for (i in 0...positions.length) {
            if (i % 3 == 0) {
                position.fromArray(positions, i);
                normal.copy(position);
                normal.x -= normal.x > 0 ? halfSegmentSize : -halfSegmentSize;
                normal.y -= normal.y > 0 ? halfSegmentSize : -halfSegmentSize;
                normal.z -= normal.z > 0 ? halfSegmentSize : -halfSegmentSize;
                normal.normalize();

                positions[i + 0] = box.x * position.x.sign + normal.x * radius;
                positions[i + 1] = box.y * position.y.sign + normal.y * radius;
                positions[i + 2] = box.z * position.z.sign + normal.z * radius;

                normals[i + 0] = normal.x;
                normals[i + 1] = normal.y;
                normals[i + 2] = normal.z;
            }

            var side = Std.int(i / faceTris);
            var uvIndex = i / 3 * 2;

            switch (side) {
                case 0: // right
                    faceDirVector.set(1, 0, 0);
                    uvs[uvIndex + 0] = getUv(faceDirVector, normal, 'z', 'y', radius, depth);
                    uvs[uvIndex + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
                    break;
                case 1: // left
                    faceDirVector.set(-1, 0, 0);
                    uvs[uvIndex + 0] = 1.0 - getUv(faceDirVector, normal, 'z', 'y', radius, depth);
                    uvs[uvIndex + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
                    break;
                case 2: // top
                    faceDirVector.set(0, 1, 0);
                    uvs[uvIndex + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
                    uvs[uvIndex + 1] = getUv(faceDirVector, normal, 'z', 'x', radius, depth);
                    break;
                case 3: // bottom
                    faceDirVector.set(0, -1, 0);
                    uvs[uvIndex + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
                    uvs[uvIndex + 1] = 1.0 - getUv(faceDirVector, normal, 'z', 'x', radius, depth);
                    break;
                case 4: // front
                    faceDirVector.set(0, 0, 1);
                    uvs[uvIndex + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'y', radius, width);
                    uvs[uvIndex + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
                    break;
                case 5: // back
                    faceDirVector.set(0, 0, -1);
                    uvs[uvIndex + 0] = getUv(faceDirVector, normal, 'x', 'y', radius, width);
                    uvs[uvIndex + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
                    break;
            }
        }
    }

    private inline function getUv(faceDirVector:Vector3, normal:Vector3, uvAxis:String, projectionAxis:String, radius:Float, sideLength:Float):Float {
        var totArcLength = 2 * Math.PI * radius / 4;
        var centerLength = Math.max(sideLength - 2 * radius, 0);
        var halfArc = Math.PI / 4;
        var tempNormal = normal.clone();
        tempNormal[$projectionAxis] = 0;
        tempNormal.normalize();

        var arcUvRatio = 0.5 * totArcLength / (totArcLength + centerLength);
        var arcAngleRatio = 1.0 - (tempNormal.angleTo(faceDirVector) / halfArc);

        if (tempNormal[$uvAxis] > 0) {
            return arcAngleRatio * arcUvRatio;
        } else {
            var lenUv = centerLength / (totArcLength + centerLength);
            return lenUv + arcUvRatio + arcUvRatio * (1.0 - arcAngleRatio);
        }
    }
}