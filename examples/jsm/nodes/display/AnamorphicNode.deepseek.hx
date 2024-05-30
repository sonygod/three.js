import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.utils.LoopNode;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.nodes.ColorAdjustmentNode;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.nodes.PassNode;
import three.js.objects.QuadMesh;
import three.js.core.Vector2;
import three.js.core.RenderTarget;

class AnamorphicNode extends TempNode {

    public function new(textureNode:ShaderNode, tresholdNode:ShaderNode, scaleNode:ShaderNode, samples:Int) {
        super('vec4');

        this.textureNode = textureNode;
        this.tresholdNode = tresholdNode;
        this.scaleNode = scaleNode;
        this.colorNode = new Vector3(0.1, 0.0, 1.0);
        this.samples = samples;
        this.resolution = new Vector2(1, 1);

        this._renderTarget = new RenderTarget();
        this._renderTarget.texture.name = 'anamorphic';

        this._invSize = new UniformNode(new Vector2());

        this._textureNode = PassNode.texturePass(this, this._renderTarget.texture);

        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode():ShaderNode {
        return this._textureNode;
    }

    public function setSize(width:Float, height:Float):Void {
        this._invSize.value.set(1 / width, 1 / height);

        width = Math.max(Math.round(width * this.resolution.x), 1);
        height = Math.max(Math.round(height * this.resolution.y), 1);

        this._renderTarget.setSize(width, height);
    }

    public function updateBefore(frame:Frame):Void {
        var renderer = frame.renderer;

        var textureNode = this.textureNode;
        var map = textureNode.value;

        this._renderTarget.texture.type = map.type;

        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;

        var quadMesh = new QuadMesh();
        quadMesh.material = this._material;

        this.setSize(map.image.width, map.image.height);

        // render

        renderer.setRenderTarget(this._renderTarget);

        quadMesh.render(renderer);

        // restore

        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:NodeBuilder):ShaderNode {
        var textureNode = this.textureNode;

        if (textureNode.isTextureNode !== true) {
            trace('AnamorphNode requires a TextureNode.');
            return new Vector4();
        }

        //

        var uvNode = textureNode.uvNode || UVNode.uv();

        var sampleTexture = function(uv:Vector2):ShaderNode {
            return textureNode.cache().context({getUV: function():Vector2 { return uv; }, forceUVContext: true});
        };

        var anamorph = function():ShaderNode {
            var samples = this.samples;
            var halfSamples = Math.floor(samples / 2);

            var total = new Vector3(0).toVar();

            LoopNode.loop({start: - halfSamples, end: halfSamples}, function(i:Int):Void {
                var softness = new Float(i).abs().div(halfSamples).oneMinus();

                var uv = new Vector2(uvNode.x.add(this._invSize.x.mul(i).mul(this.scaleNode)), uvNode.y);
                var color = sampleTexture(uv);
                var pass = ColorAdjustmentNode.threshold(color, this.tresholdNode).mul(softness);

                total.addAssign(pass);
            });

            return total.mul(this.colorNode);
        };

        //

        var material = this._material || (this._material = builder.createNodeMaterial());
        material.fragmentNode = anamorph();

        //

        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;

        //

        return this._textureNode;
    }
}

static function anamorphic(node:ShaderNode, threshold:Float = 0.9, scale:Float = 3, samples:Int = 32):ShaderNode {
    return new AnamorphicNode(node, threshold, scale, samples);
}

ShaderNode.addNodeElement('anamorphic', anamorphic);