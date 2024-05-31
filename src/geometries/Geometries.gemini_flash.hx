import three.geometries.*;

export BoxGeometry from three.geometries.BoxGeometry;
export CapsuleGeometry from three.geometries.CapsuleGeometry;
export CircleGeometry from three.geometries.CircleGeometry;
export ConeGeometry from three.geometries.ConeGeometry;
export CylinderGeometry from three.geometries.CylinderGeometry;
export DodecahedronGeometry from three.geometries.DodecahedronGeometry;
export EdgesGeometry from three.geometries.EdgesGeometry;
export ExtrudeGeometry from three.geometries.ExtrudeGeometry;
export IcosahedronGeometry from three.geometries.IcosahedronGeometry;
export LatheGeometry from three.geometries.LatheGeometry;
export OctahedronGeometry from three.geometries.OctahedronGeometry;
export PlaneGeometry from three.geometries.PlaneGeometry;
export PolyhedronGeometry from three.geometries.PolyhedronGeometry;
export RingGeometry from three.geometries.RingGeometry;
export ShapeGeometry from three.geometries.ShapeGeometry;
export SphereGeometry from three.geometries.SphereGeometry;
export TetrahedronGeometry from three.geometries.TetrahedronGeometry;
export TorusGeometry from three.geometries.TorusGeometry;
export TorusKnotGeometry from three.geometries.TorusKnotGeometry;
export TubeGeometry from three.geometries.TubeGeometry;
export WireframeGeometry from three.geometries.WireframeGeometry;


**Explanation:**

1. **Import the necessary classes:**
   - `import three.geometries.*;` imports all classes from the `three.geometries` package.

2. **Export each class:**
   - `export BoxGeometry from three.geometries.BoxGeometry;` exports each geometry class individually, allowing them to be used in other Haxe projects.

**How to use this Haxe code:**

1. **Import the `Geometries` class:**
   
   import your.package.Geometries; // Replace 'your.package' with the actual package name
   

2. **Create instances of the geometry classes:**
   
   var boxGeometry = new Geometries.BoxGeometry(1, 1, 1);
   var sphereGeometry = new Geometries.SphereGeometry(1, 32, 32);