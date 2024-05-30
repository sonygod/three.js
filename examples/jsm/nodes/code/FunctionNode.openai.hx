package three.js.examples.javascript.nodes.code;

import three.js.examples.javascript.nodes.CodeNode;
import three.js.core.Node;

class FunctionNode extends CodeNode {
    public var keywords:Dynamic = {};

    public function new(code:String = '', includes:Array<Dynamic> = [], language:String = '') {
        super(code, includes, language);
    }

    public function getNodeType(builder:Dynamic):String {
        return getNodeFunction(builder).type;
    }

    public function getInputs(builder:Dynamic):Array<Dynamic> {
        return getNodeFunction(builder).inputs;
    }

    public function getNodeFunction(builder:Dynamic):Dynamic {
        var nodeData = builder.getDataFromNode(this);
        var nodeFunction = nodeData.nodeFunction;

        if (nodeFunction == null) {
            nodeFunction = builder.parser.parseFunction(code);
            nodeData.nodeFunction = nodeFunction;
        }

        return nodeFunction;
    }

    override public function generate(builder:Dynamic, output:String):String {
        super.generate(builder);

        var nodeFunction = getNodeFunction(builder);
        var name = nodeFunction.name;
        var type = nodeFunction.type;
        var nodeCode = builder.getCodeFromNode(this, type);

        if (name != '') {
            nodeCode.name = name;
        }

        var propertyName = builder.getPropertyName(nodeCode);

        var code = getNodeFunction(builder).getCode(propertyName);

        var keywords = this.keywords;
        var keywordsProperties = Reflect.fields(keywords);

        if (keywordsProperties.length > 0) {
            for (property in keywordsProperties) {
                var propertyRegExp = new EReg('\\b' + property + '\\b', 'g');
                var nodeProperty = keywords[property].build(builder, 'property');
                code = propertyRegExp.replace(code, nodeProperty);
            }
        }

        nodeCode.code = code + '\n';

        if (output == 'property') {
            return propertyName;
        } else {
            return builder.format('${propertyName}()', type, output);
        }
    }
}

extern class NativeFunction {
    public var functionNode:FunctionNode;
    public function new(params:Array<Dynamic>):Void;
}

function nativeFn(code:String, includes:Array<Dynamic> = [], language:String = ''):NativeFunction {
    for (i in 0...includes.length) {
        var include = includes[i];
        if (Std.isOfType(include, Function)) {
            includes[i] = include.functionNode;
        }
    }

    var functionNode = nodeObject(new FunctionNode(code, includes, language));
    var fn = function(params:Array<Dynamic>):Void {
        functionNode.call(params);
    };
    fn.functionNode = functionNode;
    return fn;
}

function glslFn(code:String, includes:Array<Dynamic>):NativeFunction {
    return nativeFn(code, includes, 'glsl');
}

function wgslFn(code:String, includes:Array<Dynamic>):NativeFunction {
    return nativeFn(code, includes, 'wgsl');
}

addNodeClass('FunctionNode', FunctionNode);