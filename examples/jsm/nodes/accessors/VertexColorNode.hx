package three.js.examples.jvm.nodes.accessors;

import three.js.core.Node;
import three.js.core.AttributeNode;
import three.js.shadernode.ShaderNode;
import three.math.Vector4;

class VertexColorNode extends AttributeNode {
    public var isVertexColorNode:Bool = true;
    public var index:Int;

    public function new(?index:Int = 0) {
        super(null, 'vec4');
        this.index = index;
    }

    public function getAttributeName(builder:Dynamic):String {
        var index:Int = this.index;
        return 'color' + (index > 0 ? Std.string(index) : '');
    }

    public function generate(builder:Dynamic):Dynamic {
        var attributeName:String = this.getAttributeName(builder);
        var geometryAttribute:Bool = builder.hasGeometryAttribute(attributeName);
        var result:Dynamic;

        if (geometryAttribute) {
            result = super.generate(builder);
        } else {
            // Vertex color fallback should be white
            result = builder.generateConst(nodeType, new Vector4(1, 1, 1, 1));
        }

        return result;
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.index = this.index;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.index = data.index;
    }
}

class VertexColorNodeFactory {
    public static function vertexColor(?params:Array<Dynamic>):VertexColorNode {
        return new VertexColorNode(params != null && params.length > 0 ? params[0] : 0);
    }
}

addNodeClass('VertexColorNode', VertexColorNode);