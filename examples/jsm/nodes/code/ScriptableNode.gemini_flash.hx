import Node from "../core/Node.hx";
import ScriptableValueNode from "./ScriptableValueNode.hx";
import ShaderNode from "../shadernode/ShaderNode.hx";

class Resources extends Map<String, Dynamic> {

	public function new() : Void {
		super();
	}

	public function get(key: String, callback: Dynamic = null, ...params: Array<Dynamic>): Dynamic {
		if (this.has(key)) {
			return super.get(key);
		}

		if (callback != null) {
			var value = callback(...params);
			this.set(key, value);
			return value;
		}

		return null;
	}

}

class Parameters {

	public var scriptableNode: ScriptableNode;

	public function new(scriptableNode: ScriptableNode) {
		this.scriptableNode = scriptableNode;
	}

	public function get parameters(): Dynamic {
		return this.scriptableNode.parameters;
	}

	public function get layout(): Dynamic {
		return this.scriptableNode.getLayout();
	}

	public function getInputLayout(id: String): Dynamic {
		return this.scriptableNode.getInputLayout(id);
	}

	public function get(name: String): Dynamic {
		var param = this.parameters[name];
		var value = param != null ? param.getValue() : null;
		return value;
	}

}

var global: Resources = new Resources();

class ScriptableNode extends Node {

	public var codeNode: Dynamic;
	public var parameters: Dynamic;
	public var _local: Resources;
	public var _output: ScriptableValueNode;
	public var _outputs: Map<String, ScriptableValueNode> = new Map<String, ScriptableValueNode>();
	public var _source: String;
	public var _method: Dynamic;
	public var _object: Dynamic;
	public var _value: Dynamic;
	public var _needsOutputUpdate: Bool = true;

	public function new(codeNode: Dynamic = null, parameters: Dynamic = {}) {
		super();

		this.codeNode = codeNode;
		this.parameters = parameters;

		this._local = new Resources();
		this._output = ScriptableValueNode.scriptableValue();
		this._source = this.source;
		this._method = null;
		this._object = null;
		this._value = null;

		this.onRefresh = this.onRefresh.bind(this);

		this.isScriptableNode = true;
	}

	public function get source(): String {
		return this.codeNode != null ? this.codeNode.code : '';
	}

	public function setLocal(name: String, value: Dynamic): Void {
		this._local.set(name, value);
	}

	public function getLocal(name: String): Dynamic {
		return this._local.get(name);
	}

	public function onRefresh(): Void {
		this._refresh();
	}

	public function getInputLayout(id: String): Dynamic {
		for (element in this.getLayout()) {
			if (element.inputType != null && (element.id == id || element.name == id)) {
				return element;
			}
		}
		return null;
	}

	public function getOutputLayout(id: String): Dynamic {
		for (element in this.getLayout()) {
			if (element.outputType != null && (element.id == id || element.name == id)) {
				return element;
			}
		}
		return null;
	}

	public function setOutput(name: String, value: Dynamic): ScriptableNode {
		var outputs = this._outputs;
		if (outputs.exists(name)) {
			outputs.get(name).value = value;
		} else {
			outputs.set(name, ScriptableValueNode.scriptableValue(value));
		}
		return this;
	}

	public function getOutput(name: String): ScriptableValueNode {
		return this._outputs.get(name);
	}

	public function getParameter(name: String): Dynamic {
		return this.parameters[name];
	}

	public function setParameter(name: String, value: Dynamic): ScriptableNode {
		var parameters = this.parameters;
		if (value != null && value.isScriptableNode) {
			this.deleteParameter(name);
			parameters[name] = value;
			parameters[name].getDefaultOutput().events.addEventListener('refresh', this.onRefresh);
		} else if (value != null && value.isScriptableValueNode) {
			this.deleteParameter(name);
			parameters[name] = value;
			parameters[name].events.addEventListener('refresh', this.onRefresh);
		} else if (parameters[name] == null) {
			parameters[name] = ScriptableValueNode.scriptableValue(value);
			parameters[name].events.addEventListener('refresh', this.onRefresh);
		} else {
			parameters[name].value = value;
		}
		return this;
	}

	public function getValue(): Dynamic {
		return this.getDefaultOutput().getValue();
	}

	public function deleteParameter(name: String): ScriptableNode {
		var valueNode = this.parameters[name];
		if (valueNode != null) {
			if (valueNode.isScriptableNode) {
				valueNode = valueNode.getDefaultOutput();
			}
			valueNode.events.removeEventListener('refresh', this.onRefresh);
		}
		return this;
	}

	public function clearParameters(): ScriptableNode {
		for (name in this.parameters) {
			this.deleteParameter(name);
		}
		this.needsUpdate = true;
		return this;
	}

