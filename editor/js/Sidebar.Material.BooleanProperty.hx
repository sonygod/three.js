package three.js.editor.js;

import ui.UICheckbox;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialBooleanProperty {
    private var editor:Editor;
    private var property:String;
    private var name:String;
    private var container:UIRow;
    private var boolean:UICheckbox;
    private var object:Object3D;
    private var materialSlot:Int;
    private var material:Material;

    public function new(editor:Editor, property:String, name:String) {
        this.editor = editor;
        this.property = property;
        this.name = name;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        boolean = new UICheckbox().setLeft('100px').onChange(onChange);
        container.add(boolean);
    }

    private function onChange() {
        if (material[property] != boolean.getValue()) {
            editor.execute(new SetMaterialValueCommand(editor, object, property, boolean.getValue(), materialSlot));
        }
    }

    private function update(currentObject:Object3D, ?currentMaterialSlot:Int = 0) {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null) return;
        if (object.material == null) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            boolean.setValue(material[property]);
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }

    public function new() {
        editor.signals.objectSelected.add(update);
        editor.signals.materialChanged.add(update);
    }
}