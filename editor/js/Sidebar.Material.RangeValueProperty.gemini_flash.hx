package ;

import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialRangeCommand;
import editor.Editor;
import editor.signals.ObjectSelectedSignal;
import editor.signals.MaterialChangedSignal;

class SidebarMaterialRangeValueProperty {

    public function new(editor:Editor, property:String, name:String, isMin:Bool, ?range:Array<Float>, ?precision:Int, ?step:Float, ?nudge:Float, ?unit:String) {

        if (range == null) range = [-Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
        if (precision == null) precision = 2;
        if (step == null) step = 1;
        if (nudge == null) nudge = 0.01;
        if (unit == null) unit = "";

        var signals = editor.signals;

        var container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        var number = new UINumber()
            .setWidth('60px')
            .setRange(range[0], range[1])
            .setPrecision(precision)
            .setStep(step)
            .setNudge(nudge)
            .setUnit(unit)
            .onChange(onChange);
        container.add(number);

        var object:Dynamic = null;
        var materialSlot:Int = 0;
        var material:Dynamic = null;

        function onChange():Void {
            if (material == null || material[property] == null) return;
            if (material[property][if (isMin) 0 else 1] != number.getValue()) {
                var minValue = if (isMin) number.getValue() else material[property][0];
                var maxValue = if (isMin) material[property][1] else number.getValue();
                editor.execute(new SetMaterialRangeCommand(editor, object, property, minValue, maxValue, materialSlot));
            }
        }

        function update(currentObject:Dynamic, currentMaterialSlot:Int = 0):Void {
            object = currentObject;
            materialSlot = currentMaterialSlot;
            if (object == null || object.material == null) {
                container.setDisplay('none');
                return;
            }
            material = editor.getObjectMaterial(object, materialSlot);
            if (material != null && Reflect.hasField(material, property)) {
                number.setValue(material[property][if (isMin) 0 else 1]);
                container.setDisplay('');
            } else {
                container.setDisplay('none');
            }
        }

        signals.objectSelected.add(update);
        signals.materialChanged.add(update);

        return container;
    }
}