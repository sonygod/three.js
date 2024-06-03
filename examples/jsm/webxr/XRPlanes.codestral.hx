import three.core.Object3D;
import three.geometries.BoxGeometry;
import three.math.Matrix4;
import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import haxe.ds.Map;

class XRPlanes extends Object3D {
    private var matrix:Matrix4 = new Matrix4();
    private var currentPlanes:Map<any, Mesh> = new Map();
    private var xr:any;

    public function new(renderer:any) {
        super();
        this.xr = renderer.xr;
        this.xr.addEventListener('planesdetected', (event:Dynamic) => {
            this.handlePlanesDetected(event);
        });
    }

    private function handlePlanesDetected(event:Dynamic):Void {
        var frame = event.data;
        var planes = frame.detectedPlanes;
        var referenceSpace = this.xr.getReferenceSpace();
        var planeschanged = false;

        for (plane in currentPlanes.keys()) {
            if (!planes.has(plane)) {
                var mesh = currentPlanes.get(plane);
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
                var polygon = plane.polygon;
                var minX = Float.MAX_VALUE;
                var maxX = Float.MIN_VALUE;
                var minZ = Float.MAX_VALUE;
                var maxZ = Float.MIN_VALUE;

                for (point in polygon) {
                    minX = Math.min(minX, point.x);
                    maxX = Math.max(maxX, point.x);
                    minZ = Math.min(minZ, point.z);
                    maxZ = Math.max(maxZ, point.z);
                }

                var width = maxX - minX;
                var height = maxZ - minZ;
                var geometry = new BoxGeometry(width, 0.01, height);
                var material = new MeshBasicMaterial({ color: 0xffffff * Math.random() });
                var mesh = new Mesh(geometry, material);
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
    }
}