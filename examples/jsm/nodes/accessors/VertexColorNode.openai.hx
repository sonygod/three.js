package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.AttributeNode;
import three.js.shadernode.ShaderNode;

class VertexColorNode extends AttributeNode {
    public var isVertexColorNode:Bool = true;

    public var index:Int;

    public function new(?index:Int = 0) {
        super(null, 'vec4');
        this.index = index;
    }

    override public function getAttributeName(builder:Dynamic):String {
        return 'color' + (index > 0 ? Std.string(index) : '');
    }

    override public function generate(builder:Dynamic):Dynamic {
        var attributeName = getAttributeName(builder);
        var geometryAttribute = builder.hasGeometryAttribute(attributeName);

        var result:Dynamic;

        if (geometryAttribute == true) {
            result = super.generate(builder);
        } else {
            // Vertex color fallback should be white
            result = builder.generateConst(this.nodeType, new Vector4(1, 1, 1, 1));
        }

        return result;
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.index = index;
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        index = data.index;
    }
}

class VertexColor {
    public static function node(?params:Array<Dynamic>):VertexArrayNode {
        return new VertexColorNode(params);
    }
}

Node.addNodeClass('VertexColorNode', VertexColorNode);