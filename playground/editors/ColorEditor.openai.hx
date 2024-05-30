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

        var v = new three.Color();
        var node = new three.nodes.UniformNode(v);

        super("Color", node);

        var updateFields = function(editing:String) {
            var value:three.Color = node.value;
            var hexValue:Int = value.getHex();
            var hexString:String = StringTools.hex(hexValue, 6);

            if (editing != "color") {
                field.setValue(hexValue, false);
            }

            if (editing != "hex") {
                hexField.setValue("#" + hexString, false);
            }

            if (editing != "rgb") {
                fieldR.setValue(parseFloat(StringTools.format("%2.3f", value.r)));
                fieldG.setValue(parseFloat(StringTools.format("%2.3f", value.g)));
                fieldB.setValue(parseFloat(StringTools.format("%2.3f", value.b)));
            }

            fieldR.setTagColor("#" + hexString.substr(0, 2) + "0000");
            fieldG.setTagColor("#00" + hexString.substr(2, 2) + "00");
            fieldB.setTagColor("#0000" + hexString.substr(4, 2));

            this.invalidate(); // it's important to scriptable nodes ( cpu nodes needs update )
        };

        var field = new ColorInput(0xFFFFFF);
        field.onChange(function(){
            node.value.setHex(field.getValue());
            updateFields("picker");
        });

        var hexField = new StringInput();
        hexField.onChange(function(){
            var value:String = hexField.getValue();

            if (value.indexOf("#") == 0) {
                var hexStr:String = value.substr(1).lpad("0", 6);

                node.value.setHex(Std.parseInt(hexStr, 16));

                updateFields("hex");
            }
        });
        hexField.addEventListener("blur", function(){
            updateFields();
        });

        var onChangeRGB = function() {
            node.value.setRGB(fieldR.getValue(), fieldG.getValue(), fieldB.getValue());
            updateFields("rgb");
        };

        var fieldR = new NumberInput(1, 0, 1);
        fieldR.setTagColor("red");
        fieldR.onChange(onChangeRGB);

        var fieldG = new NumberInput(1, 0, 1);
        fieldG.setTagColor("green");
        fieldG.onChange(onChangeRGB);

        var fieldB = new NumberInput(1, 0, 1);
        fieldB.setTagColor("blue");
        fieldB.onChange(onChangeRGB);

        this.add(new Element().add(field).setSerializable(false))
            .add(new LabelElement("Hex").add(hexField).setSerializable(false))
            .add(new LabelElement("RGB").add(fieldR).add(fieldG).add(fieldB));

        updateFields();
    }
}