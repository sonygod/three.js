import Node from '../core/Node.hx';
import { scriptableValue } from './ScriptableValueNode.hx';
import { addNodeElement, nodeProxy, float } from '../shadernode/ShaderNode.hx';

class Resources extends Map {
	public function get(key:Dynamic, ?callback:Dynamic, ...params):Dynamic {
		if (this.has(key)) return super.get(key);
		if (callback != null) {
			const value = callback(...params);
			this.set(key, value);
			return value;
		}
	}
}

class Parameters {
	public var scriptableNode:Dynamic;

	public function new(scriptableNode:Dynamic) {
		this.scriptableNode = scriptableNode;
	}

	public function get parameters():Dynamic {
		return this.scriptableNode.parameters;
	}

	public function get layout():Dynamic {
		return this.scriptableNode.getLayout();
	}

	public function getInputLayout(id:Dynamic):Dynamic {
		return this.scriptableNode.getInputLayout(id);
	}

	public function get(name:Dynamic):Dynamic {
		const param = this.parameters[name];
		const value = param ? param.getValue() : null;
		return value;
	}
}

@:enum(true)
class global {
	public static var global:Resources = new Resources();
}

class ScriptableNode extends Node {
	public var codeNode:Dynamic;
	public var parameters:Dynamic;
	public var _local:Resources;
	public var _output:Dynamic;
	public var _outputs:Dynamic;
	public var _source:Dynamic;
	public var _method:Dynamic;
	public var _object:Dynamic;
	public var _value:Dynamic;
	public var _needsOutputUpdate:Bool;

