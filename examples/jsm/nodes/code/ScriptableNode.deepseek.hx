package three.js.examples.jsm.nodes.code;

import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.shadernode.ScriptableValueNode;

typedef Resources = Map<String, Dynamic>;

class Resources {

    public function new() {
        super();
    }

    public function get(key:String, callback:Dynamic = null, params:Array<Dynamic>):Dynamic {
        if (this.has(key)) return super.get(key);
        if (callback !== null) {
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

    public function get parameters():Dynamic {
        return this.scriptableNode.parameters;
    }

    public function get layout():Dynamic {
        return this.scriptableNode.getLayout();
    }

    public function getInputLayout(id:String):Dynamic {
        return this.scriptableNode.getInputLayout(id);
    }

    public function get(name:String):Dynamic {
        var param = this.parameters[name];
        var value = param ? param.getValue() : null;
        return value;
    }

}

class ScriptableNode extends Node {

    public var codeNode:Dynamic = null;
    public var parameters:Dynamic = {};
    public var _local:Resources;
    public var _output:ScriptableValueNode;
    public var _outputs:Dynamic = {};
    public var _source:String;
    public var _method:Dynamic = null;
    public var _object:Dynamic = null;
    public var _value:Dynamic = null;
    public var _needsOutputUpdate:Bool = true;
    public var isScriptableNode:Bool = true;

    public function new(codeNode:Dynamic = null, parameters:Dynamic = {}) {
        super();
        this.codeNode = codeNode;
        this.parameters = parameters;
        this._local = new Resources();
        this._output = new ScriptableValueNode();
        this._source = this.source;
        this.onRefresh = this.onRefresh.bind(this);
    }

    public function get source():String {
        return this.codeNode ? this.codeNode.code : '';
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

    public function getInputLayout(id:String):Dynamic {
        for (element in this.getLayout()) {
            if (element.inputType && (element.id == id || element.name == id)) {
                return element;
            }
        }
        return null;
    }

    public function getOutputLayout(id:String):Dynamic {
        for (element in this.getLayout()) {
            if (element.outputType && (element.id == id || element.name == id)) {
                return element;
            }
        }
        return null;
    }

    public function setOutput(name:String, value:Dynamic):ScriptableNode {
        var outputs = this._outputs;
        if (outputs[name] === undefined) {
            outputs[name] = new ScriptableValueNode(value);
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
        if (value && value.isScriptableNode) {
            this.deleteParameter(name);
            parameters[name] = value;
            parameters[name].getDefaultOutput().events.addEventListener('refresh', this.onRefresh);
        } else if (value && value.isScriptableValueNode) {
            this.deleteParameter(name);
            parameters[name] = value;
            parameters[name].events.addEventListener('refresh', this.onRefresh);
        } else if (parameters[name] === undefined) {
            parameters[name] = new ScriptableValueNode(value);
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
        if (valueNode) {
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
        var method = object[name];
        if (typeof method === 'function') {
            return method(params);
        }
        return null;
    }

    public function callAsync(name:String, params:Array<Dynamic>):Dynamic {
        var object = this.getObject();
        var method = object[name];
        if (typeof method === 'function') {
            return method.constructor.name === 'AsyncFunction' ? await method(params) : method(params);
        }
        return null;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return this.getDefaultOutputNode().getNodeType(builder);
    }

    public function refresh(output:String = null):Void {
        if (output !== null) {
            this.getOutput(output).refresh();
        } else {
            this._refresh();
        }
    }

    public function getObject():Dynamic {
        if (this.needsUpdate) this.dispose();
        if (this._object !== null) return this._object;
        //
        var refresh = () -> this.refresh();
        var setOutput = (id:String, value:Dynamic) -> this.setOutput(id, value);
        var parameters = new Parameters(this);
        var THREE = global.get('THREE');
        var TSL = global.get('TSL');
        var method = this.getMethod(this.codeNode);
        var params = [parameters, this._local, global, refresh, setOutput, THREE, TSL];
        this._object = method(params);
        var layout = this._object.layout;
        if (layout) {
            if (layout.cache === false) {
                this._local.clear();
            }
            // default output
            this._output.outputType = layout.outputType || null;
            if (Array.isArray(layout.elements)) {
                for (element in layout.elements) {
                    var id = element.id || element.name;
                    if (element.inputType) {
                        if (this.getParameter(id) === undefined) this.setParameter(id, null);
                        this.getParameter(id).inputType = element.inputType;
                    }
                    if (element.outputType) {
                        if (this.getOutput(id) === undefined) this.setOutput(id, null);
                        this.getOutput(id).outputType = element.outputType;
                    }
                }
            }
        }
        return this._object;
    }

    public function deserialize(data:Dynamic):Void {
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
        var output = this.getDefaultOutput().value;
        if (output && output.isNode) {
            return output;
        }
        return ShaderNode.float();
    }

    public function getDefaultOutput():Dynamic {
        return this._exec()._output;
    }

    public function getMethod():Dynamic {
        if (this.needsUpdate) this.dispose();
        if (this._method !== null) return this._method;
        //
        var parametersProps = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
        var interfaceProps = ['layout', 'init', 'main', 'dispose'];
        var properties = interfaceProps.join(', ');
        var declarations = 'var ' + properties + '; var output = {};\n';
        var returns = '\nreturn { ...output, ' + properties + ' };';
        var code = declarations + this.codeNode.code + returns;
        //
        this._method = new Function(parametersProps, code);
        return this._method;
    }

    public function dispose():Void {
        if (this._method === null) return;
        if (this._object && typeof this._object.dispose === 'function') {
            this._object.dispose();
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

    public function set needsUpdate(value:Bool):Void {
        if (value === true) this.dispose();
    }

    public function get needsUpdate():Bool {
        return this.source !== this._source;
    }

    private function _exec():ScriptableNode {
        if (this.codeNode === null) return this;
        if (this._needsOutputUpdate === true) {
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

var global:Resources = new Resources();

ShaderNode.addNodeElement('scriptable', new ScriptableNode());

Node.addNodeClass('ScriptableNode', ScriptableNode);