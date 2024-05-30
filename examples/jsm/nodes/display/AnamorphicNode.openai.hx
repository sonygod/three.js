package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.js.shadernode.ShaderNode;
import three.js.utils.LoopNode;
import three.js.core.UniformNode;
import three.js.core.NodeUpdateType;
import three.js.accessors.UVNode;
import three.js.nodes.PassNode;
import three.js.THREE.Vector2;
import three.js.objects.QuadMesh;

class AnamorphicNode extends TempNode {

    public var textureNode:Node;
    public var tresholdNode:Node;
    public var scaleNode:Node;
    public var colorNode:Vec3;
    public var samples:Int;
    public var resolution:Vector2;
    public var _renderTarget:RenderTarget;
    public var _invSize:UniformNode;
    public var _textureNode:Node;

    public function new(textureNode:Node, tresholdNode:Node, scaleNode:Node, samples:Int) {
        super('vec4');

        this.textureNode = textureNode;
        this.tresholdNode = tresholdNode;
        this.scaleNode = scaleNode;
        this.colorNode = new Vec3(0.1, 0.0, 1.0);
        this.samples = samples;
        this.resolution = new Vector2(1, 1);

        this._renderTarget = new RenderTarget();
        this._renderTarget.texture.name = 'anamorphic';

        this._invSize = new UniformNode(new Vector2());

        this._textureNode = PassNode.texturePass(this, this._renderTarget.texture);

        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode():Node {
        return this._textureNode;
    }

    public function setSize(width:Int, height:Int) {
        this._invSize.value.set(1 / width, 1 / height);

        width = Std.int(Math.max(width * this.resolution.x, 1));
        height = Std.int(Math.max(height * this.resolution.y, 1));

        this._renderTarget.setSize(width, height);
    }

    public function updateBefore(frame:Any) {
        var renderer:Any = frame.renderer;
        var textureNode:Node = this.textureNode;
        var map:Any = textureNode.value;

        this._renderTarget.texture.type = map.type;

        var currentRenderTarget:Any = renderer.getRenderTarget();
        var currentTexture:Any = textureNode.value;

        quadMesh.material = this._material;

        this.setSize(map.image.width, map.image.height);

        // render

        renderer.setRenderTarget(this._renderTarget);

        quadMesh.render(renderer);

        // restore

        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:Any) {
        var textureNode:Node = this.textureNode;

        if (!Std.is(textureNode, TextureNode)) {
            throw new Error('AnamorphNode requires a TextureNode.');
            return new Vec4();
        }

        var uvNode:UVNode = textureNode.uvNode != null ? textureNode.uvNode : new UVNode();
        var sampleTexture:Any = function(uv:Vec2) {
            return textureNode.cache().context({ getUV: function() { return uv; }, forceUVContext: true });
        };

        var anamorph:Any = tslFn(function() {
            var total:Vec3 = new Vec3(0);

            LoopNode.loop({
                start: -Math.floor(samples / 2),
                end: Math.floor(samples / 2)
            }, function(i:Int) {
                var softness:Float = Math.abs(i) / Math.floor(samples / 2);
                var uv:Vec2 = new Vec2(uvNode.x + _invSize.x * i * scaleNode, uvNode.y);
                var color:Vec4 = sampleTexture(uv);
                var pass:Vec4 = threshold(color, tresholdNode).mul(softness);
                total.addAssign(pass);
            });

            return total.mul(this.colorNode);
        });

        var material:Any = this._material != null ? this._material : (this._material = builder.createNodeMaterial());
        material.fragmentNode = anamorph();

        var properties:Any = builder.getNodeProperties(this);
        properties.textureNode = textureNode;

        return this._textureNode;
    }
}

function anamorphic(node:Node, threshold:Float = 0.9, scale:Float = 3, samples:Int = 32) {
    return nodeObject(new AnamorphicNode(nodeObject(node), nodeObject(threshold), nodeObject(scale), samples));
}

addNodeElement('anamorphic', anamorphic);

#elseif js

extern class QuadMesh {}

var quadMesh:QuadMesh = new QuadMesh();

#else

#error "Target should be either js or else."

#end