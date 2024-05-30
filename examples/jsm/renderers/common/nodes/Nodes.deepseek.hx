import DataMap from '../DataMap.js';
import ChainMap from '../ChainMap.js';
import NodeBuilderState from './NodeBuilderState.js';
import { EquirectangularReflectionMapping, EquirectangularRefractionMapping, NoToneMapping, SRGBColorSpace } from 'three';
import { NodeFrame, vec4, objectGroup, renderGroup, frameGroup, cubeTexture, texture, rangeFog, densityFog, reference, viewportBottomLeft, normalWorld, pmremTexture, viewportTopLeft } from '../../../nodes/Nodes.js';

class Nodes extends DataMap {

	var renderer:Dynamic;
	var backend:Dynamic;
	var nodeFrame:NodeFrame;
	var nodeBuilderCache:Map<String, NodeBuilderState>;
	var callHashCache:ChainMap;
	var groupsData:ChainMap;

	public function new(renderer:Dynamic, backend:Dynamic) {
		super();
		this.renderer = renderer;
		this.backend = backend;
		this.nodeFrame = new NodeFrame();
		this.nodeBuilderCache = new Map();
		this.callHashCache = new ChainMap();
		this.groupsData = new ChainMap();
	}

	public function updateGroup(nodeUniformsGroup:Dynamic):Bool {
		var groupNode = nodeUniformsGroup.groupNode;
		var name = groupNode.name;
		if (name == objectGroup.name) return true;
		if (name == renderGroup.name) {
			var uniformsGroupData = this.get(nodeUniformsGroup);
			var renderId = this.nodeFrame.renderId;
			if (uniformsGroupData.renderId != renderId) {
				uniformsGroupData.renderId = renderId;
				return true;
			}
			return false;
		}
		if (name == frameGroup.name) {
			var uniformsGroupData = this.get(nodeUniformsGroup);
			var frameId = this.nodeFrame.frameId;
			if (uniformsGroupData.frameId != frameId) {
				uniformsGroupData.frameId = frameId;
				return true;
			}
			return false;
		}
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
			var nodeBuilder = this.backend.createNodeBuilder(renderObject.object, this.renderer, renderObject.scene);
			nodeBuilder.material = renderObject.material;
			nodeBuilder.context.material = renderObject.material;
			nodeBuilder.lightsNode = renderObject.lightsNode;
			nodeBuilder.environmentNode = this.getEnvironmentNode(renderObject.scene);
			nodeBuilder.fogNode = this.getFogNode(renderObject.scene);
			nodeBuilder.clippingContext = renderObject.clippingContext;
			nodeBuilder.build();
			nodeBuilderState = this._createNodeBuilderState(nodeBuilder);
			this.nodeBuilderCache.set(this.getForRenderCacheKey(renderObject), nodeBuilderState);
		}
		nodeBuilderState.usedTimes++;
		renderObjectData.nodeBuilderState = nodeBuilderState;
		return nodeBuilderState;
	}

	public function delete(object:Dynamic):Bool {
		if (object.isRenderObject) {
			var nodeBuilderState = this.get(object).nodeBuilderState;
			nodeBuilderState.usedTimes--;
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

	private function _createNodeBuilderState(nodeBuilder:Dynamic):NodeBuilderState {
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
			var cacheKey = [];
			if (lightsNode) cacheKey.push(lightsNode.getCacheKey());
			if (environmentNode) cacheKey.push(environmentNode.getCacheKey());
			if (fogNode) cacheKey.push(fogNode.getCacheKey());
			cacheKeyData = {
				callId: callId,
				cacheKey: cacheKey.join(',')
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
		if (background) {
			if (sceneData.background != background) {
				var backgroundNode = null;
				if (background.isCubeTexture == true || (background.mapping == EquirectangularReflectionMapping || background.mapping == EquirectangularRefractionMapping)) {
					backgroundNode = pmremTexture(background, normalWorld);
				} else if (background.isTexture == true) {
					backgroundNode = texture(background, viewportBottomLeft).setUpdateMatrix(true);
				} else if (background.isColor != true) {
					trace('WebGPUNodes: Unsupported background configuration.', background);
				}
				sceneData.backgroundNode = backgroundNode;
				sceneData.background = background;
			}
		} else if (sceneData.backgroundNode) {
			delete sceneData.backgroundNode;
			delete sceneData.background;
		}
	}

	public function updateFog(scene:Dynamic) {
		var sceneData = this.get(scene);
		var fog = scene.fog;
		if (fog) {
			if (sceneData.fog != fog) {
				var fogNode = null;
				if (fog.isFogExp2) {
					fogNode = densityFog(reference('color', 'color', fog), reference('density', 'float', fog));
				} else if (fog.isFog) {
					fogNode = rangeFog(reference('color', 'color', fog), reference('near', 'float', fog), reference('far', 'float', fog));
				} else {
					trace('WebGPUNodes: Unsupported fog configuration.', fog);
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
		if (environment) {
			if (sceneData.environment != environment) {
				var environmentNode = null;
				if (environment.isCubeTexture == true) {
					environmentNode = cubeTexture(environment);
				} else if (environment.isTexture == true) {
					environmentNode = texture(environment);
				} else {
					trace('Nodes: Unsupported environment configuration.', environment);
				}
				sceneData.environmentNode = environmentNode;
				sceneData.environment = environment;
			}
		} else if (sceneData.environmentNode) {
			delete sceneData.environmentNode;
			delete sceneData.environment;
		}
	}

	public function getNodeFrame(renderer:Dynamic = this.renderer, scene:Dynamic = null, object:Dynamic = null, camera:Dynamic = null, material:Dynamic = null):NodeFrame {
		var nodeFrame = this.nodeFrame;
		nodeFrame.renderer = renderer;
		nodeFrame.scene = scene;
		nodeFrame.object = object;
		nodeFrame.camera = camera;
		nodeFrame.material = material;
		return nodeFrame;
	}

	public function getNodeFrameForRender(renderObject:Dynamic):NodeFrame {
		return this.getNodeFrame(renderObject.renderer, renderObject.scene, renderObject.object, renderObject.camera, renderObject.material);
	}

	public function getOutputNode(outputTexture:Dynamic):Dynamic {
		var output = texture(outputTexture, viewportTopLeft);
		if (this.isToneMappingState) {
			if (this.renderer.toneMappingNode) {
				output = vec4(this.renderer.toneMappingNode.context({color: output.rgb}), output.a);
			} else if (this.renderer.toneMapping != NoToneMapping) {
				output = output.toneMapping(this.renderer.toneMapping);
			}
		}
		if (this.renderer.currentColorSpace == SRGBColorSpace) {
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
		this.nodeFrame = new NodeFrame();
		this.nodeBuilderCache = new Map();
	}

}