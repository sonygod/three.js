import UniformNode;
import uv from '../core/UVNode';
import textureSize from '../core/TextureSizeNode';
import colorSpaceToLinear from '../display/ColorSpaceNode';
import expression from '../code/ExpressionNode';
import addNodeClass from '../core/Node';
import maxMipLevel from '../utils/MaxMipLevelNode';
import addNodeElement from '../shadernode/ShaderNode';
import NodeUpdateType from '../core/constants';

class TextureNode extends UniformNode {

    public var isTextureNode:Bool = true;
    public var uvNode:Any = null;
    public var levelNode:Any = null;
    public var compareNode:Any = null;
    public var depthNode:Any = null;
    public var gradNode:Array<Any> = null;
    public var sampler:Bool = true;
    public var updateMatrix:Bool = false;
    public var updateType:Int = NodeUpdateType.NONE;
    public var referenceNode:Any = null;
    private var _value:Any;

    public function new(value:Any, uvNode:Any = null, levelNode:Any = null) {
        super(value);
        this._value = value;
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this.setUpdateMatrix(uvNode == null);
    }

    public function set value(value:Any) {
        if (this.referenceNode != null) {
            this.referenceNode.value = value;
        } else {
            this._value = value;
        }
    }

    public function get value():Any {
        return this.referenceNode != null ? this.referenceNode.value : this._value;
    }

    // More methods here
}

function texture(value:Any, uvNode:Any = null, levelNode:Any = null):TextureNode {
    return new TextureNode(value, uvNode, levelNode);
}

function textureLoad(value:Any, uvNode:Any = null, levelNode:Any = null):TextureNode {
    return texture(value, uvNode, levelNode).setSampler(false);
}

function sampler(aTexture:Any):Any {
    return aTexture is TextureNode ? aTexture : texture(aTexture).convert("sampler");
}

addNodeElement("texture", texture);
addNodeClass("TextureNode", TextureNode);