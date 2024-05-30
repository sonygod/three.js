import js.Browser.window;
import js.html.Div;
import js.html.Input;

class SidebarMaterialNumberProperty {
    public var container:Div;
    public var number:Input;
    public var onChange:Void->Void;
    public var update:Dynamic->Void;

    public function new(editor:Dynamic, property:String, name:String, range:[Float], precision:Int) {
        container = window.document.createDivElement();
        var label = window.document.createDivElement();
        label.innerHTML = name;
        container.appendChild(label);

        number = window.document.createInputElement();
        number.type = "number";
        number.min = Std.string(range[0]);
        number.max = Std.string(range[1]);
        number.step = "any";
        number.style.width = "60px";
        number.onchange = function() onChange();
        container.appendChild(number);

        var signals = editor.signals;
        var object:Dynamic, materialSlot:Int, material:Dynamic;

        function onChange() {
            if (material.hasOwnProperty(property) && material[$property] != number.value) {
                var command = SetMaterialValueCommand(editor, object, property, number.value, materialSlot);
                editor.execute(command);
            }
        }

        function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null || !Reflect.hasField(object, "material")) {
                return;
            }

            material = editor.getObjectMaterial(object, materialSlot);

            if (material.hasOwnProperty(property)) {
                number.value = material[$property];
                container.style.display = "";
            } else {
                container.style.display = "none";
            }
        }

        signals.objectSelected.add($update);
        signals.materialChanged.add($update);
    }
}

class SetMaterialValueCommand {
    public var editor:Dynamic;
    public var object:Dynamic;
    public var property:String;
    public var value:Float;
    public var materialSlot:Int;

    public function new(editor:Dynamic, object:Dynamic, property:String, value:Float, materialSlot:Int) {
        this.editor = editor;
        this.object = object;
        this.property = property;
        this.value = value;
        this.materialSlot = materialSlot;
    }

    public function execute() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[$property] = value;
        editor.needUpdate = true;
    }

    public function undo() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[$property] = 0;
        editor.needUpdate = true;
    }
}

function main() {
    var editor = {
        signals: {
            objectSelected: function() {},
            materialChanged: function() {}
        },
        getObjectMaterial: function(object:Dynamic, materialSlot:Int) {
            return { $property: 0 };
        }
    };

    var property = "testProperty";
    var name = "Test Property";
    var range = [0.0, 1.0];
    var precision = 2;

    var sidebarProperty = SidebarMaterialNumberProperty(editor, property, name, range, precision);
}

main();