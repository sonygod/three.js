import h3d.Material;
import h3d.MeshPhysicalMaterial;

class TestMeshPhysicalMaterial {
    static public function extending() {
        var object = new MeshPhysicalMaterial();
        trace(Std.is(object, Material)); // true
    }

    static public function instancing() {
        var object = new MeshPhysicalMaterial();
        trace(object != null); // true
    }

    static public function type() {
        var object = new MeshPhysicalMaterial();
        trace(object.getType() == "MeshPhysicalMaterial"); // true
    }

    static public function isMeshPhysicalMaterial() {
        var object = new MeshPhysicalMaterial();
        trace(object.isMeshPhysicalMaterial()); // true
    }
}