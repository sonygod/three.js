import LightingNode from './LightingNode';
import { NodeUpdateType } from '../core/constants';
import { UniformNode } from '../core/UniformNode';
import { Node } from '../core/Node';
import { vec3, vec4 } from '../shadernode/ShaderNode';
import { ReferenceNode } from '../accessors/ReferenceNode';
import { TextureNode } from '../accessors/TextureNode';
import { PositionNode } from '../accessors/PositionNode';
import { NormalNode } from '../accessors/NormalNode';
import { WebGPUCoordinateSystem } from 'three';
//import { add } from '../math/OperatorNode';

import { Color, DepthTexture, NearestFilter, LessCompare, NoToneMapping } from 'three';

var overrideMaterial: Null<NodeMaterial> = null;

class AnalyticLightNode extends LightingNode {

	public var light: Null<Light> = null;
	public var rtt: Null<RenderTarget> = null;
	public var shadowNode: Null<Node> = null;
	public var shadowMaskNode: Null<Node> = null;
	public var color: Color;
	public var colorNode: Node;
	public var _defaultColorNode: Node;
	public var isAnalyticLightNode: Bool = true;

	public function new(light: Null<Light> = null) {
		super();

		this.updateType = NodeUpdateType.FRAME;

		this.light = light;

		this.rtt = null;
		this.shadowNode = null;
		this.shadowMaskNode = null;

		this.color = new Color();
		this._defaultColorNode = UniformNode.uniform(this.color);

		this.colorNode = this._defaultColorNode;
	}

	override public function getCacheKey(): String {
		return super.getCacheKey() + '-' + (this.light.id + '-' + (this.light.castShadow ? '1' : '0'));
	}

	override public function getHash(): String {
		return this.light.uuid;
	}

	public function setupShadow(builder: NodeBuilder) {
		var object = builder.object;

		if (object.receiveShadow === false) return;

		if (this.shadowNode === null) {
			if (overrideMaterial === null) {
				overrideMaterial = builder.createNodeMaterial();
				overrideMaterial.fragmentNode = vec4(0, 0, 0, 1);
				overrideMaterial.isShadowNodeMaterial = true;
			}

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

			var bias = ReferenceNode.reference('bias', 'float', shadow);
			var normalBias = ReferenceNode.reference('normalBias', 'float', shadow);

			var position = object.material.shadowPositionNode || PositionNode.positionWorld;

			var shadowCoord = UniformNode.uniform(shadow.matrix).mul(position.add(NormalNode.normalWorld.mul(normalBias)));
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

			var textureCompare = (depthTexture: DepthTexture, shadowCoord: Node, compare: Node) => TextureNode.texture(depthTexture, shadowCoord).compare(compare);

			var shadowNode = textureCompare(depthTexture, shadowCoord.xy, shadowCoord.z);

			var shadowColor = TextureNode.texture(rtt.texture, shadowCoord);
			var shadowMaskNode = frustumTest.mix(1, shadowNode.mix(shadowColor.a.mix(1, shadowColor), 1));

			this.rtt = rtt;
			this.colorNode = this.colorNode.mul(shadowMaskNode);

			this.shadowNode = shadowNode;
			this.shadowMaskNode = shadowMaskNode;

			this.updateBeforeType = NodeUpdateType.RENDER;
		}
	}

	public function setup(builder: NodeBuilder) {
		if (this.light.castShadow) this.setupShadow(builder);
		else if (this.shadowNode !== null) this.disposeShadow();
	}

	public function updateShadow(frame: NodeFrame) {
		var renderer = frame.renderer;
		var scene = frame.scene;

		var currentOverrideMaterial = scene.overrideMaterial;

		scene.overrideMaterial = overrideMaterial;

		this.rtt.setSize(this.light.shadow.mapSize.width, this.light.shadow.mapSize.height);

		this.light.shadow.updateMatrices(this.light);

		var currentToneMapping = renderer.toneMapping;
		var currentRenderTarget = renderer.getRenderTarget();
		var currentRenderObjectFunction = renderer.getRenderObjectFunction();

		renderer.setRenderObjectFunction((object: Object3D, ...params) => {
			if (object.castShadow === true) {
				renderer.renderObject(object, ...params);
			}
		});

		renderer.setRenderTarget(this.rtt);
		renderer.toneMapping = NoToneMapping;

		renderer.render(scene, this.light.shadow.camera);

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

	override public function updateBefore(frame: NodeFrame) {
		if (this.light.castShadow) this.updateShadow(frame);
	}

	override public function update(/*frame: NodeFrame*/) {
		this.color.copy(this.light.color).multiplyScalar(this.light.intensity);
	}
}

export default AnalyticLightNode;

Node.addNodeClass('AnalyticLightNode', AnalyticLightNode);