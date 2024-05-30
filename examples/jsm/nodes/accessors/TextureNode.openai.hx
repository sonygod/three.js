package three.js.examples.jsm.nodes.accessors;

import three.js.core.UniformNode;
import three.js.nodes.UVNode;
import three.js.nodes.TextureSizeNode;
import three.js.display.ColorSpaceNode;
import three.js.code.ExpressionNode;
import three.js.core.Node;
import three.js.utils.MaxMipLevelNode;
import three.js.shadernode.ShaderNode;

class TextureNode extends UniformNode {
    
    public var isTextureNode:Bool = true;

    public var uvNode:UVNode;
    public var levelNode:Node;
    public var compareNode:Node;
    public var depthNode:Node;
    public var gradNode:Array<Node>;
    public var referenceNode:Node;

    public var sampler:Bool;
    public var updateMatrix:Bool;
    public var updateType:Int;

    private var _value:Dynamic;

    public function new(value:Dynamic, ?uvNode:UVNode, ?levelNode:Node) {
        super(value);
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this.compareNode = null;
        this.depthNode = null;
        this.gradNode = null;
        this.sampler = true;
        this.updateMatrix = false;
        this.updateType = NodeUpdateType.NONE;
        this.referenceNode = null;
        this._value = value;
        this.setUpdateMatrix(uvNode === null);
    }

    public function set_value(value:Dynamic):Void {
        if (this.referenceNode != null) {
            this.referenceNode.value = value;
        } else {
            this._value = value;
        }
    }

    public function get_value():Dynamic {
        return (this.referenceNode != null) ? this.referenceNode.value : this._value;
    }

    public function getUniformHash(builder:Dynamic):String {
        return this.value.uuid;
    }

    public function getNodeType(builder:Dynamic):String {
        if (this.value.isDepthTexture) return 'float';
        return 'vec4';
    }

    public function getInputType(builder:Dynamic):String {
        return 'texture';
    }

    public function getDefaultUV():UVNode {
        return new UVNode(this.value.channel);
    }

    public function updateReference(state:Dynamic):Dynamic {
        return this.value;
    }

    public function getTransformedUV(uvNode:UVNode):Vec2 {
        var texture:Texture = this.value;
        return UniformNode.mul(new Vec3(uvNode, 1), texture.matrix).xy;
    }

    public function setUpdateMatrix(value:Bool):TextureNode {
        this.updateMatrix = value;
        this.updateType = (value ? NodeUpdateType.FRAME : NodeUpdateType.NONE);
        return this;
    }

    public function setupUV(builder:Dynamic, uvNode:UVNode):UVNode {
        var texture:Texture = this.value;
        if (builder.isFlipY() && (texture.isRenderTargetTexture || texture.isFramebufferTexture || texture.isDepthTexture)) {
            uvNode = new UVNode(uvNode.x, uvNode.y.oneMinus());
        }
        return uvNode;
    }

    public function setup(builder:Dynamic):Void {
        var properties:Dynamic = builder.getNodeProperties(this);
        var uvNode:UVNode = this.uvNode;
        if (uvNode == null || builder.context.forceUVContext) {
            uvNode = builder.context.getUV(this);
        }
        if (uvNode == null) {
            uvNode = this.getDefaultUV();
        }
        if (this.updateMatrix) {
            uvNode = this.getTransformedUV(uvNode);
        }
        uvNode = this.setupUV(builder, uvNode);
        var levelNode:Node = this.levelNode;
        if (levelNode == null && builder.context.getTextureLevel != null) {
            levelNode = builder.context.getTextureLevel(this);
        }
        properties.uvNode = uvNode;
        properties.levelNode = levelNode;
        properties.compareNode = this.compareNode;
        properties.gradNode = this.gradNode;
        properties.depthNode = this.depthNode;
    }

    public function generateUV(builder:Dynamic, uvNode:UVNode):String {
        return uvNode.build(builder, (this.sampler ? 'vec2' : 'ivec2'));
    }

    public function generateSnippet(builder:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, compareSnippet:String, gradSnippet:Array<String>):String {
        var texture:Texture = this.value;
        var snippet:String;
        if (levelSnippet != null) {
            snippet = builder.generateTextureLevel(texture, textureProperty, uvSnippet, levelSnippet, depthSnippet);
        } else if (gradSnippet != null) {
            snippet = builder.generateTextureGrad(texture, textureProperty, uvSnippet, gradSnippet, depthSnippet);
        } else if (compareSnippet != null) {
            snippet = builder.generateTextureCompare(texture, textureProperty, uvSnippet, compareSnippet, depthSnippet);
        } else if (!this.sampler) {
            snippet = builder.generateTextureLoad(texture, textureProperty, uvSnippet, depthSnippet);
        } else {
            snippet = builder.generateTexture(texture, textureProperty, uvSnippet, depthSnippet);
        }
        return snippet;
    }

