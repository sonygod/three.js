package three.js.examples.jsm.nodes.code;

import three.js.examples.jsm.nodes.CodeNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

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

    private function getNodeFunction(builder:Dynamic):Dynamic {
        var nodeData:Dynamic = builder.getDataFromNode(this);
        var nodeFunction:Dynamic = nodeData.nodeFunction;

        if (nodeFunction == null) {
            nodeFunction = builder.parser.parseFunction(this.code);
            nodeData.nodeFunction = nodeFunction;
        }

        return nodeFunction;
    }

    public function generate(builder:Dynamic, output:String):String {
        super.generate(builder);

        var nodeFunction:Dynamic = getNodeFunction(builder);
        var name:String = nodeFunction.name;
        var type:String = nodeFunction.type;

        var nodeCode:String = builder.getCodeFromNode(this, type);

        if (name != '') {
            // use a custom property name
            nodeCode.name = name;
        }

        var propertyName:String = builder.getPropertyName(nodeCode);

        var code:String = getNodeFunction(builder).getCode(propertyName);

        var keywords:Dynamic = this.keywords;
        var keywordsProperties:Array<String> = Object.keys(keywords);

        if (keywordsProperties.length > 0) {
            for (property in keywordsProperties) {
                var propertyRegExp:EReg = new EReg("\\b" + property + "\\b", "g");
                var nodeProperty:String = keywords[property].build(builder, 'property');

                code = code.replace(propertyRegExp, nodeProperty);
            }
        }

        nodeCode.code = code + "\n";

        if (output == 'property') {
            return propertyName;
        } else {
            return builder.format('${ propertyName }()', type, output);
        }
    }

    public static function nativeFn(code:String, includes:Array<Dynamic> = [], language:String = ''):Dynamic {
        for (i in 0...includes.length) {
            var include:Dynamic = includes[i];

            // TSL Function: glslFn, wgslFn
            if (Std.isOfType(include, Function)) {
                includes[i] = include.functionNode;
            }
        }

        var functionNode:FunctionNode = nodeObject(new FunctionNode(code, includes, language));
        var fn:Dynamic = (params:Array<Dynamic>) -> functionNode.call(params);
        fn.functionNode = functionNode;

        return fn;
    }

    public static function glslFn(code:String, includes:Array<Dynamic>):Dynamic {
        return nativeFn(code, includes, 'glsl');
    }

    public static function wgslFn(code:String, includes:Array<Dynamic>):Dynamic {
        return nativeFn(code, includes, 'wgsl');
    }
}

Node.addNodeClass('FunctionNode', FunctionNode);