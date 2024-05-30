package three.js.nodes.lighting;

import three.js.nodes.LightingNode;
import three.js.constants.NodeUpdateType;
import three.js.nodes.UniformNode;
import three.js.nodes.ShaderNode;
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
    public var light: Null<Light>;

    public var rtt: Null<RenderTarget>;
    public var shadowNode: Null<Node>;
    public var shadowMaskNode: Null<Node>;

    public var color: Color;
    private var _defaultColorNode: UniformNode;
    public var colorNode: Node;

    public var isAnalyticLightNode: Bool;

    public function new(?light: Light) {
        super();
        updateType = NodeUpdateType.FRAME;
        this.light = light;
        rtt = null;
        shadowNode = null;
        shadowMaskNode = null;
        color = new Color();
        _defaultColorNode = uniform(color);
        colorNode = _defaultColorNode;
        isAnalyticLightNode = true;
    }

    override public function getCacheKey(): String {
        return super.getCacheKey() + '-' + light.id + '-' + (light.castShadow ? '1' : '0');
    }

    override public function getHash(): String {
        return light.uuid;
    }

    public function setupShadow(builder: Builder) {
        var object = builder.object;
        if (!object.receiveShadow) return;
        if (shadowNode == null) {
            if (overrideMaterial == null) {
                overrideMaterial = builder.createNodeMaterial();
                overrideMaterial.fragmentNode = vec4(0, 0, 0, 1);
                overrideMaterial.isShadowNodeMaterial = true;
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
            var bias = reference('bias', 'float', shadow);
            var normalBias = reference('normalBias', 'float', shadow);
            var position = object.material.shadowPositionNode || positionWorld;
            var shadowCoord = uniform(shadow.matrix).mul(position.add(normalWorld.mul(normalBias)));
            shadowCoord = shadowCoord.xyz.div(shadowCoord.w);
            var frustumTest = shadowCoord.x.greaterThanEqual(0).and(shadowCoord.x.lessThanEqual(1))
                .and(shadowCoord.y.greaterThanEqual(0)).and(shadowCoord.y.lessThanEqual(1))
                .and(shadowCoord.z.lessThanEqual(1));
            var coordZ = shadowCoord.z.add(bias);
            if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem) {
                coordZ = coordZ.mul(2).sub(1);
            }
            shadowCoord = vec3(shadowCoord.x, shadowCoord.y.oneMinus(), coordZ);
            var textureCompare = function(depthTexture, shadowCoord, compare) {
                return texture(depthTexture, shadowCoord).compare(compare);
            }
            shadowNode = textureCompare(depthTexture, shadowCoord.xy, shadowCoord.z);
            var shadowMaskNode = frustumTest.mix(1, shadowNode.mix(texture(rtt.texture, shadowCoord).a.mix(1, texture(rtt.texture, shadowCoord)), 1));
            rtt = rtt;
            colorNode = colorNode.mul(shadowMaskNode);
            shadowNode = shadowNode;
            shadowMaskNode = shadowMaskNode;
            updateBeforeType = NodeUpdateType.RENDER;
        }
    }

    public function setup(builder: Builder) {
        if (light.castShadow) setupShadow(builder);
        else if (shadowNode != null) disposeShadow();
    }

    public function updateShadow(frame: Frame) {
        var rtt = rtt;
        var light = light;
        var renderer = frame.renderer;
        var scene = frame.scene;
        var currentOverrideMaterial = scene.overrideMaterial;
        scene.overrideMaterial = overrideMaterial;
        rtt.setSize(light.shadow.mapSize.width, light.shadow.mapSize.height);
        light.shadow.updateMatrices(light);
        var currentToneMapping = renderer.toneMapping;
        var currentRenderTarget = renderer.getRenderTarget();
        var currentRenderObjectFunction = renderer.getRenderObjectFunction();
        renderer.setRenderObjectFunction(function(object, params) {
            if (object.castShadow) renderer.renderObject(object, params);
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

    public function updateBefore(frame: Frame) {
        if (light.castShadow) updateShadow(frame);
    }

    public function update(/*frame: Frame*/) {
        color.copy(light.color).multiplyScalar(light.intensity);
    }
}

nodeClasses['AnalyticLightNode'] = AnalyticLightNode;