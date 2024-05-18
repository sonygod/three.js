package three.js.examples.jvm.nodes.accessors;

import UniformNode;
import UVNode;
import TextureSizeNode;
import ColorSpaceNode;
import ExpressionNode;
import Node;
import MaxMipLevelNode;
import ShaderNode;

class TextureNode extends UniformNode {

    public var isTextureNode:Bool = true;

    public var uvNode:UVNode;
    public var levelNode:Node;
    public var compareNode:Node;
    public var depthNode:Node;
    public var gradNode:Node;

    public var sampler:Bool = true;
    public var updateMatrix:Bool = false;
    public var updateType:Int = NodeUpdateType.NONE;

    public var referenceNode:Node;

    public var _value:Dynamic;

    public function new(value:Dynamic, uvNode:UVNode = null, levelNode:Node = null) {
        super(value);
        this.uvNode = uvNode;
        this.levelNode = levelNode;
        this.compareNode = null;
        this.depthNode = null;
        this.gradNode = null;
        this._value = value;
        setUpdateMatrix(uvNode === null);
    }

    public function set_value(value:Dynamic) {
        if (referenceNode != null) {
            referenceNode.value = value;
        } else {
            _value = value;
        }
    }

    public function get_value():Dynamic {
        return referenceNode != null ? referenceNode.value : _value;
    }

    public function getUniformHash(builder:Dynamic/*builder*/):String {
        return value.uuid;
    }

    public function getNodeType(builder:Dynamic/*builder*/):String {
        if (value.isDepthTexture == true) return 'float';
        return 'vec4';
    }

    public function getInputType(builder:Dynamic/*builder*/):String {
        return 'texture';
    }

    public function getDefaultUV():UVNode {
        return new UVNode(value.channel);
    }

    public function updateReference(state:Dynamic/*state*/):Dynamic {
        return value;
    }

    public function getTransformedUV(uvNode:UVNode):Vec2 {
        var texture:Dynamic = value;
        return uniform(texture.matrix).mul(new Vec3(uvNode, 1)).xy;
    }

    public function setUpdateMatrix(value:Bool):TextureNode {
        updateMatrix = value;
        updateType = value ? NodeUpdateType.FRAME : NodeUpdateType.NONE;
        return this;
    }

    public function setupUV(builder:Dynamic, uvNode:UVNode):UVNode {
        var texture:Dynamic = value;
        if (builder.isFlipY() && (texture.isRenderTargetTexture == true || texture.isFramebufferTexture == true || texture.isDepthTexture == true)) {
            uvNode = uvNode.setY(uvNode.y.oneMinus());
        }
        return uvNode;
    }

    public function setup(builder:Dynamic):Void {
        var properties:Dynamic = builder.getNodeProperties(this);
        var uvNode:UVNode = this.uvNode;
        if ((uvNode == null || builder.context.forceUVContext == true) && builder.context.getUV != null) {
            uvNode = builder.context.getUV(this);
        }
        if (uvNode == null) uvNode = getDefaultUV();
        if (updateMatrix == true) {
            uvNode = getTransformedUV(uvNode);
        }
        uvNode = setupUV(builder, uvNode);
        var levelNode:Node = this.levelNode;
        if (levelNode == null && builder.context.getTextureLevel != null) {
            levelNode = builder.context.getTextureLevel(this);
        }
        properties.uvNode = uvNode;
        properties.levelNode = levelNode;
        properties.compareNode = compareNode;
        properties.gradNode = gradNode;
        properties.depthNode = depthNode;
    }

    public function generateUV(builder:Dynamic, uvNode:UVNode):String {
        return uvNode.build(builder, sampler == true ? 'vec2' : 'ivec2');
    }

    public function generateSnippet(builder:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, compareSnippet:String, gradSnippet:Array<String>):String {
        var texture:Dynamic = value;
        var snippet:String;
        if (levelSnippet != null) {
            snippet = builder.generateTextureLevel(texture, textureProperty, uvSnippet, levelSnippet, depthSnippet);
        } else if (gradSnippet != null) {
            snippet = builder.generateTextureGrad(texture, textureProperty, uvSnippet, gradSnippet, depthSnippet);
        } else if (compareSnippet != null) {
            snippet = builder.generateTextureCompare(texture, textureProperty, uvSnippet, compareSnippet, depthSnippet);
        } else if (sampler == false) {
            snippet = builder.generateTextureLoad(texture, textureProperty, uvSnippet, depthSnippet);
        } else {
            snippet = builder.generateTexture(texture, textureProperty, uvSnippet, depthSnippet);
        }
        return snippet;
    }

