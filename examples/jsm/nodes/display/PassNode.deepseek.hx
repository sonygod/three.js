import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.accessors.TextureNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.ViewportDepthNode;
import three.js.three.RenderTarget;
import three.js.three.Vector2;
import three.js.three.HalfFloatType;
import three.js.three.DepthTexture;
import three.js.three.NoToneMapping;
import three.js.three.FloatType;

class PassTextureNode extends TextureNode {

	public function new(passNode:PassNode, texture:Texture) {
		super(texture);
		this.passNode = passNode;
		this.setUpdateMatrix(false);
	}

	public function setup(builder:ShaderNode.Builder):ShaderNode {
		this.passNode.build(builder);
		return super.setup(builder);
	}

	public function clone():PassTextureNode {
		return new PassTextureNode(this.passNode, this.value);
	}

}

class PassNode extends TempNode {

	public function new(scope:String, scene:Scene, camera:Camera) {
		super('vec4');
		this.scope = scope;
		this.scene = scene;
		this.camera = camera;
		this._pixelRatio = 1;
		this._width = 1;
		this._height = 1;
		var depthTexture = new DepthTexture();
		depthTexture.isRenderTargetTexture = true;
		depthTexture.type = FloatType;
		depthTexture.name = 'PostProcessingDepth';
		var renderTarget = new RenderTarget(this._width * this._pixelRatio, this._height * this._pixelRatio, {type: HalfFloatType});
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
		this.isPassNode = true;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getTextureNode():ShaderNode {
		return this._textureNode;
	}

	public function getTextureDepthNode():ShaderNode {
		return this._depthTextureNode;
	}

	public function getViewZNode():ShaderNode {
		if (this._viewZNode === null) {
			var cameraNear = this._cameraNear;
			var cameraFar = this._cameraFar;
			this._viewZNode = ViewportDepthNode.perspectiveDepthToViewZ(this._depthTextureNode, cameraNear, cameraFar);
		}
		return this._viewZNode;
	}

	public function getDepthNode():ShaderNode {
		if (this._depthNode === null) {
			var cameraNear = this._cameraNear;
			var cameraFar = this._cameraFar;
			this._depthNode = ViewportDepthNode.viewZToOrthographicDepth(this.getViewZNode(), cameraNear, cameraFar);
		}
		return this._depthNode;
	}

	public function setup():ShaderNode {
		return this.scope === PassNode.COLOR ? this.getTextureNode() : this.getDepthNode();
	}

	public function updateBefore(frame:Frame) {
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

	public function setSize(width:Float, height:Float) {
		this._width = width;
		this._height = height;
		var effectiveWidth = this._width * this._pixelRatio;
		var effectiveHeight = this._height * this._pixelRatio;
		this.renderTarget.setSize(effectiveWidth, effectiveHeight);
	}

	public function setPixelRatio(pixelRatio:Float) {
		this._pixelRatio = pixelRatio;
		this.setSize(this._width, this._height);
	}

	public function dispose() {
		this.renderTarget.dispose();
	}

}

PassNode.COLOR = 'color';
PassNode.DEPTH = 'depth';

function pass(scene:Scene, camera:Camera):ShaderNode {
	return ShaderNode.nodeObject(new PassNode(PassNode.COLOR, scene, camera));
}

function texturePass(pass:PassNode, texture:Texture):ShaderNode {
	return ShaderNode.nodeObject(new PassTextureNode(pass, texture));
}

function depthPass(scene:Scene, camera:Camera):ShaderNode {
	return ShaderNode.nodeObject(new PassNode(PassNode.DEPTH, scene, camera));
}

Node.addNodeClass('PassNode', PassNode);