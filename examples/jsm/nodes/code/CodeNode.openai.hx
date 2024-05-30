package three.js.nodes.code;

import three.js.core.Node;

class CodeNode extends Node {
    public var isCodeNode:Bool = true;
    public var code:String;
    public var language:String;
    public var includes:Array<Dynamic>;

    public function new(code:String = '', includes:Array<Dynamic> = [], language:String = '') {
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

    public function getIncludes(builder:Dynamic /*builder*/):Array<Dynamic> {
        return this.includes;
    }

    public function generate(builder:Dynamic):String {
        var includes:Array<Dynamic> = this.getIncludes(builder);

        for (include in includes) {
            include.build(builder);
        }

        var nodeCode = builder.getCodeFromNode(this, this.getNodeType(builder));
        nodeCode.code = this.code;

        return nodeCode.code;
    }

    public override function serialize(data:Dynamic):Void {
        super.serialize(data);

        data.code = this.code;
        data.language = this.language;
    }

    public override function deserialize(data:Dynamic):Void {
        super.deserialize(data);

        this.code = data.code;
        this.language = data.language;
    }
}

// Proxy functions
private function code(src:String, includes:Array<Dynamic>, language:String):CodeNode {
    return new CodeNode(src, includes, language);
}

private function js(src:String, includes:Array<Dynamic>):CodeNode {
    return code(src, includes, 'js');
}

private function wgsl(src:String, includes:Array<Dynamic>):CodeNode {
    return code(src, includes, 'wgsl');
}

private function glsl(src:String, includes:Array<Dynamic>):CodeNode {
    return code(src, includes, 'glsl');
}

// Register the node class
Node.addNodeClass('CodeNode', CodeNode);

// Export the node class
private function _():Void {
    CodeNode;
}