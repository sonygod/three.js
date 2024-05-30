import haxe.ds.StringMap;
import js.Node;
import js.Texture;
import js.three.DepthTexture;
import js.three.RenderTarget;
import js.three.Vector2;
import js.three.HalfFloatType;
import js.three.NoToneMapping;
import js.three.NodeUpdateType;
import js.three.ShaderNode;
import js.three.TempNode;
import js.three.TextureNode;
import js.three.Uniform;
import js.three.ViewportDepthNode;

class PassTextureNode extends TextureNode {
    public var passNode:PassNode;

    public function new(passNode:PassNode, texture:Texture) {
        super(texture);
        this.passNode = passNode;
        this.setUpdateMatrix(false);
    }

    public function setup(builder:ShaderNode.Builder) {
        passNode.build(builder);
        return super.setup(builder);
    }

    public function clone():PassTextureNode {
        return new PassTextureNode(passNode, value);
    }
}

class PassNode extends TempNode {
    public static var COLOR:String = 'color';
    public static var DEPTH:String = 'depth';

    public var scope:String;
    public var scene:js.Object;
    public var camera:js.Object;
    public var _pixelRatio:Float;
    public var _width:Int;
    public var _height:Int;
    public var renderTarget:RenderTarget;
    public var updateBeforeType:NodeUpdateType;
    public var _textureNode:PassTextureNode;
    public var _depthTextureNode:PassTextureNode;
    public var _depthNode:js.Node;
    public var _viewZNode:js.Node;
    public var _cameraNear:Uniform;
    public var _cameraFar:Uniform;

    public function new(scope:String, scene:js.Object, camera:js.Object) {
        super('vec4');
        this.scope = scope;
        this.scene = scene;
        this.camera = camera;
        _pixelRatio = 1.0;
        _width = 1;
        _height = 1;
        var depthTexture = new DepthTexture();
        depthTexture.isRenderTargetTexture = true;
        //depthTexture.type = FloatType;
        depthTexture.name = 'PostProcessingDepth';
        renderTarget = new RenderTarget(_width * _pixelRatio, _height * _pixelRatio, { type: HalfFloatType });
        renderTarget.texture.name = 'PostProcessing';
        renderTarget.depthTexture = depthTexture;
        updateBeforeType = NodeUpdateType.FRAME;
        _textureNode = new PassTextureNode(this, renderTarget.texture);
        _depthTextureNode = new PassTextureNode(this, depthTexture);
        _depthNode = null;
        _viewZNode = null;
        _cameraNear = new Uniform(0);
        _cameraFar = new Uniform(0);
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getTextureNode():PassTextureNode {
        return _textureNode;
    }

    public function getTextureDepthNode():PassTextureNode {
        return _depthTextureNode;
    }

    public function getViewZNode():js.Node {
        if (_viewZNode == null) {
            _viewZNode = new ViewportDepthNode.perspectiveDepthToViewZ(_depthTextureNode, _cameraNear, _cameraFar);
        }
        return _viewZNode;
    }

    public function getDepthNode():js.Node {
        if (_depthNode == null) {
            _depthNode = new ViewportDepthNode.viewZToOrthographicDepth(getViewZNode(), _cameraNear, _cameraFar);
        }
        return _depthNode;
    }

    public function setup():js.Node {
        return if (scope == PassNode.COLOR) getTextureNode() else getDepthNode();
    }

    public function updateBefore(frame:js.Object) {
        var renderer = frame.renderer;
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

    public function setSize(width:Int, height:Int) {
        _width = width;
        _height = height;
        var effectiveWidth = _width * _pixelRatio;
        var effectiveHeight = _height * _pixelRatio;
        renderTarget.setSize(effectiveWidth, effectiveHeight);
    }

    public function setPixelRatio(pixelRatio:Float) {
        _pixelRatio = pixelRatio;
        setSize(_width, _height);
    }

    public function dispose() {
        renderTarget.dispose();
    }
}

function pass(scene:js.Object, camera:js.Object):ShaderNode.NodeObject {
    return new ShaderNode.NodeObject(new PassNode(PassNode.COLOR, scene, camera));
}

function texturePass(pass:PassNode, texture:Texture):ShaderNode.NodeObject {
    return new ShaderNode.NodeObject(new PassTextureNode(pass, texture));
}

function depthPass(scene:js.Object, camera:js.Object):ShaderNode.NodeObject {
    return new ShaderNode.NodeObject(new PassNode(PassNode.DEPTH, scene, camera));
}

static function addNodeClass(name:String, nodeClass:js.Node) {
    ShaderNode.addNodeClass(name, nodeClass);
}