    public function generate(builder:Dynamic, output:String):String {
        var properties:Dynamic = builder.getNodeProperties(this);
        var texture:Dynamic = value;
        if (texture == null || texture.isTexture != true) {
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
                var uvNode:UVNode = properties.uvNode;
                var levelNode:Node = properties.levelNode;
                var compareNode:Node = properties.compareNode;
                var depthNode:Node = properties.depthNode;
                var gradNode:Array<Node> = properties.gradNode;
                var uvSnippet:String = generateUV(builder, uvNode);
                var levelSnippet:String = levelNode != null ? levelNode.build(builder, 'float') : null;
                var depthSnippet:String = depthNode != null ? depthNode.build(builder, 'int') : null;
                var compareSnippet:String = compareNode != null ? compareNode.build(builder, 'float') : null;
                var gradSnippet:Array<String> = gradNode != null ? [gradNode[0].build(builder, 'vec2'), gradNode[1].build(builder, 'vec2')] : null;
                var nodeVar:String = builder.getVarFromNode(this);
                propertyName = builder.getPropertyName(nodeVar);
                var snippet:String = generateSnippet(builder, textureProperty, uvSnippet, levelSnippet, depthSnippet, compareSnippet, gradSnippet);
                builder.addLineFlowCode('${propertyName} = ${snippet}');
                if (builder.context.tempWrite != false) {
                    nodeData.snippet = snippet;
                    nodeData.propertyName = propertyName;
                }
            }
            var snippet:String = propertyName;
            var nodeType:String = getNodeType(builder);
            if (builder.needsColorSpaceToLinear(texture)) {
                snippet = colorSpaceToLinear(expression(snippet, nodeType)).setup(builder).build(builder, nodeType);
            }
            return builder.format(snippet, nodeType, output);
        }
    }

    public function setSampler(value:Bool):TextureNode {
        sampler = value;
        return this;
    }

    public function getSampler():Bool {
        return sampler;
    }

    public function uv(uvNode:UVNode):TextureNode {
        var textureNode:TextureNode = clone();
        textureNode.uvNode = uvNode;
        textureNode.referenceNode = this;
        return nodeObject(textureNode);
    }

    public function blur(levelNode:Node):TextureNode {
        var textureNode:TextureNode = clone();
        textureNode.levelNode = levelNode.mul(maxMipLevel(textureNode));
        textureNode.referenceNode = this;
        return nodeObject(textureNode);
    }

    public function level(levelNode:Node):TextureNode {
        var textureNode:TextureNode = clone();
        textureNode.levelNode = levelNode;
        textureNode.referenceNode = this;
        return textureNode;
    }

    public function size(levelNode:Node):TextureSizeNode {
        return textureSize(this, levelNode);
    }

    public function compare(compareNode:Node):TextureNode {
        var textureNode:TextureNode = clone();
        textureNode.compareNode = nodeObject(compareNode);
        textureNode.referenceNode = this;
        return nodeObject(textureNode);
    }

    public function grad(gradNodeX:Node, gradNodeY:Node):TextureNode {
        var textureNode:TextureNode = clone();
        textureNode.gradNode = [nodeObject(gradNodeX), nodeObject(gradNodeY)];
        textureNode.referenceNode = this;
        return nodeObject(textureNode);
    }

    public function depth(depthNode:Node):TextureNode {
        var textureNode:TextureNode = clone();
        textureNode.depthNode = nodeObject(depthNode);
        textureNode.referenceNode = this;
        return nodeObject(textureNode);
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.value = value.toJSON(data.meta).uuid;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        value = data.meta.textures[data.value];
    }

    public function update():Void {
        var texture:Dynamic = value;
        if (texture.matrixAutoUpdate == true) {
            texture.updateMatrix();
        }
    }

    public function clone():TextureNode {
        var newNode:TextureNode = new TextureNode(value, uvNode, levelNode);
        newNode.sampler = sampler;
        return newNode;
    }
}

class TextureNodeProxy {
    public static function texture(value:Dynamic, ?uvNode:UVNode, ?levelNode:Node):TextureNode {
        return new TextureNode(value, uvNode, levelNode);
    }

    public static function textureLoad(?params:Array<Dynamic>):TextureNode {
        return texture(params[0], params[1], params[2]).setSampler(false);
    }

    //public static function textureLevel(value:Dynamic, uv:UVNode, level:Node):TextureNode {
    //    return texture(value, uv).level(level);
    //}

    public static function sampler(aTexture:Dynamic):TextureNode {
        return (aTexture.isNode == true ? aTexture : texture(aTexture)).convert('sampler');
    }
}

addNodeElement('texture', TextureNodeProxy.texture);
//addNodeElement('textureLevel', TextureNodeProxy.textureLevel);

addNodeClass('TextureNode', TextureNode);