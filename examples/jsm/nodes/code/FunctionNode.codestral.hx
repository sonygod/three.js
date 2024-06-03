import CodeNode from './CodeNode';
import Node from '../core/Node';
import ShaderNode from '../shadernode/ShaderNode';

class FunctionNode extends CodeNode {

    public var keywords:haxe.ds.StringMap<Dynamic>;

    public function new(code:String = '', includes:Array<Dynamic> = [], language:String = '') {
        super(code, includes, language);
        this.keywords = new haxe.ds.StringMap<Dynamic>();
    }

    public function getNodeType(builder:Dynamic):String {
        return this.getNodeFunction(builder).type;
    }

    public function getInputs(builder:Dynamic):Array<Dynamic> {
        return this.getNodeFunction(builder).inputs;
    }

    public function getNodeFunction(builder:Dynamic):Dynamic {
        var nodeData = builder.getDataFromNode(this);
        var nodeFunction = nodeData.nodeFunction;

        if (nodeFunction == null) {
            nodeFunction = builder.parser.parseFunction(this.code);
            nodeData.nodeFunction = nodeFunction;
        }

        return nodeFunction;
    }

    @Override public function generate(builder:Dynamic, output:String = null):String {
        super.generate(builder);
        var nodeFunction = this.getNodeFunction(builder);
        var name = nodeFunction.name;
        var type = nodeFunction.type;
        var nodeCode = builder.getCodeFromNode(this, type);

        if (name != '') {
            nodeCode.name = name;
        }

        var propertyName = builder.getPropertyName(nodeCode);
        var code = nodeFunction.getCode(propertyName);
        var keywords = this.keywords;
        var keys = keywords.keys();

        while (keys.hasNext()) {
            var property = keys.next();
            var propertyRegExp = new EReg("\\b" + property + "\\b", "g");
            var nodeProperty = Reflect.callMethod(keywords.get(property), builder, ["property"]);
            code = code.replace(propertyRegExp, nodeProperty);
        }

        nodeCode.code = code + "\n";

        if (output == 'property') {
            return propertyName;
        } else {
            return builder.format(propertyName + "()", type, output);
        }
    }
}

function nativeFn(code:String, includes:Array<Dynamic> = [], language:String = ''):Dynamic {
    for (i in 0...includes.length) {
        if (Std.is(includes[i], Dynamic) && Reflect.hasField(includes[i], "functionNode")) {
            includes[i] = Reflect.field(includes[i], "functionNode");
        }
    }

    var functionNode = ShaderNode.nodeObject(new FunctionNode(code, includes, language));
    var fn = function(...params) {
        return functionNode.call(params);
    };
    fn.functionNode = functionNode;

    return fn;
}

function glslFn(code:String, includes:Array<Dynamic>):Dynamic {
    return nativeFn(code, includes, 'glsl');
}

function wgslFn(code:String, includes:Array<Dynamic>):Dynamic {
    return nativeFn(code, includes, 'wgsl');
}

Node.addNodeClass('FunctionNode', FunctionNode);