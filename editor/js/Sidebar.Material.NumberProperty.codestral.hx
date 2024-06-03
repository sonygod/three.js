import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialNumberProperty {

    private var editor: Editor;
    private var property: String;
    private var name: String;
    private var range: Array<Float>;
    private var precision: Int;
    private var signals: Signals;
    private var container: UIRow;
    private var number: UINumber;
    private var object: Dynamic;
    private var materialSlot: Int;
    private var material: Dynamic;

    public function new(editor: Editor, property: String, name: String, range: Array<Float> = [-Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY], precision: Int = 2) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.range = range;
        this.precision = precision;
        this.signals = editor.signals;

        this.container = new UIRow();
        this.container.add(new UIText(name).setClass('Label'));

        this.number = new UINumber()
            .setWidth('60px')
            .setRange(range[0], range[1])
            .setPrecision(precision)
            .onChange(this.onChange);
        this.container.add(this.number);

        this.signals.objectSelected.add(this.update);
        this.signals.materialChanged.add(this.update);
    }

    private function onChange(): Void {
        if (this.material[this.property] != this.number.getValue()) {
            this.editor.execute(new SetMaterialValueCommand(this.editor, this.object, this.property, this.number.getValue(), this.materialSlot));
        }
    }

    private function update(currentObject: Dynamic, currentMaterialSlot: Int = 0): Void {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object == null) return;
        if (Reflect.hasField(this.object, 'material') == false) return;

        this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        if (Reflect.hasField(this.material, this.property)) {
            this.number.setValue(this.material[this.property]);
            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer(): UIRow {
        return this.container;
    }
}