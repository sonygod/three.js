package three.js.editor.js;

import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialRangeCommand;

class SidebarMaterialRangeValueProperty {
    var editor:SidebarEditor;
    var property:String;
    var name:String;
    var isMin:Bool;
    var range:Array<Float> = [-Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
    var precision:Int = 2;
    var step:Float = 1;
    var nudge:Float = 0.01;
    var unit:String = "";

    var signals:Signals;
    var container:UIRow;
    var number:UINumber;
    var object:Object3D;
    var materialSlot:Int;
    var material:Material;

    public function new(editor:SidebarEditor, property:String, name:String, isMin:Bool, ?range:Array<Float>, ?precision:Int, ?step:Float, ?nudge:Float, ?unit:String) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.isMin = isMin;
        if (range != null) this.range = range;
        if (precision != null) this.precision = precision;
        if (step != null) this.step = step;
        if (nudge != null) this.nudge = nudge;
        if (unit != null) this.unit = unit;

        signals = editor.signals;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        number = new UINumber();
        number.setWidth('60px');
        number.setRange(range[0], range[1]);
        number.setPrecision(precision);
        number.setStep(step);
        number.setNudge(nudge);
        number.setUnit(unit);
        number.onChange = onChange;
        container.add(number);
    }

    function onChange() {
        if (material[property][isMin ? 0 : 1] != number.getValue()) {
            var minValue:Float = isMin ? number.getValue() : material[property][0];
            var maxValue:Float = isMin ? material[property][1] : number.getValue();
            editor.execute(new SetMaterialRangeCommand(editor, object, property, minValue, maxValue, materialSlot));
        }
    }

    function update(currentObject:Object3D, currentMaterialSlot:Int = 0) {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null) return;
        if (object.material == null) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            number.setValue(material[property][isMin ? 0 : 1]);
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }

    public function init() {
        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
        return container;
    }
}