package three.js.examples.javascript.webxr;

import three.BoxGeometry;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;

class XRPlanes extends Object3D {
    private var currentPlanes:Map<String, Mesh>;
    private var xr:Dynamic;

    public function new(renderer:Dynamic) {
        super();
        var matrix:Matrix4 = new Matrix4();

        currentPlanes = new Map<String, Mesh>();

        xr = renderer.xr;

        xr.addEventListener('planesdetected', function(event) {
            var frame = event.data;
            var planes:Array<Dynamic> = frame.detectedPlanes;

            var referenceSpace = xr.getReferenceSpace();

            var planeschanged:Bool = false;

            for (plane in currentPlanes.keys()) {
                if (planes.indexOf(plane) == -1) {
                    var mesh:Mesh = currentPlanes.get(plane);
                    mesh.geometry.dispose();
                    mesh.material.dispose();
                    this.remove(mesh);

                    currentPlanes.remove(plane);

                    planeschanged = true;
                }
            }

            for (plane in planes) {
                if (!currentPlanes.exists(plane)) {
                    var pose = frame.getPose(plane.planeSpace, referenceSpace);
                    matrix.fromArray(pose.transform.matrix);

                    var polygon:Array<Dynamic> = plane.polygon;

                    var minX:Float = Math.POSITIVE_INFINITY;
                    var maxX:Float = Math.NEGATIVE_INFINITY;
                    var minZ:Float = Math.POSITIVE_INFINITY;
                    var maxZ:Float = Math.NEGATIVE_INFINITY;

                    for (point in polygon) {
                        minX = Math.min(minX, point.x);
                        maxX = Math.max(maxX, point.x);
                        minZ = Math.min(minZ, point.z);
                        maxZ = Math.max(maxZ, point.z);
                    }

                    var width:Float = maxX - minX;
                    var height:Float = maxZ - minZ;

                    var geometry:BoxGeometry = new BoxGeometry(width, 0.01, height);
                    var material:MeshBasicMaterial = new MeshBasicMaterial({ color: 0xffffff * Math.random() });

                    var mesh:Mesh = new Mesh(geometry, material);
                    mesh.position.setFromMatrixPosition(matrix);
                    mesh.quaternion.setFromRotationMatrix(matrix);
                    this.add(mesh);

                    currentPlanes.set(plane, mesh);

                    planeschanged = true;
                }
            }

            if (planeschanged) {
                this.dispatchEvent({ type: 'planeschanged' });
            }
        });
    }
}

/* Export the class */
extern class XRPlanes {
    public function new(renderer:Dynamic);
}