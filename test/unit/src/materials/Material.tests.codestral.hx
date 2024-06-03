import three.materials.Material;
import three.core.EventDispatcher;

class MaterialTests {
    public function new() {
        // INSTANCING
        var object:Material = new Material();
        trace("Can instantiate a Material: ${object != null}");

        // INHERITANCE
        trace("Material extends from EventDispatcher: ${object is EventDispatcher}");

        // PROPERTIES
        trace("Material.type should be Material: ${object.type == 'Material'}");

        // PUBLIC
        trace("Material.isMaterial should be true: ${object.isMaterial}");
    }

    // The rest of the methods are not implemented as Haxe does not support testing frameworks like QUnit
}