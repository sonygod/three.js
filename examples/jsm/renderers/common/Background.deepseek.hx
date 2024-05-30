import DataMap from './DataMap.hx';
import Color4 from './Color4.hx';
import { Mesh, SphereGeometry, BackSide, LinearSRGBColorSpace } from 'three';
import { vec4, context, normalWorld, backgroundBlurriness, backgroundIntensity, NodeMaterial, modelViewProjection } from '../../nodes/Nodes.hx';

class Background extends DataMap {

	var _clearColor:Color4;

	public function new(renderer:Dynamic, nodes:Dynamic) {
		super();
		this.renderer = renderer;
		this.nodes = nodes;
		this._clearColor = new Color4();
	}

	public function update(scene:Dynamic, renderList:Dynamic, renderContext:Dynamic):Void {
		var renderer = this.renderer;
		var background = this.nodes.getBackgroundNode(scene) || scene.background;
		var forceClear = false;

		if (background == null) {
			renderer._clearColor.getRGB(this._clearColor, LinearSRGBColorSpace);
			this._clearColor.a = renderer._clearColor.a;
		} else if (background.isColor == true) {
			background.getRGB(this._clearColor, LinearSRGBColorSpace);
			this._clearColor.a = 1;
			forceClear = true;
		} else if (background.isNode == true) {
			var sceneData = this.get(scene);
			var backgroundNode = background;
			this._clearColor.copy(renderer._clearColor);
			var backgroundMesh = sceneData.backgroundMesh;

			if (backgroundMesh == undefined) {
				var backgroundMeshNode = context(vec4(backgroundNode).mul(backgroundIntensity), {
					getUV: () -> normalWorld,
					getTextureLevel: () -> backgroundBlurriness
				});
				var viewProj = modelViewProjection();
				viewProj = viewProj.setZ(viewProj.w);
				var nodeMaterial = new NodeMaterial();
				nodeMaterial.side = BackSide;
				nodeMaterial.depthTest = false;
				nodeMaterial.depthWrite = false;
				nodeMaterial.fog = false;
				nodeMaterial.vertexNode = viewProj;
				nodeMaterial.fragmentNode = backgroundMeshNode;
				sceneData.backgroundMeshNode = backgroundMeshNode;
				sceneData.backgroundMesh = backgroundMesh = new Mesh(new SphereGeometry(1, 32, 32), nodeMaterial);
				backgroundMesh.frustumCulled = false;
				backgroundMesh.onBeforeRender = function (renderer, scene, camera) {
					this.matrixWorld.copyPosition(camera.matrixWorld);
				};
			}

			var backgroundCacheKey = backgroundNode.getCacheKey();

			if (sceneData.backgroundCacheKey != backgroundCacheKey) {
				sceneData.backgroundMeshNode.node = vec4(backgroundNode).mul(backgroundIntensity);
				backgroundMesh.material.needsUpdate = true;
				sceneData.backgroundCacheKey = backgroundCacheKey;
			}

			renderList.unshift(backgroundMesh, backgroundMesh.geometry, backgroundMesh.material, 0, 0, null);
		} else {
			trace('THREE.Renderer: Unsupported background configuration.', background);
		}

		if (renderer.autoClear == true || forceClear == true) {
			this._clearColor.multiplyScalar(this._clearColor.a);
			var clearColorValue = renderContext.clearColorValue;
			clearColorValue.r = this._clearColor.r;
			clearColorValue.g = this._clearColor.g;
			clearColorValue.b = this._clearColor.b;
			clearColorValue.a = this._clearColor.a;
			renderContext.depthClearValue = renderer._clearDepth;
			renderContext.stencilClearValue = renderer._clearStencil;
			renderContext.clearColor = renderer.autoClearColor == true;
			renderContext.clearDepth = renderer.autoClearDepth == true;
			renderContext.clearStencil = renderer.autoClearStencil == true;
		} else {
			renderContext.clearColor = false;
			renderContext.clearDepth = false;
			renderContext.clearStencil = false;
		}
	}
}