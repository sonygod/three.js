import js.Map;
import Node from '../core/Node';
import { scriptableValue } from './ScriptableValueNode';
import { addNodeElement, nodeProxy, float } from '../shadernode/ShaderNode';

class Resources extends Map<Dynamic, Dynamic> {

    public function get(key: Dynamic, callback: Null<Function> = null, params: Array<Dynamic> = []): Dynamic {
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

    private var scriptableNode: ScriptableNode;

    public function new(scriptableNode: ScriptableNode) {
        this.scriptableNode = scriptableNode;
    }

    public function get parameters(): Dynamic {
        return this.scriptableNode.parameters;
    }

    public function get layout(): Dynamic {
        return this.scriptableNode.getLayout();
    }

    public function getInputLayout(id: Dynamic): Dynamic {
        return this.scriptableNode.getInputLayout(id);
    }

    public function get(name: String): Dynamic {
        var param = this.parameters[name];
        var value = (param != null) ? param.getValue() : null;

        return value;
    }

}

var global = new Resources();

class ScriptableNode extends Node {

    private var codeNode: Null<Dynamic>;
    private var parameters: Dynamic;
    private var _local: Resources;
    private var _output: Dynamic;
    private var _outputs: Dynamic;
    private var _source: String;
    private var _method: Null<Function>;
    private var _object: Null<Dynamic>;
    private var _value: Null<Dynamic>;
    private var _needsOutputUpdate: Bool;

    public function new(codeNode: Null<Dynamic> = null, parameters: Dynamic = {}) {
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

        this.isScriptableNode = true;
    }

    public function get source(): String {
        return (this.codeNode != null) ? this.codeNode.code : '';
    }

    public function setLocal(name: Dynamic, value: Dynamic): Dynamic {
        return this._local.set(name, value);
    }

    public function getLocal(name: Dynamic): Dynamic {
        return this._local.get(name);
    }

    public function onRefresh(): Void {
        this._refresh();
    }

    public function getInputLayout(id: Dynamic): Dynamic {
        for (element in this.getLayout()) {
            if (element.inputType && (element.id == id || element.name == id)) {
                return element;
            }
        }

        return null;
    }

    public function getOutputLayout(id: Dynamic): Dynamic {
        for (element in this.getLayout()) {
            if (element.outputType && (element.id == id || element.name == id)) {
                return element;
            }
        }

        return null;
    }

    public function setOutput(name: String, value: Dynamic): ScriptableNode {
        if (this._outputs[name] == null) {
            this._outputs[name] = scriptableValue(value);
        } else {
            this._outputs[name].value = value;
        }

        return this;
    }

    public function getOutput(name: String): Dynamic {
        return this._outputs[name];
    }

    public function getParameter(name: String): Dynamic {
        return this.parameters[name];
    }

    public function setParameter(name: String, value: Dynamic): ScriptableNode {
        if (value != null && value.isScriptableNode) {
            this.deleteParameter(name);

            this.parameters[name] = value;
            value.getDefaultOutput().events.addEventListener('refresh', this.onRefresh);
        } else if (value != null && value.isScriptableValueNode) {
            this.deleteParameter(name);

            this.parameters[name] = value;
            value.events.addEventListener('refresh', this.onRefresh);
        } else if (this.parameters[name] == null) {
            this.parameters[name] = scriptableValue(value);
            this.parameters[name].events.addEventListener('refresh', this.onRefresh);
        } else {
            this.parameters[name].value = value;
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

    public function call(name: String, params: Array<Dynamic> = []): Dynamic {
        var object = this.getObject();
        var method = Reflect.field(object, name);

        if (Type.isFunction(method)) {
            return Reflect.callMethod(object, method, params);
        }

        return null;
    }

    public async function callAsync(name: String, params: Array<Dynamic> = []): Promise<Dynamic> {
        var object = this.getObject();
        var method = Reflect.field(object, name);

        if (Type.isFunction(method)) {
            return Reflect.isFunction(method.constructor.name == 'AsyncFunction') ? await Reflect.callMethod(object, method, params) : Reflect.callMethod(object, method, params);
        }

        return null;
    }

    public function getNodeType(builder: Dynamic): Dynamic {
        return this.getDefaultOutputNode().getNodeType(builder);
    }

    public function refresh(output: Null<Dynamic> = null): Void {
        if (output != null) {
            this.getOutput(output).refresh();
        } else {
            this._refresh();
        }
    }

    public function getObject(): Dynamic {
        if (this.needsUpdate) this.dispose();
        if (this._object != null) return this._object;

        var refresh = this._refresh.bind(this);
        var setOutput = this.setOutput.bind(this);

        var parameters = new Parameters(this);

        var THREE = global.get('THREE');
        var TSL = global.get('TSL');

        var method = this.getMethod(this.codeNode);
        var params = [parameters, this._local, global, refresh, setOutput, THREE, TSL];

        this._object = Reflect.callMethod(null, method, params);

        var layout = this._object.layout;

        if (layout != null) {
            if (layout.cache === false) {
                this._local.clear();
            }

            this._output.outputType = layout.outputType || null;

            if (Std.is(layout.elements, Array)) {
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

        return float();
    }

    public function getDefaultOutput(): Dynamic {
        return this._exec()._output;
    }

    public function getMethod(): Function {
        if (this.needsUpdate) this.dispose();
        if (this._method != null) return this._method;

        var parametersProps = ['parameters', 'local', 'global', 'refresh', 'setOutput', 'THREE', 'TSL'];
        var interfaceProps = ['layout', 'init', 'main', 'dispose'];

        var properties = interfaceProps.join(', ');
        var declarations = 'var ${properties}; var output = {};\n';
        var returns = '\nreturn { ...output, ${properties} };';

        var code = declarations + this.codeNode.code + returns;

        this._method = new Function(parametersProps.join(', '), code);

        return this._method;
    }

    public function dispose(): Void {
        if (this._method == null) return;

        if (this._object != null && Type.isFunction(Reflect.field(this._object, 'dispose'))) {
            Reflect.callMethod(this._object, Reflect.field(this._object, 'dispose'), []);
        }

        this._method = null;
        this._object = null;
        this._source = null;
        this._value = null;
        this._needsOutputUpdate = true;
        this._output.value = null;
        this._outputs = {};
    }

    public function setup(): Dynamic {
        return this.getDefaultOutputNode();
    }

    public function set needsUpdate(value: Bool): Void {
        if (value) this.dispose();
    }

    public function get needsUpdate(): Bool {
        return this.source != this._source;
    }

    private function _exec(): ScriptableNode {
        if (this.codeNode == null) return this;

        if (this._needsOutputUpdate) {
            this._value = this.call('main');

            this._needsOutputUpdate = false;
        }

        this._output.value = this._value;

        return this;
    }

    private function _refresh(): Void {
        this.needsUpdate = true;

        this._exec();

        this._output.refresh();
    }

}

export default ScriptableNode;

export function scriptable(): Dynamic {
    return nodeProxy(ScriptableNode);
}

addNodeElement('scriptable', scriptable());

Node.addNodeClass('ScriptableNode', ScriptableNode);