import three.core.Node as Node;
import three.core.TempNode as TempNode;
import three.accessors.TextureNode as TextureNode;
import three.core.constants.NodeUpdateType;
import three.shadernode.ShaderNode as ShaderNode;
import three.core.UniformNode as UniformNode;
import three.nodes.ViewportDepthNode as ViewportDepthNode;
import three.math.Vector2;
import three.textures.DepthTexture;
import three.renderers.WebGLRenderer as WebGLRenderer;
import three.renderers.webGL.WebGLRenderTarget as WebGLRenderTarget;
import three.renderers.webGL.WebGLMultisampleRenderTarget as WebGLMultisampleRenderTarget;
import three.constants.ToneMapping;
import three.constants.TextureDataType;

class PassTextureNode extends TextureNode {

	public var passNode:PassNode;

	public function new(passNode:PassNode, texture:three.textures.Texture) {
		super(texture);
		this.passNode = passNode;
		this.setUpdateMatrix(false);
	}

	override public function setup(builder:Node.NodeBuilder):Node.Node {
		this.passNode.build(builder);
		return super.setup(builder);
	}

	override public function clone():Node {
		return new PassTextureNode(this.passNode, this.value);
	}

}

class PassNode extends TempNode {

	public static var COLOR:String = "color";
	public static var DEPTH:String = "depth";

	public var scope:String;
	public var scene:three.scenes.Scene;
	public var camera:three.cameras.Camera;

	private var _pixelRatio:Float;
	private var _width:Int;
	private var _height:Int;

	private var _textureNode:ShaderNode;
	private var _depthTextureNode:ShaderNode;

	private var _depthNode:Node;
	private var _viewZNode:Node;

	private var _cameraNear:UniformNode;
	private var _cameraFar:UniformNode;

	private var _renderTarget:WebGLRenderTarget;

	public function new(scope:String, scene:three.scenes.Scene, camera:three.cameras.Camera) {
		super("vec4");
		this.scope = scope;
		this.scene = scene;
		this.camera = camera;
		this._pixelRatio = 1;
		this._width = 1;
		this._height = 1;
		this.updateBeforeType = NodeUpdateType.FRAME;
		var depthTexture = new DepthTexture();
		depthTexture.isRenderTargetTexture = true;
		depthTexture.name = "PostProcessingDepth";
		var renderTarget = new WebGLRenderTarget(this._width * this._pixelRatio, this._height * this._pixelRatio, { type: TextureDataType.HALF_FLOAT });
		renderTarget.texture.name = "PostProcessing";
		renderTarget.depthTexture = depthTexture;
		this._renderTarget = renderTarget;
		this._textureNode = new ShaderNode(new PassTextureNode(this, renderTarget.texture));
		this._depthTextureNode = new ShaderNode(new PassTextureNode(this, depthTexture));
		this._depthNode = null;
		this._viewZNode = null;
		this._cameraNear = new UniformNode(0);
		this._cameraFar = new UniformNode(0);
		this.isPassNode = true;
	}

	override public function isGlobal():Bool {
		return true;
	}

	public function getTextureNode():ShaderNode {
		return this._textureNode;
	}

	public function getTextureDepthNode():ShaderNode {
		return this._depthTextureNode;
	}

	public function getViewZNode():Node {
		if (this._viewZNode == null) {
			this._viewZNode = ViewportDepthNode.perspectiveDepthToViewZ(this._depthTextureNode, this._cameraNear, this._cameraFar);
		}
		return this._viewZNode;
	}

	public function getDepthNode():Node {
		if (this._depthNode == null) {
			this._depthNode = ViewportDepthNode.viewZToOrthographicDepth(this.getViewZNode(), this._cameraNear, this._cameraFar);
		}
		return this._depthNode;
	}

	override public function setup():Node {
		return if (this.scope == PassNode.COLOR) this.getTextureNode() else this.getDepthNode();
	}

	override public function updateBefore(frame:Node.Frame):Void {
		var renderer:WebGLRenderer = frame.renderer;
		var scene:three.scenes.Scene = this.scene;
		var camera:three.cameras.Camera = this.camera;
		this._pixelRatio = renderer.getPixelRatio();
		var size:Vector2 = renderer.getSize(new Vector2());
		this.setSize(size.x, size.y);
		var currentToneMapping:ToneMapping = renderer.toneMapping;
		var currentToneMappingNode:Node = renderer.toneMappingNode;
		var currentRenderTarget:WebGLRenderTarget = renderer.getRenderTarget();
		this._cameraNear.value = camera.near;
		this._cameraFar.value = camera.far;
		renderer.toneMapping = ToneMapping.NO_TONE_MAPPING;
		renderer.toneMappingNode = null;
		renderer.setRenderTarget(this._renderTarget);
		renderer.render(scene, camera);
		renderer.toneMapping = currentToneMapping;
		renderer.toneMappingNode = currentToneMappingNode;
		renderer.setRenderTarget(currentRenderTarget);
	}

	public function setSize(width:Int, height:Int):Void {
		this._width = width;
		this._height = height;
		this._renderTarget.setSize(this._width * this._pixelRatio, this._height * this._pixelRatio);
	}

	public function setPixelRatio(pixelRatio:Float):Void {
		this._pixelRatio = pixelRatio;
		this.setSize(this._width, this._height);
	}

	public function dispose():Void {
		this._renderTarget.dispose();
	}

}

public function pass(scene:three.scenes.Scene, camera:three.cameras.Camera):ShaderNode {
	return new ShaderNode(new PassNode(PassNode.COLOR, scene, camera));
}

public function texturePass(pass:PassNode, texture:three.textures.Texture):ShaderNode {
	return new ShaderNode(new PassTextureNode(pass, texture));
}

public function depthPass(scene:three.scenes.Scene, camera:three.cameras.Camera):ShaderNode {
	return new ShaderNode(new PassNode(PassNode.DEPTH, scene, camera));
}

Node.addNodeClass("PassNode", PassNode);