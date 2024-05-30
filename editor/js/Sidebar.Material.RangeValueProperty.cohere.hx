import js.Browser.window;

import js.html.Element;

import js.ui.UINumber;

import js.ui.UIRow;

import js.ui.UIText;

class SidebarMaterialRangeValueProperty {
    public var container:UIRow;
    public var number:UINumber;
    public var object:Dynamic;
    public var materialSlot:Int;
    public var material:Dynamic;
    public var property:String;
    public var isMin:Bool;
    public var range:Array<Float>;
    public var precision:Int;
    public var step:Float;
    public var nudge:Float;
    public var unit:String;
    public var onChange:Void->Void;
    public var update:Dynamic->Void;
    public var editor:Dynamic;
    public function new(editor:Dynamic, property:String, name:String, isMin:Bool, ?range:Array<Float> = [-Infinity, Infinity], ?precision:Int = 2, ?step:Float = 1.0, ?nudge:Float = 0.01, ?unit:String = '') {
        this.editor = editor;
        this.property = property;
        this.isMin = isMin;
        this.range = range;
        this.precision = precision;
        this.step = step;
        this.nudge = nudge;
        this.unit = unit;
        this.container = UIRow_();
        this.container.add(UIText_CreateLabel(name));
        this.number = UINumber_();
        this.number.setWidth('60px');
        this.number.setRange(this.range[0], this.range[1]);
        this.number.setPrecision(this.precision);
        this.number.setStep(this.step);
        this.number.setNudge(this.nudge);
        this.number.setUnit(this.unit);
        this.number.onChange(this.onChange = function() {
            if (this.material[this.property][this.isMin ? 0 : 1] != this.number.getValue()) {
                var minValue = this.isMin ? this.number.getValue() : this.material[this.property][0];
                var maxValue = this.isMin ? this.material[this.property][1] : this.number.getValue();
                this.editor.execute(SetMaterialRangeCommand_(this.editor, this.object, this.property, minValue, maxValue, this.materialSlot));
            }
        });
        this.container.add(this.number);
        this.update = function(currentObject:Dynamic, ?currentMaterialSlot:Int = 0) {
            this.object = currentObject;
            this.materialSlot = currentMaterialSlot;
            if (this.object == null || this.object.material == null) {
                return;
            }
            this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);
            if (this.material != null && this.material.hasOwnProperty(this.property)) {
                this.number.setValue(this.material[this.property][this.isMin ? 0 : 1]);
                this.container.setDisplay('');
            } else {
                this.container.setDisplay('none');
            }
        }
        this.editor.signals.objectSelected.add(this.update);
        this.editor.signals.materialChanged.add(this.update);
    }
    static function UIText_CreateLabel(name:String) {
        var label = UIText_();
        label.setText(name);
        label.setClass('Label');
        return label;
    }
    static function UINumber_() {
        return UINumber.create();
    }
    static function UIRow_() {
        return UIRow.create();
    }
    static function SetMaterialRangeCommand_(editor:Dynamic, object:Dynamic, property:String, minValue:Float, maxValue:Float, materialSlot:Int) {
        return {
            execute: function() {
                editor.setObjectMaterialValue(object, property, minValue, materialSlot);
                editor.setObjectMaterialValue(object, property, maxValue, materialSlot);
            },
            undo: function() {
                editor.setObjectMaterialValue(object, property, object.material[property][0], materialSlot);
                editor.setObjectMaterialValue(object, property, object.material[property][1], materialSlot);
            }
        }
    }
}

class js__$SidebarMaterialRangeValueProperty_HxOverrides {
    public static function toString(obj:SidebarMaterialRangeValueProperty):String {
        return obj.toString();
    }
}

export class js__$SidebarMaterialRangeValueProperty {
    static var SidebarMaterialRangeValueProperty:SidebarMaterialRangeValueProperty_Constructor = SidebarMaterialRangeValueProperty;
}

type SidebarMaterialRangeValueProperty_Constructor = {
    new(editor:Dynamic, property:String, name:String, isMin:Bool, ?range:Array<Float>, ?precision:Int, ?step:Float, ?nudge:Float, ?unit:String):SidebarMaterialRangeValueProperty;
}