package three.js.examples.javascript.nodes.display;

import three.js.core.TempNode;
import three.js.shadernode.ShaderNode;
import three.js.core.NodeUpdateType;
import three.js.accessors.UVNode;
import three.js.accessors.TextureNode;
import three.js.nodes.display.PassNode;
import three.js.core.UniformNode;
import three.js.objects.QuadMesh;
import three.js.math.MathNode;

class AfterImageNode extends TempNode {
    public var textureNode:TextureNode;
    public var textureNodeOld:TextureNode;
    public var damp:UniformNode;
    public var _compRT:RenderTarget;
    public var _oldRT:RenderTarget;
    public var _textureNode:TextureNode;
    public var updateBeforeType:NodeUpdateType;

    public function new(textureNode:TextureNode, damp:Float = 0.96) {
        super(textureNode);
        this.textureNode = textureNode;
        this.textureNodeOld = new TextureNode();
        this.damp = new UniformNode(damp);

        this._compRT = new RenderTarget();
        this._compRT.texture.name = 'AfterImageNode.comp';

        this._oldRT = new RenderTarget();
        this._oldRT.texture.name = 'AfterImageNode.old';

        this._textureNode = new PassNode(this, this._compRT.texture);

        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode():TextureNode {
        return this._textureNode;
    }

    public function setSize(width:Int, height:Int) {
        this._compRT.setSize(width, height);
        this._oldRT.setSize(width, height);
    }

    public function updateBefore(frame:Any) {
        var renderer:Any = frame.renderer;
        var textureNode:TextureNode = this.textureNode;
        var map:Texture = textureNode.value;

        var textureType:String = map.type;

        this._compRT.texture.type = textureType;
        this._oldRT.texture.type = textureType;

        var currentRenderTarget:Any = renderer.getRenderTarget();
        var currentTexture:Texture = textureNode.value;

        this.textureNodeOld.value = this._oldRT.texture;

        // comp
        renderer.setRenderTarget(this._compRT);
        quadMeshComp.render(renderer);

        // Swap the textures
        var temp:Any = this._oldRT;
        this._oldRT = this._compRT;
        this._compRT = temp;

        // set size before swapping fails
        this.setSize(map.image.width, map.image.height);

        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:Any) {
        var textureNode:TextureNode = this.textureNode;
        var textureNodeOld:TextureNode = this.textureNodeOld;

        if (!textureNode.isTextureNode) {
            throw new Error('AfterImageNode requires a TextureNode.');
        }

        var uvNode:UVNode = textureNode.uvNode || new UVNode();

        textureNodeOld.uvNode = uvNode;

        var sampleTexture:Any = function(uv:Any) {
            return textureNode.cache().context({ getUV: function() return uv, forceUVContext: true });
        };

        var when_gt:Any = function(x_immutable:Any, y_immutable:Any) {
            var y:Float = new Float(y_immutable).toVar();
            var x:Vec4 = new Vec4(x_immutable).toVar();

            return Math.max(sign(x.sub(y)), 0.0);
        };

        var afterImg:Any = function() {
            var texelOld:Vec4 = new Vec4(textureNodeOld);
            var texelNew:Vec4 = new Vec4(sampleTexture(uvNode));

            texelOld.mulAssign(this.damp.mul(when_gt(texelOld, 0.1)));
            return Math.max(texelNew, texelOld);
        };

        var materialComposed:Any = this._materialComposed || (this._materialComposed = builder.createNodeMaterial());
        materialComposed.fragmentNode = afterImg();

        quadMeshComp.material = materialComposed;

        var properties:Any = builder.getNodeProperties(this);
        properties.textureNode = textureNode;

        return this._textureNode;
    }
}

class AfterImage {
    public static function afterImage(node:Node, damp:Float = 0.96) {
        return new AfterImageNode(node, damp);
    }
}

nodeElements.push({ name: 'afterImage', func: AfterImage.afterImage });