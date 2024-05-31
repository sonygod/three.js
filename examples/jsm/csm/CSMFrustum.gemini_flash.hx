import three.Matrix4;
import three.Vector3;

class CSMFrustum {

	public var vertices : { near : Array<Vector3>, far : Array<Vector3> };

	public function new(data:Dynamic = null) {

		if (data == null) {
			data = {};
		}

		this.vertices = {
			near: [
				new Vector3(),
				new Vector3(),
				new Vector3(),
				new Vector3()
			],
			far: [
				new Vector3(),
				new Vector3(),
				new Vector3(),
				new Vector3()
			]
		};

		if (data.projectionMatrix != null) {

			this.setFromProjectionMatrix(data.projectionMatrix, data.maxFar != null ? data.maxFar : 10000);

		}

	}

	public function setFromProjectionMatrix(projectionMatrix:Matrix4, maxFar:Float):{ near : Array<Vector3>, far : Array<Vector3> } {

		var isOrthographic:Bool = projectionMatrix.elements[2 * 4 + 3] == 0;

		var inverseProjectionMatrix = new Matrix4().copy(projectionMatrix).invert();

		// 3 --- 0  vertices.near/far order
		// |     |
		// 2 --- 1
		// clip space spans from [-1, 1]

		this.vertices.near[0].set(1, 1, -1);
		this.vertices.near[1].set(1, -1, -1);
		this.vertices.near[2].set(-1, -1, -1);
		this.vertices.near[3].set(-1, 1, -1);
		for (v in this.vertices.near) {

			v.applyMatrix4(inverseProjectionMatrix);

		}

		this.vertices.far[0].set(1, 1, 1);
		this.vertices.far[1].set(1, -1, 1);
		this.vertices.far[2].set(-1, -1, 1);
		this.vertices.far[3].set(-1, 1, 1);
		for (v in this.vertices.far) {

			v.applyMatrix4(inverseProjectionMatrix);

			var absZ = Math.abs(v.z);
			if (isOrthographic) {

				v.z *= Math.min(maxFar / absZ, 1.0);

			} else {

				v.multiplyScalar(Math.min(maxFar / absZ, 1.0));

			}

		}

		return this.vertices;

	}

	public function split(breaks:Array<Float>, target:Array<CSMFrustum>):Void {

		while (breaks.length > target.length) {

			target.push(new CSMFrustum());

		}

		target.length = breaks.length;

		for (i in 0...breaks.length) {

			var cascade = target[i];

			if (i == 0) {

				for (j in 0...4) {

					cascade.vertices.near[j].copy(this.vertices.near[j]);

				}

			} else {

				for (j in 0...4) {

					cascade.vertices.near[j].lerpVectors(this.vertices.near[j], this.vertices.far[j], breaks[i - 1]);

				}

			}

			if (i == breaks.length - 1) {

				for (j in 0...4) {

					cascade.vertices.far[j].copy(this.vertices.far[j]);

				}

			} else {

				for (j in 0...4) {

					cascade.vertices.far[j].lerpVectors(this.vertices.near[j], this.vertices.far[j], breaks[i]);

				}

			}

		}

	}

	public function toSpace(cameraMatrix:Matrix4, target:CSMFrustum):Void {

		for (i in 0...4) {

			target.vertices.near[i]
				.copy(this.vertices.near[i])
				.applyMatrix4(cameraMatrix);

			target.vertices.far[i]
				.copy(this.vertices.far[i])
				.applyMatrix4(cameraMatrix);

		}

	}

}