import three.core.Color;
import three.core.Matrix4;
import three.core.MeshDepthMaterial;
import three.core.ShaderMaterial;
import three.core.UniformsUtils;
import three.core.Vector2;
import three.core.Vector3;
import three.math.Vector4;
import three.renderers.FullScreenQuad;
import three.renderers.WebGLRenderTarget;
import three.sceneGraph.Object3D;
import three.sceneGraph.Pass;
import three.shaders.CopyShader;

class OutlinePass extends Pass {

	public var renderScene:Object3D;
	public var renderCamera:three.core.Camera;
	public var selectedObjects:Array<Object3D>;
	public var visibleEdgeColor:Color;
	public var hiddenEdgeColor:Color;
	public var edgeGlow:Float;
	public var usePatternTexture:Bool;
	public var edgeThickness:Float;
	public var edgeStrength:Float;
	public var downSampleRatio:Int;
	public var pulsePeriod:Float;

	private var _visibilityCache:Map<Object3D, Bool>;
	private var resx:Int;
	private var resy:Int;
	private var renderTargetMaskBuffer:WebGLRenderTarget;
	private var depthMaterial:MeshDepthMaterial;
	private var prepareMaskMaterial:ShaderMaterial;
	private var renderTargetDepthBuffer:WebGLRenderTarget;
	private var renderTargetMaskDownSampleBuffer:WebGLRenderTarget;
	private var renderTargetBlurBuffer1:WebGLRenderTarget;
	private var renderTargetBlurBuffer2:WebGLRenderTarget;
	private var edgeDetectionMaterial:ShaderMaterial;
	private var renderTargetEdgeBuffer1:WebGLRenderTarget;
	private var renderTargetEdgeBuffer2:WebGLRenderTarget;
	private var separableBlurMaterial1:ShaderMaterial;
	private var separableBlurMaterial2:ShaderMaterial;
	private var overlayMaterial:ShaderMaterial;
	private var materialCopy:ShaderMaterial;
	private var fsQuad:FullScreenQuad;
	private var tempPulseColor1:Color;
	private var tempPulseColor2:Color;
	private var textureMatrix:Matrix4;

