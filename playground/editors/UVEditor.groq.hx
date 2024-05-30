package three.js.playground.editors;

import flow.SelectInput;
import flow.LabelElement;
import three.nodes.UV;

class UVEditor extends BaseNodeEditor {

    public function new() {
        super("UV", new UV(), 200);

        var optionsField = new SelectInput(["0", "1", "2", "3"], 0);
        optionsField.onChange = function() {
            UV(node).index = Std.parseInt(optionsField.getValue());
            invalidate();
        }

        add(new LabelElement("Channel").add(optionsField));
    }

}