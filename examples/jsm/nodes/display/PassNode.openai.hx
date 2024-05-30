package three.js.examples.jvm.nodes.display;

import three.js.core.Node;
import three.js.accessors.TextureNode;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.core.UniformNode;
import three.js.nodes.display.ViewportDepthNode;
import three.js.RenderTarget;
import three.js.Vector2;
import three.js.utils.HalfFloatType;
import three.js.texture.DepthTexture;

class PassTextureNode extends TextureNode {

    public var passNode:PassNode;
    public var value:Texture;

    public function new(passNode:PassNode, texture:Texture) {
        super(texture);
        this.passNode = passNode;
        this.setUpdateMatrix(false);
    }

    override public function setup(builder:Dynamic):Void {
        passNode.build(builder);
        super.setup(builder);
    }

    override public function clone():TextureNode {
        return new PassTextureNode(passNode, value);
    }
}

class PassNode extends TempNode {

    public var scope:String;
    public var scene:Dynamic;
    public var camera:Dynamic;
    public var _pixelRatio:Float;
    public var _width:Int;
    public var _height:Int;
    public var renderTarget:RenderTarget;
    public var _textureNode:ShaderNode;
    public var _depthTextureNode:ShaderNode;
    public var _depthNode:ShaderNode;
    public var _viewZNode:ShaderNode;
    public var _cameraNear:UniformNode;
    public var _cameraFar:UniformNode;

    public function new(scope:String, scene:Dynamic, camera:Dynamic) {
        super('vec4');
        this.scope = scope;
        this.scene = scene;
        this.camera = camera;
        this._pixelRatio = 1;
        this._width = 1;
        this._height = 1;
        var depthTexture = new DepthTexture();
        depthTexture.isRenderTargetTexture = true;
        depthTexture.name = 'PostProcessingDepth';
        renderTarget = new RenderTarget(_width * _pixelRatio, _height * _pixelRatio, { type: HalfFloatType });
        renderTarget.texture.name = 'PostProcessing';
        renderTarget.depthTexture = depthTexture;
        this._textureNode = ShaderNode.create(new PassTextureNode(this, renderTarget.texture));
        this._depthTextureNode = ShaderNode.create(new PassTextureNode(this, depthTexture));
        this._depthNode = null;
        this._viewZNode = null;
        this._cameraNear = new UniformNode(0);
        this._cameraFar = new UniformNode(0);
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getTextureNode():ShaderNode {
        return _textureNode;
    }

    public function getTextureDepthNode():ShaderNode {
        return _depthTextureNode;
    }

    public function getViewZNode():ShaderNode {
        if (_viewZNode == null) {
            var cameraNear = _cameraNear;
            var cameraFar = _cameraFar;
            _viewZNode = ViewportDepthNode.perspectiveDepthToViewZ(_depthTextureNode, cameraNear, cameraFar);
        }
        return _viewZNode;
    }

    public function getDepthNode():ShaderNode {
        if (_depthNode == null) {
            var cameraNear = _cameraNear;
            var cameraFar = _cameraFar;
            _depthNode = ViewportDepthNode.viewZToOrthographicDepth(getViewZNode(), cameraNear, cameraFar);
        }
        return _depthNode;
    }

    public function setup():ShaderNode {
        return scope == COLOR ? getTextureNode() : getDepthNode();
    }

    public function updateBefore(frame:Dynamic):Void {
        var renderer = frame.renderer;
        var scene = this.scene;
        var camera = this.camera;
        _pixelRatio = renderer.getPixelRatio();
        var size = renderer.getSize(new Vector2());
        setSize(size.width, size.height);
        var currentToneMapping = renderer.toneMapping;
        var currentToneMappingNode = renderer.toneMappingNode;
        var currentRenderTarget = renderer.getRenderTarget();
        _cameraNear.value = camera.near;
        _cameraFar.value = camera.far;
        renderer.toneMapping = NoToneMapping;
        renderer.toneMappingNode = null;
        renderer.setRenderTarget(renderTarget);
        renderer.render(scene, camera);
        renderer.toneMapping = currentToneMapping;
        renderer.toneMappingNode = currentToneMappingNode;
        renderer.setRenderTarget(currentRenderTarget);
    }

    public function setSize(width:Int, height:Int):Void {
        _width = width;
        _height = height;
        var effectiveWidth = _width * _pixelRatio;
        var effectiveHeight = _height * _pixelRatio;
        renderTarget.setSize(effectiveWidth, effectiveHeight);
    }

    public function setPixelRatio(pixelRatio:Float):Void {
        _pixelRatio = pixelRatio;
        setSize(_width, _height);
    }

    public function dispose():Void {
        renderTarget.dispose();
    }

}

class PassNode {
    public static var COLOR:String = 'color';
    public static var DEPTH:String = 'depth';
}

// exports
export PassNode;
export function pass(scene:Dynamic, camera:Dynamic):ShaderNode {
    return ShaderNode.create(new PassNode(PassNode.COLOR, scene, camera));
}
export function texturePass(pass:PassNode, texture:Texture):ShaderNode {
    return ShaderNode.create(new PassTextureNode(pass, texture));
}
export function depthPass(scene:Dynamic, camera:Dynamic):ShaderNode {
    return ShaderNode.create(new PassNode(PassNode.DEPTH, scene, camera));
}

Node.addClass('PassNode', PassNode);