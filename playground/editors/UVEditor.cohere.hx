import js.Browser.Window;
import js.three.nodes.UVNode;
import js.flow.SelectInput;
import js.flow.LabelElement;

class UVEditor extends BaseNodeEditor {
	public function new() {
		var node = new UVNode();
		super('UV', node, 200);
		var optionsField = new SelectInput(['0', '1', '2', '3'], 0);
		optionsField.onChange(function() {
			node.index = Std.parseInt(optionsField.getValue());
			this.invalidate();
		});
		this.add(new LabelElement('Channel').add(optionsField));
	}
}