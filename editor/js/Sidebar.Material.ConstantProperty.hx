package three.js.editor.js;

import js.ui.UIRow;
import js.ui.UISelect;
import js.ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialConstantProperty {
    private var editor:Dynamic;
    private var property:String;
    private var name:String;
    private var options:Array<Dynamic>;
    private var container:UIRow;
    private var constant:UISelect;
    private var object:Dynamic;
    private var materialSlot:Int;
    private var material:Dynamic;

    public function new(editor:Dynamic, property:String, name:String, options:Array<Dynamic>) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.options = options;

        var signals = editor.signals;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        constant = new UISelect().setOptions(options);
        constant.onChange = onChange;
        container.add(constant);
    }

    private function onChange():Void {
        var value:Int = Std.parseInt(constant.getValue());

        if (material[property] != value) {
            editor.execute(new SetMaterialValueCommand(editor, object, property, value, materialSlot));
        }
    }

    private function update(currentObject:Dynamic, ?currentMaterialSlot:Int = 0):Void {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null) return;
        if (object.material == null) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            constant.setValue(material[property]);
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }

    public function new():UIRow {
        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
        return container;
    }
}