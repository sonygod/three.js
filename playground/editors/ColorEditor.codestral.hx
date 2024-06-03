import flow.ColorInput;
import flow.StringInput;
import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import BaseNodeEditor;
import three.Color;
import three.nodes.UniformNode;

class ColorEditor extends BaseNodeEditor {

    public function new() {
        var v:Color = new Color();
        var node:UniformNode = new UniformNode(v);

        super('Color', node);

        var updateFields = function(editing:String) {
            var value = node.value;
            var hexValue = value.getHex();
            var hexString = hexValue.toString(16).toUpperCase().padStart(6, '0');

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

            this.invalidate();
        };

        var field = new ColorInput(0xFFFFFF).onChange(function() {
            node.value.setHex(field.getValue());
            updateFields('picker');
        });

        var hexField = new StringInput().onChange(function() {
            var value = hexField.getValue();

            if (value.indexOf('#') == 0) {
                var hexStr = value.slice(1).padEnd(6, '0');
                node.value.setHex(Std.parseInt(hexStr, 16));
                updateFields('hex');
            }
        });

        hexField.addEventListener('blur', function() {
            updateFields('');
        });

        var onChangeRGB = function() {
            node.value.setRGB(fieldR.getValue(), fieldG.getValue(), fieldB.getValue());
            updateFields('rgb');
        };

        var fieldR = new NumberInput(1, 0, 1).setTagColor('red').onChange(onChangeRGB);
        var fieldG = new NumberInput(1, 0, 1).setTagColor('green').onChange(onChangeRGB);
        var fieldB = new NumberInput(1, 0, 1).setTagColor('blue').onChange(onChangeRGB);

        this.add(new Element().add(field).setSerializable(false))
            .add(new LabelElement('Hex').add(hexField).setSerializable(false))
            .add(new LabelElement('RGB').add(fieldR).add(fieldG).add(fieldB));

        updateFields('');
    }
}