import Node from '../core/Node.hx';
import AnalyticLightNode from './AnalyticLightNode.hx';
import { nodeObject, nodeProxy, vec3 } from '../shadernode/ShaderNode.hx';

var LightNodes = new WeakMap();

function sortLights(lights) {
  return lights.sort($bind(function(a, b) {
    return a.id - b.id;
  }));
}

class LightsNode extends Node {
  constructor(lightNodes = []) {
    super('vec3');
    this.totalDiffuseNode = vec3().temp('totalDiffuse');
    this.totalSpecularNode = vec3().temp('totalSpecular');
    this.outgoingLightNode = vec3().temp('outgoingLight');
    this.lightNodes = lightNodes;
    this._hash = null;
  }

  get hasLight() {
    return this.lightNodes.length > 0;
  }

  getHash() {
    if (this._hash == null) {
      var hash = [];
      var _g = 0;
      while (_g < this.lightNodes.length) {
        var lightNode = this.lightNodes[_g];
        ++_g;
        hash.push(lightNode.getHash());
      }
      this._hash = 'lights-' + hash.join(',');
    }
    return this._hash;
  }

  setup(builder) {
    var context = builder.context;
    var lightingModel = context.lightingModel;
    var outgoingLightNode = this.outgoingLightNode;
    if (lightingModel != null) {
      var stack = builder.addStack();
      lightingModel.start(context, stack, builder);
      var _g = 0;
      while (_g < this.lightNodes.length) {
        var lightNode = this.lightNodes[_g];
        ++_g;
        lightNode.build(builder);
      }
      lightingModel.indirectDiffuse(context, stack, builder);
      lightingModel.indirectSpecular(context, stack, builder);
      lightingModel.ambientOcclusion(context, stack, builder);
      var backdrop = context.backdrop;
      var backdropAlpha = context.backdropAlpha;
      var totalDiffuse = context.reflectedLight.directDiffuse.add(context.reflectedLight.indirectDiffuse);
      if (backdrop != null) {
        if (backdropAlpha != null) {
          totalDiffuse = vec3(backdropAlpha.mix(totalDiffuse, backdrop));
        } else {
          totalDiffuse = vec3(backdrop);
        }
        context.material.transparent = true;
      }
      this.totalDiffuseNode.assign(totalDiffuse);
      this.totalSpecularNode.assign(context.reflectedLight.directSpecular.add(context.reflectedLight.indirectSpecular));
      this.outgoingLightNode.assign(this.totalDiffuseNode.add(this.totalSpecularNode));
      lightingModel.finish(context, stack, builder);
      outgoingLightNode = outgoingLightNode.bypass(builder.removeStack());
    }
    return outgoingLightNode;
  }

  _getLightNodeById(id) {
    var _g = 0;
    while (_g < this.lightNodes.length) {
      var lightNode = this.lightNodes[_g];
      ++_g;
      if (lightNode.isAnalyticLightNode && lightNode.light.id == id) {
        return lightNode;
      }
    }
    return null;
  }

  fromLights(lights = []) {
    var lightNodes = [];
    lights = sortLights(lights);
    var _g = 0;
    while (_g < lights.length) {
      var light = lights[_g];
      ++_g;
      var lightNode = this._getLightNodeById(light.id);
      if (lightNode == null) {
        var lightClass = Type.getClass(light);
        var lightNodeClass = LightNodes.get(lightClass);
        if (lightNodeClass == null) {
          lightNodeClass = AnalyticLightNode;
        }
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

export var lights = function(lights) {
  return nodeObject(new LightsNode().fromLights(lights));
};

export var lightsNode = nodeProxy(LightsNode);

export function addLightNode(lightClass, lightNodeClass) {
  if (LightNodes.has(lightClass)) {
    console.warn('Redefinition of light node ' + Type.getClassName(lightNodeClass));
    return;
  }
  if (!Std.is(lightClass, Class)) {
    throw new Error('Light ' + Type.getClassName(lightClass) + ' is not a class');
  }
  if (!Std.is(lightNodeClass, Class) || lightNodeClass.prototype == null) {
    throw new Error('Light node ' + Type.getClassName(lightNodeClass) + ' is not a class');
  }
  LightNodes.set(lightClass, lightNodeClass);
};