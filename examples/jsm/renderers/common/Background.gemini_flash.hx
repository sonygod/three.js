import DataMap from "./DataMap.hx";
import Color4 from "./Color4.hx";
import three.Mesh;
import three.SphereGeometry;
import three.BackSide;
import three.LinearSRGBColorSpace;
import three.Material;
import three.Renderer;
import three.Scene;
import three.Camera;
import three.Vector3;
import Nodes from "../../nodes/Nodes.hx";

class Background extends DataMap {
	var renderer:Renderer;
	var nodes:Nodes;

	public function new(renderer:Renderer, nodes:Nodes) {
		super();
		this.renderer = renderer;
		this.nodes = nodes;
	}

	public function update(scene:Scene, renderList:Array<Dynamic>, renderContext:Dynamic):Void {
		var renderer = this.renderer;
		var background = this.nodes.getBackgroundNode(scene) || scene.background;

		var forceClear = false;

		if (background == null) {
			renderer._clearColor.getRGB(_clearColor, LinearSRGBColorSpace);
			_clearColor.a = renderer._clearColor.a;
		} else if (cast background.isColor) {
			background.getRGB(_clearColor, LinearSRGBColorSpace);
			_clearColor.a = 1;

			forceClear = true;
		} else if (cast background.isNode) {
			var sceneData = this.get(scene);
			var backgroundNode = background;

			_clearColor.copy(renderer._clearColor);

			var backgroundMesh = sceneData.backgroundMesh;

			if (backgroundMesh == null) {
				var backgroundMeshNode = Nodes.context(Nodes.vec4(backgroundNode).mul(Nodes.backgroundIntensity), {
					getUV: function() return Nodes.normalWorld;
					getTextureLevel: function() return Nodes.backgroundBlurriness;
				});

				var viewProj = Nodes.modelViewProjection();
				viewProj = viewProj.setZ(viewProj.w);

				var nodeMaterial = new three.MeshBasicMaterial();
				nodeMaterial.side = BackSide;
				nodeMaterial.depthTest = false;
				nodeMaterial.depthWrite = false;
				nodeMaterial.fog = false;
				nodeMaterial.vertexNode = viewProj;
				nodeMaterial.fragmentNode = backgroundMeshNode;

				sceneData.backgroundMeshNode = backgroundMeshNode;
				sceneData.backgroundMesh = backgroundMesh = new Mesh(new SphereGeometry(1, 32, 32), nodeMaterial);
				backgroundMesh.frustumCulled = false;

				backgroundMesh.onBeforeRender = function(renderer:Renderer, scene:Scene, camera:Camera) {
					this.matrixWorld.copyPosition(camera.matrixWorld);
				};
			}

			var backgroundCacheKey = backgroundNode.getCacheKey();

			if (sceneData.backgroundCacheKey != backgroundCacheKey) {
				sceneData.backgroundMeshNode.node = Nodes.vec4(backgroundNode).mul(Nodes.backgroundIntensity);

				backgroundMesh.material.needsUpdate = true;

				sceneData.backgroundCacheKey = backgroundCacheKey;
			}

			renderList.unshift(backgroundMesh, backgroundMesh.geometry, backgroundMesh.material, 0, 0, null);
		} else {
			console.error('THREE.Renderer: Unsupported background configuration.', background);
		}

		if (renderer.autoClear || forceClear) {
			_clearColor.multiplyScalar(_clearColor.a);

			var clearColorValue = renderContext.clearColorValue;

			clearColorValue.r = _clearColor.r;
			clearColorValue.g = _clearColor.g;
			clearColorValue.b = _clearColor.b;
			clearColorValue.a = _clearColor.a;

			renderContext.depthClearValue = renderer._clearDepth;
			renderContext.stencilClearValue = renderer._clearStencil;

			renderContext.clearColor = renderer.autoClearColor;
			renderContext.clearDepth = renderer.autoClearDepth;
			renderContext.clearStencil = renderer.autoClearStencil;
		} else {
			renderContext.clearColor = false;
			renderContext.clearDepth = false;
			renderContext.clearStencil = false;
		}
	}
}

var _clearColor = new Color4();

export default Background;