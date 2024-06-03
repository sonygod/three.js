import js.Browser.document;
import three.nodes.core.TempNode;
import three.nodes.shadernode.ShaderNode;
import three.nodes.core.constants.NodeUpdateType;
import three.nodes.accessors.UVNode;
import three.nodes.accessors.TextureNode;
import three.nodes.display.PassNode;
import three.nodes.core.UniformNode;
import three.RenderTarget;
import three.nodes.math.MathNode;
import three.objects.QuadMesh;

class AfterImageNode extends TempNode {
    public var textureNode:ShaderNode;
    public var textureNodeOld:ShaderNode;
    public var damp:ShaderNode;
    private var _compRT:RenderTarget;
    private var _oldRT:RenderTarget;
    private var _textureNode:ShaderNode;
    public var updateBeforeType:NodeUpdateType;

    public function new(textureNode:ShaderNode, damp:Float = 0.96) {
        super(textureNode);
        this.textureNode = textureNode;
        this.textureNodeOld = TextureNode.texture();
        this.damp = UniformNode.uniform(damp);

        this._compRT = new RenderTarget();
        this._compRT.texture.name = 'AfterImageNode.comp';

        this._oldRT = new RenderTarget();
        this._oldRT.texture.name = 'AfterImageNode.old';

        this._textureNode = PassNode.texturePass(this, this._compRT.texture);

        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode():ShaderNode {
        return this._textureNode;
    }

    public function setSize(width:Int, height:Int) {
        this._compRT.setSize(width, height);
        this._oldRT.setSize(width, height);
    }

    public function updateBefore(frame:Frame) {
        var renderer = frame.renderer;

        var textureNode = this.textureNode;
        var map = textureNode.value;

        var textureType = map.type;

        this._compRT.texture.type = textureType;
        this._oldRT.texture.type = textureType;

        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;

        this.textureNodeOld.value = this._oldRT.texture;

        // comp
        renderer.setRenderTarget(this._compRT);
        var quadMeshComp = new QuadMesh();
        quadMeshComp.render(renderer);

        // Swap the textures
        var temp = this._oldRT;
        this._oldRT = this._compRT;
        this._compRT = temp;

        // set size before swapping fails
        this.setSize(map.image.width, map.image.height);

        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:Builder):ShaderNode {
        var textureNode = this.textureNode;
        var textureNodeOld = this.textureNodeOld;

        if (Std.is(textureNode, TextureNode) !== true) {
            js.Browser.console.error('AfterImageNode requires a TextureNode.');
            return ShaderNode.vec4();
        }

        //

        var uvNode = Std.is(textureNode.uvNode, Dynamic) ? textureNode.uvNode : UVNode.uv();

        textureNodeOld.uvNode = uvNode;

        var sampleTexture = function(uv:ShaderNode):ShaderNode {
            return textureNode.cache().context({ getUV: function() return uv, forceUVContext: true });
        };

        var when_gt = ShaderNode.tslFn(function(args:Array<Dynamic>) {
            var y = ShaderNode.float(args[1]).toVar();
            var x = ShaderNode.vec4(args[0]).toVar();

            return MathNode.max(MathNode.sign(x.sub(y)), 0.0);
        });

        var afterImg = ShaderNode.tslFn(function(args:Array<Dynamic>) {
            var texelOld = ShaderNode.vec4(textureNodeOld);
            var texelNew = ShaderNode.vec4(sampleTexture(uvNode));

            texelOld.mulAssign(damp.mul(when_gt(texelOld, 0.1)));
            return MathNode.max(texelNew, texelOld);
        });

        //

        var materialComposed = Std.is(this._materialComposed, Dynamic) ? this._materialComposed : builder.createNodeMaterial();
        materialComposed.fragmentNode = afterImg();

        var quadMeshComp = new QuadMesh();
        quadMeshComp.material = materialComposed;

        //

        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;

        //

        return this._textureNode;
    }
}

function afterImage(node:Dynamic, damp:Float):ShaderNode {
    return ShaderNode.nodeObject(new AfterImageNode(ShaderNode.nodeObject(node), damp));
}

ShaderNode.addNodeElement('afterImage', afterImage);

export default AfterImageNode;