import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Vector3;
import three.math.Vector4;
import three.webgl.WebGLAnimation;
import three.webgl.WebGLAttributes;
import three.webgl.WebGLBackground;
import three.webgl.WebGLBindingStates;
import three.webgl.WebGLBufferRenderer;
import three.webgl.WebGLCapabilities;
import three.webgl.WebGLClipping;
import three.webgl.WebGLCubeMaps;
import three.webgl.WebGLCubeUVMaps;
import three.webgl.WebGLExtensions;
import three.webgl.WebGLGeometries;
import three.webgl.WebGLIndexedBufferRenderer;
import three.webgl.WebGLInfo;
import three.webgl.WebGLMorphtargets;
import three.webgl.WebGLObjects;
import three.webgl.WebGLPrograms;
import three.webgl.WebGLProperties;
import three.webgl.WebGLRenderLists;
import three.webgl.WebGLRenderStates;
import three.webgl.WebGLRenderTarget;
import three.webgl.WebGLShadowMap;
import three.webgl.WebGLState;
import three.webgl.WebGLTextures;
import three.webgl.WebGLUniforms;
import three.webgl.WebGLUtils;
import three.webgl.WebXRManager;
import three.webgl.WebGLMaterials;
import three.webgl.WebGLUniformsGroups;
import three.utils.createCanvasElement;
import three.math.ColorManagement;

class WebGLRenderer {

	public var isWebGLRenderer:Bool;

	public function new(parameters:Dynamic = null) {
		var _alpha:Bool;
		var uintClearColor:Int32 = [0,0,0,0];
		var intClearColor:Int32 = [0,0,0,0];

		var currentRenderList:WebGLRenderList;
		var currentRenderState:WebGLRenderState;

		var renderListStack:Array<WebGLRenderList>;
		var renderStateStack:Array<WebGLRenderState>;

		this.isWebGLRenderer = true;

		if (parameters != null && parameters.context != null) {
			if (typeof WebGLRenderingContext !== "undefined" && parameters.context instanceof WebGLRenderingContext) {
				throw new Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");
			}

			_alpha = parameters.context.getContextAttributes().alpha;
		} else {
			_alpha = parameters.alpha;
		}

		// ... rest of the constructor code ...

	}

	// ... rest of the class code ...

}