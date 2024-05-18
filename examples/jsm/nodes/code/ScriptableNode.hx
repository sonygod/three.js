package three.js.examples.jsm.nodes.code;

import Node;
import ScriptableValueNode.scriptableValue;
import ShaderNode.addNodeElement;
import ShaderNode.addNodeClass;
import ShaderNode.nodeProxy;
import ShaderNode.float;

class Resources<T> extends Map<String, T> {
    public function new() {
        super();
    }

    public function get(key:String, callback:Void->T, params:Array<Dynamic>):T {
        if (this.exists(key)) {
            return this.get(key);
        }

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
    function get_parameters():Dynamic {
        return scriptableNode.parameters;
    }

    public var layout(get, never):Layout;
    function get_layout():Layout {
        return scriptableNode.getLayout();
    }

    public function getInputLayout(id:String):LayoutElement {
        return scriptableNode.getInputLayout(id);
    }

    public function get(name:String):Dynamic {
        var param = parameters[name];
        var value:Dynamic = param != null ? param.getValue() : null;
        return value;
    }
}

var global = new Resources();

class ScriptableNode extends Node {
    public var codeNode:Node;
    public var parameters:Dynamic;
    public var _local:Resources<String, Dynamic>;
    public var _output:ScriptableValueNode;
    public var _outputs:Map<String, ScriptableValueNode>;
    public var _source:String;
    public var _method:Dynamic;
    public var _object:Dynamic;
    public var _value:Dynamic;
    public var _needsOutputUpdate:Bool;

    public function new(codeNode:Node = null, parameters:Dynamic = {}) {
        super();
        this.codeNode = codeNode;
        this.parameters = parameters;

        _local = new Resources();
        _output = scriptableValue();
        _outputs = new Map<String, ScriptableValueNode>();
        _source = this.source;
        _method = null;
        _object = null;
        _value = null;
        _needsOutputUpdate = true;

        onRefresh = onRefresh.bind(this);
        isScriptableNode = true;
    }

    public var source(get, never):String;
    function get_source():String {
        return codeNode != null ? codeNode.code : '';
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

    public function getInputLayout(id:String):LayoutElement {
        for (element in getLayout()) {
            if (element.inputType && (element.id == id || element.name == id)) {
                return element;
            }
        }
        return null;
    }

    public function getOutputLayout(id:String):LayoutElement {
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

    public function getOutput(name:String):ScriptableValueNode {
        return _outputs[name];
    }

    public function getParameter(name:String):Dynamic {
        return parameters[name];
    }

    public function setParameter(name:String, value:Dynamic):ScriptableNode {
        var parameters = this.parameters;
        if (value != null && value.isScriptableNode) {
            deleteParameter(name);
            parameters[name] = value;
            value.getDefaultOutput().events.addEventListener('refresh', onRefresh);
        } else if (value != null && value.isScriptableValueNode) {
            deleteParameter(name);
            parameters[name] = value;
            value.events.addEventListener('refresh', onRefresh);
        } else if (parameters[name] == null) {
            parameters[name] = scriptableValue(value);
            parameters[name].events.addEventListener('refresh', onRefresh);
        } else {
            parameters[name].value = value;
        }
        return this;
    }

    public function getValue():Dynamic {
        return getDefaultOutput().getValue();
    }

    public function deleteParameter(name:String):ScriptableNode {
        var valueNode = parameters[name];
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

    public function call(name:String, params:Array<Dynamic>):Dynamic {
        var object = getObject();
        var method = object[name];
        if (method != null && Type.getClass(method) == Function) {
            return method.apply(object, params);
        }
        return null;
    }

    public function callAsync(name:String, params:Array<Dynamic>):Promise<Dynamic> {
        var object = getObject();
        var method = object[name];
        if (method != null && Type.getClass(method) == Function) {
            if (method.constructor.name == 'AsyncFunction') {
                return Promise.promise(method.apply(object, params));
            } else {
                return Promise.promise(method.apply(object, params));
            }
        }
        return Promise.promise(null);
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return getDefaultOutputNode().getNodeType(builder);
    }

    public function refresh(output:String = null):Void {
        if (output != null) {
            getOutput(output).refresh();
        } else {
            _refresh();
        }
    }

    public function getObject():Dynamic {
        if (needsUpdate) dispose();
        if (_object != null) return _object;
        var refresh = function() {
            this.refresh();
        };
        var setOutput = function(id:String, value:Dynamic) {
            this.setOutput(id, value);
        };
        var parameters = new Parameters(this);
        var THREE = global.get('THREE');
        var TSL = global.get('TSL');
        var method = getMethod(codeNode);
        var params = [parameters, _local, global, refresh, setOutput, THREE, TSL];
        _object = method.apply(null, params);
        var layout = _object.layout;
        if (layout != null) {
            if (layout.cache == false) {
                _local.clear();
            }
            // default output
            _output.outputType = layout.outputType == null ? null : layout.outputType;
            if (layout.elements != null) {
                for (element in layout.elements) {
                    var id = element.id != null ? element.id : element.name;
                    if (element.inputType != null) {
                        if (getParameter(id) == null) setParameter(id, null);
                        getParameter(id).inputType = element.inputType;
                    }
                    if (element.outputType != null) {
                        if (getOutput(id) == null) setOutput(id, null);
                        getOutput(id).outputType = element.outputType;
                    }
                }
            }
        }
        return _object;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        for (name in parameters.keys()) {
            var valueNode = parameters[name];
            if (valueNode.isScriptableNode) valueNode = valueNode.getDefaultOutput();
            valueNode.events.addEventListener('refresh', onRefresh);
        }
    }

    public function getLayout():Layout {
        return getObject().layout;
    }

    public function getDefaultOutputNode():Node {
        var output = getDefaultOutput().value;
        if (output != null && output.isNode) {
            return output;
        }
        return float();
    }

    public function getDefaultOutput():ScriptableValueNode {
        return _exec()._output;
    }

    public function getMethod():Dynamic {
        if (needsUpdate) dispose();
        if (_method != null) return _method;
        var parametersProps = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
        var interfaceProps = ['layout', 'init', 'main', 'dispose'];
        var properties = interfaceProps.join(', ');
        var declarations = 'var ' + properties + '; var output = {};\n';
        var returns = '\nreturn { ...output, ' + properties + ' };';
        var code = declarations + codeNode.code + returns;

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
        _outputs = new Map<String, ScriptableValueNode>();
    }

    public function setup():Node {
        return getDefaultOutputNode();
    }

    public var needsUpdate(get, set):Bool;
    function get_needsUpdate():Bool {
        return source != _source;
    }
    function set_needsUpdate(value:Bool):Void {
        if (value) dispose();
    }

    function _exec():ScriptableNode {
        if (codeNode == null) return this;
        if (_needsOutputUpdate) {
            _value = call('main');
            _needsOutputUpdate = false;
        }
        _output.value = _value;
        return this;
    }

    function _refresh():Void {
        needsUpdate = true;
        _exec();
        _output.refresh();
    }
}

addNodeElement('scriptable', nodeProxy(ScriptableNode));
addNodeClass('ScriptableNode', ScriptableNode);