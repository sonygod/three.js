import DataMap from '../DataMap.hx';
import ChainMap from '../ChainMap.hx';
import NodeBuilderState from './NodeBuilderState.hx';
import { EquirectangularReflectionMapping, EquirectangularRefractionMapping, NoToneMapping, SRGBColorSpace } from 'three';
import { NodeFrame, vec4, objectGroup, renderGroup, frameGroup, cubeTexture, texture, rangeFog, densityFog, reference, viewportBottomLeft, normalWorld, pmremTexture, viewportTopLeft } from '../../../nodes/Nodes.hx';

class Nodes extends DataMap {

    public var renderer: any;
    public var backend: any;
    public var nodeFrame: NodeFrame;
    public var nodeBuilderCache: haxe.ds.StringMap<NodeBuilderState>;
    public var callHashCache: ChainMap<haxe.ds.StringMap<Dynamic>>;
    public var groupsData: ChainMap<haxe.ds.StringMap<Dynamic>>;

    public function new(renderer: any, backend: any) {
        super();

        this.renderer = renderer;
        this.backend = backend;
        this.nodeFrame = new NodeFrame();
        this.nodeBuilderCache = new haxe.ds.StringMap();
        this.callHashCache = new ChainMap();
        this.groupsData = new ChainMap();
    }

    public function updateGroup(nodeUniformsGroup: any): Bool {
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
        }

        if (name == frameGroup.name) {
            var uniformsGroupData = this.get(nodeUniformsGroup);
            var frameId = this.nodeFrame.frameId;

            if (uniformsGroupData.frameId != frameId) {
                uniformsGroupData.frameId = frameId;
                return true;
            }
        }

        var groupChain = [groupNode, nodeUniformsGroup];
        var groupData = this.groupsData.get(groupChain);

        if (groupData == null) {
            this.groupsData.set(groupChain, groupData = {});
        }

        if (groupData.version != groupNode.version) {
            groupData.version = groupNode.version;
            return true;
        }

        return false;
    }

    public function getForRenderCacheKey(renderObject: any): String {
        return renderObject.initialCacheKey;
    }

    public function getForRender(renderObject: any): NodeBuilderState {
        var renderObjectData = this.get(renderObject);
        var nodeBuilderState = renderObjectData.nodeBuilderState;

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

    public function delete(object: any): Bool {
        if (object.isRenderObject) {
            var nodeBuilderState = this.get(object).nodeBuilderState;
            nodeBuilderState.usedTimes--;

            if (nodeBuilderState.usedTimes == 0) {
                this.nodeBuilderCache.remove(this.getForRenderCacheKey(object));
            }
        }

        return super.delete(object);
    }

    public function getForCompute(computeNode: any): NodeBuilderState {
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

    private function _createNodeBuilderState(nodeBuilder: any): NodeBuilderState {
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

    public function getEnvironmentNode(scene: any): any {
        return scene.environmentNode || this.get(scene).environmentNode || null;
    }

    public function getBackgroundNode(scene: any): any {
        return scene.backgroundNode || this.get(scene).backgroundNode || null;
    }

    public function getFogNode(scene: any): any {
        return scene.fogNode || this.get(scene).fogNode || null;
    }

    public function getCacheKey(scene: any, lightsNode: any): String {
        var chain = [scene, lightsNode];
        var callId = this.renderer.info.calls;
        var cacheKeyData = this.callHashCache.get(chain);

        if (cacheKeyData == null || cacheKeyData.callId != callId) {
            var environmentNode = this.getEnvironmentNode(scene);
            var fogNode = this.getFogNode(scene);
            var cacheKey = [];

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

    public function updateScene(scene: any): Void {
        this.updateEnvironment(scene);
        this.updateFog(scene);
        this.updateBackground(scene);
    }

    public function get isToneMappingState(): Bool {
        return this.renderer.getRenderTarget() == null;
    }

    public function updateBackground(scene: any): Void {
        var sceneData = this.get(scene);
        var background = scene.background;

        if (background != null) {
            if (sceneData.background != background) {
                var backgroundNode = null;

                if (background.isCubeTexture == true || (background.mapping == EquirectangularReflectionMapping || background.mapping == EquirectangularRefractionMapping)) {
                    backgroundNode = pmremTexture(background, normalWorld);
                } else if (background.isTexture == true) {
                    backgroundNode = texture(background, viewportBottomLeft).setUpdateMatrix(true);
                } else if (background.isColor != true) {
                    trace('Nodes: Unsupported background configuration.', background);
                }

                sceneData.backgroundNode = backgroundNode;
                sceneData.background = background;
            }
        } else if (sceneData.backgroundNode != null) {
            sceneData.backgroundNode = null;
            sceneData.background = null;
        }
    }

    public function updateFog(scene: any): Void {
        var sceneData = this.get(scene);
        var fog = scene.fog;

        if (fog != null) {
            if (sceneData.fog != fog) {
                var fogNode = null;

                if (fog.isFogExp2) {
                    fogNode = densityFog(reference('color', 'color', fog), reference('density', 'float', fog));
                } else if (fog.isFog) {
                    fogNode = rangeFog(reference('color', 'color', fog), reference('near', 'float', fog), reference('far', 'float', fog));
                } else {
                    trace('Nodes: Unsupported fog configuration.', fog);
                }

                sceneData.fogNode = fogNode;
                sceneData.fog = fog;
            }
        } else {
            sceneData.fogNode = null;
            sceneData.fog = null;
        }
    }

    public function updateEnvironment(scene: any): Void {
        var sceneData = this.get(scene);
        var environment = scene.environment;

        if (environment != null) {
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
        } else if (sceneData.environmentNode != null) {
            sceneData.environmentNode = null;
            sceneData.environment = null;
        }
    }

    public function getNodeFrame(renderer: any = this.renderer, scene: any = null, object: any = null, camera: any = null, material: any = null): NodeFrame {
        var nodeFrame = this.nodeFrame;
        nodeFrame.renderer = renderer;
        nodeFrame.scene = scene;
        nodeFrame.object = object;
        nodeFrame.camera = camera;
        nodeFrame.material = material;

        return nodeFrame;
    }

    public function getNodeFrameForRender(renderObject: any): NodeFrame {
        return this.getNodeFrame(renderObject.renderer, renderObject.scene, renderObject.object, renderObject.camera, renderObject.material);
    }

    public function getOutputNode(outputTexture: any): any {
        var output = texture(outputTexture, viewportTopLeft);

        if (this.isToneMappingState) {
            if (this.renderer.toneMappingNode != null) {
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

    public function updateBefore(renderObject: any): Void {
        var nodeFrame = this.getNodeFrameForRender(renderObject);
        var nodeBuilder = renderObject.getNodeBuilderState();

        for (node in nodeBuilder.updateBeforeNodes) {
            nodeFrame.updateBeforeNode(node);
        }
    }

    public function updateForCompute(computeNode: any): Void {
        var nodeFrame = this.getNodeFrame();
        var nodeBuilder = this.getForCompute(computeNode);

        for (node in nodeBuilder.updateNodes) {
            nodeFrame.updateNode(node);
        }
    }

    public function updateForRender(renderObject: any): Void {
        var nodeFrame = this.getNodeFrameForRender(renderObject);
        var nodeBuilder = renderObject.getNodeBuilderState();

        for (node in nodeBuilder.updateNodes) {
            nodeFrame.updateNode(node);
        }
    }

    public function dispose(): Void {
        super.dispose();

        this.nodeFrame = new NodeFrame();
        this.nodeBuilderCache = new haxe.ds.StringMap();
    }
}