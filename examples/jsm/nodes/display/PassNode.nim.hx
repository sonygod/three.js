import three.examples.jsm.nodes.core.Node.addNodeClass;
import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.accessors.TextureNode;
import three.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.examples.jsm.nodes.shadernode.ShaderNode.nodeObject;
import three.examples.jsm.nodes.core.UniformNode.uniform;
import three.examples.jsm.nodes.display.ViewportDepthNode.viewZToOrthographicDepth;
import three.examples.jsm.nodes.display.ViewportDepthNode.perspectiveDepthToViewZ;
import three.examples.jsm.nodes.display.RenderTarget;
import three.examples.jsm.nodes.display.Vector2;
import three.examples.jsm.nodes.display.HalfFloatType;
import three.examples.jsm.nodes.display.DepthTexture;
import three.examples.jsm.nodes.display.NoToneMapping;

class PassTextureNode extends TextureNode {

	public var passNode:PassNode;

	public function new(passNode:PassNode, texture:Dynamic) {
		super(texture);
		this.passNode = passNode;
		this.setUpdateMatrix(false);
	}

	public function setup(builder:Dynamic):Dynamic {
		this.passNode.build(builder);
		return super.setup(builder);
	}

	public function clone():PassTextureNode {
		return new PassTextureNode(this.passNode, this.value);
	}

}

class PassNode extends TempNode {

	public var scope:Dynamic;
	public var scene:Dynamic;
	public var camera:Dynamic;
	private var _pixelRatio:Float;
	private var _width:Int;
	private var _height:Int;
	private var _textureNode:Dynamic;
	private var _depthTextureNode:Dynamic;
	private var _depthNode:Dynamic;
	private var _viewZNode:Dynamic;
	private var _cameraNear:Dynamic;
	private var _cameraFar:Dynamic;

	public function new(scope:Dynamic, scene:Dynamic, camera:Dynamic) {
		super('vec4');
		this.scope = scope;
		this.scene = scene;
		this.camera = camera;
		this._pixelRatio = 1;
		this._width = 1;
		this._height = 1;
		var depthTexture = new DepthTexture();
		depthTexture.isRenderTargetTexture = true;
		//depthTexture.type = FloatType;
		depthTexture.name = 'PostProcessingDepth';
		var renderTarget = new RenderTarget(this._width * this._pixelRatio, this._height * this._pixelRatio, { type: HalfFloatType });
		renderTarget.texture.name = 'PostProcessing';
		renderTarget.depthTexture = depthTexture;
		this.renderTarget = renderTarget;
		this.updateBeforeType = NodeUpdateType.FRAME;
		this._textureNode = nodeObject(new PassTextureNode(this, renderTarget.texture));
		this._depthTextureNode = nodeObject(new PassTextureNode(this, depthTexture));
		this._depthNode = null;
		this._viewZNode = null;
		this._cameraNear = uniform(0);
		this._cameraFar = uniform(0);
		this.isPassNode = true;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getTextureNode():Dynamic {
		return this._textureNode;
	}

	public function getTextureDepthNode():Dynamic {
		return this._depthTextureNode;
	}

	public function getViewZNode():Dynamic {
		if (this._viewZNode === null) {
			var cameraNear = this._cameraNear;
			var cameraFar = this._cameraFar;
			this._viewZNode = perspectiveDepthToViewZ(this._depthTextureNode, cameraNear, cameraFar);
		}
		return this._viewZNode;
	}

	public function getDepthNode():Dynamic {
		if (this._depthNode === null) {
			var cameraNear = this._cameraNear;
			var cameraFar = this._cameraFar;
			this._depthNode = viewZToOrthographicDepth(this.getViewZNode(), cameraNear, cameraFar);
		}
		return this._depthNode;
	}

	public function setup():Dynamic {
		return this.scope === PassNode.COLOR ? this.getTextureNode() : this.getDepthNode();
	}

	public function updateBefore(frame:Dynamic):Void {
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

class PassNode {
	public static inline var COLOR = 'color';
	public static inline var DEPTH = 'depth';
}

addNodeClass('PassNode', PassNode);