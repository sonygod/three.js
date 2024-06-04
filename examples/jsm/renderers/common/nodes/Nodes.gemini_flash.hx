import DataMap from '../DataMap.hx';
import ChainMap from '../ChainMap.hx';
import NodeBuilderState from './NodeBuilderState.hx';
import three from 'three';
import Nodes from '../../../nodes/Nodes.hx';

class Nodes extends DataMap {

	public renderer:Dynamic;
	public backend:Dynamic;
	public nodeFrame:Nodes.NodeFrame;
	public nodeBuilderCache:Map<String, NodeBuilderState>;
	public callHashCache:ChainMap<Array<Dynamic>, { callId:Int, cacheKey:String }>;
	public groupsData:ChainMap<Array<Dynamic>, { version:Int }>;

	public function new(renderer:Dynamic, backend:Dynamic) {
		super();
		this.renderer = renderer;
		this.backend = backend;
		this.nodeFrame = new Nodes.NodeFrame();
		this.nodeBuilderCache = new Map();
		this.callHashCache = new ChainMap();
		this.groupsData = new ChainMap();
	}

	public function updateGroup(nodeUniformsGroup:Dynamic):Bool {
		var groupNode = nodeUniformsGroup.groupNode;
		var name = groupNode.name;

		// objectGroup is every updated

		if (name == Nodes.objectGroup.name) return true;

		// renderGroup is updated once per render/compute call

		if (name == Nodes.renderGroup.name) {
			var uniformsGroupData = this.get(nodeUniformsGroup);
			var renderId = this.nodeFrame.renderId;

			if (uniformsGroupData.renderId != renderId) {
				uniformsGroupData.renderId = renderId;
				return true;
			}

			return false;
		}

		// frameGroup is updated once per frame

		if (name == Nodes.frameGroup.name) {
			var uniformsGroupData = this.get(nodeUniformsGroup);
			var frameId = this.nodeFrame.frameId;

			if (uniformsGroupData.frameId != frameId) {
				uniformsGroupData.frameId = frameId;
				return true;
			}

			return false;
		}

		// other groups are updated just when groupNode.needsUpdate is true

		var groupChain = [groupNode, nodeUniformsGroup];

		var groupData = this.groupsData.get(groupChain);
		if (groupData == null) this.groupsData.set(groupChain, groupData = {});

		if (groupData.version != groupNode.version) {
			groupData.version = groupNode.version;
			return true;
		}

		return false;
	}

	public function getForRenderCacheKey(renderObject:Dynamic):String {
		return renderObject.initialCacheKey;
	}

	public function getForRender(renderObject:Dynamic):NodeBuilderState {
		var renderObjectData = this.get(renderObject);

		var nodeBuilderState = renderObjectData.nodeBuilderState;

		if (nodeBuilderState == null) {
			var nodeBuilderCache = this.nodeBuilderCache;
			var cacheKey = this.getForRenderCacheKey(renderObject);
			nodeBuilderState = nodeBuilderCache.get(cacheKey);

			if (nodeBuilderState == null) {
				var nodeBuilder = this.backend.createNodeBuilder(renderObject.object, this.renderer, renderObject.scene);
				nodeBuilder.material = renderObject.material;
				nodeBuilder.context.material = renderObject.material;
				nodeBuilder.lightsNode = renderObject.lightsNode;
				nodeBuilder.environmentNode = this.getEnvironmentNode(renderObject.scene);
				nodeBuilder.fogNode = this.getFogNode(renderObject.scene);
				nodeBuilder.clippingContext = renderObject.clippingContext;
				nodeBuilder.build();
				nodeBuilderState = this._createNodeBuilderState(nodeBuilder);
				nodeBuilderCache.set(cacheKey, nodeBuilderState);
			}

			nodeBuilderState.usedTimes ++;
			renderObjectData.nodeBuilderState = nodeBuilderState;
		}

		return nodeBuilderState;
	}

