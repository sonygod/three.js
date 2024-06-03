import shadernode.ShaderNode;
import core.TempNode;
import core.constants.NodeUpdateType;
import math.OperatorNode;
import accessors.UVNode;
import display.PassNode;
import core.UniformNode;
import three.Vector2;
import three.RenderTarget;
import objects.QuadMesh;

class GaussianBlurNode extends TempNode {
    var _quadMesh1:QuadMesh = new QuadMesh();
    var _quadMesh2:QuadMesh = new QuadMesh();
    var textureNode:ShaderNode.TextureNode;
    var sigma:Float;
    var directionNode:ShaderNode.Vec2Node;
    var _invSize:UniformNode;
    var _passDirection:UniformNode;
    var _horizontalRT:RenderTarget = new RenderTarget();
    var _verticalRT:RenderTarget = new RenderTarget();
    var _textureNode:PassNode.TextureNode;
    var _material:ShaderNode.NodeMaterial;
    var resolution:Vector2 = new Vector2(1, 1);

    public function new(textureNode:ShaderNode.TextureNode, sigma:Float = 2) {
        super('vec4');
        this.textureNode = textureNode;
        this.sigma = sigma;
        this.directionNode = ShaderNode.vec2(1);
        this._invSize = UniformNode.uniform(new Vector2());
        this._passDirection = UniformNode.uniform(new Vector2());
        this._horizontalRT.texture.name = 'GaussianBlurNode.horizontal';
        this._verticalRT.texture.name = 'GaussianBlurNode.vertical';
        this._textureNode = PassNode.texturePass(this, this._verticalRT.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function setSize(width:Int, height:Int) {
        width = Math.max(Math.round(width * this.resolution.x), 1);
        height = Math.max(Math.round(height * this.resolution.y), 1);
        this._invSize.value.set(1 / width, 1 / height);
        this._horizontalRT.setSize(width, height);
        this._verticalRT.setSize(width, height);
    }

    public function updateBefore(frame:ShaderNode.Frame) {
        var renderer = frame.renderer;
        var textureNode = this.textureNode;
        var map = textureNode.value;
        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;
        _quadMesh1.material = this._material;
        _quadMesh2.material = this._material;
        this.setSize(map.image.width, map.image.height);
        var textureType = map.type;
        this._horizontalRT.texture.type = textureType;
        this._verticalRT.texture.type = textureType;
        renderer.setRenderTarget(this._horizontalRT);
        this._passDirection.value.set(1, 0);
        _quadMesh1.render(renderer);
        textureNode.value = this._horizontalRT.texture;
        renderer.setRenderTarget(this._verticalRT);
        this._passDirection.value.set(0, 1);
        _quadMesh2.render(renderer);
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function getTextureNode():PassNode.TextureNode {
        return this._textureNode;
    }

    public function setup(builder:ShaderNode.NodeBuilder) {
        var textureNode = this.textureNode;
        if (textureNode.isTextureNode !== true) {
            trace('GaussianBlurNode requires a TextureNode.');
            return ShaderNode.vec4();
        }
        var uvNode = textureNode.uvNode || UVNode.uv();
        var sampleTexture = (uv) -> textureNode.cache().context({getUV: () -> uv, forceUVContext: true});
        var blur = ShaderNode.tslFn(() => {
            var kernelSize = 3 + (2 * this.sigma);
            var gaussianCoefficients = this._getCoefficients(kernelSize);
            var invSize = this._invSize;
            var direction = ShaderNode.vec2(this.directionNode).mul(this._passDirection);
            var weightSum = ShaderNode.float(gaussianCoefficients[0]).toVar();
            var diffuseSum = ShaderNode.vec4(sampleTexture(uvNode).mul(weightSum)).toVar();
            for (var i:Int = 1; i < kernelSize; i++) {
                var x = ShaderNode.float(i);
                var w = ShaderNode.float(gaussianCoefficients[i]);
                var uvOffset = ShaderNode.vec2(direction.mul(invSize.mul(x))).toVar();
                var sample1 = ShaderNode.vec4(sampleTexture(uvNode.add(uvOffset)));
                var sample2 = ShaderNode.vec4(sampleTexture(uvNode.sub(uvOffset)));
                diffuseSum.addAssign(sample1.add(sample2).mul(w));
                weightSum.addAssign(OperatorNode.mul(2.0, w));
            }
            return diffuseSum.div(weightSum);
        });
        var material = this._material || (this._material = builder.createNodeMaterial());
        material.fragmentNode = blur();
        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        return this._textureNode;
    }

    private function _getCoefficients(kernelRadius:Int):Array<Float> {
        var coefficients = [];
        for (var i:Int = 0; i < kernelRadius; i++) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }
        return coefficients;
    }
}

static function gaussianBlur(node:ShaderNode.Node, sigma:Float):ShaderNode.NodeObject {
    return ShaderNode.nodeObject(new GaussianBlurNode(ShaderNode.nodeObject(node), sigma));
}

ShaderNode.addNodeElement('gaussianBlur', gaussianBlur);