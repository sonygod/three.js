import js.ui.UIColor;
import js.ui.UINumber;
import js.ui.UIRow;
import js.ui.UIText;

import js.commands.SetMaterialColorCommand;
import js.commands.SetMaterialValueCommand;

class SidebarMaterialColorProperty {
    public var container:UIRow;
    public var color:UIColor;
    public var intensity:UINumber;
    public var object:Dynamic;
    public var materialSlot:Int;
    public var material:Dynamic;
    public var editor:Dynamic;
    public var property:String;
    public var name:String;
    public var signals:Dynamic;

    public function new(editor:Dynamic, property:String, name:String) {
        this.editor = editor;
        this.property = property;
        this.name = name;
        this.signals = editor.signals;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        color = new UIColor();
        color.onInput(onChange);
        container.add(color);

        if (property == 'emissive') {
            intensity = new UINumber(1);
            intensity.setWidth('30px');
            intensity.setRange(0, Infinity);
            intensity.onChange(onChange);
            container.add(intensity);
        }

        object = null;
        materialSlot = 0;
        material = null;

        signals.objectSelected.add($bind(this, update));
        signals.materialChanged.add($bind(this, update));
    }

    public function onChange():Void {
        if (material[property].getHex() != color.getHexValue()) {
            editor.execute(new SetMaterialColorCommand(editor, object, property, color.getHexValue(), materialSlot));
        }

        if (intensity != null) {
            if (material['$property' + 'Intensity'] != intensity.getValue()) {
                editor.execute(new SetMaterialValueCommand(editor, object, '$property' + 'Intensity', intensity.getValue(), materialSlot));
            }
        }
    }

    public function update(currentObject:Dynamic, currentMaterialSlot:Int = 0):Void {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null || !Reflect.hasField(object, 'material')) {
            return;
        }

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            color.setHexValue(material[property].getHexString());

            if (intensity != null) {
                intensity.setValue(material['$property' + 'Intensity']);
            }

            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }
}

class Export {
    public static function SidebarMaterialColorProperty(editor:Dynamic, property:String, name:String):SidebarMaterialColorProperty {
        return new SidebarMaterialColorProperty(editor, property, name);
    }
}