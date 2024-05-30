import js.three.BoxGeometry;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.Object3D;

class XRPlanes extends Object3D {
    var currentPlanes: Map<js.three.Plane, Mesh>;
    var matrix: Matrix4;
    var xr: XRRenderer;

    public function new(renderer: XRRenderer) {
        super();
        matrix = new Matrix4();
        currentPlanes = new Map();
        xr = renderer.xr;

        xr.addEventListener('planesdetected', function(event: js.three.Event) {
            var frame = event.data;
            var planes = frame.detectedPlanes;
            var referenceSpace = xr.getReferenceSpace();
            var planeschanged = false;

            for (var plane in currentPlanes.keys()) {
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
                if (!currentPlanes.has(plane)) {
                    var pose = frame.getPose(plane.planeSpace, referenceSpace);
                    matrix.fromArray(pose.transform.matrix);

                    var polygon = plane.polygon;
                    var minX = Float.POSITIVE_INFINITY;
                    var maxX = Float.NEGATIVE_INFINITY;
                    var minZ = Float.POSITIVE_INFINITY;
                    var maxZ = Float.NEGATIVE_INFINITY;

                    for (var point in polygon) {
                        minX = min(minX, point.x);
                        maxX = max(maxX, point.x);
                        minZ = min(minZ, point.z);
                        maxZ = max(maxZ, point.z);
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
                this.dispatchEvent(new js.Dynamic({ type: 'planeschanged' }));
            }
        });
    }
}

class XRRenderer {
    var xr: XRRenderer;
    function getReferenceSpace(): XRReferenceSpace;
}

class XRReferenceSpace {
}

class Event {
    var data: Dynamic;
}

class Plane {
    var planeSpace: XRReferenceSpace;
    var polygon: Array<js.three.Vector3>;
}

class Vector3 {
    function get x(): Float;
    function set x(v: Float): Void;
    function get z(): Float;
    function set z(v: Float): Void;
}

class Float {
    static var POSITIVE_INFINITY: Float;
    static var NEGATIVE_INFINITY: Float;
}

class Dynamic {
}

inline function min(a: Float, b: Float): Float {
    if (a < b) return a;
    else return b;
}

inline function max(a: Float, b: Float): Float {
    if (a > b) return a;
    else return b;
}

class MatrixPosition {
    function setFromMatrixPosition(m: Matrix4): Void;
}

class Quaternion {
    function setFromRotationMatrix(m: Matrix4): Void;
}