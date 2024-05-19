package three.js.playground.editors;

import flow.ColorInput;
import flow.StringInput;
import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import three.Color;
import three.nodes.UniformNode;
import BaseNodeEditor;

class ColorEditor extends BaseNodeEditor {
    public function new() {
        super("Color", createNode());
    }

    private function createNode():UniformNode {
        var v:Color = new Color();
        return new UniformNode(v);
    }

    private var field:ColorInput;
    private var hexField:StringInput;
    private var fieldR:NumberInput;
    private var fieldG:NumberInput;
    private var fieldB:NumberInput;

    override public function init():Void {
        var node:UniformNode = cast getNode();
        var value:Color = node.value;

        field = new ColorInput(0xFFFFFF);
        field.onChange = function() {
            value.setHex(field.getValue());
            updateFields('picker');
        }

        hexField = new StringInput();
        hexField.onChange = function() {
            var value:String = hexField.getValue();
            if (value.indexOf('#') == 0) {
                var hexStr:String = value.slice(1).padEnd(6, '0');
                value.setHex( Std.parseInt(hexStr, 16) );
                updateFields('hex');
            }
        };
        hexField.addEventListener('blur', updateFields);

        fieldR = new NumberInput(1, 0, 1);
        fieldR.setTagColor('red');
        fieldR.onChange = onChangeRGB;

        fieldG = new NumberInput(1, 0, 1);
        fieldG.setTagColor('green');
        fieldG.onChange = onChangeRGB;

        fieldB = new NumberInput(1, 0, 1);
        fieldB.setTagColor('blue');
        fieldB.onChange = onChangeRGB;

        add(new Element().add(field).setSerializable(false));
        add(new LabelElement('Hex').add(hexField).setSerializable(false));
        add(new LabelElement('RGB').add(fieldR).add(fieldG).add(fieldB));

        updateFields();
    }

    private function updateFields(?editing:String):Void {
        var node:UniformNode = cast getNode();
        var value:Color = node.value;
        var hexValue:Int = value.getHex();
        var hexString:String = hexValue.toHexString().toUpperCase().padStart(6, '0');

        if (editing != 'color') {
            field.setValue(hexValue, false);
        }

        if (editing != 'hex') {
            hexField.setValue('#' + hexString, false);
        }

        if (editing != 'rgb') {
            fieldR.setValue(value.r.toFixed(3), false);
            fieldG.setValue(value.g.toFixed(3), false);
            fieldB.setValue(value.b.toFixed(3), false);
        }

        fieldR.setTagColor('#' + hexString.slice(0, 2) + '0000');
        fieldG.setTagColor('#00' + hexString.slice(2, 4) + '00');
        fieldB.setTagColor('#0000' + hexString.slice(4, 6));

        invalidate(); // it's important to scriptable nodes (cpu nodes needs update)
    }

    private function onChangeRGB():Void {
        var node:UniformNode = cast getNode();
        node.value.setRGB(fieldR.getValue(), fieldG.getValue(), fieldB.getValue());
        updateFields('rgb');
    }
}