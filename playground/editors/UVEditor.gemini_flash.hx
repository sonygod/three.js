import flow.SelectInput;
import flow.LabelElement;
import BaseNodeEditor from "../BaseNodeEditor";
import three.nodes.uv;

class UVEditor extends BaseNodeEditor {

	public function new() {
		var node = uv();

		super("UV", node, 200);

		var optionsField = new SelectInput(["0", "1", "2", "3"], 0);
		optionsField.onChange = function() {
			node.index = Std.parseInt(optionsField.getValue());
			this.invalidate();
		};

		this.add(new LabelElement("Channel").add(optionsField));
	}

}