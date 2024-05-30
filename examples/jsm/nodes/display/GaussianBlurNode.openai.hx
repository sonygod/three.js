package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.js.shadernode.ShaderNode;
import three.js.core.constants.NodeUpdateType;
import three.js.math.OperatorNode;
import three.js.accessors.UVNode;
import three.js.nodes.PassNode;
import three.js.core.UniformNode;
import three.js.objects.QuadMesh;
import three.js.renderers.RenderTarget;
import three.js.math.Vector2;

class GaussianBlurNode extends TempNode {
    public var textureNode:TempNode;
    public var sigma:Float;
    public var directionNode:Vector2;
    public var _invSize:UniformNode;
    public var _passDirection:UniformNode;
    public var _horizontalRT:RenderTarget;
    public var _verticalRT:RenderTarget;
    public var _textureNode:TempNode;
    public var resolution:Vector2;
    public var _material:NodeMaterial;
    public var quadMesh1:QuadMesh;
    public var quadMesh2:QuadMesh;

    public function new(textureNode:TempNode, sigma:Float = 2) {
        super('vec4');

        this.textureNode = textureNode;
        this.sigma = sigma;

        this.directionNode = new Vector2(1, 0);

        this._invSize = new UniformNode(new Vector2());
        this._passDirection = new UniformNode(new Vector2());

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

    public function updateBefore(frame:Dynamic) {
        var renderer = frame.renderer;
        var textureNode = this.textureNode;
        var map = textureNode.value;

        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;

        quadMesh1.material = this._material;
        quadMesh2.material = this._material;

        this.setSize(map.image.width, map.image.height);

        var textureType = map.type;

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

    public function getTextureNode():TempNode {
        return this._textureNode;
    }

    public function setup(builder:Dynamic) {
        var textureNode = this.textureNode;

        if (!textureNode.isTextureNode) {
            console.error('GaussianBlurNode requires a TextureNode.');
            return vec4();
        }

        var uvNode = textureNode.uvNode || UVNode.uv();

        var sampleTexture = function(uv:Vector2) {
            return textureNode.cache().context({ getUV: function() { return uv; }, forceUVContext: true });
        };

        var blur = tslFn(function() {
            var kernelSize = 3 + (2 * this.sigma);
            var gaussianCoefficients = _getCoefficients(kernelSize);

            var invSize = this._invSize;
            var direction = vec2(this.directionNode).mul(this._passDirection);

            var weightSum = float(gaussianCoefficients[0]).toVar();
            var diffuseSum = vec4(sampleTexture(uvNode).mul(weightSum)).toVar();

            for (i in 1...kernelSize) {
                var x = float(i);
                var w = float(gaussianCoefficients[i]);

                var uvOffset = vec2(direction.mul(invSize.mul(x))).toVar();

                var sample1 = vec4(sampleTexture(uvNode.add(uvOffset)));
                var sample2 = vec4(sampleTexture(uvNode.sub(uvOffset)));

                diffuseSum.addAssign(sample1.add(sample2).mul(w));
                weightSum.addAssign(mul(2.0, w));
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

        for (i in 0...kernelRadius) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }

        return coefficients;
    }
}

class QuadMesh {
    public var material:NodeMaterial;
    public function new() {}

    public function render(renderer:Dynamic) {}
}

class NodeMaterial {
    public var fragmentNode:TempNode;
    public function new() {}
}

class RenderTarget {
    public var texture:Texture;
    public function new() {}
    public function setSize(width:Float, height:Float) {}
}

class Texture {
    public var type:String;
    public var name:String;
    public function new() {}
}

class Vector2 {
    public var x:Float;
    public var y:Float;
    public function new(x:Float, y:Float) {}
    public function mul(v:Vector2):Vector2 {
        return new Vector2(x * v.x, y * v.y);
    }
    public function add(v:Vector2):Vector2 {
        return new Vector2(x + v.x, y + v.y);
    }
    public function sub(v:Vector2):Vector2 {
        return new Vector2(x - v.x, y - v.y);
    }
}

class UniformNode {
    public var value:Dynamic;
    public function new(value:Dynamic) {}
}

class OperatorNode {
    public function mul(a:Float, b:Float):Float {
        return a * b;
    }
}

class UVNode {
    public static function uv():UVNode {
        return new UVNode();
    }
    public function new() {}
}

class PassNode {
    public static function texturePass(node:TempNode, texture:Texture):TempNode {
        return new TempNode();
    }
}

class ShaderNode {
    public function nodeObject(node:TempNode):TempNode {
        return node;
    }
    public function addNodeElement(name:String, node:TempNode):Void {
        // todo: implement this
    }
}

class TempNode {
    public function new(type:String) {}
    public function toVar():TempNode {
        return this;
    }
}

class gaussianBlur {
    public static function gaussianBlur(node:TempNode, sigma:Float = 2):TempNode {
        return ShaderNode.nodeObject(new GaussianBlurNode(ShaderNode.nodeObject(node), sigma));
    }
}

class ShaderNode {
    public function addNodeElement(name:String, node:TempNode):Void {
        // todo: implement this
    }
}