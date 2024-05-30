import Node from '../core/Node.hx';
import AnalyticLightNode from './AnalyticLightNode.hx';
import { nodeObject, nodeProxy, vec3 } from '../shadernode/ShaderNode.hx';

typedef LightNodes = haxe.ds.WeakMap<Dynamic, Dynamic>;

var LightNodes = new LightNodes();

class LightsNode extends Node {

	public var totalDiffuseNode:Vec3;
	public var totalSpecularNode:Vec3;
	public var outgoingLightNode:Vec3;
	public var lightNodes:Array<Dynamic>;
	private var _hash:String;

	public function new(lightNodes:Array<Dynamic> = []) {
		super('vec3');

		this.totalDiffuseNode = vec3().temp('totalDiffuse');
		this.totalSpecularNode = vec3().temp('totalSpecular');
		this.outgoingLightNode = vec3().temp('outgoingLight');

		this.lightNodes = lightNodes;
		this._hash = null;
	}

	public function get hasLight() {
		return this.lightNodes.length > 0;
	}

	public function getHash():String {
		if (this._hash == null) {
			var hash = [];
			for (lightNode in this.lightNodes) {
				hash.push(lightNode.getHash());
			}
			this._hash = 'lights-' + hash.join(',');
		}
		return this._hash;
	}

	public function setup(builder:Dynamic):Dynamic {
		var context = builder.context;
		var lightingModel = context.lightingModel;

		var outgoingLightNode = this.outgoingLightNode;

		if (lightingModel != null) {
			var { lightNodes, totalDiffuseNode, totalSpecularNode } = this;

			context.outgoingLight = outgoingLightNode;

			var stack = builder.addStack();

			//

			lightingModel.start(context, stack, builder);

			// lights

			for (lightNode in lightNodes) {
				lightNode.build(builder);
			}

			//

			lightingModel.indirectDiffuse(context, stack, builder);
			lightingModel.indirectSpecular(context, stack, builder);
			lightingModel.ambientOcclusion(context, stack, builder);

			//

			var { backdrop, backdropAlpha } = context;
			var { directDiffuse, directSpecular, indirectDiffuse, indirectSpecular } = context.reflectedLight;

			var totalDiffuse = directDiffuse.add(indirectDiffuse);

			if (backdrop != null) {
				if (backdropAlpha != null) {
					totalDiffuse = vec3(backdropAlpha.mix(totalDiffuse, backdrop));
				} else {
					totalDiffuse = vec3(backdrop);
				}
				context.material.transparent = true;
			}

			totalDiffuseNode.assign(totalDiffuse);
			totalSpecularNode.assign(directSpecular.add(indirectSpecular));

			outgoingLightNode.assign(totalDiffuseNode.add(totalSpecularNode));

			//

			lightingModel.finish(context, stack, builder);

			//

			outgoingLightNode = outgoingLightNode.bypass(builder.removeStack());
		}

		return outgoingLightNode;
	}

	private function _getLightNodeById(id:Int):Dynamic {
		for (lightNode in this.lightNodes) {
			if (lightNode.isAnalyticLightNode && lightNode.light.id == id) {
				return lightNode;
			}
		}
		return null;
	}

	public function fromLights(lights:Array<Dynamic>):LightsNode {
		var lightNodes = [];

		lights = sortLights(lights);

		for (light in lights) {
			var lightNode = this._getLightNodeById(light.id);

			if (lightNode == null) {
				var lightClass = light.constructor;
				var lightNodeClass = LightNodes.has(lightClass) ? LightNodes.get(lightClass) : AnalyticLightNode;

				lightNode = nodeObject(new lightNodeClass(light));
			}

			lightNodes.push(lightNode);
		}

		this.lightNodes = lightNodes;
		this._hash = null;

		return this;
	}
}

export default LightsNode;

export function lights(lights:Array<Dynamic>):Dynamic {
	return nodeObject(new LightsNode().fromLights(lights));
}

export function lightsNode(LightsNode:Dynamic):Dynamic {
	return nodeProxy(LightsNode);
}

export function addLightNode(lightClass:Dynamic, lightNodeClass:Dynamic):Void {
	if (LightNodes.has(lightClass)) {
		trace('Redefinition of light node ' + lightNodeClass.type);
		return;
	}

	if (!Type.typeof(lightClass) == 'function') throw new Error('Light ' + lightClass.name + ' is not a class');
	if (!Type.typeof(lightNodeClass) == 'function' || !lightNodeClass.type) throw new Error('Light node ' + lightNodeClass.type + ' is not a class');

	LightNodes.set(lightClass, lightNodeClass);
}