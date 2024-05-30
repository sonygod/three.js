package three.js.examples.jvm.nodes.code;

import Node;
import addNodeClass;
import ShaderNode.addNodeElement;
import ShaderNode.nodeProxy;
import ShaderNode.float;

class Resources extends Map<String, Dynamic> {

	public function get(key:String, ?callback:Dynamic->Void, params:Array<Dynamic>=null):Dynamic {
		if (this.exists(key)) return super.get(key);
		if (callback != null) {
			var value = callback(params);
			this.set(key, value);
			return value;
		}
		return null;
	}

}

class Parameters {

	public var scriptableNode:ScriptableNode;

	public function new(scriptableNode:ScriptableNode) {
		this.scriptableNode = scriptableNode;
	}

	public var parameters(get, never):Dynamic;
	inline function get_parameters():Dynamic {
		return scriptableNode.parameters;
	}

	public var layout(get, never):Dynamic;
-inline function get_layout():Dynamic {
		return scriptableNode.getLayout();
	}

	public function getInputLayout(id:String):Dynamic {
		return scriptableNode.getInputLayout(id);
	}

	public function get(name:String):Dynamic {
		var param:Dynamic = parameters[name];
		var value:Dynamic = (param != null) ? param.getValue() : null;
		return value;
	}

}

var global = new Resources();

class ScriptableNode extends Node {

	public var codeNode:Dynamic;
	public var parameters:Dynamic;
	public var _local:Resources;
	public var _output:Dynamic;
	public var _outputs:Dynamic<String, Dynamic>;
	public var _source:String;
	public var _method:Dynamic;
	public var _object:Dynamic;
	public var _value:Dynamic;
	public var _needsOutputUpdate:Bool;
	public var onRefresh:Void->Void;

	public function new(?codeNode:Dynamic, ?parameters:Dynamic={}) {
		super();
		this.codeNode = codeNode;
		this.parameters = parameters;
		this._local = new Resources();
		this._output = scriptableValue();
		this._outputs = {};
		this._source = this.source;
		this._method = null;
		this._object = null;
		this._value = null;
		this._needsOutputUpdate = true;
		this.onRefresh = this.onRefresh.bind(this);
		this.isScriptableNode = true;
	}

	inline function get_source():String {
		return (codeNode != null) ? codeNode.code : '';
	}

	public function setLocal(name:String, value:Dynamic):Void {
		return _local.set(name, value);
	}

	public function getLocal(name:String):Dynamic {
		return _local.get(name);
	}

	public function onRefresh():Void {
		_refresh();
	}

	public function getInputLayout(id:String):Dynamic {
		for (element in getLayout()) {
			if (element.inputType && (element.id == id || element.name == id)) {
				return element;
			}
		}
		return null;
	}

	public function getOutputLayout(id:String):Dynamic {
		for (element in getLayout()) {
			if (element.outputType && (element.id == id || element.name == id)) {
				return element;
			}
		}
		return null;
	}

	public function setOutput(name:String, value:Dynamic):ScriptableNode {
		var outputs = _outputs;
		if (!outputs.exists(name)) {
			outputs[name] = scriptableValue(value);
		} else {
			outputs[name].value = value;
		}
		return this;
	}

	public function getOutput(name:String):Dynamic {
		return _outputs[name];
	}

	public function getParameter(name:String):Dynamic {
		return parameters[name];
	}

	public function setParameter(name:String, value:Dynamic):ScriptableNode {
		var parameters:Dynamic = this.parameters;
		if (value != null && value.isScriptableNode) {
			deleteParameter(name);
			parameters[name] = value;
			parameters[name].getDefaultOutput().events.addEventListener('refresh', onRefresh);
		} else if (value != null && value.isScriptableValueNode) {
			deleteParameter(name);
			parameters[name] = value;
			parameters[name].events.addEventListener('refresh', onRefresh);
		} else if (parameters.exists(name)) {
			parameters[name].value = value;
		} else {
			parameters[name] = scriptableValue(value);
			parameters[name].events.addEventListener('refresh', onRefresh);
		}
		return this;
	}

	public function getValue():Dynamic {
		return getDefaultOutput().getValue();
	}

	public function deleteParameter(name:String):ScriptableNode {
		var valueNode:Dynamic = parameters[name];
		if (valueNode != null) {
			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();
			valueNode.events.removeEventListener('refresh', onRefresh);
		}
		return this;
	}

