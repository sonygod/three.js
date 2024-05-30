package three.js.examples.javascript.nodes.display;

import three.js.core.TempNode;
import three.js.shadernode.ShaderNode;
import three.js.core.constants.NodeUpdateType;
import three.js.accessors.UVNode;
import three.js.accessors.TextureNode;
import three.js.nodes.PassNode;
import three.math.MathNode;
import three.objects.QuadMesh;

class AfterImageNode extends TempNode {
    public var textureNode:TextureNode;
    public var textureNodeOld:TextureNode;
    public var damp:UniformNode;
    public var _compRT:RenderTarget;
    public var _oldRT:RenderTarget;
    public var _textureNode:TextureNode;

    public function new(textureNode:TextureNode, damp:Float = 0.96) {
        super(textureNode);
        this.textureNode = textureNode;
        this.textureNodeOld = new TextureNode();
        this.damp = new UniformNode(damp);
        _compRT = new RenderTarget();
        _compRT.texture.name = 'AfterImageNode.comp';
        _oldRT = new RenderTarget();
        _oldRT.texture.name = 'AfterImageNode.old';
        _textureNode = new TextureNode();
        _textureNode.value = pass(this, _compRT.texture);
    }

    public function getTextureNode():TextureNode {
        return _textureNode;
    }

    public function setSize(width:Int, height:Int) {
        _compRT.setSize(width, height);
        _oldRT.setSize(width, height);
    }

    public function updateBefore(frame:Dynamic) {
        var renderer:Dynamic = frame.renderer;
        var textureNode:TextureNode = this.textureNode;
        var map:Dynamic = textureNode.value;
        var textureType:String = map.type;
        _compRT.texture.type = textureType;
        _oldRT.texture.type = textureType;
        var currentRenderTarget:Dynamic = renderer.getRenderTarget();
        var currentTexture:Dynamic = textureNode.value;
        textureNodeOld.value = _oldRT.texture;
        renderer.setRenderTarget(_compRT);
        quadMeshComp.render(renderer);
        var temp:RenderTarget = _oldRT;
        _oldRT = _compRT;
        _compRT = temp;
        setSize(map.image.width, map.image.height);
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:Dynamic) {
        var textureNode:TextureNode = this.textureNode;
        var textureNodeOld:TextureNode = this.textureNodeOld;
        if (!textureNode.isTextureNode) {
            trace('AfterImageNode requires a TextureNode.');
            return new Vec4();
        }
        var uvNode:UVNode = textureNode.uvNode || new UVNode();
        textureNodeOld.uvNode = uvNode;
        var sampleTexture:Dynamic = function(uv:Dynamic) {
            return textureNode.cache().context({ getUV: function() { return uv; }, forceUVContext: true });
        };
        var whenGt:Dynamic = tslFn(function(x_immutable:Dynamic, y_immutable:Dynamic) {
            var y:Float = y_immutable.toFloat();
            var x:Vec4 = new Vec4(x_immutable);
            return max(sign(x.sub(y)), 0.0);
        });
        var afterImg:Dynamic = tslFn(function() {
            var texelOld:Vec4 = new Vec4(textureNodeOld);
            var texelNew:Vec4 = new Vec4(sampleTexture(uvNode));
            texelOld.mulAssign(damp.mul(whenGt(texelOld, 0.1)));
            return max(texelNew, texelOld);
        });
        var materialComposed:MaterialNode = _materialComposed || (_materialComposed = builder.createNodeMaterial());
        materialComposed.fragmentNode = afterImg();
        quadMeshComp.material = materialComposed;
        var properties:Dynamic = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        return _textureNode;
    }
}

function afterImage(node:Dynamic, damp:Float = 0.96) {
    return nodeObject(new AfterImageNode(nodeObject(node), damp));
}

addNodeElement('afterImage', afterImage);

extern class QuadMesh {
    public function render(renderer:Dynamic) {}
}

extern class RenderTarget {
    public var texture:Dynamic;
    public function setSize(width:Int, height:Int) {}
    public function setRenderTarget(self:RenderTarget) {}
}

extern class UniformNode {
    public function new(value:Float) {}
    public function mul(value:Float) {}
}

extern class Vec4 {
    public function new(value:Dynamic) {}
    public function sub(value:Dynamic) {}
    public function mulAssign(value:Float) {}
}

extern class UVNode {
    public function new() {}
}

extern class TextureNode {
    public var value:Dynamic;
    public var uvNode:UVNode;
    public function cache() {}
    public function isTextureNode(get:Bool) {}
}

extern class PassNode {
    public function pass(self:Dynamic, texture:Dynamic) {}
}

extern class MathNode {
    public function sign(value:Float) {}
    public function max(value1:Float, value2:Float) {}
}

extern class NodeUpdateType {
    public static var RENDER:Int;
}

extern class ShaderNode {
    public static var nodeObject:Dynamic;
    public static var tslFn:Dynamic;
    public static var float:Dynamic;
    public static var vec4:Dynamic;
    public static var uniform:Dynamic;
}