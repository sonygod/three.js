import three.RenderTarget;
import three.Vector2;
import three.DepthTexture;
import three.HalfFloatType;
import three.NoToneMapping;
import three.WebGLRenderer;

import shadernode.ShaderNode;
import shadernode.UniformNode;
import shadernode.NodeObject;
import shadernode.TempNode;
import shadernode.TextureNode;
import shadernode.ViewportDepthNode;
import shadernode.NodeUpdateType;

class PassTextureNode extends TextureNode {

    public var passNode:PassNode;

    public function new(passNode:PassNode, texture:three.Texture) {
        super(texture);
        this.passNode = passNode;
        this.setUpdateMatrix(false);
    }

    override public function setup(builder:ShaderNode) {
        this.passNode.build(builder);
        return super.setup(builder);
    }

    override public function clone() {
        return new PassTextureNode(this.passNode, this.value);
    }

}

class PassNode extends TempNode {

    public static var COLOR:String = "color";
    public static var DEPTH:String = "depth";

    public var scope:String;
    public var scene:Dynamic;
    public var camera:Dynamic;

    public var _pixelRatio:Float;
    public var _width:Int;
    public var _height:Int;

    public var renderTarget:RenderTarget;

    public var _textureNode:NodeObject;
    public var _depthTextureNode:NodeObject;

    public var _depthNode:ShaderNode;
    public var _viewZNode:ShaderNode;
    public var _cameraNear:UniformNode;
    public var _cameraFar:UniformNode;

    public function new(scope:String, scene:Dynamic, camera:Dynamic) {
        super("vec4");
        this.scope = scope;
        this.scene = scene;
        this.camera = camera;

        this._pixelRatio = 1.0;
        this._width = 1;
        this._height = 1;

        var depthTexture = new DepthTexture();
        depthTexture.isRenderTargetTexture = true;
        //depthTexture.type = FloatType;
        depthTexture.name = "PostProcessingDepth";

        var renderTarget = new RenderTarget(this._width * this._pixelRatio, this._height * this._pixelRatio, { type: HalfFloatType });
        renderTarget.texture.name = "PostProcessing";
        renderTarget.depthTexture = depthTexture;

        this.renderTarget = renderTarget;

        this.updateBeforeType = NodeUpdateType.FRAME;

        this._textureNode = NodeObject.fromNode(new PassTextureNode(this, renderTarget.texture));
        this._depthTextureNode = NodeObject.fromNode(new PassTextureNode(this, depthTexture));

        this._depthNode = null;
        this._viewZNode = null;
        this._cameraNear = new UniformNode(0.0);
        this._cameraFar = new UniformNode(0.0);

        this.isPassNode = true;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getTextureNode():NodeObject {
        return this._textureNode;
    }

    public function getTextureDepthNode():NodeObject {
        return this._depthTextureNode;
    }

    public function getViewZNode():ShaderNode {
        if (this._viewZNode == null) {
            var cameraNear = this._cameraNear;
            var cameraFar = this._cameraFar;
            this._viewZNode = ViewportDepthNode.perspectiveDepthToViewZ(this._depthTextureNode, cameraNear, cameraFar);
        }
        return this._viewZNode;
    }

    public function getDepthNode():ShaderNode {
        if (this._depthNode == null) {
            var cameraNear = this._cameraNear;
            var cameraFar = this._cameraFar;
            this._depthNode = ViewportDepthNode.viewZToOrthographicDepth(this.getViewZNode(), cameraNear, cameraFar);
        }
        return this._depthNode;
    }

    override public function setup():ShaderNode {
        return if (this.scope == PassNode.COLOR) this.getTextureNode() else this.getDepthNode();
    }

    override public function updateBefore(frame:Dynamic):Void {
        var renderer = cast(frame.renderer, WebGLRenderer);
        var scene = this.scene;
        var camera = this.camera;

        this._pixelRatio = renderer.getPixelRatio();

        var size = renderer.getSize(new Vector2());
        this.setSize(size.width, size.height);

        var currentToneMapping = renderer.toneMapping;
        var currentToneMappingNode = renderer.toneMappingNode;
        var currentRenderTarget = renderer.getRenderTarget();

        this._cameraNear.value = camera.near;
        this._cameraFar.value = camera.far;

        renderer.toneMapping = NoToneMapping;
        renderer.toneMappingNode = null;
        renderer.setRenderTarget(this.renderTarget);

        renderer.render(scene, camera);

        renderer.toneMapping = currentToneMapping;
        renderer.toneMappingNode = currentToneMappingNode;
        renderer.setRenderTarget(currentRenderTarget);
    }

    public function setSize(width:Int, height:Int):Void {
        this._width = width;
        this._height = height;
        var effectiveWidth = this._width * this._pixelRatio;
        var effectiveHeight = this._height * this._pixelRatio;
        this.renderTarget.setSize(effectiveWidth, effectiveHeight);
    }

    public function setPixelRatio(pixelRatio:Float):Void {
        this._pixelRatio = pixelRatio;
        this.setSize(this._width, this._height);
    }

    public function dispose():Void {
        this.renderTarget.dispose();
    }

}

class PassNodeStatic {
    public static function pass(scene:Dynamic, camera:Dynamic):NodeObject {
        return NodeObject.fromNode(new PassNode(PassNode.COLOR, scene, camera));
    }

    public static function texturePass(pass:PassNode, texture:three.Texture):NodeObject {
        return NodeObject.fromNode(new PassTextureNode(pass, texture));
    }

    public static function depthPass(scene:Dynamic, camera:Dynamic):NodeObject {
        return NodeObject.fromNode(new PassNode(PassNode.DEPTH, scene, camera));
    }
}

ShaderNode.addNodeClass("PassNode", PassNode);