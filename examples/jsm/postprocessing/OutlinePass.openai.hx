package three.js.examples.jsm.postprocessing;

import three.js.Lib;
import three.js.math.Matrix4;
import three.js.math.Vector2;
import three.js.math.Vector3;
import three.js.renderers.WebGLRenderTarget;

class OutlinePass {
    public var renderScene:Scene;
    public var renderCamera:Camera;
    public var selectedObjects:Array<Mesh>;
    public var visibleEdgeColor:Color;
    public var hiddenEdgeColor:Color;
    public var edgeGlow:Float;
    public var usePatternTexture:Bool;
    public var edgeThickness:Float;
    public var edgeStrength:Float;
    public var downSampleRatio:Float;
    public var pulsePeriod:Float;

    public var _visibilityCache:Map<Mesh, Bool>;

    public var resolution:Vector2;

    public var renderTargetMaskBuffer:WebGLRenderTarget;
    public var renderTargetDepthBuffer:WebGLRenderTarget;
    public var renderTargetMaskDownSampleBuffer:WebGLRenderTarget;
    public var renderTargetBlurBuffer1:WebGLRenderTarget;
    public var renderTargetBlurBuffer2:WebGLRenderTarget;
    public var renderTargetEdgeBuffer1:WebGLRenderTarget;
    public var renderTargetEdgeBuffer2:WebGLRenderTarget;

    public var depthMaterial:MeshDepthMaterial;
    public var prepareMaskMaterial:ShaderMaterial;
    public var edgeDetectionMaterial:ShaderMaterial;
    public var separableBlurMaterial1:ShaderMaterial;
    public var separableBlurMaterial2:ShaderMaterial;
    public var overlayMaterial:ShaderMaterial;
    public var materialCopy:ShaderMaterial;

    public var fsQuad:FullScreenQuad;

    public var tempPulseColor1:Color;
    public var tempPulseColor2:Color;
    public var textureMatrix:Matrix4;

    public function new(resolution:Vector2, scene:Scene, camera:Camera, selectedObjects:Array<Mesh>) {
        this.renderScene = scene;
        this.renderCamera = camera;
        this.selectedObjects = selectedObjects;
        this.visibleEdgeColor = new Color(1, 1, 1);
        this.hiddenEdgeColor = new Color(0.1, 0.04, 0.02);
        this.edgeGlow = 0.0;
        this.usePatternTexture = false;
        this.edgeThickness = 1.0;
        this.edgeStrength = 3.0;
        this.downSampleRatio = 2.0;
        this.pulsePeriod = 0;

        this._visibilityCache = new Map<Mesh, Bool>();

        this.resolution = resolution;

        this.renderTargetMaskBuffer = new WebGLRenderTarget(resolution.x, resolution.y);
        this.renderTargetMaskBuffer.texture.name = 'OutlinePass.mask';
        this.renderTargetMaskBuffer.texture.generateMipmaps = false;

        this.depthMaterial = new MeshDepthMaterial();
        this.depthMaterial.side = DoubleSide;
        this.depthMaterial.depthPacking = RGBADepthPacking;
        this.depthMaterial.blending = NoBlending;

        this.prepareMaskMaterial = getPrepareMaskMaterial();
        this.prepareMaskMaterial.side = DoubleSide;

        // ...
    }

    // ...
}