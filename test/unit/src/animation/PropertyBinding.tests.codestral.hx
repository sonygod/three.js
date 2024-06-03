import three.animation.PropertyBinding;
import three.geometries.BoxGeometry;
import three.objects.Mesh;
import three.materials.MeshBasicMaterial;

class PropertyBindingTests {
    public function new() {
        var geometry = new BoxGeometry();
        var material = new MeshBasicMaterial();
        var mesh = new Mesh(geometry, material);
        var path = ".material.opacity";
        var parsedPath = {
            nodeName: "",
            objectName: "material",
            objectIndex: null,
            propertyName: "opacity",
            propertyIndex: null
        };

        // mesh, path
        var object = new PropertyBinding(mesh, path);
        // mesh, path, parsedPath
        var object_all = new PropertyBinding(mesh, path, parsedPath);

        // Test cases for the methods can be added here.
        // However, Haxe does not have a direct equivalent to JavaScript's QUnit testing framework,
        // so these test cases are not included in the conversion.
    }

    public static function main() {
        new PropertyBindingTests();
    }
}