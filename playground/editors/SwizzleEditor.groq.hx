package three.playground.editors;

import flow.LabelElement;
import three.nodes.Split;
import three.nodes.Float;
import three.DataTypeLib;
import three.NodeEditorUtils;

class SwizzleEditor extends BaseNodeEditor {
	
	public function new() {
		super("Swizzle", createNode(), 175);
		
		var inputElement:LabelElement = DataTypeLib.setInputAestheticsFromType(new LabelElement("Input"), "node");
		inputElement.onConnect = function() {
			node.node = inputElement.getLinkedObject() || new Float();
		}
		this.add(inputElement);
		
		var componentsElement = NodeEditorUtils.createElementFromJSON({
			inputType: "String",
			allows: "xyzwrgba",
			transform: "lowercase",
			options: ["x", "y", "z", "w", "r", "g", "b", "a"],
			maxLength: 4
		});
		componentsElement.addEventListener("changeInput", function() {
			var string:String = componentsElement.value;
			node.components = if (string != null && string != "") string else "x";
			this.invalidate();
		});
		this.add(componentsElement);
	}
	
	private function createNode():Split {
		var node:Split = new Split(new Float(), "x");
		return node;
	}
}