	public function clearParameters():ScriptableNode {
		for (name in parameters.keys()) {
			deleteParameter(name);
		}
		needsUpdate = true;
		return this;
	}

	public function call(name:String, params:Array<Dynamic>=null):Dynamic {
		var object:Dynamic = getObject();
		var method:Dynamic = object[name];
		if (method != null && Std.isOfType(method, Function)) {
			return method.apply(null, params);
		}
		return null;
	}

	public function callAsync(name:String, params:Array<Dynamic>=null):Promise<Dynamic> {
		var object:Dynamic = getObject();
		var method:Dynamic = object[name];
		if (method != null && Std.isOfType(method, Function)) {
			return Promise.async(function(callback) {
				method.apply(null, params).then(callback);
			});
		}
		return Promise.reject('Method not found');
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return getDefaultOutputNode().getNodeType(builder);
	}

	public function refresh(?output:Dynamic):Void {
		if (output != null) {
			getOutput(output).refresh();
		} else {
			_refresh();
		}
	}

	public function getObject():Dynamic {
		if (needsUpdate) dispose();
		if (_object != null) return _object;
		
		var refresh = _refresh.bind(this);
		var setOutput = setOutput.bind(this);
		var parameters:Parameters = new Parameters(this);
		var THREE:Dynamic = global.get('THREE');
		var TSL:Dynamic = global.get('TSL');
		var method:Dynamic = getMethod(codeNode);
		var params:Array<Dynamic> = [parameters, _local, global, refresh, setOutput, THREE, TSL];
		_object = method.apply(null, params);
		var layout:Dynamic = _object.layout;
		if (layout != null) {
			if (layout.cache == false) {
				_local.clear();
			}
			_output.outputType = layout.outputType;
			if (Std.isOfType(layout.elements, Array)) {
				for (element in layout.elements) {
					var id:String = element.id || element.name;
					if (element.inputType) {
						if (!parameters.exists(id)) setParameter(id, null);
						parameters[id].inputType = element.inputType;
					}
					if (element.outputType) {
						if (!outputs.exists(id)) setOutput(id, null);
						outputs[id].outputType = element.outputType;
					}
				}
			}
		}
		return _object;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		for (name in parameters.keys()) {
			var valueNode:Dynamic = parameters[name];
			if (valueNode != null && valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();
			valueNode.events.addEventListener('refresh', onRefresh);
		}
	}

	inline function getLayout():Dynamic {
		return getObject().layout;
	}

	public function getDefaultOutputNode():Dynamic {
		var output:Dynamic = getDefaultOutput().value;
		if (output != null && output.isNode) return output;
		return float();
	}

	inline function getDefaultOutput():Dynamic {
		return _exec()._output;
	}

	inline function getMethod(codeNode:Dynamic):Dynamic {
		if (needsUpdate) dispose();
		if (_method != null) return _method;
		
		var parametersProps:Array<String> = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
		var interfaceProps:Array<String> = ['layout', 'init', 'main', 'dispose'];
		var properties:String = interfaceProps.join(', ');
		var declarations:String = 'var ' + properties + '; var output = {};\n';
		var returns:String = '\nreturn { ...output, ' + properties + ' };';
		var code:String = declarations + codeNode.code + returns;
		
		_method = new Function(parametersProps, code);
		return _method;
	}

	public function dispose():Void {
		if (_method == null) return;
		if (_object != null && _object.dispose != null) {
			_object.dispose();
		}
		_method = null;
		_object = null;
		_source = null;
		_value = null;
		_needsOutputUpdate = true;
		_output.value = null;
		_outputs = {};
	}

	public function setup():Dynamic {
		return getDefaultOutputNode();
	}

	public var needsUpdate(get, set):Bool;
	inline function get_needsUpdate():Bool {
		return _source != source;
	}
	inline function set_needsUpdate(value:Bool):Void {
		if (value) dispose();
	}

	inline function _exec():ScriptableNode {
		if (codeNode == null) return this;
		if (_needsOutputUpdate) {
			_value = call('main');
			_needsOutputUpdate = false;
		}
		_output.value = _value;
		return this;
	}

	inline function _refresh():Void {
		needsUpdate = true;
		_exec();
		_output.refresh();
	}
}

scriptable = nodeProxy(ScriptableNode);
addNodeElement('scriptable', scriptable);
addNodeClass('ScriptableNode', ScriptableNode);