	public function new(?codeNode:Dynamic, ?parameters:Dynamic) {
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

	public function get source():Dynamic {
		return this.codeNode ? this.codeNode.code : '';
	}

	public function setLocal(name:Dynamic, value:Dynamic):Dynamic {
		return this._local.set(name, value);
	}

	public function getLocal(name:Dynamic):Dynamic {
		return this._local.get(name);
	}

	public function onRefresh():Void {
		this._refresh();
	}

	public function getInputLayout(id:Dynamic):Dynamic {
		for (element in this.getLayout()) {
			if (element.inputType && (element.id == id || element.name == id)) {
				return element;
			}
		}
	}

	public function getOutputLayout(id:Dynamic):Dynamic {
		for (element in this.getLayout()) {
			if (element.outputType && (element.id == id || element.name == id)) {
				return element;
			}
		}
	}

	public function setOutput(name:Dynamic, value:Dynamic):Dynamic {
		const outputs = this._outputs;
		if (outputs[name] == null) {
			outputs[name] = scriptableValue(value);
		} else {
			outputs[name].value = value;
		}
		return this;
	}

	public function getOutput(name:Dynamic):Dynamic {
		return this._outputs[name];
	}

	public function getParameter(name:Dynamic):Dynamic {
		return this.parameters[name];
	}

	public function setParameter(name:Dynamic, value:Dynamic):Dynamic {
		const parameters = this.parameters;
		if (value && value.isScriptableNode) {
			this.deleteParameter(name);
			parameters[name] = value;
			parameters[name].getDefaultOutput().events.addEventListener('refresh', this.onRefresh);
		} else if (value && value.isScriptableValueNode) {
			this.deleteParameter(name);
			parameters[name] = value;
			parameters[name].events.addEventListener('refresh', this.onRefresh);
		} else if (parameters[name] == null) {
			parameters[name] = scriptableValue(value);
			parameters[name].events.addEventListener('refresh', this.onRefresh);
		} else {
			parameters[name].value = value;
		}
		return this;
	}

	public function getValue():Dynamic {
		return this.getDefaultOutput().getValue();
	}

	public function deleteParameter(name:Dynamic):Dynamic {
		var valueNode = this.parameters[name];
		if (valueNode != null) {
			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();
			valueNode.events.removeEventListener('refresh', this.onRefresh);
		}
		return this;
	}

	public function clearParameters():Dynamic {
		for (name in $iterator(this.parameters)) {
			this.deleteParameter(name);
		}
		this.needsUpdate = true;
		return this;
	}

	public function call(name:Dynamic, ...params):Dynamic {
		const object = this.getObject();
		const method = Reflect.field(object, name);
		if (Reflect.isFunction(method)) {
			return method(...params);
		}
	}

	public async function callAsync(name:Dynamic, ...params):Dynamic {
		const object = this.getObject();
		const method = Reflect.field(object, name);
		if (Reflect.isFunction(method)) {
			if (Reflect.isFunction(method, 'async')) {
				return await method(...params);
			} else {
				return method(...params);
			}
		}
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.getDefaultOutputNode().getNodeType(builder);
	}

	public function refresh(?output:Dynamic):Dynamic {
		if (output != null) {
			this.getOutput(output).refresh();
		} else {
			this._refresh();
		}
	}

	public function getObject():Dynamic {
		if (this.needsUpdate) this.dispose();
		if (this._object != null) return this._object;

		//

		const refresh = function():Void -> this.refresh();
		const setOutput = function(id:Dynamic, value:Dynamic):Void -> this.setOutput(id, value);

		const parameters = new Parameters(this);

		const THREE = global.global.get('THREE');
		const TSL = global.global.get('TSL');

		const method = this.getMethod(this.codeNode);
		const params = [parameters, this._local, global.global, refresh, setOutput, THREE, TSL];

		this._object = method(...params);

		const layout = this._object.layout;

		if (layout != null) {
			if (layout.cache == false) {
				this._local.clear();
			}

			// default output
			this._output.outputType = layout.outputType ?? null;

			if (layout.elements != null) {
				for (element in layout.elements) {
					const id = element.id ?? element.name;

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

		return this._object;
	}

	public override function deserialize(data:Dynamic):Void {
		super.deserialize(data);

		for (name in this.parameters) {
			var valueNode = this.parameters[name];
			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();
			valueNode.events.addEventListener('refresh', this.onRefresh);
		}
	}

	public function getLayout():Dynamic {
		return this.getObject().layout;
	}

	public function getDefaultOutputNode():Dynamic {
		const output = this.getDefaultOutput().value;
		if (output && output.isNode) {
			return output;
		}
		return float();
	}

	public function getDefaultOutput():Dynamic {
		return this._exec()._output;
	}

	public function getMethod():Dynamic {
		if (this.needsUpdate) this.dispose();
		if (this._method != null) return this._method;

		//

		const parametersProps = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
		const interfaceProps = ['layout', 'init', 'main', 'dispose'];

		const properties = interfaceProps.join(', ');
		const declarations = 'var ' + properties + '; var output = {};\n';
		const returns = '\nreturn { ...output, ' + properties + ' };';

		const code = declarations + this.codeNode.code + returns;

		//

		this._method = Reflect.makeClosure(parametersProps, code);

		return this._method;
	}

	public function dispose():Void {
		if (this._method == null) return;

		if (this._object && Reflect.hasField(this._object, 'dispose')) {
			Reflect.field(this._object, 'dispose');
		}

		this._method = null;
		this._object = null;
		this._source = null;
		this._value = null;
		this._needsOutputUpdate = true;
		this._output.value = null;
		this._outputs = {};
	}

	public function setup():Dynamic {
		return this.getDefaultOutputNode();
	}

	public function set needsUpdate(value:Bool):Bool {
		if (value) this.dispose();
	}

	public function get needsUpdate():Bool {
		return this.source != this._source;
	}

	public function _exec():Dynamic {
		if (this.codeNode == null) return this;

		if (this._needsOutputUpdate) {
			this._value = this.call('main');
			this._needsOutputUpdate = false;
		}

		this._output.value = this._value;

		return this;
	}

	public function _refresh():Void {
		this.needsUpdate = true;
		this._exec();
		this._output.refresh();
	}
}

@:native('ScriptableNode') @:require('shadergraph')
class ScriptableNode_native extends Node { }

@:native('scriptable') @:require('shadergraph')
class scriptable_native { }

@:native('addNodeElement') @:require('shadergraph')
function addNodeElement_native(id:Dynamic, node:Dynamic):Void { }

@:native('addNodeClass') @:require('shadergraph')
function addNodeClass_native(name:Dynamic, node:Dynamic):Void { }

addNodeElement('scriptable', nodeProxy(ScriptableNode));
addNodeClass('ScriptableNode', ScriptableNode);

export { ScriptableNode, scriptable, addNodeElement, addNodeClass };
export @:native('ScriptableNode') var ScriptableNode_native:Dynamic;
export @:native('scriptable') var scriptable_native:Dynamic;
export @:native('addNodeElement') function addNodeElement_native(id:Dynamic, node:Dynamic):Void;
export @:native('addNodeClass') function addNodeClass_native(name:Dynamic, node:Dynamic):Void;