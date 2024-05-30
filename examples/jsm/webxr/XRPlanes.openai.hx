package three.js.examples.webxr;

import three.BoxGeometry;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;

class XRPlanes extends Object3D {

    public function new(renderer:Dynamic) {
        super();

        var matrix = new Matrix4();

        var currentPlanes = new Map<XRPPlane, Mesh>();

        var xr = renderer.xr;

        xr.addEventListener('planesdetected', function(event:Event) {
            var frame = event.data;
            var planes:Array<XRPPlane> = frame.detectedPlanes;

            var referenceSpace = xr.getReferenceSpace();

            var planesChanged = false;

            for (plane in currentPlanes.keys()) {
                if (planes.indexOf(plane) == -1) {
                    var mesh = currentPlanes.get(plane);
                    mesh.geometry.dispose();
                    mesh.material.dispose();
                    this.remove(mesh);
                    currentPlanes.remove(plane);
                    planesChanged = true;
                }
            }

            for (plane in planes) {
                if (!currentPlanes.exists(plane)) {
                    var pose = frame.getPose(plane.planeSpace, referenceSpace);
                    matrix.fromArray(pose.transform.matrix);

                    var polygon:Array<XRPPoint> = plane.polygon;

                    var minX = Math.POSITIVE_INFINITY;
                    var maxX = Math.NEGATIVE_INFINITY;
                    var minZ = Math.POSITIVE_INFINITY;
                    var maxZ = Math.NEGATIVE_INFINITY;

                    for (point in polygon) {
                        minX = Math.min(minX, point.x);
                        maxX = Math.max(maxX, point.x);
                        minZ = Math.min(minZ, point.z);
                        maxZ = Math.max(maxZ, point.z);
                    }

                    var width = maxX - minX;
                    var height = maxZ - minZ;

                    var geometry = new BoxGeometry(width, 0.01, height);
                    var material = new MeshBasicMaterial({ color: Math.random() * 0xffffff });
                    var mesh = new Mesh(geometry, material);
                    mesh.position.fromMatrixPosition(matrix);
                    mesh.quaternion.fromRotationMatrix(matrix);
                    this.add(mesh);

                    currentPlanes.set(plane, mesh);
                    planesChanged = true;
                }
            }

            if (planesChanged) {
                this.dispatchEvent({ type: 'planeschanged' });
            }
        });
    }
}