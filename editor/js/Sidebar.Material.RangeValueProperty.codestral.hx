import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import SetMaterialRangeCommand;

class SidebarMaterialRangeValueProperty {
    private var editor:Editor;
    private var property:String;
    private var name:String;
    private var isMin:Bool;
    private var range:Array<Float>;
    private var precision:Int;
    private var step:Float;
    private var nudge:Float;
    private var unit:String;
    private var signals:Signals;
    private var container:UIRow;
    private var number:UINumber;
    private var object:Dynamic;
    private var materialSlot:Int;
    private var material:Dynamic;

    public function new(editor:Editor, property:String, name:String, isMin:Bool, range:Array<Float> = [-Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY], precision:Int = 2, step:Float = 1, nudge:Float = 0.01, unit:String = '') {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.isMin = isMin;
        this.range = range;
        this.precision = precision;
        this.step = step;
        this.nudge = nudge;
        this.unit = unit;
        this.signals = editor.signals;

        this.container = new UIRow();
        this.container.add(new UIText(name).setClass('Label'));

        this.number = new UINumber().setWidth('60px').setRange(range[0], range[1]).setPrecision(precision).setStep(step).setNudge(nudge).setUnit(unit).onChange(this.onChange.bind(this));
        this.container.add(this.number);

        this.object = null;
        this.materialSlot = null;
        this.material = null;

        this.signals.objectSelected.add(this.update.bind(this));
        this.signals.materialChanged.add(this.update.bind(this));
    }

    private function onChange():Void {
        if (this.material[this.property][this.isMin ? 0 : 1] != this.number.getValue()) {
            var minValue:Float = this.isMin ? this.number.getValue() : this.material[this.property][0];
            var maxValue:Float = this.isMin ? this.material[this.property][1] : this.number.getValue();

            this.editor.execute(new SetMaterialRangeCommand(this.editor, this.object, this.property, minValue, maxValue, this.materialSlot));
        }
    }

    private function update(currentObject:Dynamic, currentMaterialSlot:Int = 0):Void {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object == null) return;
        if (this.object.material == null) return;

        this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        if (this.property in this.material) {
            this.number.setValue(this.material[this.property][this.isMin ? 0 : 1]);
            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer():UIRow {
        return this.container;
    }
}