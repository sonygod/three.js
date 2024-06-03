import js.Boot;
import js.WeakMap;
import js.Array;
import Node from '../core/Node';
import AnalyticLightNode from './AnalyticLightNode';
import { nodeObject, nodeProxy, vec3 } from '../shadernode/ShaderNode';

var LightNodes:WeakMap<Class<Dynamic>, Class<Dynamic>> = new WeakMap();

function sortLights(lights:Array<Dynamic>):Array<Dynamic> {
	return lights.sort(function(a:Dynamic, b:Dynamic):Int {
		return a.id - b.id;
	});
}

class LightsNode extends Node {
	var totalDiffuseNode:Dynamic;
	var totalSpecularNode:Dynamic;
	var outgoingLightNode:Dynamic;
	var lightNodes:Array<Dynamic>;
	var _hash:String;

	public function new(lightNodes:Array<Dynamic> = []) {
		super('vec3');
		this.totalDiffuseNode = vec3().temp('totalDiffuse');
		this.totalSpecularNode = vec3().temp('totalSpecular');
		this.outgoingLightNode = vec3().temp('outgoingLight');
		this.lightNodes = lightNodes;
		this._hash = null;
	}

	public function get hasLight():Bool {
		return this.lightNodes.length > 0;
	}

	public function getHash():String {
		if(this._hash == null) {
			var hash:Array<String> = [];
			for(lightNode in this.lightNodes) {
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

		if(lightingModel != null) {
			var lightNodes = this.lightNodes;
			var totalDiffuseNode = this.totalDiffuseNode;
			var totalSpecularNode = this.totalSpecularNode;

			context.outgoingLight = outgoingLightNode;

			var stack = builder.addStack();

			lightingModel.start(context, stack, builder);

			for(lightNode in lightNodes) {
				lightNode.build(builder);
			}

			lightingModel.indirectDiffuse(context, stack, builder);
			lightingModel.indirectSpecular(context, stack, builder);
			lightingModel.ambientOcclusion(context, stack, builder);

			var backdrop = context.backdrop;
			var backdropAlpha = context.backdropAlpha;
			var directDiffuse = context.reflectedLight.directDiffuse;
			var directSpecular = context.reflectedLight.directSpecular;
			var indirectDiffuse = context.reflectedLight.indirectDiffuse;
			var indirectSpecular = context.reflectedLight.indirectSpecular;

			var totalDiffuse = directDiffuse.add(indirectDiffuse);

			if(backdrop != null) {
				if(backdropAlpha != null) {
					totalDiffuse = vec3(backdropAlpha.mix(totalDiffuse, backdrop));
				} else {
					totalDiffuse = vec3(backdrop);
				}
				context.material.transparent = true;
			}

			totalDiffuseNode.assign(totalDiffuse);
			totalSpecularNode.assign(directSpecular.add(indirectSpecular));

			outgoingLightNode.assign(totalDiffuseNode.add(totalSpecularNode));

			lightingModel.finish(context, stack, builder);

			outgoingLightNode = outgoingLightNode.bypass(builder.removeStack());
		}

		return outgoingLightNode;
	}

	public function _getLightNodeById(id:Int):Dynamic {
		for(lightNode in this.lightNodes) {
			if(lightNode.isAnalyticLightNode && lightNode.light.id == id) {
				return lightNode;
			}
		}
		return null;
	}

	public function fromLights(lights:Array<Dynamic> = []):LightsNode {
		var lightNodes:Array<Dynamic> = [];

		lights = sortLights(lights);

		for(light in lights) {
			var lightNode = this._getLightNodeById(light.id);

			if(lightNode == null) {
				var lightClass = Type.getClass(light);
				var lightNodeClass = LightNodes.has(lightClass) ? LightNodes.get(lightClass) : AnalyticLightNode;

				lightNode = nodeObject(Boot.newInstance(lightNodeClass, [light]));
			}

			lightNodes.push(lightNode);
		}

		this.lightNodes = lightNodes;
		this._hash = null;

		return this;
	}
}

function lights(lights:Array<Dynamic>):Dynamic {
	return nodeObject(new LightsNode().fromLights(lights));
}

function lightsNode(type:Class<Dynamic>):Dynamic {
	return nodeProxy(type);
}

function addLightNode(lightClass:Class<Dynamic>, lightNodeClass:Class<Dynamic>):Void {
	if(LightNodes.has(lightClass)) {
		trace('Redefinition of light node ${lightNodeClass.type}');
		return;
	}

	if(Boot.isClass(lightClass) == false) throw new js.Error('Light ${lightClass.name} is not a class');
	if(Boot.isClass(lightNodeClass) == false || Reflect.field(lightNodeClass, 'type') == null) throw new js.Error('Light node ${lightNodeClass.type} is not a class');

	LightNodes.set(lightClass, lightNodeClass);
}