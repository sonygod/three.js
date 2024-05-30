import LightingNode from './LightingNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { uniform } from '../core/UniformNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { vec3, vec4 } from '../shadernode/ShaderNode.hx';
import { reference } from '../accessors/ReferenceNode.hx';
import { texture } from '../accessors/TextureNode.hx';
import { positionWorld } from '../accessors/PositionNode.hx';
import { normalWorld } from '../accessors/NormalNode.hx';
import { WebGPUCoordinateSystem } from 'three';

import { Color, DepthTexture, NearestFilter, LessCompare, NoToneMapping } from 'three';

var overrideMaterial = null;

class AnalyticLightNode extends LightingNode {
	public updateType:NodeUpdateType;
	public light:Dynamic;
	public rtt:Dynamic;
	public shadowNode:Dynamic;
	public shadowMaskNode:Dynamic;
	public color:Color;
	public _defaultColorNode:Dynamic;
	public colorNode:Dynamic;
	public isAnalyticLightNode:Bool;

	public function new(light:Dynamic = null) {
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
		return super.getCacheKey() + '-' + (Std.string(this.light.id) + '-' + (this.light.castShadow ? '1' : '0'));
	}

	public function getHash():Int {
		return this.light.uuid;
	}

	public function setupShadow(builder:Dynamic) {
		var object = builder.object;
		if (object.receiveShadow == false) return;

		var shadowNode = this.shadowNode;
		if (shadowNode == null) {
			if (overrideMaterial == null) {
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

			var bias = reference('bias', 'float', shadow);
			var normalBias = reference('normalBias', 'float', shadow);

			var position = object.material.shadowPositionNode ?? positionWorld;

			var shadowCoord = uniform(shadow.matrix).mul(position.add(normalWorld.mul(normalBias)));
			shadowCoord = shadowCoord.xyz.div(shadowCoord.w);

			var frustumTest = shadowCoord.x.greaterThanEqual(0)
				.and(shadowCoord.x.lessThanEqual(1))
				.and(shadowCoord.y.greaterThanEqual(0))
				.and(shadowCoord.y.lessThanEqual(1))
				.and(shadowCoord.z.lessThanEqual(1));

			var coordZ = shadowCoord.z.add(bias);

			if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem) {
				coordZ = coordZ.mul(2).sub(1);
			}

			shadowCoord = vec3(
				shadowCoord.x,
				shadowCoord.y.oneMinus(),
				coordZ
			);

			function textureCompare(depthTexture:Dynamic, shadowCoord:Dynamic, compare:Dynamic) {
				return texture(depthTexture, shadowCoord).compare(compare);
			}

			// BasicShadowMap
			shadowNode = textureCompare(depthTexture, shadowCoord.xy, shadowCoord.z);

			// PCFShadowMap
			/*
			var mapSize = reference('mapSize', 'vec2', shadow);
			var radius = reference('radius', 'float', shadow);

			var texelSize = vec2(1).div(mapSize);
			var dx0 = texelSize.x.negate().mul(radius);
			var dy0 = texelSize.y.negate().mul(radius);
			var dx1 = texelSize.x.mul(radius);
			var dy1 = texelSize.y.mul(radius);
			var dx2 = dx0.mul(2);
			var dy2 = dy0.mul(2);
			var dx3 = dx1.mul(2);
			var dy3 = dy1.mul(2);

			shadowNode = add(
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx0, dy0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(0, dy0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx1, dy0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx2, dy2)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(0, dy2)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx3, dy2)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx0, 0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx2, 0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy, shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx3, 0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx1, 0)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx2, dy3)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(0, dy3)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx3, dy3)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx0, dy1)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(0, dy1)), shadowCoord.z),
				textureCompare(depthTexture, shadowCoord.xy.add(vec2(dx1, dy1)), shadowCoord.z)
			).mul(1 / 17);
			*/

			var shadowColor = texture(rtt.texture, shadowCoord);
			var shadowMaskNode = frustumTest.mix(1, shadowNode.mix(shadowColor.a.mix(1, shadowColor), 1));

			this.rtt = rtt;
			this.colorNode = this.colorNode.mul(shadowMaskNode);

			this.shadowNode = shadowNode;
			this.shadowMaskNode = shadowMaskNode;

			this.updateBeforeType = NodeUpdateType.RENDER;
		}
	}

	public function setup(builder:Dynamic) {
		if (this.light.castShadow) this.setupShadow(builder);
		else if (this.shadowNode != null) this.disposeShadow();
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

		renderer.setRenderObjectFunction(function(object:Dynamic, ...params) {
			if (object.castShadow == true) {
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
		this.rtt.dispose();

		this.shadowNode = null;
		this.shadowMaskNode = null;
		this.rtt = null;

		this.colorNode = this._defaultColorNode;
	}

	public function updateBefore(frame:Dynamic) {
		var light = this.light;
		if (light.castShadow) this.updateShadow(frame);
	}

	public function update(/*frame:Dynamic*/) {
		var light = this.light;
		this.color.copy(light.color).multiplyScalar(light.intensity);
	}
}

addNodeClass('AnalyticLightNode', AnalyticLightNode);