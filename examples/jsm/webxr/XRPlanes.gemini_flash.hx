import three.core.Object3D;
import three.math.Matrix4;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;
import three.objects.Mesh;
import three.renderers.WebGLRenderer;

class XRPlanes extends Object3D {
  public var renderer:WebGLRenderer;
  public var currentPlanes:Map<Dynamic,Mesh>;
  public var matrix:Matrix4;

  public function new(renderer:WebGLRenderer) {
    super();
    this.renderer = renderer;
    this.matrix = new Matrix4();
    this.currentPlanes = new Map();
    renderer.xr.addEventListener("planesdetected", function(event:Dynamic) {
      var frame = event.data;
      var planes = frame.detectedPlanes;
      var referenceSpace = renderer.xr.getReferenceSpace();
      var planeschanged = false;
      for (var plane in currentPlanes.keys()) {
        if (!planes.has(plane)) {
          currentPlanes.get(plane).geometry.dispose();
          currentPlanes.get(plane).material.dispose();
          remove(currentPlanes.get(plane));
          currentPlanes.remove(plane);
          planeschanged = true;
        }
      }
      for (var plane in planes) {
        if (!currentPlanes.has(plane)) {
          var pose = frame.getPose(plane.planeSpace, referenceSpace);
          matrix.fromArray(pose.transform.matrix);
          var polygon = plane.polygon;
          var minX = Number.MAX_SAFE_INTEGER;
          var maxX = Number.MIN_SAFE_INTEGER;
          var minZ = Number.MAX_SAFE_INTEGER;
          var maxZ = Number.MIN_SAFE_INTEGER;
          for (var point in polygon) {
            minX = Math.min(minX, point.x);
            maxX = Math.max(maxX, point.x);
            minZ = Math.min(minZ, point.z);
            maxZ = Math.max(maxZ, point.z);
          }
          var width = maxX - minX;
          var height = maxZ - minZ;
          var geometry = new BoxGeometry(width, 0.01, height);
          var material = new MeshBasicMaterial({color: 0xFFFFFF * Math.random()});
          var mesh = new Mesh(geometry, material);
          mesh.position.setFromMatrixPosition(matrix);
          mesh.quaternion.setFromRotationMatrix(matrix);
          add(mesh);
          currentPlanes.set(plane, mesh);
          planeschanged = true;
        }
      }
      if (planeschanged) {
        dispatchEvent({type: "planeschanged"});
      }
    });
  }
}