import flow.ColorInput;
import flow.StringInput;
import flow.NumberInput;
import flow.LabelElement;
import flow.Element;
import three.Color;
import three.nodes.UniformNode;
import three.playground.editors.BaseNodeEditor;

class ColorEditor extends BaseNodeEditor {

    public function new() {
        var v = new Color();
        var node = new UniformNode(v);

        super('Color', node);

        var updateFields = function(editing: String = null): Void {
            var value = node.value;
            var hexValue = value.getHex();
            var hexString = StringTools.hex(hexValue, 6).toUpperCase();

            if (editing != 'color') {
                field.setValue(hexValue, false);
            }

            if (editing != 'hex') {
                hexField.setValue('#' + hexString, false);
            }

            if (editing != 'rgb') {
                fieldR.setValue(value.r, false);
                fieldG.setValue(value.g, false);
                fieldB.setValue(value.b, false);
            }

            fieldR.setTagColor('#' + hexString.substr(0, 2) + '0000');
            fieldG.setTagColor('#00' + hexString.substr(2, 2) + '00');
            fieldB.setTagColor('#0000' + hexString.substr(4, 2));

            this.invalidate();
        };

        var field = new ColorInput(0xFFFFFF).onChange(function() {
            node.value.setHex(field.getValue());
            updateFields('picker');
        });

        var hexField = new StringInput().onChange(function() {
            var value = hexField.getValue();
            if (value.indexOf('#') == 0) {
                var hexStr = StringTools.rpad(value.substr(1), '0', 6);
                node.value.setHex(Std.parseInt(hexStr));
                updateFields('hex');
            }
        });

        hexField.addEventListener('blur', function() {
            updateFields();
        });

        var onChangeRGB = function(): Void {
            node.value.setRGB(fieldR.getValue(), fieldG.getValue(), fieldB.getValue());
            updateFields('rgb');
        };

        var fieldR = new NumberInput(1, 0, 1).setTagColor('red').onChange(onChangeRGB);
        var fieldG = new NumberInput(1, 0, 1).setTagColor('green').onChange(onChangeRGB);
        var fieldB = new NumberInput(1, 0, 1).setTagColor('blue').onChange(onChangeRGB);

        this.add(new Element().add(field).setSerializable(false))
            .add(new LabelElement('Hex').add(hexField).setSerializable(false))
            .add(new LabelElement('RGB').add(fieldR).add(fieldG).add(fieldB));

        updateFields();
    }
}