import flow.SelectInput;
import flow.LabelElement;
import three.nodes.UVNode;
import playground.editors.BaseNodeEditor;

class UVEditor extends BaseNodeEditor {

    public function new() {
        var node: UVNode = new UVNode();

        super('UV', node, 200);

        var optionsField: SelectInput = new SelectInput(['0', '1', '2', '3'], 0);
        optionsField.onChange(function() {
            node.index = Std.parseInt(optionsField.getValue());
            this.invalidate();
        });

        this.add(new LabelElement('Channel').add(optionsField));
    }

}