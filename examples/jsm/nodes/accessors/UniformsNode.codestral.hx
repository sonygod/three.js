import js.html.Lib;
import three.jsm.core.Node;
import three.jsm.shadernode.ShaderNode;
import three.jsm.core.NodeUtils;
import three.jsm.core.constants.NodeUpdateType;
import three.jsm.utils.ArrayElementNode;
import three.jsm.nodes.accessors.BufferNode;

class UniformsElementNode extends ArrayElementNode {

    public function new(arrayBuffer:BufferNode, indexNode:ShaderNode) {
        super(arrayBuffer, indexNode);
        this.isArrayBufferElementNode = true;
    }

    public function getNodeType(builder:Builder):String {
        return this.node.getElementType(builder);
    }

    @override
    public function generate(builder:Builder):String {
        var snippet = super.generate(builder);
        var type = this.getNodeType();
        return builder.format(snippet, 'vec4', type);
    }
}

class UniformsNode extends BufferNode {

    public var array:Array<Dynamic>;
    public var elementType:String;
    private var _elementType:String;
    private var _elementLength:Int;

    public function new(value:Array<Dynamic>, ?elementType:String) {
        super(null, 'vec4');
        this.array = value;
        this.elementType = (elementType != null) ? elementType : '';
        this._elementType = null;
        this._elementLength = 0;
        this.updateType = NodeUpdateType.RENDER;
        this.isArrayBufferNode = true;
    }

    public function getElementType():String {
        return (this.elementType != '') ? this.elementType : this._elementType;
    }

    public function getElementLength():Int {
        return this._elementLength;
    }

    @override
    public function update(frame:Int):Void {
        var elementLength = this.getElementLength();
        var elementType = this.getElementType();

        if (elementLength == 1) {
            for (i in 0...this.array.length) {
                var index = i * 4;
                this.value[index] = this.array[i];
            }
        } else if (elementType == 'color') {
            for (i in 0...this.array.length) {
                var index = i * 4;
                var vector = this.array[i];
                this.value[index] = vector.r;
                this.value[index + 1] = vector.g;
                this.value[index + 2] = (vector.hasOwnProperty('b')) ? vector.b : 0;
            }
        } else {
            for (i in 0...this.array.length) {
                var index = i * 4;
                var vector = this.array[i];
                this.value[index] = vector.x;
                this.value[index + 1] = vector.y;
                this.value[index + 2] = (vector.hasOwnProperty('z')) ? vector.z : 0;
                this.value[index + 3] = (vector.hasOwnProperty('w')) ? vector.w : 0;
            }
        }
    }

    @override
    public function setup(builder:Builder):Bool {
        var length = this.array.length;
        this._elementType = (this.elementType == '') ? NodeUtils.getValueType(this.array[0]) : this.elementType;
        this._elementLength = builder.getTypeLength(this._elementType);
        this.value = Array<Float>(length * 4);
        this.bufferCount = length;
        return super.setup(builder);
    }

    public function element(indexNode:ShaderNode):ShaderNode {
        return ShaderNode.nodeObject(new UniformsElementNode(this, ShaderNode.nodeObject(indexNode)));
    }
}

export function uniforms(values:Array<Dynamic>, nodeType:String):ShaderNode {
    return ShaderNode.nodeObject(new UniformsNode(values, nodeType));
}

Node.addNodeClass('UniformsNode', UniformsNode);