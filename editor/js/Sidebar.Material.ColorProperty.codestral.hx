package three.js.editor.js;

import ui.UIColor;
import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialColorCommand;
import commands.SetMaterialValueCommand;

class SidebarMaterialColorProperty {
    private var editor: Editor;
    private var property: String;
    private var name: String;
    private var signals: Signals;
    private var container: UIRow;
    private var color: UIColor;
    private var intensity: UINumber;
    private var object: Object;
    private var materialSlot: Int;
    private var material: Material;

    public function new(editor: Editor, property: String, name: String) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.signals = editor.signals;

        this.container = new UIRow();
        this.container.add(new UIText(name).setClass('Label'));

        this.color = new UIColor().onInput(onChange);
        this.container.add(this.color);

        if (property == 'emissive') {
            this.intensity = new UINumber(1).setWidth('30px').setRange(0, Int.POSITIVE_INFINITY).onChange(onChange);
            this.container.add(this.intensity);
        }

        this.object = null;
        this.materialSlot = 0;
        this.material = null;

        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
    }

    private function onChange() {
        if (this.material[property].getHex() != this.color.getHexValue()) {
            this.editor.execute(new SetMaterialColorCommand(this.editor, this.object, this.property, this.color.getHexValue(), this.materialSlot));
        }

        if (this.intensity != null) {
            if (this.material[property + "Intensity"] != this.intensity.getValue()) {
                this.editor.execute(new SetMaterialValueCommand(this.editor, this.object, property + "Intensity", this.intensity.getValue(), this.materialSlot));
            }
        }
    }

    private function update(currentObject: Object, currentMaterialSlot: Int = 0) {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object == null) return;
        if (this.object.material == null) return;

        this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        if (this.material.exists(this.property)) {
            this.color.setHexValue(this.material[this.property].getHexString());

            if (this.intensity != null) {
                this.intensity.setValue(this.material[this.property + "Intensity"]);
            }

            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer(): UIRow {
        return this.container;
    }
}