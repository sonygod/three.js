import three.examples.jsm.nodes.core.Node;
import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.accessors.TextureNode;
import three.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.examples.jsm.nodes.core.UniformNode;
import three.examples.jsm.nodes.display.ViewportDepthNode;
import three.RenderTarget;
import three.Vector2;
import three.HalfFloatType;
import three.DepthTexture;
import three.NoToneMapping;

class PassTextureNode extends TextureNode {

    public var passNode: PassNode;

    public function new(passNode: PassNode, texture: Dynamic) {
        super(texture);
        this.passNode = passNode;
        this.setUpdateMatrix(false);
    }

    override public function setup(builder: Dynamic): Dynamic {
        this.passNode.build(builder);
        return super.setup(builder);
    }

    override public function clone(): PassTextureNode {
        return new PassTextureNode(this.passNode, this.value);
    }
}

class PassNode extends TempNode {

    static public var COLOR: String = 'color';
    static public var DEPTH: String = 'depth';

    public var scope: String;
    public var scene: Dynamic;
    public var camera: Dynamic;

    private var _pixelRatio: Float = 1;
    private var _width: Int = 1;
    private var _height: Int = 1;

    public var renderTarget: RenderTarget;

    private var _textureNode: Dynamic;
    private var _depthTextureNode: Dynamic;
    private var _depthNode: Dynamic;
    private var _viewZNode: Dynamic;
    private var _cameraNear: Dynamic;
    private var _cameraFar: Dynamic;

    public var isPassNode: Bool = true;

    public function new(scope: String, scene: Dynamic, camera: Dynamic) {
        super('vec4');
        this.scope = scope;
        this.scene = scene;
        this.camera = camera;

        var depthTexture = new DepthTexture();
        depthTexture.isRenderTargetTexture = true;
        depthTexture.name = 'PostProcessingDepth';

        var renderTarget = new RenderTarget(_width * _pixelRatio, _height * _pixelRatio, { type: HalfFloatType });
        renderTarget.texture.name = 'PostProcessing';
        renderTarget.depthTexture = depthTexture;

        this.renderTarget = renderTarget;

        this.updateBeforeType = NodeUpdateType.FRAME;

        this._textureNode = ShaderNode.nodeObject(new PassTextureNode(this, renderTarget.texture));
        this._depthTextureNode = ShaderNode.nodeObject(new PassTextureNode(this, depthTexture));

        this._depthNode = null;
        this._viewZNode = null;
        this._cameraNear = UniformNode.uniform(0);
        this._cameraFar = UniformNode.uniform(0);
    }

    public function isGlobal(): Bool {
        return true;
    }

    public function getTextureNode(): Dynamic {
        return this._textureNode;
    }

    public function getTextureDepthNode(): Dynamic {
        return this._depthTextureNode;
    }

    public function getViewZNode(): Dynamic {
        if (this._viewZNode == null) {
            var cameraNear = this._cameraNear;
            var cameraFar = this._cameraFar;

            this._viewZNode = ViewportDepthNode.perspectiveDepthToViewZ(this._depthTextureNode, cameraNear, cameraFar);
        }

        return this._viewZNode;
    }

    public function getDepthNode(): Dynamic {
        if (this._depthNode == null) {
            var cameraNear = this._cameraNear;
            var cameraFar = this._cameraFar;

            this._depthNode = ViewportDepthNode.viewZToOrthographicDepth(this.getViewZNode(), cameraNear, cameraFar);
        }

        return this._depthNode;
    }

    override public function setup(): Dynamic {
        return this.scope == PassNode.COLOR ? this.getTextureNode() : this.getDepthNode();
    }

    override public function updateBefore(frame: Dynamic): Void {
        var renderer = frame.renderer;
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

    public function setSize(width: Int, height: Int): Void {
        this._width = width;
        this._height = height;

        var effectiveWidth = this._width * this._pixelRatio;
        var effectiveHeight = this._height * this._pixelRatio;

        this.renderTarget.setSize(effectiveWidth, effectiveHeight);
    }

    public function setPixelRatio(pixelRatio: Float): Void {
        this._pixelRatio = pixelRatio;

        this.setSize(this._width, this._height);
    }

    public function dispose(): Void {
        this.renderTarget.dispose();
    }
}

Node.addNodeClass('PassNode', PassNode);

function pass(scene: Dynamic, camera: Dynamic): Dynamic {
    return ShaderNode.nodeObject(new PassNode(PassNode.COLOR, scene, camera));
}

function texturePass(pass: PassNode, texture: Dynamic): Dynamic {
    return ShaderNode.nodeObject(new PassTextureNode(pass, texture));
}

function depthPass(scene: Dynamic, camera: Dynamic): Dynamic {
    return ShaderNode.nodeObject(new PassNode(PassNode.DEPTH, scene, camera));
}