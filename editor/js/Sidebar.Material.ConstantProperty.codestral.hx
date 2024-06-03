import ui.UIRow;
import ui.UISelect;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialConstantProperty {
    private var editor: Editor;
    private var property: String;
    private var name: String;
    private var options: Array<Dynamic>;
    private var signals: Signals;
    private var container: UIRow;
    private var constant: UISelect;
    private var object: Dynamic;
    private var materialSlot: Int;
    private var material: Dynamic;

    public function new(editor: Editor, property: String, name: String, options: Array<Dynamic>) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.options = options;
        this.signals = editor.signals;

        this.container = new UIRow();
        this.container.add(new UIText(name).setClass('Label'));

        this.constant = new UISelect().setOptions(options).onChange(this.onChange.bind(this));
        this.container.add(this.constant);

        this.object = null;
        this.materialSlot = null;
        this.material = null;

        this.signals.objectSelected.add(this.update.bind(this));
        this.signals.materialChanged.add(this.update.bind(this));
    }

    private function onChange(): Void {
        var value = Std.parseInt(this.constant.getValue());

        if (this.material[this.property] !== value) {
            this.editor.execute(new SetMaterialValueCommand(this.editor, this.object, this.property, value, this.materialSlot));
        }
    }

    private function update(currentObject: Dynamic, currentMaterialSlot: Int = 0): Void {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object === null) return;
        if (this.object.material === null) return;

        this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        if (Reflect.hasField(this.material, this.property)) {
            this.constant.setValue(this.material[this.property]);
            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer(): UIRow {
        return this.container;
    }
}