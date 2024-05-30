import js.three.nodes.UniformNode;
import js.flow.ColorInput;
import js.flow.StringInput;
import js.flow.NumberInput;
import js.flow.LabelElement;
import js.flow.Element;

class ColorEditor extends BaseNodeEditor {
    public function new(v:Color, node:UniformNode) {
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

            invalidate();
        };

        var field = new ColorInput(0xFFFFFF);
        field.onChange = function() {
            node.value.setHex(field.getValue());
            updateFields('picker');
        };

        var hexField = new StringInput();
        hexField.onChange = function() {
            var value = hexField.getValue();
            if (value.indexOf('#') == 0) {
                var hexStr = value.slice(1, 7).padEnd(6, '0');
                node.value.setHex(Std.parseInt('0x' + hexStr));
                updateFields('hex');
            }
        };
        hexField.addEventListener('blur', function() {
            updateFields();
        });

        var onChangeRGB = function() {
            node.value.setRGB(fieldR.getValue(), fieldG.getValue(), fieldB.getValue());
            updateFields('rgb');
        };

        var fieldR = new NumberInput(1, 0, 1);
        fieldR.setTagColor('red');
        fieldR.onChange = onChangeRGB;

        var fieldG = new NumberInput(1, 0, 1);
        fieldG.setTagColor('green');
        fieldG.onChange = onChangeRGB;

        var fieldB = new NumberInput(1, 0, 1);
        fieldB.setTagColor('blue');
        fieldB.onChange = onChangeRGB;

        add(new Element().add(field).setSerializable(false))
            .add(new LabelElement('Hex').add(hexField).setSerializable(false))
            .add(new LabelElement('RGB').add(fieldR).add(fieldG).add(fieldB));

        updateFields();
    }
}