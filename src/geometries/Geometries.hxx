// Geometries.hx
package three.js.src.geometries;

import three.js.src.geometries.BoxGeometry;
import three.js.src.geometries.CapsuleGeometry;
import three.js.src.geometries.CircleGeometry;
import three.js.src.geometries.ConeGeometry;
import three.js.src.geometries.CylinderGeometry;
import three.js.src.geometries.DodecahedronGeometry;
import three.js.src.geometries.EdgesGeometry;
import three.js.src.geometries.ExtrudeGeometry;
import three.js.src.geometries.IcosahedronGeometry;
import three.js.src.geometries.LatheGeometry;
import three.js.src.geometries.OctahedronGeometry;
import three.js.src.geometries.PlaneGeometry;
import three.js.src.geometries.PolyhedronGeometry;
import three.js.src.geometries.RingGeometry;
import three.js.src.geometries.ShapeGeometry;
import three.js.src.geometries.SphereGeometry;
import three.js.src.geometries.TetrahedronGeometry;
import three.js.src.geometries.TorusGeometry;
import three.js.src.geometries.TorusKnotGeometry;
import three.js.src.geometries.TubeGeometry;
import three.js.src.geometries.WireframeGeometry;

class Geometries {
    public function new() {
        var boxGeometry = new BoxGeometry();
        var capsuleGeometry = new CapsuleGeometry();
        var circleGeometry = new CircleGeometry();
        var coneGeometry = new ConeGeometry();
        var cylinderGeometry = new CylinderGeometry();
        var dodecahedronGeometry = new DodecahedronGeometry();
        var edgesGeometry = new EdgesGeometry();
        var extrudeGeometry = new ExtrudeGeometry();
        var icosahedronGeometry = new IcosahedronGeometry();
        var latheGeometry = new LatheGeometry();
        var octahedronGeometry = new OctahedronGeometry();
        var planeGeometry = new PlaneGeometry();
        var polyhedronGeometry = new PolyhedronGeometry();
        var ringGeometry = new RingGeometry();
        var shapeGeometry = new ShapeGeometry();
        var sphereGeometry = new SphereGeometry();
        var tetrahedronGeometry = new TetrahedronGeometry();
        var torusGeometry = new TorusGeometry();
        var torusKnotGeometry = new TorusKnotGeometry();
        var tubeGeometry = new TubeGeometry();
        var wireframeGeometry = new WireframeGeometry();
    }
}