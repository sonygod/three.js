import ui.UICheckbox;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialBooleanProperty {
    public var editor: Editor;
    public var property: String;
    public var name: String;
    private var signals: Signals;
    private var container: UIRow;
    private var boolean: UICheckbox;
    private var object: Dynamic;
    private var materialSlot: Int;
    private var material: Dynamic;

    public function new(editor: Editor, property: String, name: String) {
        this.editor = editor;
        this.property = property;
        this.name = name;

        signals = editor.signals;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        boolean = new UICheckbox().setLeft('100px').onChange(onChange);
        container.add(boolean);

        object = null;
        materialSlot = null;
        material = null;

        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
    }

    private function onChange(): Void {
        if (material[property] !== boolean.getValue()) {
            editor.execute(new SetMaterialValueCommand(editor, object, property, boolean.getValue(), materialSlot));
        }
    }

    public function update(currentObject: Dynamic, currentMaterialSlot: Int = 0): Void {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object === null) return;
        if (object.material === null) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            boolean.setValue(material[property]);
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }

    public function getContainer(): UIRow {
        return container;
    }
}