	public function delete(object:Dynamic):Bool {
		if (object.isRenderObject) {
			var nodeBuilderState = this.get(object).nodeBuilderState;
			nodeBuilderState.usedTimes --;

			if (nodeBuilderState.usedTimes == 0) {
				this.nodeBuilderCache.delete(this.getForRenderCacheKey(object));
			}
		}

		return super.delete(object);
	}

	public function getForCompute(computeNode:Dynamic):NodeBuilderState {
		var computeData = this.get(computeNode);

		var nodeBuilderState = computeData.nodeBuilderState;

		if (nodeBuilderState == null) {
			var nodeBuilder = this.backend.createNodeBuilder(computeNode, this.renderer);
			nodeBuilder.build();
			nodeBuilderState = this._createNodeBuilderState(nodeBuilder);
			computeData.nodeBuilderState = nodeBuilderState;
		}

		return nodeBuilderState;
	}

	public function _createNodeBuilderState(nodeBuilder:Dynamic):NodeBuilderState {
		return new NodeBuilderState(
			nodeBuilder.vertexShader,
			nodeBuilder.fragmentShader,
			nodeBuilder.computeShader,
			nodeBuilder.getAttributesArray(),
			nodeBuilder.getBindings(),
			nodeBuilder.updateNodes,
			nodeBuilder.updateBeforeNodes,
			nodeBuilder.transforms
		);
	}

	public function getEnvironmentNode(scene:Dynamic):Dynamic {
		return scene.environmentNode || this.get(scene).environmentNode || null;
	}

	public function getBackgroundNode(scene:Dynamic):Dynamic {
		return scene.backgroundNode || this.get(scene).backgroundNode || null;
	}

	public function getFogNode(scene:Dynamic):Dynamic {
		return scene.fogNode || this.get(scene).fogNode || null;
	}

	public function getCacheKey(scene:Dynamic, lightsNode:Dynamic):String {
		var chain = [scene, lightsNode];
		var callId = this.renderer.info.calls;

		var cacheKeyData = this.callHashCache.get(chain);

		if (cacheKeyData == null || cacheKeyData.callId != callId) {
			var environmentNode = this.getEnvironmentNode(scene);
			var fogNode = this.getFogNode(scene);

			var cacheKey = new Array<String>();

			if (lightsNode != null) cacheKey.push(lightsNode.getCacheKey());
			if (environmentNode != null) cacheKey.push(environmentNode.getCacheKey());
			if (fogNode != null) cacheKey.push(fogNode.getCacheKey());

			cacheKeyData = {
				callId: callId,
				cacheKey: cacheKey.join(",")
			};

			this.callHashCache.set(chain, cacheKeyData);
		}

		return cacheKeyData.cacheKey;
	}

	public function updateScene(scene:Dynamic) {
		this.updateEnvironment(scene);
		this.updateFog(scene);
		this.updateBackground(scene);
	}

	public function get isToneMappingState():Bool {
		return this.renderer.getRenderTarget() ? false : true;
	}

	public function updateBackground(scene:Dynamic) {
		var sceneData = this.get(scene);
		var background = scene.background;

		if (background != null) {
			if (sceneData.background != background) {
				var backgroundNode = null;

				if (background.isCubeTexture || (background.mapping == three.EquirectangularReflectionMapping || background.mapping == three.EquirectangularRefractionMapping)) {
					backgroundNode = Nodes.pmremTexture(background, Nodes.normalWorld);
				} else if (background.isTexture) {
					backgroundNode = Nodes.texture(background, Nodes.viewportBottomLeft).setUpdateMatrix(true);
				} else if (!background.isColor) {
					console.error("WebGPUNodes: Unsupported background configuration.", background);
				}

				sceneData.backgroundNode = backgroundNode;
				sceneData.background = background;
			}
		} else if (sceneData.backgroundNode != null) {
			delete sceneData.backgroundNode;
			delete sceneData.background;
		}
	}

