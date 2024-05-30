package three.js.examples.jsm.csm;

import three.Vector3;
import three.Matrix4;

class CSMFrustum {
  public var vertices: {
    near: Array<Vector3>,
    far:  Array<Vector3>
  };

  public function new(data:Dynamic = null) {
    if (data == null) data = {};
    vertices = {
      near: [for (i in 0...4) Vector3.create()],
      far:  [for (i in 0...4) Vector3.create()]
    };

    if (data.projectionMatrix != null) {
      setFromProjectionMatrix(data.projectionMatrix, data.maxFar != null ? data.maxFar : 10000);
    }
  }

  public function setFromProjectionMatrix(projectionMatrix:Matrix4, maxFar:Float) {
    var isOrthographic = projectionMatrix.elements[2 * 4 + 3] == 0;
    var inverseProjectionMatrix = projectionMatrix.clone().invert();

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
      var absZ = Math.abs(v.z);
      if (isOrthographic) {
        v.z *= Math.min(maxFar / absZ, 1.0);
      } else {
        v.multiplyScalar(Math.min(maxFar / absZ, 1.0));
      }
    }

    return vertices;
  }

  public function split(breaks:Array<Float>, target:Array<CSMFrustum>) {
    while (breaks.length > target.length) {
      target.push(new CSMFrustum());
    }

    target.length = breaks.length;

    for (i in 0...breaks.length) {
      var cascade = target[i];

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

  public function toSpace(cameraMatrix:Matrix4, target:CSMFrustum) {
    for (i in 0...4) {
      target.vertices.near[i].copy(vertices.near[i]).applyMatrix4(cameraMatrix);
      target.vertices.far[i].copy(vertices.far[i]).applyMatrix4(cameraMatrix);
    }
  }
}