	public function new(resolution:Vector2, scene:Object3D, camera:three.core.Camera, selectedObjects:Array<Object3D>) {
		super();

		this.renderScene = scene;
		this.renderCamera = camera;
		this.selectedObjects = selectedObjects !== undefined ? selectedObjects : [];
		this.visibleEdgeColor = new Color(1, 1, 1);
		this.hiddenEdgeColor = new Color(0.1, 0.04, 0.02);
		this.edgeGlow = 0.0;
		this.usePatternTexture = false;
		this.edgeThickness = 1.0;
		this.edgeStrength = 3.0;
		this.downSampleRatio = 2;
		this.pulsePeriod = 0;

		this._visibilityCache = new Map<Object3D, Bool>();

		this.resolution = (resolution !== undefined) ? new Vector2(resolution.x, resolution.y) : new Vector2(256, 256);

		resx = Math.round(this.resolution.x / this.downSampleRatio);
		resy = Math.round(this.resolution.y / this.downSampleRatio);

		this.renderTargetMaskBuffer = new WebGLRenderTarget(this.resolution.x, this.resolution.y);
		this.renderTargetMaskBuffer.texture.name = 'OutlinePass.mask';
		this.renderTargetMaskBuffer.texture.generateMipmaps = false;

		this.depthMaterial = new MeshDepthMaterial();
		this.depthMaterial.side = three.core.DoubleSide;
		this.depthMaterial.depthPacking = three.constants.RGBADepthPacking;
		this.depthMaterial.blending = three.constants.NoBlending;

		this.prepareMaskMaterial = this.getPrepareMaskMaterial();
		this.prepareMaskMaterial.side = three.core.DoubleSide;
		this.prepareMaskMaterial.fragmentShader = replaceDepthToViewZ(this.prepareMaskMaterial.fragmentShader, this.renderCamera);

		this.renderTargetDepthBuffer = new WebGLRenderTarget(this.resolution.x, this.resolution.y, { type: three.constants.HalfFloatType });
		this.renderTargetDepthBuffer.texture.name = 'OutlinePass.depth';
		this.renderTargetDepthBuffer.texture.generateMipmaps = false;

		this.renderTargetMaskDownSampleBuffer = new WebGLRenderTarget(resx, resy, { type: three.constants.HalfFloatType });
		this.renderTargetMaskDownSampleBuffer.texture.name = 'OutlinePass.depthDownSample';
		this.renderTargetMaskDownSampleBuffer.texture.generateMipmaps = false;

		this.renderTargetBlurBuffer1 = new WebGLRenderTarget(resx, resy, { type: three.constants.HalfFloatType });
		this.renderTargetBlurBuffer1.texture.name = 'OutlinePass.blur1';
		this.renderTargetBlurBuffer1.texture.generateMipmaps = false;
		this.renderTargetBlurBuffer2 = new WebGLRenderTarget(Math.round(resx / 2), Math.round(resy / 2), { type: three.constants.HalfFloatType });
		this.renderTargetBlurBuffer2.texture.name = 'OutlinePass.blur2';
		this.renderTargetBlurBuffer2.texture.generateMipmaps = false;

		this.edgeDetectionMaterial = this.getEdgeDetectionMaterial();
		this.renderTargetEdgeBuffer1 = new WebGLRenderTarget(resx, resy, { type: three.constants.HalfFloatType });
		this.renderTargetEdgeBuffer1.texture.name = 'OutlinePass.edge1';
		this.renderTargetEdgeBuffer1.texture.generateMipmaps = false;
		this.renderTargetEdgeBuffer2 = new WebGLRenderTarget(Math.round(resx / 2), Math.round(resy / 2), { type: three.constants.HalfFloatType });
		this.renderTargetEdgeBuffer2.texture.name = 'OutlinePass.edge2';
		this.renderTargetEdgeBuffer2.texture.generateMipmaps = false;

		const MAX_EDGE_THICKNESS = 4;
		const MAX_EDGE_GLOW = 4;

		this.separableBlurMaterial1 = this.getSeperableBlurMaterial(MAX_EDGE_THICKNESS);
		this.separableBlurMaterial1.uniforms['texSize'].value.set(resx, resy);
		this.separableBlurMaterial1.uniforms['kernelRadius'].value = 1;
		this.separableBlurMaterial2 = this.getSeperableBlurMaterial(MAX_EDGE_GLOW);
		this.separableBlurMaterial2.uniforms['texSize'].value.set(Math.round(resx / 2), Math.round(resy / 2));
		this.separableBlurMaterial2.uniforms['kernelRadius'].value = MAX_EDGE_GLOW;

		// Overlay material
		this.overlayMaterial = this.getOverlayMaterial();

		// copy material

		const copyShader = CopyShader;

		this.copyUniforms = UniformsUtils.clone(copyShader.uniforms);

		this.materialCopy = new ShaderMaterial({
			uniforms: this.copyUniforms,
			vertexShader: copyShader.vertexShader,
			fragmentShader: copyShader.fragmentShader,
			blending: three.constants.NoBlending,
			depthTest: false,
			depthWrite: false
		});

		this.enabled = true;
		this.needsSwap = false;

		this._oldClearColor = new Color();
		this.oldClearAlpha = 1;

		this.fsQuad = new FullScreenQuad(null);

		this.tempPulseColor1 = new Color();
		this.tempPulseColor2 = new Color();
		this.textureMatrix = new Matrix4();

		function replaceDepthToViewZ(string, camera) {
			const type = camera.isPerspectiveCamera ? 'perspective' : 'orthographic';
			return string.replace(/DEPTH_TO_VIEW_Z/g, type + 'DepthToViewZ');
		}
	}

	public function dispose() {
		this.renderTargetMaskBuffer.dispose();
		this.renderTargetDepthBuffer.dispose();
		this.renderTargetMaskDownSampleBuffer.dispose();
		this.renderTargetBlurBuffer1.dispose();
		this.renderTargetBlurBuffer2.dispose();
		this.renderTargetEdgeBuffer1.dispose();
		this.renderTargetEdgeBuffer2.dispose();

		this.depthMaterial.dispose();
		this.prepareMaskMaterial.dispose();
		this.edgeDetectionMaterial.dispose();
		this.separableBlurMaterial1.dispose();
		this.separableBlurMaterial2.dispose();
		this.overlayMaterial.dispose();
		this.materialCopy.dispose();

		this.fsQuad.dispose();
	}

	public function setSize(width:Int, height:Int) {
		this.renderTargetMaskBuffer.setSize(width, height);
		this.renderTargetDepthBuffer.setSize(width, height);

		let resx = Math.round(this.resolution.x / this.downSampleRatio);
		let resy = Math.round(this.resolution.y / this.downSampleRatio);
		this.renderTargetMaskDownSampleBuffer.setSize(resx, resy);
		this.renderTargetBlurBuffer1.setSize(resx, resy);
		this.renderTargetEdgeBuffer1.setSize(resx, resy);
		this.separableBlurMaterial1.uniforms['texSize'].value.set(resx, resy);

		resx = Math.round(resx / 2);
		resy = Math.round(resy / 2);

		this.renderTargetBlurBuffer2.setSize(resx, resy);
		this.renderTargetEdgeBuffer2.setSize(resx, resy);

		this.separableBlurMaterial2.uniforms['texSize'].value.set(resx, resy);
	}

	// ... (other functions omitted for brevity)
}

// ... (other classes omitted for brevity)

OutlinePass.BlurDirectionX = new Vector2(1.0, 0.0);
OutlinePass.BlurDirectionY = new Vector2(0.0, 1.0);