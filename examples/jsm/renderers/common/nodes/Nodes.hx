Here is the converted Haxe code:
```
package three.js.examples.jvm.renderers.common.nodes;

import DataMap;
import ChainMap;
import NodeBuilderState;
import three.EquirectangularReflectionMapping;
import three.EquirectangularRefractionMapping;
import three.NoToneMapping;
import three.SRGBColorSpace;
import Nodes.NodeFrame;
import Nodes.Vec4;
import Nodes.ObjectGroup;
import Nodes.RenderGroup;
import Nodes.FrameGroup;
import Nodes.CubeTexture;
import Nodes.Texture;
import Nodes.RangeFog;
import Nodes.DensityFog;
import Nodes.Reference;
import Nodes.ViewportBottomLeft;
import Nodes.NormalWorld;
import Nodes.PmremTexture;
import Nodes.ViewportTopLeft;

class Nodes extends DataMap {

    public var renderer:Dynamic;
    public var backend:Dynamic;
    public var nodeFrame:NodeFrame;
    public var nodeBuilderCache:Map<String, NodeBuilderState>;
    public var callHashCache:ChainMap;
    public var groupsData:ChainMap;

    public function new(renderer:Dynamic, backend:Dynamic) {
        super();
        this.renderer = renderer;
        this.backend = backend;
        this.nodeFrame = new NodeFrame();
        this.nodeBuilderCache = new Map<String, NodeBuilderState>();
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
        var nodeBuilderState:NodeBuilderState = renderObjectData.nodeBuilderState;
        if (nodeBuilderState == null) {
            var cacheKey = this.getForRenderCacheKey(renderObject);
            nodeBuilderState = this.nodeBuilderCache.get(cacheKey);
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
                this.nodeBuilderCache.set(cacheKey, nodeBuilderState);
            }
            nodeBuilderState.usedTimes++;
            renderObjectData.nodeBuilderState = nodeBuilderState;
        }
        return nodeBuilderState;
    }

    public function delete(object:Dynamic):Void {
        if (object.isRenderObject) {
            var nodeBuilderState:NodeBuilderState = this.get(object).nodeBuilderState;
            nodeBuilderState.usedTimes--;
            if (nodeBuilderState.usedTimes == 0) {
                this.nodeBuilderCache.delete(this.getForRenderCacheKey(object));
            }
        }
        super.delete(object);
    }

    public function getForCompute(computeNode:Dynamic):NodeBuilderState {
        var computeData = this.get(computeNode);
        var nodeBuilderState:NodeBuilderState = computeData.nodeBuilderState;
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
            var cacheKey:Array<String> = [];
            if (lightsNode != null) cacheKey.push(lightsNode.getCacheKey());
            if (environmentNode != null) cacheKey.push(environmentNode.getCacheKey());
            if (fogNode != null) cacheKey.push(fogNode.getCacheKey());
            cacheKeyData = {
                callId: callId,
                cacheKey: cacheKey.join(',')
            };
            this.callHashCache.set(chain, cacheKeyData);
        }
        return cacheKeyData.cacheKey;
    }

    public function updateScene(scene:Dynamic):Void {
        this.updateEnvironment(scene);
        this.updateFog(scene);
        this.updateBackground(scene);
    }

    public function get_isToneMappingState():Bool {
        return this.renderer.getRenderTarget() ? false : true;
    }

    public function updateBackground(scene:Dynamic):Void {
        var sceneData = this.get(scene);
        var background = scene.background;
        if (background != null) {
            if (sceneData.background != background) {
                var backgroundNode:Dynamic = null;
                if (background.isCubeTexture || (background.mapping == EquirectangularReflectionMapping || background.mapping == EquirectangularRefractionMapping)) {
                    backgroundNode = pmremTexture(background, normalWorld);
                } else if (background.isTexture) {
                    backgroundNode = texture(background, viewportBottomLeft).setUpdateMatrix(true);
                } else if (!background.isColor) {
                    console.error('WebGPUNodes: Unsupported background configuration.', background);
                }
                sceneData.backgroundNode = backgroundNode;
                sceneData.background = background;
            }
        } else if (sceneData.backgroundNode != null) {
            delete sceneData.backgroundNode;
            delete sceneData.background;
        }
    }

    public function updateFog(scene:Dynamic):Void {
        var sceneData = this.get(scene);
        var fog = scene.fog;
        if (fog != null) {
            if (sceneData.fog != fog) {
                var fogNode:Dynamic = null;
                if (fog.isFogExp2) {
                    fogNode = densityFog(reference('color', 'color', fog), reference('density', 'float', fog));
                } else if (fog.isFog) {
                    fogNode = rangeFog(reference('color', 'color', fog), reference('near', 'float', fog), reference('far', 'float', fog));
                } else {
                    console.error('WebGPUNodes: Unsupported fog configuration.', fog);
                }
                sceneData.fogNode = fogNode;
                sceneData.fog = fog;
            }
        } else {
            delete sceneData.fogNode;
            delete sceneData.fog;
        }
    }

    public function updateEnvironment(scene:Dynamic):Void {
        var sceneData = this.get(scene);
        var environment = scene.environment;
        if (environment != null) {
            if (sceneData.environment != environment) {
                var environmentNode:Dynamic = null;
                if (environment.isCubeTexture) {
                    environmentNode = cubeTexture(environment);
                } else if (environment.isTexture) {
                    environmentNode = texture(environment);
                } else {
                    console.error('Nodes: Unsupported environment configuration.', environment);
                }
                sceneData.environmentNode = environmentNode;
                sceneData.environment = environment;
            }
        } else if (sceneData.environmentNode != null) {
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
            if (this.renderer.toneMappingNode != null) {
                output = vec4(this.renderer.toneMappingNode.context({ color: output.rgb }), output.a);
            } else if (this.renderer.toneMapping != NoToneMapping) {
                output = output.toneMapping(this.renderer.toneMapping);
            }
        }
        if (this.renderer.currentColorSpace == SRGBColorSpace) {
            output = output.linearToColorSpace(this.renderer.currentColorSpace);
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
        this.nodeFrame = new NodeFrame();
        this.nodeBuilderCache = new Map<String, NodeBuilderState>();
    }
}
```
Note that I've assumed that the Haxe compiler will automatically convert the JavaScript code to Haxe syntax. However, please review the converted code to ensure that it is correct and compatible with your Haxe project.