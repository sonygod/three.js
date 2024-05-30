package three.js.editor.js;

import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UICheckbox;
import commands.SetMaterialValueCommand;

class SidebarMaterialBooleanProperty {
    private var editor:Editor;
    private var property:String;
    private var name:String;
    private var container:UIRow;
    private var booleanUICheckbox:UICheckbox;
    private var object:Object3D;
    private var materialSlot:Int;
    private var material:Material;

    public function new(editor:Editor, property:String, name:String) {
        this.editor = editor;
        this.property = property;
        this.name = name;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        booleanUICheckbox = new UICheckbox().setLeft('100px');
        booleanUICheckbox.onChange = onChange;
        container.add(booleanUICheckbox);

        object = null;
        materialSlot = 0;
        material = null;

        editor.signals.objectSelected.add(update);
        editor.signals.materialChanged.add(update);
    }

    private function onChange() {
        if (material != null && material[property] != booleanUICheckbox.getValue()) {
            editor.execute(new SetMaterialValueCommand(editor, object, property, booleanUICheckbox.GetValue(), materialSlot));
        }
    }

    private function update(currentObject:Object3D, currentMaterialSlot:Int = 0) {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null) return;
        if (object.material == null) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            booleanUICheckbox.setValue(Reflect.field(material, property));
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }
}