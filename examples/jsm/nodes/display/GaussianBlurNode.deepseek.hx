import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.math.OperatorNode;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.nodes.display.PassNode;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.objects.QuadMesh;
import three.js.Three;

class GaussianBlurNode extends TempNode {

    public var textureNode:ShaderNode;
    public var sigma:Float;
    public var directionNode:ShaderNode;
    public var _invSize:UniformNode;
    public var _passDirection:UniformNode;
    public var _horizontalRT:RenderTarget;
    public var _verticalRT:RenderTarget;
    public var _textureNode:ShaderNode;
    public var updateBeforeType:NodeUpdateType;
    public var resolution:Vector2;

    public function new(textureNode:ShaderNode, sigma:Float = 2) {
        super('vec4');
        this.textureNode = textureNode;
        this.sigma = sigma;
        this.directionNode = ShaderNode.vec2(1);
        this._invSize = UniformNode.uniform(new Vector2());
        this._passDirection = UniformNode.uniform(new Vector2());
        this._horizontalRT = new RenderTarget();
        this._horizontalRT.texture.name = 'GaussianBlurNode.horizontal';
        this._verticalRT = new RenderTarget();
        this._verticalRT.texture.name = 'GaussianBlurNode.vertical';
        this._textureNode = PassNode.texturePass(this, this._verticalRT.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
        this.resolution = new Vector2(1, 1);
    }

    public function setSize(width:Float, height:Float) {
        width = Math.max(Math.round(width * this.resolution.x), 1);
        height = Math.max(Math.round(height * this.resolution.y), 1);
        this._invSize.value.set(1 / width, 1 / height);
        this._horizontalRT.setSize(width, height);
        this._verticalRT.setSize(width, height);
    }

    public function updateBefore(frame:Frame) {
        var renderer:Renderer = frame.renderer;
        var textureNode:ShaderNode = this.textureNode;
        var map:Texture = textureNode.value;
        var currentRenderTarget:RenderTarget = renderer.getRenderTarget();
        var currentTexture:Texture = textureNode.value;
        var quadMesh1:QuadMesh = new QuadMesh();
        var quadMesh2:QuadMesh = new QuadMesh();
        quadMesh1.material = this._material;
        quadMesh2.material = this._material;
        this.setSize(map.image.width, map.image.height);
        var textureType:String = map.type;
        this._horizontalRT.texture.type = textureType;
        this._verticalRT.texture.type = textureType;
        // horizontal
        renderer.setRenderTarget(this._horizontalRT);
        this._passDirection.value.set(1, 0);
        quadMesh1.render(renderer);
        // vertical
        textureNode.value = this._horizontalRT.texture;
        renderer.setRenderTarget(this._verticalRT);
        this._passDirection.value.set(0, 1);
        quadMesh2.render(renderer);
        // restore
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function getTextureNode():ShaderNode {
        return this._textureNode;
    }

    public function setup(builder:NodeBuilder) {
        var textureNode:ShaderNode = this.textureNode;
        if (textureNode.isTextureNode !== true) {
            trace('GaussianBlurNode requires a TextureNode.');
            return ShaderNode.vec4();
        }
        //
        var uvNode:ShaderNode = textureNode.uvNode || ShaderNode.uv();
        var sampleTexture = function(uv:ShaderNode) {
            return textureNode.cache().context({getUV: function() {return uv;}, forceUVContext: true});
        };
        var blur = function() {
            var kernelSize = 3 + (2 * this.sigma);
            var gaussianCoefficients = this._getCoefficients(kernelSize);
            var invSize:UniformNode = this._invSize;
            var direction:ShaderNode = ShaderNode.vec2(this.directionNode).mul(this._passDirection);
            var weightSum:Float = ShaderNode.float(gaussianCoefficients[0]).toVar();
            var diffuseSum:ShaderNode = ShaderNode.vec4(sampleTexture(uvNode)).mul(weightSum).toVar();
            for (i in 1...kernelSize) {
                var x:Float = ShaderNode.float(i);
                var w:Float = ShaderNode.float(gaussianCoefficients[i]);
                var uvOffset:ShaderNode = ShaderNode.vec2(direction.mul(invSize.mul(x))).toVar();
                var sample1:ShaderNode = ShaderNode.vec4(sampleTexture(uvNode.add(uvOffset)));
                var sample2:ShaderNode = ShaderNode.vec4(sampleTexture(uvNode.sub(uvOffset)));
                diffuseSum.addAssign(sample1.add(sample2).mul(w));
                weightSum.addAssign(OperatorNode.mul(2.0, w));
            }
            return diffuseSum.div(weightSum);
        };
        //
        var material = this._material || (this._material = builder.createNodeMaterial());
        material.fragmentNode = blur();
        //
        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        //
        return this._textureNode;
    }

    private function _getCoefficients(kernelRadius:Int):Array<Float> {
        var coefficients:Array<Float> = [];
        for (i in 0...kernelRadius) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }
        return coefficients;
    }
}

class GaussianBlur {
    public static function gaussianBlur(node:ShaderNode, sigma:Float):ShaderNode {
        return new GaussianBlurNode(node, sigma);
    }
}

ShaderNode.addNodeElement('gaussianBlur', GaussianBlur.gaussianBlur);