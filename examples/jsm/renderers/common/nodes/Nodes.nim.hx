import DataMap.DataMap;
import ChainMap.ChainMap;
import NodeBuilderState.NodeBuilderState;
import EquirectangularReflectionMapping.EquirectangularReflectionMapping;
import EquirectangularRefractionMapping.EquirectangularRefractionMapping;
import NoToneMapping.NoToneMapping;
import SRGBColorSpace.SRGBColorSpace;
import NodeFrame.NodeFrame;
import Vec4.Vec4;
import ObjectGroup.ObjectGroup;
import RenderGroup.RenderGroup;
import FrameGroup.FrameGroup;
import CubeTexture.CubeTexture;
import Texture.Texture;
import RangeFog.RangeFog;
import DensityFog.DensityFog;
import Reference.Reference;
import ViewportBottomLeft.ViewportBottomLeft;
import NormalWorld.NormalWorld;
import PmremTexture.PmremTexture;
import ViewportTopLeft.ViewportTopLeft;
import Nodes.Nodes;

class Nodes extends DataMap {

	public var renderer:Renderer;
	public var backend:Backend;
	public var nodeFrame:NodeFrame;
	public var nodeBuilderCache:Map<Dynamic, Dynamic>;
	public var callHashCache:ChainMap;
	public var groupsData:ChainMap;

	public function new(renderer:Renderer, backend:Backend) {

		super();

		this.renderer = renderer;
		this.backend = backend;
		this.nodeFrame = new NodeFrame();
		this.nodeBuilderCache = new Map<Dynamic, Dynamic>();
		this.callHashCache = new ChainMap();
		this.groupsData = new ChainMap();

	}

	public function updateGroup(nodeUniformsGroup:NodeUniformsGroup):Bool {

		var groupNode:Node = nodeUniformsGroup.groupNode;
		var name:String = groupNode.name;

		// objectGroup is every updated

		if (name == ObjectGroup.name) return true;

		// renderGroup is updated once per render/compute call

		if (name == RenderGroup.name) {

			var uniformsGroupData:UniformsGroupData = this.get(nodeUniformsGroup);
			var renderId:Int = this.nodeFrame.renderId;

			if (uniformsGroupData.renderId != renderId) {

				uniformsGroupData.renderId = renderId;

				return true;

			}

			return false;

		}

		// frameGroup is updated once per frame

		if (name == FrameGroup.name) {

			var uniformsGroupData:UniformsGroupData = this.get(nodeUniformsGroup);
			var frameId:Int = this.nodeFrame.frameId;

			if (uniformsGroupData.frameId != frameId) {

				uniformsGroupData.frameId = frameId;

				return true;

			}

			return false;

		}

		// other groups are updated just when groupNode.needsUpdate is true

		var groupChain:Array<Dynamic> = [groupNode, nodeUniformsGroup];

		var groupData:Dynamic = this.groupsData.get(groupChain);
		if (groupData == null) this.groupsData.set(groupChain, groupData = {});

		if (groupData.version != groupNode.version) {

			groupData.version = groupNode.version;

			return true;

		}

		return false;

	}

	public function getForRenderCacheKey(renderObject:RenderObject):Dynamic {

		return renderObject.initialCacheKey;

	}

