import Node, { addNodeClass } from '../core/Node.hx';
import { scriptableValue } from './ScriptableValueNode.hx';
import { addNodeElement, nodeProxy, float } from '../shadernode/ShaderNode.hx';

class Resources extends haxe.ds.Map<String, Dynamic> {

	public function get(key:String, callback:Null<Dynamic>, params:Array<Dynamic>):Dynamic {

		if (this.exists(key)) return super.get(key);

		if (callback != null) {

			var value = callback.apply(params);
			this.set(key, value);
			return value;

		}

	}

}

class Parameters {

	public var scriptableNode:ScriptableNode;

	public function new(scriptableNode:ScriptableNode) {

		this.scriptableNode = scriptableNode;

	}

	public var parameters(get, never):Map<String, Dynamic> {

		return this.scriptableNode.parameters;

	}

	public var layout(get, never):Layout {

		return this.scriptableNode.getLayout();

	}

	public function getInputLayout(id:String):LayoutElement {

		return this.scriptableNode.getInputLayout(id);

	}

	public function get(name:String):Dynamic {

		var param = this.parameters[name];
		var value = param != null ? param.getValue() : null;

		return value;

	}

}

@:build(macro.Library.add("global"))
extern var global:Resources;

class ScriptableNode extends Node {

	public var codeNode:Node;
	public var parameters:Map<String, Dynamic>;

	private var _local:Resources;
	private var _output:ScriptableValueNode;
	private var _outputs:Map<String, Dynamic>;
	private var _source:String;
	private var _method:Dynamic;
	private var _object:Dynamic;
	private var _value:Dynamic;
	private var _needsOutputUpdate:Bool;

	public function new(codeNode:Node = null, parameters:Map<String, Dynamic> = {}) {

		super();

		this.codeNode = codeNode;
		this.parameters = parameters;

		this._local = new Resources();
		this._output = scriptableValue();
		this._outputs = new Map();
		this._source = this.source;
		this._method = null;
		this._object = null;
		this._value = null;
		this._needsOutputUpdate = true;

		this.onRefresh = this.onRefresh.bind(this);

		this.isScriptableNode = true;

	}

	public var source(get, never):String {

		return this.codeNode != null ? this.codeNode.code : '';

	}

	public function setLocal(name:String, value:Dynamic):Dynamic {

		return this._local.set(name, value);

	}

	public function getLocal(name:String):Dynamic {

		return this._local.get(name);

	}

	public function onRefresh():Void {

		this._refresh();

	}

	public function getInputLayout(id:String):LayoutElement {

		for (element in this.getLayout()) {

			if (element.inputType && (element.id == id || element.name == id)) {

				return element;

			}

		}

	}

	public function getOutputLayout(id:String):LayoutElement {

		for (element in this.getLayout()) {

			if (element.outputType && (element.id == id || element.name == id)) {

				return element;

			}

		}

	}

	public function setOutput(name:String, value:Dynamic):ScriptableNode {

		var outputs = this._outputs;

		if (outputs[name] == null) {

			outputs[name] = scriptableValue(value);

		} else {

			outputs[name].value = value;

		}

		return this;

	}

	public function getOutput(name:String):Dynamic {

		return this._outputs[name];

	}

	public function getParameter(name:String):Dynamic {

		return this.parameters[name];

	}

