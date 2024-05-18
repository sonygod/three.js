package three.js.examples.jsm.nodes.code;

import three.js.core.Node;
import three.shadernode.ShaderNode;

class CodeNode extends Node {
    public var isCodeNode:Bool = true;
    public var code:String;
    public var language:String;
    public var includes:Array<Dynamic>;

    public function new(?code:String = '', ?includes:Array<Dynamic> = [], ?language:String = '') {
        super('code');
        this.code = code;
        this.language = language;
        this.includes = includes;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function setIncludes(includes:Array<Dynamic>):CodeNode {
        this.includes = includes;
        return this;
    }

    public function getIncludes(?builder:Dynamic):Array<Dynamic> {
        return this.includes;
    }

    public function generate(builder:Dynamic):String {
        var includes:Array<Dynamic> = this.getIncludes(builder);
        for (include in includes) {
            include.build(builder);
        }
        var nodeCode = builder.getCodeFromNode(this, getNodeType(builder));
        nodeCode.code = this.code;
        return nodeCode.code;
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.code = this.code;
        data.language = this.language;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.code = data.code;
        this.language = data.language;
    }
}

typedef CodeNodeType = CodeNode;

@:keep
@:forward(code)
abstract CodeProxy(CodeNodeType) from CodeNodeType to CodeNodeType {
    public inline function new(src:String, includes:Array<Dynamic>, language:String) {
        this = new CodeNodeType(src, includes, language);
    }
}

@:keep
function js(src:String, includes:Array<Dynamic>):CodeNodeType {
    return new CodeProxy(src, includes, 'js');
}

@:keep
function wgsl(src:String, includes:Array<Dynamic>):CodeNodeType {
    return new CodeProxy(src, includes, 'wgsl');
}

@:keep
function glsl(src:String, includes:Array<Dynamic>):CodeNodeType {
    return new CodeProxy(src, includes, 'glsl');
}

Node.addNodeClass('CodeNode', CodeNode);