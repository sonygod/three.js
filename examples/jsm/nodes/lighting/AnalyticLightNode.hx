package three.js.examples.javascript.nodes.lighting;

import three.js.core.constants.NodeUpdateType;
import three.js.core.UniformNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.accessors.ReferenceNode;
import three.js.accessors.TextureNode;
import three.js.accessors.PositionNode;
import three.js.accessors.NormalNode;
import three.js.WebGPUCoordinateSystem;
import three.js.Color;
import three.js.DepthTexture;
import three.js.NearestFilter;
import three.js.LessCompare;
import three.js.NoToneMapping;

class AnalyticLightNode extends LightingNode {
    public var light:Dynamic;
    public var rtt:Dynamic;
    public var shadowNode:Dynamic;
    public var shadowMaskNode:Dynamic;

    public var color:Color;
    public var _defaultColorNode:UniformNode;
    public var colorNode:Dynamic;

    public var isAnalyticLightNode:Bool;

    public function new(light:Dynamic = null) {
        super();

        updateType = NodeUpdateType.FRAME;

        this.light = light;

        rtt = null;
        shadowNode = null;
        shadowMaskNode = null;

        color = new Color();
        _defaultColorNode = new UniformNode(color);
        colorNode = _defaultColorNode;

        isAnalyticLightNode = true;
    }

    override public function getCacheKey():String {
        return super.getCacheKey() + '-' + light.id + '-' + (light.castShadow ? '1' : '0');
    }

    override public function getHash():String {
        return light.uuid;
    }

    public function setupShadow(builder:Dynamic) {
        var object = builder.object;

        if (!object.receiveShadow) return;

        if (shadowNode == null) {
            if (overrideMaterial == null) {
                overrideMaterial = builder.createNodeMaterial();
                overrideMaterial.fragmentNode = new ShaderNode(vec4(0, 0, 0, 1));
                overrideMaterial.isShadowNodeMaterial = true; // Use to avoid other overrideMaterial override material.fragmentNode unintentionally when using material.shadowNode
            }

            var shadow = light.shadow;
            var rtt = builder.createRenderTarget(shadow.mapSize.width, shadow.mapSize.height);

            var depthTexture = new DepthTexture();
            depthTexture.minFilter = NearestFilter;
            depthTexture.magFilter = NearestFilter;
            depthTexture.image.width = shadow.mapSize.width;
            depthTexture.image.height = shadow.mapSize.height;
            depthTexture.compareFunction = LessCompare;

            rtt.depthTexture = depthTexture;

            shadow.camera.updateProjectionMatrix();

            var bias = new ReferenceNode('bias', 'float', shadow);
            var normalBias = new ReferenceNode('normalBias', 'float', shadow);

            var position = object.material.shadowPositionNode || new PositionNode();
            var normalWorld = new NormalNode();

            var shadowCoord = new UniformNode(shadow.matrix).mul(position.add(normalWorld.mul(normalBias)));
            shadowCoord = shadowCoord.xyz.div(shadowCoord.w);

            var frustumTest = shadowCoord.x.greaterThanEqual(0)
                .and(shadowCoord.x.lessThanEqual(1))
                .and(shadowCoord.y.greaterThanEqual(0))
                .and(shadowCoord.y.lessThanEqual(1))
                .and(shadowCoord.z.lessThanEqual(1));

            var coordZ = shadowCoord.z.add(bias);

            if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem) {
                coordZ = coordZ.mul(2).sub(1); // WebGPU: Convertion [ 0, 1 ] to [ - 1, 1 ]
            }

            shadowCoord = new ShaderNode(vec3(shadowCoord.x, shadowCoord.y.oneMinus(), coordZ));

            var textureCompare = function(depthTexture:DepthTexture, shadowCoord:ShaderNode, compare:ShaderNode) {
                return new TextureNode(depthTexture, shadowCoord).compare(compare);
            };

            // BasicShadowMap
            shadowNode = textureCompare(depthTexture, shadowCoord.xy, shadowCoord.z);

            // PCFShadowMap
            // ...

            var shadowColor = new TextureNode(rtt.texture, shadowCoord);
            var shadowMaskNode = frustumTest.mix(1, shadowNode.mix(shadowColor.a.mix(1, shadowColor), 1));

            this.rtt = rtt;
            this.colorNode = this.colorNode.mul(shadowMaskNode);

            this.shadowNode = shadowNode;
            this.shadowMaskNode = shadowMaskNode;

            this.updateBeforeType = NodeUpdateType.RENDER;
        }
    }

    public function setup(builder:Dynamic) {
        if (light.castShadow) setupShadow(builder);
        else if (shadowNode != null) disposeShadow();
    }

    public function updateShadow(frame:Dynamic) {
        var rtt = this.rtt;
        var light = this.light;

        var renderer = frame.renderer;
        var scene = frame.scene;

        var currentOverrideMaterial = scene.overrideMaterial;

        scene.overrideMaterial = overrideMaterial;

        rtt.setSize(light.shadow.mapSize.width, light.shadow.mapSize.height);

        light.shadow.updateMatrices(light);

        var currentToneMapping = renderer.toneMapping;
        var currentRenderTarget = renderer.getRenderTarget();
        var currentRenderObjectFunction = renderer.getRenderObjectFunction();

        renderer.setRenderObjectFunction(function(object:Dynamic, ...params:Array<Dynamic>) {
            if (object.castShadow) {
                renderer.renderObject(object, ...params);
            }
        });

        renderer.setRenderTarget(rtt);
        renderer.toneMapping = NoToneMapping;

        renderer.render(scene, light.shadow.camera);

        renderer.setRenderTarget(currentRenderTarget);
        renderer.setRenderObjectFunction(currentRenderObjectFunction);

        renderer.toneMapping = currentToneMapping;

        scene.overrideMaterial = currentOverrideMaterial;
    }

    public function disposeShadow() {
        rtt.dispose();

        shadowNode = null;
        shadowMaskNode = null;
        rtt = null;

        colorNode = _defaultColorNode;
    }

    override public function updateBefore(frame:Dynamic) {
        if (light.castShadow) updateShadow(frame);
    }

    override public function update(/*frame:Dynamic*/) {
        light.color.copy(color).multiplyScalar(light.intensity);
    }
}

addNodeClass('AnalyticLightNode', AnalyticLightNode);