	public function getForRender(renderObject:RenderObject):NodeBuilderState {

		var renderObjectData:RenderObjectData = this.get(renderObject);

		var nodeBuilderState:NodeBuilderState = renderObjectData.nodeBuilderState;

		if (nodeBuilderState == null) {

			var nodeBuilderCache:Map<Dynamic, Dynamic> = this.nodeBuilderCache;

			var cacheKey:Dynamic = this.getForRenderCacheKey(renderObject);

			nodeBuilderState = nodeBuilderCache.get(cacheKey);

			if (nodeBuilderState == null) {

				var nodeBuilder:NodeBuilder = this.backend.createNodeBuilder(renderObject.object, this.renderer, renderObject.scene);
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

			nodeBuilderState.usedTimes++;

			renderObjectData.nodeBuilderState = nodeBuilderState;

		}

		return nodeBuilderState;

	}

	public function delete(object:Dynamic):Bool {

		if (Std.is(object, RenderObject)) {

			var nodeBuilderState:NodeBuilderState = this.get(object).nodeBuilderState;
			nodeBuilderState.usedTimes--;

			if (nodeBuilderState.usedTimes == 0) {

				this.nodeBuilderCache.delete(this.getForRenderCacheKey(object));

			}

		}

		return super.delete(object);

	}

	public function getForCompute(computeNode:ComputeNode):NodeBuilderState {

		var computeData:ComputeData = this.get(computeNode);

		var nodeBuilderState:NodeBuilderState = computeData.nodeBuilderState;

		if (nodeBuilderState == null) {

			var nodeBuilder:NodeBuilder = this.backend.createNodeBuilder(computeNode, this.renderer);
			nodeBuilder.build();

			nodeBuilderState = this._createNodeBuilderState(nodeBuilder);

			computeData.nodeBuilderState = nodeBuilderState;

		}

		return nodeBuilderState;

	}

	public function _createNodeBuilderState(nodeBuilder:NodeBuilder):NodeBuilderState {

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

	public function getEnvironmentNode(scene:Scene):Dynamic {

		return scene.environmentNode || this.get(scene).environmentNode || null;

	}

	public function getBackgroundNode(scene:Scene):Dynamic {

		return scene.backgroundNode || this.get(scene).backgroundNode || null;

	}

	public function getFogNode(scene:Scene):Dynamic {

		return scene.fogNode || this.get(scene).fogNode || null;

	}

	public function getCacheKey(scene:Scene, lightsNode:LightsNode):String {

		var chain:Array<Dynamic> = [scene, lightsNode];
		var callId:Int = this.renderer.info.calls;

		var cacheKeyData:Dynamic = this.callHashCache.get(chain);

		if (cacheKeyData == null || cacheKeyData.callId != callId) {

			var environmentNode:Dynamic = this.getEnvironmentNode(scene);
			var fogNode:Dynamic = this.getFogNode(scene);

			var cacheKey:Array<String> = [];

			if (lightsNode != null) cacheKey.push(lightsNode.getCacheKey());
			if (environmentNode != null) cacheKey.push(environmentNode.getCacheKey());
			if (fogNode != null) cacheKey.push(fogNode.getCacheKey());

			cacheKeyData = {
				callId,
				cacheKey: cacheKey.join(',')
			};

			this.callHashCache.set(chain, cacheKeyData);

		}

		return cacheKeyData.cacheKey;

	}

	public function updateScene(scene:Scene) {

		this.updateEnvironment(scene);
		this.updateFog(scene);
		this.updateBackground(scene);

	}

	public function get isToneMappingState():Bool {

		return this.renderer.getRenderTarget() ? false : true;

	}

	public function updateBackground(scene:Scene) {

		var sceneData:SceneData = this.get(scene);
		var background:Background = scene.background;

		if (background != null) {

			if (sceneData.background != background) {

				var backgroundNode:Dynamic = null;

				if (background.isCubeTexture == true || (background.mapping == EquirectangularReflectionMapping || background.mapping == EquirectangularRefractionMapping)) {

					backgroundNode = PmremTexture(background, NormalWorld);

				} else if (background.isTexture == true) {

					backgroundNode = Texture(background, ViewportBottomLeft).setUpdateMatrix(true);

				} else if (background.isColor != true) {

					trace('WebGPUNodes: Unsupported background configuration.', background);

				}

				sceneData.backgroundNode = backgroundNode;
				sceneData.background = background;

			}

		} else if (sceneData.backgroundNode != null) {

			delete sceneData.backgroundNode;
			delete sceneData.background;

		}

	}

	public function updateFog(scene:Scene) {

		var sceneData:SceneData = this.get(scene);
		var fog:Fog = scene.fog;

		if (fog != null) {

			if (sceneData.fog != fog) {

				var fogNode:Dynamic = null;

				if (fog.isFogExp2) {

					fogNode = DensityFog(Reference('color', 'color', fog), Reference('density', 'float', fog));

				} else if (fog.isFog) {

					fogNode = RangeFog(Reference('color', 'color', fog), Reference('near', 'float', fog), Reference('far', 'float', fog));

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

	public function updateEnvironment(scene:Scene) {

		var sceneData:SceneData = this.get(scene);
		var environment:Environment = scene.environment;

		if (environment != null) {

			if (sceneData.environment != environment) {

				var environmentNode:Dynamic = null;

				if (environment.isCubeTexture == true) {

					environmentNode = CubeTexture(environment);

				} else if (environment.isTexture == true) {

					environmentNode = Texture(environment);

				} else {

					trace('Nodes: Unsupported environment configuration.', environment);

				}

				sceneData.environmentNode = environmentNode;
				sceneData.environment = environment;

			}

		} else if (sceneData.environmentNode != null) {

			delete sceneData.environmentNode;
			delete sceneData.environment;

		}

	}

	public function getNodeFrame(renderer:Renderer = this.renderer, scene:Scene = null, object:Object3D = null, camera:Camera = null, material:Material = null):NodeFrame {

		var nodeFrame:NodeFrame = this.nodeFrame;
		nodeFrame.renderer = renderer;
		nodeFrame.scene = scene;
		nodeFrame.object = object;
		nodeFrame.camera = camera;
		nodeFrame.material = material;

		return nodeFrame;

	}

	public function getNodeFrameForRender(renderObject:RenderObject):NodeFrame {

		return this.getNodeFrame(renderObject.renderer, renderObject.scene, renderObject.object, renderObject.camera, renderObject.material);

	}

	public function getOutputNode(outputTexture:Texture):Vec4 {

		var output:Vec4 = Texture(outputTexture, ViewportTopLeft);

		if (this.isToneMappingState) {

			if (this.renderer.toneMappingNode != null) {

				output = Vec4(this.renderer.toneMappingNode.context({color: output.rgb}), output.a);

			} else if (this.renderer.toneMapping != NoToneMapping) {

				output = output.toneMapping(this.renderer.toneMapping);

			}

		}

		if (this.renderer.currentColorSpace == SRGBColorSpace) {

			output = output.linearToColorSpace(this.renderer.currentColorSpace);

		}

		return output;

	}

	public function updateBefore(renderObject:RenderObject) {

		var nodeFrame:NodeFrame = this.getNodeFrameForRender(renderObject);
		var nodeBuilder:NodeBuilderState = renderObject.getNodeBuilderState();

		for (node in nodeBuilder.updateBeforeNodes) {

			nodeFrame.updateBeforeNode(node);

		}

	}

	public function updateForCompute(computeNode:ComputeNode) {

		var nodeFrame:NodeFrame = this.getNodeFrame();
		var nodeBuilder:NodeBuilderState = this.getForCompute(computeNode);

		for (node in nodeBuilder.updateNodes) {

			nodeFrame.updateNode(node);

		}

	}

	public function updateForRender(renderObject:RenderObject) {

		var nodeFrame:NodeFrame = this.getNodeFrameForRender(renderObject);
		var nodeBuilder:NodeBuilderState = renderObject.getNodeBuilderState();

		for (node in nodeBuilder.updateNodes) {

			nodeFrame.updateNode(node);

		}

	}

	public function dispose() {

		super.dispose();

		this.nodeFrame = new NodeFrame();
		this.nodeBuilderCache = new Map<Dynamic, Dynamic>();

	}

}