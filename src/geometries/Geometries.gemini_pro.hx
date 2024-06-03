import BoxGeometry from "./BoxGeometry";
import CapsuleGeometry from "./CapsuleGeometry";
import CircleGeometry from "./CircleGeometry";
import ConeGeometry from "./ConeGeometry";
import CylinderGeometry from "./CylinderGeometry";
import DodecahedronGeometry from "./DodecahedronGeometry";
import EdgesGeometry from "./EdgesGeometry";
import ExtrudeGeometry from "./ExtrudeGeometry";
import IcosahedronGeometry from "./IcosahedronGeometry";
import LatheGeometry from "./LatheGeometry";
import OctahedronGeometry from "./OctahedronGeometry";
import PlaneGeometry from "./PlaneGeometry";
import PolyhedronGeometry from "./PolyhedronGeometry";
import RingGeometry from "./RingGeometry";
import ShapeGeometry from "./ShapeGeometry";
import SphereGeometry from "./SphereGeometry";
import TetrahedronGeometry from "./TetrahedronGeometry";
import TorusGeometry from "./TorusGeometry";
import TorusKnotGeometry from "./TorusKnotGeometry";
import TubeGeometry from "./TubeGeometry";
import WireframeGeometry from "./WireframeGeometry";

class GeometryExports {
  public static var BoxGeometry:Class<BoxGeometry> = BoxGeometry;
  public static var CapsuleGeometry:Class<CapsuleGeometry> = CapsuleGeometry;
  public static var CircleGeometry:Class<CircleGeometry> = CircleGeometry;
  public static var ConeGeometry:Class<ConeGeometry> = ConeGeometry;
  public static var CylinderGeometry:Class<CylinderGeometry> = CylinderGeometry;
  public static var DodecahedronGeometry:Class<DodecahedronGeometry> = DodecahedronGeometry;
  public static var EdgesGeometry:Class<EdgesGeometry> = EdgesGeometry;
  public static var ExtrudeGeometry:Class<ExtrudeGeometry> = ExtrudeGeometry;
  public static var IcosahedronGeometry:Class<IcosahedronGeometry> = IcosahedronGeometry;
  public static var LatheGeometry:Class<LatheGeometry> = LatheGeometry;
  public static var OctahedronGeometry:Class<OctahedronGeometry> = OctahedronGeometry;
  public static var PlaneGeometry:Class<PlaneGeometry> = PlaneGeometry;
  public static var PolyhedronGeometry:Class<PolyhedronGeometry> = PolyhedronGeometry;
  public static var RingGeometry:Class<RingGeometry> = RingGeometry;
  public static var ShapeGeometry:Class<ShapeGeometry> = ShapeGeometry;
  public static var SphereGeometry:Class<SphereGeometry> = SphereGeometry;
  public static var TetrahedronGeometry:Class<TetrahedronGeometry> = TetrahedronGeometry;
  public static var TorusGeometry:Class<TorusGeometry> = TorusGeometry;
  public static var TorusKnotGeometry:Class<TorusKnotGeometry> = TorusKnotGeometry;
  public static var TubeGeometry:Class<TubeGeometry> = TubeGeometry;
  public static var WireframeGeometry:Class<WireframeGeometry> = WireframeGeometry;
}

export GeometryExports;



**Explanation:**

1. **Imports:** We import each geometry class from its respective file.
2. **`GeometryExports` Class:**
   - This class serves as a central container for all the geometry classes.
   - We use `public static var` to create static properties that hold the class references.
3. **`export GeometryExports;`:** This line exports the `GeometryExports` class, making it accessible from other Haxe files.

**How to use:**


import GeometryExports from "./your_geometry_exports_file";

// Create a BoxGeometry instance
var box = new GeometryExports.BoxGeometry(1, 1, 1);

// Create a SphereGeometry instance
var sphere = new GeometryExports.SphereGeometry(1);