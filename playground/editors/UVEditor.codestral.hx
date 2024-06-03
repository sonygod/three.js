import flow.SelectInput;
import flow.LabelElement;
import editors.BaseNodeEditor;
import three.nodes.uv;

class UVEditor extends BaseNodeEditor {

    public function new() {

        var node:uv = new uv();

        super("UV", node, 200);

        var optionsField:SelectInput = new SelectInput(["0", "1", "2", "3"], 0);
        optionsField.onChange(function() {
            node.index = Std.parseInt(optionsField.getValue());
            this.invalidate();
        });

        this.add(new LabelElement("Channel").add(optionsField));
    }
}