import js.Browser.window;
import js.Lib.{UICheckbox, UIRow, UIText};
import js.Lib.commands.SetMaterialValueCommand;

class SidebarMaterialBooleanProperty {

    var editor:Dynamic;
    var property:String;
    var name:String;
    var signals:Dynamic;
    var container:UIRow;
    var boolean:UICheckbox;
    var object:Dynamic;
    var materialSlot:Int;
    var material:Dynamic;

    public function new(editor:Dynamic, property:String, name:String) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.signals = editor.signals;
        this.container = new UIRow();
        this.container.add(new UIText(name).setClass('Label'));
        this.boolean = new UICheckbox().setLeft('100px').onChange(onChange);
        this.container.add(this.boolean);
        this.object = null;
        this.materialSlot = 0;
        this.material = null;

        this.signals.objectSelected.add(update);
        this.signals.materialChanged.add(update);
    }

    function onChange() {
        if (this.material[this.property] !== this.boolean.getValue()) {
            this.editor.execute(new SetMaterialValueCommand(this.editor, this.object, this.property, this.boolean.getValue(), this.materialSlot));
        }
    }

    function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object == null) return;
        if (this.object.material == null) return;

        this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        if (this.property in this.material) {
            this.boolean.setValue(this.material[this.property]);
            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer():UIRow {
        return this.container;
    }
}