	public function call(name: String, ...params: Array<Dynamic>): Dynamic {
		var object = this.getObject();
		var method = object[name];
		if (Reflect.isFunction(method)) {
			return Reflect.callMethod(method, object, params);
		}
		return null;
	}

	public function callAsync(name: String, ...params: Array<Dynamic>): Dynamic {
		var object = this.getObject();
		var method = object[name];
		if (Reflect.isFunction(method)) {
			if (Reflect.getProperty(method, "constructor").name == "AsyncFunction") {
				return Reflect.callMethod(method, object, params);
			} else {
				return Reflect.callMethod(method, object, params);
			}
		}
		return null;
	}

	public function getNodeType(builder: Dynamic): Dynamic {
		return this.getDefaultOutputNode().getNodeType(builder);
	}

	public function refresh(output: String = null): Void {
		if (output != null) {
			this.getOutput(output).refresh();
		} else {
			this._refresh();
		}
	}

	public function getObject(): Dynamic {
		if (this.needsUpdate) {
			this.dispose();
		}
		if (this._object != null) {
			return this._object;
		}

		var refresh = () -> this.refresh();
		var setOutput = (id: String, value: Dynamic) -> this.setOutput(id, value);

		var parameters = new Parameters(this);

		var THREE = global.get('THREE');
		var TSL = global.get('TSL');

		var method = this.getMethod(this.codeNode);
		var params = [parameters, this._local, global, refresh, setOutput, THREE, TSL];

		this._object = method(...params);

		var layout = this._object.layout;

		if (layout != null) {
			if (layout.cache == false) {
				this._local.clear();
			}

			this._output.outputType = layout.outputType != null ? layout.outputType : null;

			if (Reflect.isList(layout.elements)) {
				for (element in layout.elements) {
					var id = element.id != null ? element.id : element.name;
					if (element.inputType != null) {
						if (this.getParameter(id) == null) {
							this.setParameter(id, null);
						}
						this.getParameter(id).inputType = element.inputType;
					}
					if (element.outputType != null) {
						if (this.getOutput(id) == null) {
							this.setOutput(id, null);
						}
						this.getOutput(id).outputType = element.outputType;
					}
				}
			}
		}

		return this._object;
	}

	public function deserialize(data: Dynamic): Void {
		super.deserialize(data);
		for (name in this.parameters) {
			var valueNode = this.parameters[name];
			if (valueNode.isScriptableNode) {
				valueNode = valueNode.getDefaultOutput();
			}
			valueNode.events.addEventListener('refresh', this.onRefresh);
		}
	}

	public function getLayout(): Dynamic {
		return this.getObject().layout;
	}

	public function getDefaultOutputNode(): Node {
		var output = this.getDefaultOutput().value;
		if (output != null && output.isNode) {
			return output;
		}
		return ShaderNode.float();
	}

	public function getDefaultOutput(): ScriptableValueNode {
		return this._exec()._output;
	}

	public function getMethod(codeNode: Dynamic): Dynamic {
		if (this.needsUpdate) {
			this.dispose();
		}
		if (this._method != null) {
			return this._method;
		}

		var parametersProps = ["parameters", "local", "global", "refresh", "setOutput", "THREE", "TSL"];
		var interfaceProps = ["layout", "init", "main", "dispose"];

		var properties = interfaceProps.join(", ");
		var declarations = "var " + properties + "; var output = {};\n";
		var returns = "\nreturn { ...output, " + properties + " };";

		var code = declarations + codeNode.code + returns;

		this._method = new Function(...parametersProps, code);
		return this._method;
	}

	public function dispose(): Void {
		if (this._method == null) {
			return;
		}
		if (this._object != null && Reflect.isFunction(this._object.dispose)) {
			Reflect.callMethod(this._object.dispose, this._object, []);
		}
		this._method = null;
		this._object = null;
		this._source = null;
		this._value = null;
		this._needsOutputUpdate = true;
		this._output.value = null;
		this._outputs.clear();
	}

	public function setup(): Node {
		return this.getDefaultOutputNode();
	}

	public function set needsUpdate(value: Bool) {
		if (value) {
			this.dispose();
		}
	}

	public function get needsUpdate(): Bool {
		return this.source != this._source;
	}

	public function _exec(): ScriptableNode {
		if (this.codeNode == null) {
			return this;
		}
		if (this._needsOutputUpdate) {
			this._value = this.call("main");
			this._needsOutputUpdate = false;
		}
		this._output.value = this._value;
		return this;
	}

	public function _refresh(): Void {
		this.needsUpdate = true;
		this._exec();
		this._output.refresh();
	}

}

export var scriptable = ShaderNode.nodeProxy(ScriptableNode);
ShaderNode.addNodeElement("scriptable", scriptable);
ShaderNode.addNodeClass("ScriptableNode", ScriptableNode);

export default ScriptableNode;