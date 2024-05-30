import DataMap from '../DataMap';
import ChainMap from '../ChainMap';
import NodeBuilderState from './NodeBuilderState';
import { EquirectangularReflectionMapping, EquirectangularRefractionMapping, NoToneMapping, SRGBColorSpace } from 'three';
import { NodeFrame, Vec4, ObjectGroup, RenderGroup, FrameGroup, CubeTexture, Texture, RangeFog, DensityFog, Reference, ViewportBottomLeft, NormalWorld, PmremTexture, ViewportTopLeft } from '../../../nodes/Nodes';

class Nodes extends DataMap {
    public var renderer:Dynamic;
    public var backend:Dynamic;
    public var nodeFrame:NodeFrame;
    public var nodeBuilderCache:Map;
    public var callHashCache:ChainMap;
    public var groupsData:ChainMap;

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

        if (name == ObjectGroup.name) {
            return true;
        }

        if (name == RenderGroup.name) {
            var uniformsGroupData = this.get(nodeUniformsGroup);
            var renderId = nodeFrame.renderId;

            if (uniformsGroupData.renderId != renderId) {
                uniformsGroupData.renderId = renderId;
                return true;
            }

            return false;
        }

        if (name == FrameGroup.name) {
            var uniformsGroupData = this.get(nodeUniformsGroup);
            var frameId = nodeFrame.frameId;

            if (uniformsGroupData.frameId != frameId) {
                uniformsGroupData.frameId = frameId;
                return true;
            }

            return false;
        }

        var groupChain = [groupNode, nodeUniformsGroup];
        var groupData = groupsData.get(groupChain);

        if (groupData == null) {
            groupsData.set(groupChain, {});
            groupData = groupsData.get(groupChain);
        }

        if (groupData.version != groupNode.version) {
            groupData.version = groupNode.version;
            return true;
        }

