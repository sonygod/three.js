import node.Node;
import node.ScriptableValueNode;
import shadernode.ShaderNode;

class Resources extends Map<String, Dynamic> {

	public function new() : Void {
		super();
	}

	public function get(key: String, callback: Dynamic = null, ...params: Array<Dynamic>): Dynamic {
		if (this.has(key)) return super.get(key);

		if (callback != null) {
			var value = callback.apply(null, params);
			this.set(key, value);
			return value;
		}
	}

}

class Parameters {

	public var scriptableNode: ScriptableNode;

	public function new(scriptableNode: ScriptableNode) {
		this.scriptableNode = scriptableNode;
	}

	public function get parameters(): Dynamic {
		return scriptableNode.parameters;
	}

	public function get layout(): Dynamic {
		return scriptableNode.getLayout();
	}

	public function getInputLayout(id: String): Dynamic {
		return scriptableNode.getInputLayout(id);
	}

	public function get(name: String): Dynamic {
		var param = parameters[name];
		return param != null ? param.getValue() : null;
	}

}

var global: Resources = new Resources();

class ScriptableNode extends Node {

	public var codeNode: Dynamic;
	public var parameters: Dynamic;
	public var _local: Resources;
	public var _output: ScriptableValueNode;
	public var _outputs: Map<String, ScriptableValueNode>;
	public var _source: String;
	public var _method: Dynamic;
	public var _object: Dynamic;
	public var _value: Dynamic;
	public var _needsOutputUpdate: Bool;

	public function new(codeNode: Dynamic = null, parameters: Dynamic = {}) {
		super();

		this.codeNode = codeNode;
		this.parameters = parameters;

		this._local = new Resources();
		this._output = ScriptableValueNode.scriptableValue();
		this._outputs = new Map();
		this._source = this.source;
		this._method = null;
		this._object = null;
		this._value = null;
		this._needsOutputUpdate = true;

		this.onRefresh = this.onRefresh.bind(this);

		this.isScriptableNode = true;
	}

	public function get source(): String {
		return codeNode != null ? codeNode.code : '';
	}

	public function setLocal(name: String, value: Dynamic): Void {
		_local.set(name, value);
	}

	public function getLocal(name: String): Dynamic {
		return _local.get(name);
	}

	public function onRefresh(): Void {
		_refresh();
	}

	public function getInputLayout(id: String): Dynamic {
		for (element in this.getLayout()) {
			if (element.inputType != null && (element.id == id || element.name == id)) {
				return element;
			}
		}
	}

	public function getOutputLayout(id: String): Dynamic {
		for (element in this.getLayout()) {
			if (element.outputType != null && (element.id == id || element.name == id)) {
				return element;
			}
		}
	}

	public function setOutput(name: String, value: Dynamic): ScriptableNode {
		var outputs = _outputs;

		if (outputs.exists(name)) {
			outputs.get(name).value = value;
		} else {
			outputs.set(name, ScriptableValueNode.scriptableValue(value));
		}

		return this;
	}

	public function getOutput(name: String): ScriptableValueNode {
		return _outputs.get(name);
	}

	public function getParameter(name: String): Dynamic {
		return parameters[name];
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
			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();
			valueNode.events.removeEventListener('refresh', this.onRefresh);
		}