	public function updateFog(scene:Dynamic) {
		var sceneData = this.get(scene);
		var fog = scene.fog;

		if (fog != null) {
			if (sceneData.fog != fog) {
				var fogNode = null;

				if (fog.isFogExp2) {
					fogNode = Nodes.densityFog(Nodes.reference("color", "color", fog), Nodes.reference("density", "float", fog));
				} else if (fog.isFog) {
					fogNode = Nodes.rangeFog(Nodes.reference("color", "color", fog), Nodes.reference("near", "float", fog), Nodes.reference("far", "float", fog));
				} else {
					console.error("WebGPUNodes: Unsupported fog configuration.", fog);
				}

				sceneData.fogNode = fogNode;
				sceneData.fog = fog;
			}
		} else {
			delete sceneData.fogNode;
			delete sceneData.fog;
		}
	}

	public function updateEnvironment(scene:Dynamic) {
		var sceneData = this.get(scene);
		var environment = scene.environment;

		if (environment != null) {
			if (sceneData.environment != environment) {
				var environmentNode = null;

				if (environment.isCubeTexture) {
					environmentNode = Nodes.cubeTexture(environment);
				} else if (environment.isTexture) {
					environmentNode = Nodes.texture(environment);
				} else {
					console.error("Nodes: Unsupported environment configuration.", environment);
				}

				sceneData.environmentNode = environmentNode;
				sceneData.environment = environment;
			}
		} else if (sceneData.environmentNode != null) {
			delete sceneData.environmentNode;
			delete sceneData.environment;
		}
	}

	public function getNodeFrame(renderer:Dynamic = this.renderer, scene:Dynamic = null, object:Dynamic = null, camera:Dynamic = null, material:Dynamic = null):Nodes.NodeFrame {
		var nodeFrame = this.nodeFrame;
		nodeFrame.renderer = renderer;
		nodeFrame.scene = scene;
		nodeFrame.object = object;
		nodeFrame.camera = camera;
		nodeFrame.material = material;

		return nodeFrame;
	}

	public function getNodeFrameForRender(renderObject:Dynamic):Nodes.NodeFrame {
		return this.getNodeFrame(renderObject.renderer, renderObject.scene, renderObject.object, renderObject.camera, renderObject.material);
	}

	public function getOutputNode(outputTexture:Dynamic):Dynamic {
		var output = Nodes.texture(outputTexture, Nodes.viewportTopLeft);

		if (this.isToneMappingState) {
			if (this.renderer.toneMappingNode != null) {
				output = Nodes.vec4(this.renderer.toneMappingNode.context({color: output.rgb}), output.a);
			} else if (this.renderer.toneMapping != three.NoToneMapping) {
				output = output.toneMapping(this.renderer.toneMapping);
			}
		}

		if (this.renderer.currentColorSpace == three.SRGBColorSpace) {
			output = output.linearToColorSpace(this.renderer.currentColorSpace);
		}

		return output;
	}

	public function updateBefore(renderObject:Dynamic) {
		var nodeFrame = this.getNodeFrameForRender(renderObject);
		var nodeBuilder = renderObject.getNodeBuilderState();

		for (node in nodeBuilder.updateBeforeNodes) {
			nodeFrame.updateBeforeNode(node);
		}
	}

	public function updateForCompute(computeNode:Dynamic) {
		var nodeFrame = this.getNodeFrame();
		var nodeBuilder = this.getForCompute(computeNode);

		for (node in nodeBuilder.updateNodes) {
			nodeFrame.updateNode(node);
		}
	}

	public function updateForRender(renderObject:Dynamic) {
		var nodeFrame = this.getNodeFrameForRender(renderObject);
		var nodeBuilder = renderObject.getNodeBuilderState();

		for (node in nodeBuilder.updateNodes) {
			nodeFrame.updateNode(node);
		}
	}

	public function dispose() {
		super.dispose();
		this.nodeFrame = new Nodes.NodeFrame();
		this.nodeBuilderCache = new Map();
	}

}

export default Nodes;