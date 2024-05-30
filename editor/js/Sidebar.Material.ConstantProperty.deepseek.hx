import js.Browser.window;
import js.Lib.{UIRow, UISelect, UIText};
import js.Lib.commands.SetMaterialValueCommand;

class SidebarMaterialConstantProperty {

    var signals:Signals;
    var container:UIRow;
    var constant:UISelect;
    var object:Dynamic;
    var materialSlot:Int;
    var material:Dynamic;

    public function new(editor:Dynamic, property:String, name:String, options:Array<Dynamic>) {

        signals = editor.signals;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        constant = new UISelect().setOptions(options).onChange(onChange);
        container.add(constant);

        object = null;
        materialSlot = 0;
        material = null;

        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
    }

    function onChange() {

        var value = js.Lib.parseInt(constant.getValue());

        if (material[property] !== value) {

            editor.execute(new SetMaterialValueCommand(editor, object, property, value, materialSlot));

        }

    }

    function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {

        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null) return;
        if (object.material == null) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (property in material) {

            constant.setValue(material[property]);
            container.setDisplay('');

        } else {

            container.setDisplay('none');

        }

    }

    public function getContainer():UIRow {
        return container;
    }
}