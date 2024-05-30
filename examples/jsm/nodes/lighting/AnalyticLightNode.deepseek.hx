import LightingNode from './LightingNode.hx';
import NodeUpdateType from '../core/constants.hx';
import uniform from '../core/UniformNode.hx';
import addNodeClass from '../core/Node.hx';
import vec3 from '../shadernode/ShaderNode.hx';
import vec4 from '../shadernode/ShaderNode.hx';
import reference from '../accessors/ReferenceNode.hx';
import texture from '../accessors/TextureNode.hx';
import positionWorld from '../accessors/PositionNode.hx';
import normalWorld from '../accessors/NormalNode.hx';
import WebGPUCoordinateSystem from 'three';

class AnalyticLightNode extends LightingNode {

	public function new(light:Null<Light> = null) {
		super();

		this.updateType = NodeUpdateType.FRAME;

		this.light = light;

		this.rtt = null;
		this.shadowNode = null;
		this.shadowMaskNode = null;

		this.color = new Color();
		this._defaultColorNode = uniform(this.color);

		this.colorNode = this._defaultColorNode;

		this.isAnalyticLightNode = true;
	}

	public function getCacheKey():String {
		return super.getCacheKey() + '-' + (this.light.id + '-' + (this.light.castShadow ? '1' : '0'));
	}

	public function getHash():String {
		return this.light.uuid;
	}

	public function setupShadow(builder:Builder) {
		var object = builder.object;

		if (object.receiveShadow === false) return;

		var shadowNode = this.shadowNode;

		if (shadowNode === null) {
			var overrideMaterial = builder.createNodeMaterial();
			overrideMaterial.fragmentNode = vec4(0, 0, 0, 1);
			overrideMaterial.isShadowNodeMaterial = true;

			var shadow = this.light.shadow;
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

			var frustumTest = shadowCoord.x.greaterThanEqual(0)
				.and(shadowCoord.x.lessThanEqual(1))
				.and(shadowCoord.y.greaterThanEqual(0))
				.and(shadowCoord.y.lessThanEqual(1))
				.and(shadowCoord.z.lessThanEqual(1));

			var coordZ = shadowCoord.z.add(bias);

			if (builder.renderer.coordinateSystem === WebGPUCoordinateSystem) {
				coordZ = coordZ.mul(2).sub(1);
			}

			shadowCoord = vec3(
				shadowCoord.x,
				shadowCoord.y.oneMinus(),
				coordZ
			);

			var textureCompare = (depthTexture, shadowCoord, compare) -> texture(depthTexture, shadowCoord).compare(compare);

			shadowNode = textureCompare(depthTexture, shadowCoord.xy, shadowCoord.z);

			var shadowColor = texture(rtt.texture, shadowCoord);
			var shadowMaskNode = frustumTest.mix(1, shadowNode.mix(shadowColor.a.mix(1, shadowColor), 1));

			this.rtt = rtt;
			this.colorNode = this.colorNode.mul(shadowMaskNode);

			this.shadowNode = shadowNode;
			this.shadowMaskNode = shadowMaskNode;

			this.updateBeforeType = NodeUpdateType.RENDER;
		}
	}

	public function setup(builder:Builder) {
		if (this.light.castShadow) this.setupShadow(builder);
		else if (this.shadowNode !== null) this.disposeShadow();
	}

	public function updateShadow(frame:Frame) {
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

		renderer.setRenderObjectFunction((object, params) -> {
			if (object.castShadow === true) {
				renderer.renderObject(object, params);
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
		this.rtt.dispose();

		this.shadowNode = null;
		this.shadowMaskNode = null;
		this.rtt = null;

		this.colorNode = this._defaultColorNode;
	}

	public function updateBefore(frame:Frame) {
		var light = this.light;

		if (light.castShadow) this.updateShadow(frame);
	}

	public function update(/*frame*/) {
		var light = this.light;

		this.color.copy(light.color).multiplyScalar(light.intensity);
	}
}

addNodeClass('AnalyticLightNode', AnalyticLightNode);