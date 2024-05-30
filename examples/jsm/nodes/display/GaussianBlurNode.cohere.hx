import TempNode from '../core/TempNode.hx';
import { nodeObject, addNodeElement, tslFn, float, vec2, vec4 } from '../shadernode/ShaderNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { mul } from '../math/OperatorNode.hx';
import { uv } from '../accessors/UVNode.hx';
import { texturePass } from './PassNode.hx';
import { uniform } from '../core/UniformNode.hx';
import { Vector2, RenderTarget } from 'three';
import QuadMesh from '../../objects/QuadMesh.hx';

class GaussianBlurNode extends TempNode {
    public _invSize:Uniform<Vector2>;
    public _passDirection:Uniform<Vector2>;
    public _horizontalRT:RenderTarget;
    public _verticalRT:RenderTarget;
    public _textureNode:TextureNode;
    public resolution:Vector2;

    public function new(textureNode:TextureNode, sigma:Float = 2.) {
        super('vec4');
        this._invSize = uniform(Vector2.create());
        this._passDirection = uniform(Vector2.create());
        this._horizontalRT = new RenderTarget();
        this._verticalRT = new RenderTarget();
        this._textureNode = texturePass(this, this._verticalRT.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
        this.resolution = Vector2.one();
        this.textureNode = textureNode;
        this.sigma = sigma;
        this.directionNode = vec2(1.);
    }

    public function setSize(width:Int, height:Int):Void {
        width = std.int(std.max(width * this.resolution.x, 1.));
        height = std.int(std.max(height * this.resolution.y, 1.));
        this._invSize.value.set(1. / width, 1. / height);
        this._horizontalRT.setSize(width, height);
        this._verticalRT.setSize(width, height);
    }

    public function updateBefore(frame:Frame):Void {
        var renderer = frame.renderer;
        var textureNode = this.textureNode;
        var map = textureNode.value;
        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;
        var quadMesh1 = new QuadMesh();
        var quadMesh2 = new QuadMesh();
        quadMesh1.material = this._material;
        quadMesh2.material = this._material;
        this.setSize(map.image.width, map.image.height);
        var textureType = map.type;
        this._horizontalRT.texture.type = textureType;
        this._verticalRT.texture.type = textureType;
        renderer.setRenderTarget(this._horizontalRT);
        this._passDirection.value.set(1., 0.);
        quadMesh1.render(renderer);
        textureNode.value = this._horizontalRT.texture;
        renderer.setRenderTarget(this._verticalRT);
        this._passDirection.value.set(0., 1.);
        quadMesh2.render(renderer);
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function getTextureNode():TextureNode {
        return this._textureNode;
    }

    public function setup(builder:ShaderNodeBuilder):TextureNode {
        var textureNode = this.textureNode;
        if (!textureNode.isTextureNode) {
            trace('GaussianBlurNode requires a TextureNode.');
            return vec4();
        }
        var uvNode = textureNode.uvNode ?? uv();
        var sampleTexture = function(uv) {
            return textureNode.cache().context({getUV: function() {
                return uv;
            }, forceUVContext: true});
        };
        var blur = tslFn(function() use(uvNode) {
            var kernelSize = 3 + (2 * this.sigma);
            var gaussianCoefficients = this._getCoefficients(kernelSize);
            var invSize = this._invSize;
            var direction = vec2(this.directionNode).mul(this._passDirection);
            var weightSum = float(gaussianCoefficients[0]).toVar();
            var diffuseSum = vec4(sampleTexture(uvNode).mul(weightSum)).toVar();
            var i = 1;
            while (i < kernelSize) {
                var x = float(i);
                var w = float(gaussianCoefficients[i]);
                var uvOffset = vec2(direction.mul(invSize.mul(x))).toVar();
                var sample1 = vec4(sampleTexture(uvNode.add(uvOffset)));
                var sample2 = vec4(sampleTexture(uvNode.sub(uvOffset)));
                diffuseSum.addAssign(sample1.add(sample2).mul(w));
                weightSum.addAssign(mul(2., w));
                i++;
            }
            return diffuseSum.div(weightSum);
        });
        var material = this._material ?? (this._material = builder.createNodeMaterial());
        material.fragmentNode = blur();
        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        return this._textureNode;
    }

    public function _getCoefficients(kernelRadius:Int):Array<Float> {
        var coefficients = [];
        var i = 0;
        while (i < kernelRadius) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
            i++;
        }
        return coefficients;
    }
}

function gaussianBlur(node, sigma) {
    return nodeObject(new GaussianBlurNode(nodeObject(node), sigma));
}

addNodeElement('gaussianBlur', gaussianBlur);

class Export {
    public static default:GaussianBlurNode = GaussianBlurNode;
}