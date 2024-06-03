import three.Vector3;
import three.BoxGeometry;

class RoundedBoxGeometry extends BoxGeometry {
    private var _tempNormal:Vector3 = new Vector3();

    private function getUv(faceDirVector:Vector3, normal:Vector3, uvAxis:String, projectionAxis:String, radius:Float, sideLength:Float):Float {
        var totArcLength:Float = 2 * Math.PI * radius / 4;
        var centerLength:Float = Math.max(sideLength - 2 * radius, 0);
        var halfArc:Float = Math.PI / 4;

        _tempNormal.copy(normal);
        _tempNormal.array[projectionAxis] = 0;
        _tempNormal.normalize();

        var arcUvRatio:Float = 0.5 * totArcLength / (totArcLength + centerLength);
        var arcAngleRatio:Float = 1.0 - (_tempNormal.angleTo(faceDirVector) / halfArc);

        if (Math.sign(_tempNormal.array[uvAxis]) === 1) {
            return arcAngleRatio * arcUvRatio;
        } else {
            var lenUv:Float = centerLength / (totArcLength + centerLength);
            return lenUv + arcUvRatio + arcUvRatio * (1.0 - arcAngleRatio);
        }
    }

    public function new(width:Float = 1.0, height:Float = 1.0, depth:Float = 1.0, segments:Int = 2, radius:Float = 0.1) {
        segments = segments * 2 + 1;
        radius = Math.min(width / 2, height / 2, depth / 2, radius);

        super(1, 1, 1, segments, segments, segments);

        if (segments === 1) return;

        var geometry2 = this.toNonIndexed();
        this.index = null;
        this.attributes.position = geometry2.attributes.position;
        this.attributes.normal = geometry2.attributes.normal;
        this.attributes.uv = geometry2.attributes.uv;

        var position:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();
        var box:Vector3 = new Vector3(width, height, depth).divideScalar(2).subScalar(radius);

        var positions = this.attributes.position.array;
        var normals = this.attributes.normal.array;
        var uvs = this.attributes.uv.array;

        var faceTris:Int = positions.length / 6;
        var faceDirVector:Vector3 = new Vector3();
        var halfSegmentSize:Float = 0.5 / segments;

        for (var i:Int = 0, j:Int = 0; i < positions.length; i += 3, j += 2) {
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

            var side:Int = Math.floor(i / faceTris);

            switch (side) {
                case 0:
                    faceDirVector.set(1, 0, 0);
                    uvs[j + 0] = getUv(faceDirVector, normal, 'z', 'y', radius, depth);
                    uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
                    break;
                case 1:
                    faceDirVector.set(-1, 0, 0);
                    uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'z', 'y', radius, depth);
                    uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'z', radius, height);
                    break;
                case 2:
                    faceDirVector.set(0, 1, 0);
                    uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
                    uvs[j + 1] = getUv(faceDirVector, normal, 'z', 'x', radius, depth);
                    break;
                case 3:
                    faceDirVector.set(0, -1, 0);
                    uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'z', radius, width);
                    uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'z', 'x', radius, depth);
                    break;
                case 4:
                    faceDirVector.set(0, 0, 1);
                    uvs[j + 0] = 1.0 - getUv(faceDirVector, normal, 'x', 'y', radius, width);
                    uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
                    break;
                case 5:
                    faceDirVector.set(0, 0, -1);
                    uvs[j + 0] = getUv(faceDirVector, normal, 'x', 'y', radius, width);
                    uvs[j + 1] = 1.0 - getUv(faceDirVector, normal, 'y', 'x', radius, height);
                    break;
            }
        }
    }
}