    public function generate(builder:Dynamic, output:String):String {
        var properties:Dynamic = builder.getNodeProperties(this);
        var texture:Texture = this.value;
        if (!texture || !texture.isTexture) {
            throw new Error('TextureNode: Need a three.js texture.');
        }
        var textureProperty:String = super.generate(builder, 'property');
        if (output == 'sampler') {
            return textureProperty + '_sampler';
        } else if (builder.isReference(output)) {
            return textureProperty;
        } else {
            var nodeData:Dynamic = builder.getDataFromNode(this);
            var propertyName:String = nodeData.propertyName;
            if (propertyName == null) {
                var uvSnippet:String = this.generateUV(builder, properties.uvNode);
                var levelSnippet:String = (properties.levelNode != null) ? properties.levelNode.build(builder, 'float') : null;
                var depthSnippet:String = (properties.depthNode != null) ? properties.depthNode.build(builder, 'int') : null;
                var compareSnippet:String = (properties.compareNode != null) ? properties.compareNode.build(builder, 'float') : null;
                var gradSnippet:Array<String> = (properties.gradNode != null) ? [properties.gradNode[0].build(builder, 'vec2'), properties.gradNode[1].build(builder, 'vec2')] : null;
                var nodeVar:String = builder.getVarFromNode(this);
                propertyName = builder.getPropertyName(nodeVar);
                snippet = this.generateSnippet(builder, textureProperty, uvSnippet, levelSnippet, depthSnippet, compareSnippet, gradSnippet);
                builder.addLineFlowCode(propertyName + ' = ' + snippet);
                if (builder.context.tempWrite != false) {
                    nodeData.snippet = snippet;
                    nodeData.propertyName = propertyName;
                }
            }
            var snippet:String = propertyName;
            var nodeType:String = this.getNodeType(builder);
            if (builder.needsColorSpaceToLinear(texture)) {
                snippet = ColorSpaceNode.toLinear(ExpressionNode.build(snippet, nodeType), texture.colorSpace).setup(builder).build(builder, nodeType);
            }
            return builder.format(snippet, nodeType, output);
        }
    }

    public function setSampler(value:Bool):TextureNode {
        this.sampler = value;
        return this;
    }

    public function getSampler():Bool {
        return this.sampler;
    }

    public function uv(uvNode:UVNode):Node {
        var textureNode:TextureNode = this.clone();
        textureNode.uvNode = uvNode;
        textureNode.referenceNode = this;
        return NodeObject.build(textureNode);
    }

    public function blur(levelNode:Node):Node {
        var textureNode:TextureNode = this.clone();
        textureNode.levelNode = levelNode.mul(MaxMipLevelNode.maxMipLevel(textureNode));
        textureNode.referenceNode = this;
        return NodeObject.build(textureNode);
    }

    public function level(levelNode:Node):Node {
        var textureNode:TextureNode = this.clone();
        textureNode.levelNode = levelNode;
        textureNode.referenceNode = this;
        return textureNode;
    }

    public function size(levelNode:Node):Node {
        return TextureSizeNode.textureSize(this, levelNode);
    }

    public function compare(compareNode:Node):Node {
        var textureNode:TextureNode = this.clone();
        textureNode.compareNode = NodeObject.build(compareNode);
        textureNode.referenceNode = this;
        return NodeObject.build(textureNode);
    }

    public function grad(gradNodeX:Node, gradNodeY:Node):Node {
        var textureNode:TextureNode = this.clone();
        textureNode.gradNode = [NodeObject.build(gradNodeX), NodeObject.build(gradNodeY)];
        textureNode.referenceNode = this;
        return NodeObject.build(textureNode);
    }

    public function depth(depthNode:Node):Node {
        var textureNode:TextureNode = this.clone();
        textureNode.depthNode = NodeObject.build(depthNode);
        textureNode.referenceNode = this;
        return NodeObject.build(textureNode);
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.value = this.value.toJSON(data.meta).uuid;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.value = data.meta.textures[data.value];
    }

    public function update():Void {
        var texture:Texture = this.value;
        if (texture.matrixAutoUpdate) {
            texture.updateMatrix();
        }
    }

    public function clone():TextureNode {
        var newNode:TextureNode = Type.createInstance(Type.getClass(this), [this.value, this.uvNode, this.levelNode]);
        newNode.sampler = this.sampler;
        return newNode;
    }
}

// Utilities
function texture(value:Dynamic, ?uvNode:UVNode, ?levelNode:Node):TextureNode {
    return NodeProxy.build(new TextureNode(value, uvNode, levelNode));
}

function textureLoad(params:Array<Dynamic>):TextureNode {
    return texture(params[0], params[1], params[2]).setSampler(false);
}

// Add node elements
AddNodeElement.add('texture', texture);
//AddNodeElement.add('textureLevel', textureLevel);

AddNodeClass.add('TextureNode', TextureNode);