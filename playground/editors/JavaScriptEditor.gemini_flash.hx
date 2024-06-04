import js.Js;
import three.nodes.CodeNode;
import three.nodes.Node;
import three.nodes.Js as JsNode;
import three.nodes.FunctionNode;
import three.nodes.Vector3Node;
import three.nodes.ColorNode;
import three.nodes.TextureNode;
import three.nodes.FloatNode;
import three.nodes.IntNode;
import three.nodes.BoolNode;
import three.nodes.StringNode;
import three.nodes.NodeUtils;
import three.nodes.NodeMaterial;
import three.nodes.NodeAttribute;
import three.nodes.NodeVarying;
import three.nodes.NodeUniform;
import three.nodes.NodeGeometry;
import three.nodes.NodeMetadata;
import three.nodes.NodeCallback;
import three.nodes.NodeBuilder;
import three.nodes.NodeContext;
import three.nodes.NodeConstant;
import three.nodes.NodeSampler;
import three.nodes.NodeProperty;
import three.nodes.NodeProperties;

import three.nodes.inputs.NodeInput;
import three.nodes.inputs.Vector3Input;
import three.nodes.inputs.ColorInput;
import three.nodes.inputs.TextureInput;
import three.nodes.inputs.FloatInput;
import three.nodes.inputs.IntInput;
import three.nodes.inputs.BoolInput;
import three.nodes.inputs.StringInput;
import three.nodes.inputs.NodeInputSocket;
import three.nodes.inputs.NodeOutputSocket;
import three.nodes.inputs.NodeInputSocketType;
import three.nodes.inputs.NodeOutputSocketType;

import three.nodes.outputs.NodeOutput;
import three.nodes.outputs.Vector3Output;
import three.nodes.outputs.ColorOutput;
import three.nodes.outputs.TextureOutput;
import three.nodes.outputs.FloatOutput;
import three.nodes.outputs.IntOutput;
import three.nodes.outputs.BoolOutput;
import three.nodes.outputs.StringOutput;

import three.nodes.utils.NodeUtils;
import three.nodes.utils.NodeCallback;

import three.nodes.elements.CodeEditorElement;
import three.nodes.elements.NodeEditorElement;

import three.nodes.editors.BaseNodeEditor;

class JavaScriptEditor extends BaseNodeEditor {
	var editorElement:CodeEditorElement;

	public function new(source:String = "") {
		var codeNode = JsNode.create(source);
		super("JavaScript", codeNode, 500);

		this.setResizable(true);

		this.editorElement = new CodeEditorElement(source);
		this.editorElement.addEventListener("change", function() {
			codeNode.code = this.editorElement.source;
			this.invalidate();
			this.editorElement.focus();
		});

		this.add(this.editorElement);
	}

	public function set source(value:String) {
		this.codeNode.code = value;
	}

	public function get source():String {
		return this.codeNode.code;
	}

	public function get codeNode():CodeNode {
		return cast this.value;
	}
}