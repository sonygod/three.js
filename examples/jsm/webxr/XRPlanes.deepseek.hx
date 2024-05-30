import three.BoxGeometry;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;

class XRPlanes extends Object3D {

	public function new(renderer:Dynamic) {

		super();

		var matrix = new Matrix4();

		var currentPlanes = new Map();

		var xr = cast(renderer.xr, Dynamic);

		xr.addEventListener('planesdetected', function(event) {

			var frame = cast(event.data, Dynamic);
			var planes = cast(frame.detectedPlanes, Dynamic);

			var referenceSpace = xr.getReferenceSpace();

			var planeschanged = false;

			for (plane in currentPlanes) {

				if (planes.has(plane) == false) {

					plane.geometry.dispose();
					plane.material.dispose();
					this.remove(plane);

					currentPlanes.delete(plane);

					planeschanged = true;

				}

			}

			for (plane in planes) {

				if (currentPlanes.has(plane) == false) {

					var pose = frame.getPose(plane.planeSpace, referenceSpace);
					matrix.fromArray(pose.transform.matrix);

					var polygon = plane.polygon;

					var minX = Number.MAX_SAFE_INTEGER;
					var maxX = Number.MIN_SAFE_INTEGER;
					var minZ = Number.MAX_SAFE_INTEGER;
					var maxZ = Number.MIN_SAFE_INTEGER;

					for (point in polygon) {

						minX = Math.min(minX, point.x);
						maxX = Math.max(maxX, point.x);
						minZ = Math.min(minZ, point.z);
						maxZ = Math.max(maxZ, point.z);

					}

					var width = maxX - minX;
					var height = maxZ - minZ;

					var geometry = new BoxGeometry(width, 0.01, height);
					var material = new MeshBasicMaterial({color: 0xffffff * Math.random()});

					var mesh = new Mesh(geometry, material);
					mesh.position.setFromMatrixPosition(matrix);
					mesh.quaternion.setFromRotationMatrix(matrix);
					this.add(mesh);

					currentPlanes.set(plane, mesh);

					planeschanged = true;

				}

			}

			if (planeschanged) {

				this.dispatchEvent({type: 'planeschanged'});

			}

		});

	}

}

typedef XRPlanes = {

	new(renderer:Dynamic):Void;

}