		return this;
	}

	public function clearParameters(): ScriptableNode {
		for (name in Reflect.fields(this.parameters)) {
			this.deleteParameter(name);
		}

		this.needsUpdate = true;

		return this;
	}

	public function call(name: String, ...params: Array<Dynamic>): Dynamic {
		var object = this.getObject();
		var method = Reflect.field(object, name);
		if (Reflect.isFunction(method)) {
			return Reflect.callMethod(object, name, params);
		}
	}

	public function callAsync(name: String, ...params: Array<Dynamic>): Dynamic {
		var object = this.getObject();
		var method = Reflect.field(object, name);
		if (Reflect.isFunction(method)) {
			if (Reflect.getKind(method) == Reflect.FunctionKind.Async) {
				return Reflect.callMethod(object, name, params);
			} else {
				return Reflect.callMethod(object, name, params);
			}
		}
	}

	public function getNodeType(builder: Dynamic): Dynamic {
		return this.getDefaultOutputNode().getNodeType(builder);
	}

	public function refresh(output: String = null): Void {
		if (output != null) {
			this.getOutput(output).refresh();
		} else {
			_refresh();
		}
	}

	public function getObject(): Dynamic {
		if (this.needsUpdate) this.dispose();
		if (_object != null) return _object;

		var refresh = () -> this.refresh();
		var setOutput = (id: String, value: Dynamic) -> this.setOutput(id, value);

		var parameters = new Parameters(this);

		var THREE = global.get('THREE');
		var TSL = global.get('TSL');

		var method = this.getMethod(this.codeNode);
		var params = [parameters, _local, global, refresh, setOutput, THREE, TSL];

		_object = method.apply(null, params);

		var layout = _object.layout;

		if (layout != null) {
			if (layout.cache == false) {
				_local.clear();
			}

			_output.outputType = layout.outputType != null ? layout.outputType : null;

			if (Reflect.isArray(layout.elements)) {
				for (element in layout.elements) {
					var id = element.id != null ? element.id : element.name;

					if (element.inputType != null) {
						if (this.getParameter(id) == null) this.setParameter(id, null);
						this.getParameter(id).inputType = element.inputType;
					}

					if (element.outputType != null) {
						if (this.getOutput(id) == null) this.setOutput(id, null);
						this.getOutput(id).outputType = element.outputType;
					}
				}
			}
		}

		return _object;
	}

	public function deserialize(data: Dynamic): Void {
		super.deserialize(data);

		for (name in Reflect.fields(this.parameters)) {
			var valueNode = this.parameters[name];

			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();

			valueNode.events.addEventListener('refresh', this.onRefresh);
		}
	}

	public function getLayout(): Dynamic {
		return this.getObject().layout;
	}

	public function getDefaultOutputNode(): Dynamic {
		var output = this.getDefaultOutput().value;

		if (output != null && output.isNode) {
			return output;
		}

		return ShaderNode.float();
	}

	public function getDefaultOutput(): ScriptableValueNode {
		return _exec()._output;
	}

	public function getMethod(codeNode: Dynamic): Dynamic {
		if (this.needsUpdate) this.dispose();
		if (_method != null) return _method;

		var parametersProps = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
		var interfaceProps = ['layout', 'init', 'main', 'dispose'];

		var properties = interfaceProps.join(', ');
		var declarations = 'var ' + properties + '; var output = {};\n';
		var returns = '\nreturn { ...output, ' + properties + ' };';

		var code = declarations + codeNode.code + returns;

		_method = new Function(...parametersProps, code);

		return _method;
	}

	public function dispose(): Void {
		if (_method == null) return;

		if (_object != null && Reflect.isFunction(Reflect.field(_object, 'dispose'))) {
			Reflect.callMethod(_object, 'dispose', []);
		}

		_method = null;
		_object = null;
		_source = null;
		_value = null;
		_needsOutputUpdate = true;
		_output.value = null;
		_outputs.clear();
	}

	public function setup(): Dynamic {
		return this.getDefaultOutputNode();
	}

	public function set needsUpdate(value: Bool) {
		if (value) this.dispose();
	}

	public function get needsUpdate(): Bool {
		return this.source != _source;
	}

	public function _exec(): ScriptableNode {
		if (this.codeNode == null) return this;

		if (_needsOutputUpdate) {
			_value = this.call('main');
			_needsOutputUpdate = false;
		}

		_output.value = _value;

		return this;
	}

	public function _refresh(): Void {
		this.needsUpdate = true;
		_exec();
		_output.refresh();
	}

}

var scriptable: ScriptableNode = ShaderNode.nodeProxy(ScriptableNode);

ShaderNode.addNodeElement('scriptable', scriptable);

ShaderNode.addNodeClass('ScriptableNode', ScriptableNode);