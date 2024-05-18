package three.js.examples.jm.csm;

import three.Vector3;
import three.Matrix4;

class CSMFrustum {
    public var vertices: {
        near: Array<Vector3>,
        far: Array<Vector3>
    };

    private var inverseProjectionMatrix: Matrix4;

    public function new(data: Dynamic = null) {
        data = data != null ? data : {};

        vertices = {
            near: [for (i in 0...4) new Vector3()],
            far: [for (i in 0...4) new Vector3()]
        };

        if (Reflect.hasField(data, "projectionMatrix")) {
            setFromProjectionMatrix(data.projectionMatrix, data.maxFar != null ? data.maxFar : 10000);
        }
    }

    public function setFromProjectionMatrix(projectionMatrix: Matrix4, maxFar: Float) {
        var isOrthographic: Bool = projectionMatrix.Elements[2 * 4 + 3] == 0;

        inverseProjectionMatrix = projectionMatrix.clone().invert();

        // 3 --- 0  vertices.near/far order
        // |     |
        // 2 --- 1
        // clip space spans from [-1, 1]

        vertices.near[0].set(1, 1, -1);
        vertices.near[1].set(1, -1, -1);
        vertices.near[2].set(-1, -1, -1);
        vertices.near[3].set(-1, 1, -1);

        for (v in vertices.near) {
            v.applyMatrix4(inverseProjectionMatrix);
        }

        vertices.far[0].set(1, 1, 1);
        vertices.far[1].set(1, -1, 1);
        vertices.far[2].set(-1, -1, 1);
        vertices.far[3].set(-1, 1, 1);

        for (v in vertices.far) {
            v.applyMatrix4(inverseProjectionMatrix);

            var absZ: Float = Math.abs(v.z);
            if (isOrthographic) {
                v.z *= Math.min(maxFar / absZ, 1.0);
            } else {
                v.multiplyScalar(Math.min(maxFar / absZ, 1.0));
            }
        }

        return vertices;
    }

    public function split(breaks: Array<Float>, target: Array<CSMFrustum>) {
        while (breaks.length > target.length) {
            target.push(new CSMFrustum());
        }

        target.length = breaks.length;

        for (i in 0...breaks.length) {
            var cascade: CSMFrustum = target[i];

            if (i == 0) {
                for (j in 0...4) {
                    cascade.vertices.near[j].copy(vertices.near[j]);
                }
            } else {
                for (j in 0...4) {
                    cascade.vertices.near[j].lerpVectors(vertices.near[j], vertices.far[j], breaks[i - 1]);
                }
            }

            if (i == breaks.length - 1) {
                for (j in 0...4) {
                    cascade.vertices.far[j].copy(vertices.far[j]);
                }
            } else {
                for (j in 0...4) {
                    cascade.vertices.far[j].lerpVectors(vertices.near[j], vertices.far[j], breaks[i]);
                }
            }
        }
    }

    public function toSpace(cameraMatrix: Matrix4, target: CSMFrustum) {
        for (i in 0...4) {
            target.vertices.near[i].copy(vertices.near[i]).applyMatrix4(cameraMatrix);
            target.vertices.far[i].copy(vertices.far[i]).applyMatrix4(cameraMatrix);
        }
    }
}