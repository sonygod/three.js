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
        super('Color', new UniformNode(new Color()));

        var node:UniformNode = cast this.node;
        var value:Color = node.value;

        var field:ColorInput = new ColorInput(0xFFFFFF);
        field.onChange = function() {
            value.setHex(field.getValue());
            updateFields('picker');
        }

        var hexField:StringInput = new StringInput();
        hexField.onChange = function() {
            var value:String = hexField.getValue();
            if (value.indexOf('#') == 0) {
                var hexStr:String = value.slice(1).lpad('0', 6);
                value.setHex(Std.parseInt(hexStr, 16));
                updateFields('hex');
            }
        }
        hexField.addEventListener('blur', updateFields);

        var onChangeRGB:Void->Void = function() {
            value.setRGB(fieldR.getValue(), fieldG.getValue(), fieldB.getValue());
            updateFields('rgb');
        }

        var fieldR:NumberInput = new NumberInput(1, 0, 1);
        fieldR.setTagColor('red');
        fieldR.onChange = onChangeRGB;

        var fieldG:NumberInput = new NumberInput(1, 0, 1);
        fieldG.setTagColor('green');
        fieldG.onChange = onChangeRGB;

        var fieldB:NumberInput = new NumberInput(1, 0, 1);
        fieldB.setTagColor('blue');
        fieldB.onChange = onChangeRGB;

        this.add(new Element().add(field).setSerializable(false))
            .add(new LabelElement('Hex').add(hexField).setSerializable(false))
            .add(new LabelElement('RGB').add(fieldR).add(fieldG).add(fieldB));

        updateFields();

        function updateFields(?editing:String):Void {
            var hexValue:Int = value.getHex();
            var hexString:String = StringTools.lpad(Std.string(hexValue, 16), '0', 6);

            if (editing != 'color') {
                field.setValue(hexValue, false);
            }

            if (editing != 'hex') {
                hexField.setValue('#' + hexString, false);
            }

            if (editing != 'rgb') {
                fieldR.setValue(Std.string(value.r, 3), false);
                fieldG.setValue(Std.string(value.g, 3), false);
                fieldB.setValue(Std.string(value.b, 3), false);
            }

            fieldR.setTagColor('#' + hexString.substr(0, 2) + '0000');
            fieldG.setTagColor('#00' + hexString.substr(2, 2) + '00');
            fieldB.setTagColor('#0000' + hexString.substr(4, 2));

            this.invalidate(); // it's important to scriptable nodes (cpu nodes needs update)
        }
    }
}