        return false;
    }

    public function getForRenderCacheKey(renderObject:Dynamic):Dynamic {
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
                var nodeBuilder = backend.createNodeBuilder(renderObject.object, renderer, renderObject.scene);
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

    public function delete(object:Dynamic):Void {
        if (object.isRenderObject) {
            var nodeBuilderState = this.get(object).nodeBuilderState;
            nodeBuilderState.usedTimes--;

            if (nodeBuilderState.usedTimes == 0) {
                nodeBuilderCache.delete(this.getForRenderCacheKey(object));
            }
        }

        super.delete(object);
    }

    public function getForCompute(computeNode:Dynamic):NodeBuilderState {
        var computeData = this.get(computeNode);
        var nodeBuilderState = computeData.nodeBuilderState;

        if (nodeBuilderState == null) {
            var nodeBuilder = backend.createNodeBuilder(computeNode, renderer);
            nodeBuilder.build();

            nodeBuilderState = this._createNodeBuilderState(nodeBuilder);
            computeData.nodeBuilderState = nodeBuilderState;
        }

        return nodeBuilderState;
    }

    public function _createNodeBuilderState(nodeBuilder:Dynamic):NodeBuilderState {
        return new NodeBuilderState(nodeBuilder.vertexShader, nodeBuilder.fragmentShader, nodeBuilder.computeShader, nodeBuilder.getAttributesArray(), nodeBuilder.getBindings(), nodeBuilder.updateNodes, nodeBuilder.updateBeforeNodes, nodeBuilder.transforms);
    }

    public function getEnvironmentNode(scene:Dynamic):Dynamic {
        return scene.environmentNode != null ? scene.environmentNode : this.get(scene).environmentNode;
    }

    public function getBackgroundNode(scene:Dynamic):Dynamic {
        return scene.backgroundNode != null ? scene.backgroundNode : this.get(scene).backgroundNode;
    }

    public function getFogNode(scene:Dynamic):Dynamic {
        return scene.fogNode != null ? scene.fogNode : this.get(scene).fogNode;
    }

    public function getCacheKey(scene:Dynamic, lightsNode:Dynamic):Dynamic {
        var chain = [scene, lightsNode];
        var callId = renderer.info.calls;

        var cacheKeyData = callHashCache.get(chain);

        if (cacheKeyData == null || cacheKeyData.callId != callId) {
            var environmentNode = this.getEnvironmentNode(scene);
            var fogNode = this.getFogNode(scene);

            var cacheKey = [];

            if (lightsNode != null) {
                cacheKey.push(lightsNode.getCacheKey());
            }

            if (environmentNode != null) {
                cacheKey.push(environmentNode.getCacheKey());
            }

            if (fogNode != null) {
                cacheKey.push(fogNode.getCacheKey());
            }

            cacheKeyData = { callId: callId, cacheKey: cacheKey.join(',') };
            callHashCache.set(chain, cacheKeyData);
        }

        return cacheKeyData.cacheKey;
    }

    public function updateScene(scene:Dynamic):Void {
        this.updateEnvironment(scene);
        this.updateFog(scene);
        this.updateBackground(scene);
    }

    public function get isToneMappingState():Bool {
        return renderer.getRenderTarget() == false;
    }

    public function updateBackground(scene:Dynamic):Void {
        var sceneData = this.get(scene);
        var background = scene.background;

        if (background != null) {
            if (sceneData.background != background) {
                var backgroundNode:Dynamic = null;

                if (background.isCubeTexture || (background.mapping == EquirectangularReflectionMapping || background.mapping == EquirectangularRefractionMapping)) {
                    backgroundNode = PmremTexture(background, NormalWorld());
                } else if (background.isTexture) {
                    backgroundNode = Texture(background, ViewportBottomLeft()).setUpdateMatrix(true);
                } else if (!background.isColor) {
                    trace('WebGPUNodes: Unsupported background configuration: $background');
                }

                sceneData.backgroundNode = backgroundNode;
                sceneData.background = background;
            }
        } else if (sceneData.backgroundNode != null) {
            sceneData.backgroundNode = null;
            sceneData.background = null;
        }
    }

    public function updateFog(scene:Dynamic):Void {
        var sceneData = this.get(scene);
        var fog = scene.fog;

        if (fog != null) {
            if (sceneData.fog != fog) {
                var fogNode:Dynamic = null;

                if (fog.isFogExp2) {
                    fogNode = DensityFog(Reference('color', 'color', fog), Reference('density', 'float', fog));
                } else if (fog.isFog) {
                    fogNode = RangeFog(Reference('color', 'color', fog), Reference('near', 'float', fog), Reference('far', 'float', fog));
                } else {
                    trace('WebGPUNodes: Unsupported fog configuration: $fog');
                }

                sceneData.fogNode = fogNode;
                sceneData.fog = fog;
            }
        } else {
            sceneData.fogNode = null;
            sceneData.fog = null;
        }
    }

    public function updateEnvironment(scene:Dynamic):Void {
        var sceneData = this.get(scene);
        var environment = scene.environment;

        if (environment != null) {
            if (sceneData.environment != environment) {
                var environmentNode:Dynamic = null;

                if (environment.isCubeTexture) {
                    environmentNode = CubeTexture(environment);
                } else if (environment.isTexture) {
                    environmentNode = Texture(environment);
                } else {
                    trace('Nodes: Unsupported environment configuration: $environment');
                }

                sceneData.environmentNode = environmentNode;
                sceneData.environment = environment;
            }
        } else if (sceneData.environmentNode != null) {
            sceneData.environmentNode = null;
            sceneData.environment = null;
        }
    }

    public function getNodeFrame(renderer:Dynamic = this.renderer, scene:Dynamic = null, object:Dynamic = null, camera:Dynamic = null, material:Dynamic = null):NodeFrame {
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

    public function getOutputNode(outputTexture:Dynamic):Vec4 {
        var output = Texture(outputTexture, ViewportTopLeft());

        if (this.isToneMappingState) {
            if (renderer.toneMappingNode != null) {
                output = Vec4(renderer.toneMappingNode.context({ color: output.rgb }), output.a);
            } else if (renderer.toneMapping != NoToneMapping) {
                output = output.toneMapping(renderer.toneMapping);
            }
        }

        if (renderer.currentColorSpace == SRGBColorSpace) {
            output = output.linearToColorSpace(renderer.currentColorSpace);
        }

        return output;
    }

    public function updateBefore(renderObject:Dynamic):Void {
        var nodeFrame = this.getNodeFrameForRender(renderObject);
        var nodeBuilder = renderObject.getNodeBuilderState();

        for (node in nodeBuilder.updateBeforeNodes) {
            nodeFrame.updateBeforeNode(node);
        }
    }

    public function updateForCompute(computeNode:Dynamic):Void {
        var nodeFrame = this.getNodeFrame();
        var nodeBuilder = this.getForCompute(computeNode);

        for (node in nodeBuilder.updateNodes) {
            nodeFrame.updateNode(node);
        }
    }

    public function updateForRender(renderObject:Dynamic):Void {
        var nodeFrame = this.getNodeFrameForRender(renderObject);
        var nodeBuilder = renderObject.getNodeBuilderState();

        for (node in nodeBuilder.updateNodes) {
            nodeFrame.updateNode(node);
        }
    }

    public function dispose():Void {
        super.dispose();
        nodeFrame = new NodeFrame();
        nodeBuilderCache = new Map();
    }
}