	public function setParameter(name:String, value:Dynamic):ScriptableNode {

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

	public function deleteParameter(name:String):ScriptableNode {

		var valueNode = this.parameters[name];

		if (valueNode != null) {

			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();

			valueNode.events.removeEventListener('refresh', this.onRefresh);

		}

		return this;

	}

	public function clearParameters():ScriptableNode {

		for (name in this.parameters.keys()) {

			this.deleteParameter(name);

		}

		this.needsUpdate = true;

		return this;

	}

	public function call(name:String, params:Array<Dynamic>):Dynamic {

		var object = this.getObject();
		var method = Reflect.field(object, name);

		if (Type.typeof(method) == TFunction) {

			return Reflect.callMethod(object, method, params);

		}

	}

	public function callAsync(name:String, params:Array<Dynamic>):Future<Dynamic> {

		var object = this.getObject();
		var method = Reflect.field(object, name);

		if (Type.typeof(method) == TFunction) {

			return Type.typeof(method) == TAsyncFunction ? method.apply(params) : method.apply(params);

		}

	}

	public function getNodeType(builder:NodeBuilder):NodeType {

		return this.getDefaultOutputNode().getNodeType(builder);

	}

	public function refresh(output:String = null):Void {

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

		var refresh = () => this.refresh();
		var setOutput = (id:String, value:Dynamic) => this.setOutput(id, value);

		var parameters = new Parameters(this);

		var THREE = global.get('THREE');
		var TSL = global.get('TSL');

		var method = this.getMethod(this.codeNode);
		var params = [parameters, this._local, global, refresh, setOutput, THREE, TSL];

		this._object = method.apply(params);

		var layout = this._object.layout;

		if (layout != null) {

			if (layout.cache == false) {

				this._local.clear();

			}

			// default output
			this._output.outputType = layout.outputType || null;

			if (Array.isArray(layout.elements)) {

				for (element in layout.elements) {

					var id = element.id || element.name;

					if (element.inputType) {

						if (this.getParameter(id) == null) this.setParameter(id, null);

						this.getParameter(id).inputType = element.inputType;

					}

					if (element.outputType) {

						if (this.getOutput(id) == null) this.setOutput(id, null);

						this.getOutput(id).outputType = element.outputType;

					}

				}

			}

		}

		return this._object;

	}

	public function deserialize(data:Dynamic):Void {

		super.deserialize(data);

		for (name in this.parameters.keys()) {

			var valueNode = this.parameters[name];

			if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();

			valueNode.events.addEventListener('refresh', this.onRefresh);

		}

	}

	public function getLayout():Layout {

		return this.getObject().layout;

	}

	public function getDefaultOutputNode():Node {

		var output = this.getDefaultOutput().value;

		if (output != null && output.isNode) {

			return output;

		}

		return float();

	}

	public function getDefaultOutput():ScriptableValueNode {

		return this._exec()._output;

	}

	public function getMethod():Dynamic {

		if (this.needsUpdate) this.dispose();
		if (this._method != null) return this._method;

		//

		var parametersProps = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
		var interfaceProps = ['layout', 'init', 'main', 'dispose'];

		var properties = interfaceProps.join(', ');
		var declarations = 'var ' + properties + '; var output = {};\n';
		var returns = '\nreturn { ...output, ' + properties + ' };';

		var code = declarations + this.codeNode.code + returns;

		//

		this._method = new Function(...parametersProps, code);

		return this._method;

	}

	public function dispose():Void {

		if (this._method == null) return;

		if (this._object != null && Reflect.hasField(this._object, 'dispose')) {

			Reflect.callMethod(this._object, Reflect.field(this._object, 'dispose'));

		}

		this._method = null;
		this._object = null;
		this._source = null;
		this._value = null;
		this._needsOutputUpdate = true;
		this._output.value = null;
		this._outputs = new Map();

	}

	public function setup():Node {

		return this.getDefaultOutputNode();

	}

	public var needsUpdate(set, get):Bool {

		if (set == true) this.dispose();

		return this.source != this._source;

	}

	private function _exec():ScriptableNode {

		if (this.codeNode == null) return this;

		if (this._needsOutputUpdate == true) {

			this._value = this.call('main');

			this._needsOutputUpdate = false;

		}

		this._output.value = this._value;

		return this;

	}

	private function _refresh():Void {

		this.needsUpdate = true;

		this._exec();

		this._output.refresh();

	}

}

@:build(macro.Library.add("scriptable"))
extern var scriptable:Node;

addNodeElement('scriptable', scriptable);

addNodeClass('ScriptableNode', ScriptableNode);