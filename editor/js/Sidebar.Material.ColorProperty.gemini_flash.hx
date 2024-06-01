import dat.gui.GUIController;
import dat.gui.NumberInputOptions;
import js.Lib;
import editor.sidebars.Sidebar;
import editor.commands.SetMaterialColorCommand;
import editor.commands.SetMaterialValueCommand;

class SidebarMaterialColorProperty extends Sidebar {

    public function new(editor : Editor, property : String, name : String) {
        super();

        var signals = editor.signals;

        var container = new div();
        container.className = "UIRow";

        var nameLabel = new span();
        nameLabel.className = "Label";
        nameLabel.textContent = name;
        container.appendChild(nameLabel);

        var color = new ColorController();
        color.onChange = onChange;
        container.appendChild(color.domElement);

        var intensity : Null<NumberController> = null;
        if (property == "emissive") {
            intensity = new NumberController(1);
            intensity.setRange(0, Math.POSITIVE_INFINITY);
            intensity.onChange = onChange;
            container.appendChild(intensity.domElement);
        }

        var object : Null<Object3D> = null;
        var materialSlot : Int = 0;
        var material : Null<Material> = null;

        function onChange(_ : Dynamic) {
            if (material != null && material[property].getHex() != color.getValue()) {
                editor.execute(new SetMaterialColorCommand(editor, object, property, color.getValue(), materialSlot));
            }
            if (intensity != null) {
                if (material != null && material[property + "Intensity"] != intensity.getValue()) {
                    editor.execute(new SetMaterialValueCommand(editor, object, property + "Intensity", intensity.getValue(), materialSlot));
                }
            }
        }

        function update(currentObject : Object3D, currentMaterialSlot : Int = 0) {
            object = currentObject;
            materialSlot = currentMaterialSlot;
            if (object == null || object.material == null) return;
            material = editor.getObjectMaterial(object, materialSlot);
            if (material != null && Reflect.hasField(material, property)) {
                color.setValue(untyped material[property].getHexString());
                if (intensity != null) {
                    intensity.setValue(untyped material[property + "Intensity"]);
                }
                container.style.display = "block";
            } else {
                container.style.display = "none";
            }
        }
        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
        this.domElement = container;
    }

}

private class ColorController {
    public var domElement(get, never) : html.InputElement;

    private var controller : GUIController;

    public function new() {
        var input = js.document.createElement("input");
        input.setAttribute("type", "color");
        this.controller = new GUIController( {}, "", input);
    }

    public function onChange(callback : Dynamic->Void) : Void {
        controller.onChange = callback;
    }

    public function getValue() : Int {
        return Std.parseInt("0x" + controller.getValue().substring(1));
    }

    public function setHexValue(hex: String): Void {
        controller.setValue("#" + hex.substring(2));
    }

}

private class NumberController {
    public var domElement(get, never): html.InputElement;

    private var controller: GUIController;

    public function new(value: Float = 0) {
        var options: NumberInputOptions = { min: 0, max: 1 };
        this.controller = new GUIController(options, "value");
        this.controller.setValue(value);
    }

    public function onChange(callback: Float->Void): Void {
        controller.onChange = function(value: Float) {
            callback(value);
        };
    }

    public function getValue(): Float {
        return controller.getValue();
    }

    public function setValue(value: Float): Void {
        controller.setValue(value);
    }

    public function setRange(min: Float, max: Float): Void {
        controller.min(min);
        controller.max(max);
    }
}