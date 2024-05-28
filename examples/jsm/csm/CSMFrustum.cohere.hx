import h3d.Matrix4;
import h3d.Vector3;

class CSMFrustum {
    var vertices = { near: [], far: [] };

    public function new(data: { projectionMatrix: Matrix4, maxFar: Float } = null) {
        if (data != null && data.projectionMatrix != null) {
            setFromProjectionMatrix(data.projectionMatrix, data.maxFar ?? 10000);
        }
    }

    public function setFromProjectionMatrix(projectionMatrix: Matrix4, maxFar: Float) -> {Vector3<Float>}[] {
        var isOrthographic = projectionMatrix.rawData[2 * 4 + 3] == 0;
        var inverseProjectionMatrix = projectionMatrix.clone();
        inverseProjectionMatrix.invert();

        vertices.near[0] = Vector3(-1, 1, -1);
        vertices.near[1] = Vector3(1, 1, -1);
        vertices.near[2] = Vector3(1, -1, -1);
        vertices.near[3] = Vector3(-1, -1, -1);
        for (vertex in vertices.near) {
            vertex.applyMatrix4(inverseProjectionMatrix);
        }

        vertices.far[0] = Vector3(-1, 1, 1);
        vertices.far[1] = Vector3(1, 1, 1);
        vertices.far[2] = Vector3(1, -1, 1);
        vertices.far[3] = Vector3(-1, -1, 1);
        for (vertex in vertices.far) {
            vertex.applyMatrix4(inverseProjectionMatrix);
            var absZ = Math.abs(vertex.z);
            if (isOrthographic) {
                vertex.z *= Math.min(maxFar / absZ, 1.0);
            } else {
                vertex *= Math.min(maxFar / absZ, 1.0);
            }
        }

        return vertices;
    }

    public function split(breaks: Array<Float>, target: Array<CSMFrustum>) {
        while (breaks.length > target.length) {
            target.push(CSMFrustum());
        }

        target.length = breaks.length;

        for (i in 0...breaks.length) {
            var cascade = target[i];

            if (i == 0) {
                for (j in 0...4) {
                    cascade.vertices.near[j] = vertices.near[j].clone();
                }
            } else {
                for (j in 0...4) {
                    cascade.vertices.near[j] = vertices.near[j].clone().lerp(vertices.far[j].clone(), breaks[i - 1]);
                }
            }

            if (i == breaks.length - 1) {
                for (j in 0...4) {
                    cascade.vertices.far[j] = vertices.far[j].clone();
                }
            } else {
                for (j in 0...4) {
                    cascade.vertices.far[j] = vertices.near[j].clone().lerp(vertices.far[j].clone(), breaks[i]);
                }
            }
        }
    }

    public function toSpace(cameraMatrix: Matrix4, target: CSMFrustum) {
        for (i in 0...4) {
            target.vertices.near[i] = vertices.near[i].clone().applyMatrix4(cameraMatrix);
            target.vertices.far[i] = vertices.far[i].clone().applyMatrix4(cameraMatrix);
        }
    }
}

class Vector3<T:Float> {
    public var x: T;
    public var y: T;
    public var z: T;

    public function new(x: T, y: T, z: T) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function clone() -> Vector3<T> {
        return Vector3(x, y, z);
    }

    public function applyMatrix4(matrix: Matrix4) -> Vector3<T> {
        return Vector3<T>(
            x * matrix.rawData[0] + y * matrix.rawData[4] + z * matrix.rawData[8] + matrix.rawData[12],
            x * matrix.rawData[1] + y * matrix.rawData[5] + z * matrix.rawData[9] + matrix.rawData[13],
            x * matrix.rawData[2] + y * matrix.rawData[6] + z * matrix.rawData[10] + matrix.rawData[14]
        );
    }

    public function lerp(other: Vector3<T>, t: T) -> Vector3<T> {
        return Vector3(
            x + (other.x - x) * t,
            y + (other.y - y) * t,
            z + (other.z - z) * t
        );
    }
}

class Matrix4<T:Float> {
    public var rawData: Array<T>;

    public function new(data: Array<T>) {
        this.rawData = data;
    }

    public function clone() -> Matrix4<T> {
        return Matrix4(rawData.slice());
    }

    public function invert() -> Matrix4<T> {
        // ... implementation of matrix inversion
    }
}