import js.Lib;
import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.accessors.TextureNode;
import three.js.examples.jsm.nodes.nodes.PassNode;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.math.MathNode;
import three.js.examples.objects.QuadMesh;
import three.js.RenderTarget;

class AfterImageNode extends TempNode {

    public var textureNode:TextureNode;
    public var textureNodeOld:TextureNode;
    public var damp:UniformNode;
    private var _compRT:RenderTarget;
    private var _oldRT:RenderTarget;
    private var _textureNode:TextureNode;
    private var _materialComposed:Material;

    public function new(textureNode:TextureNode, damp:Float = 0.96) {
        super(textureNode);
        this.textureNode = textureNode;
        this.textureNodeOld = texture();
        this.damp = uniform(damp);
        this._compRT = new RenderTarget();
        this._compRT.texture.name = 'AfterImageNode.comp';
        this._oldRT = new RenderTarget();
        this._oldRT.texture.name = 'AfterImageNode.old';
        this._textureNode = texturePass(this, this._compRT.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode():TextureNode {
        return this._textureNode;
    }

    public function setSize(width:Float, height:Float):Void {
        this._compRT.setSize(width, height);
        this._oldRT.setSize(width, height);
    }

    public function updateBefore(frame:Frame):Void {
        var renderer = frame.renderer;
        var textureNode = this.textureNode;
        var map = textureNode.value;
        var textureType = map.type;
        this._compRT.texture.type = textureType;
        this._oldRT.texture.type = textureType;
        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;
        this.textureNodeOld.value = this._oldRT.texture;
        renderer.setRenderTarget(this._compRT);
        quadMeshComp.render(renderer);
        var temp = this._oldRT;
        this._oldRT = this._compRT;
        this._compRT = temp;
        this.setSize(map.image.width, map.image.height);
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:Builder):TextureNode {
        var textureNode = this.textureNode;
        var textureNodeOld = this.textureNodeOld;
        if (textureNode.isTextureNode !== true) {
            trace('AfterImageNode requires a TextureNode.');
            return vec4();
        }
        var uvNode = textureNode.uvNode || uv();
        textureNodeOld.uvNode = uvNode;
        var sampleTexture = (uv:Vec2) -> textureNode.cache().context({getUV: () -> uv, forceUVContext: true});
        var when_gt = (x_immutable:Vec4, y_immutable:Float) -> {
            var y = float(y_immutable).toVar();
            var x = vec4(x_immutable).toVar();
            return max(sign(x.sub(y)), 0.0);
        };
        var afterImg = () -> {
            var texelOld = vec4(textureNodeOld);
            var texelNew = vec4(sampleTexture(uvNode));
            texelOld.mulAssign(this.damp.mul(when_gt(texelOld, 0.1)));
            return max(texelNew, texelOld);
        };
        var materialComposed = this._materialComposed || (this._materialComposed = builder.createNodeMaterial());
        materialComposed.fragmentNode = afterImg();
        quadMeshComp.material = materialComposed;
        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        return this._textureNode;
    }
}

static function afterImage(node:Node, damp:Float):Node {
    return nodeObject(new AfterImageNode(nodeObject(node), damp));
}

addNodeElement('afterImage', afterImage);