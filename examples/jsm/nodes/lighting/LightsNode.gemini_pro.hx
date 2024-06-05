import Node from "../core/Node";
import AnalyticLightNode from "./AnalyticLightNode";
import { nodeObject, nodeProxy, vec3 } from "../shadernode/ShaderNode";

class LightsNode extends Node {
  public totalDiffuseNode:vec3;
  public totalSpecularNode:vec3;
  public outgoingLightNode:vec3;
  public lightNodes:Array<Node>;
  private _hash:String = null;

  public function new(lightNodes:Array<Node> = []) {
    super("vec3");
    this.totalDiffuseNode = vec3().temp("totalDiffuse");
    this.totalSpecularNode = vec3().temp("totalSpecular");
    this.outgoingLightNode = vec3().temp("outgoingLight");
    this.lightNodes = lightNodes;
  }

  public function get hasLight():Bool {
    return this.lightNodes.length > 0;
  }

  public function getHash():String {
    if (this._hash == null) {
      var hash = new Array<String>();
      for (lightNode in this.lightNodes) {
        hash.push(lightNode.getHash());
      }
      this._hash = "lights-" + hash.join(",");
    }
    return this._hash;
  }

  public function setup(builder:Dynamic):Dynamic {
    var context = builder.context;
    var lightingModel = context.lightingModel;
    var outgoingLightNode = this.outgoingLightNode;

    if (lightingModel != null) {
      var lightNodes = this.lightNodes;
      var totalDiffuseNode = this.totalDiffuseNode;
      var totalSpecularNode = this.totalSpecularNode;
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
      var backdrop = context.backdrop;
      var backdropAlpha = context.backdropAlpha;
      var directDiffuse = context.reflectedLight.directDiffuse;
      var directSpecular = context.reflectedLight.directSpecular;
      var indirectDiffuse = context.reflectedLight.indirectDiffuse;
      var indirectSpecular = context.reflectedLight.indirectSpecular;
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

  private function _getLightNodeById(id:Int):Node {
    for (lightNode in this.lightNodes) {
      if (Std.is(lightNode, AnalyticLightNode) && lightNode.light.id == id) {
        return lightNode;
      }
    }
    return null;
  }

  public function fromLights(lights:Array<Dynamic> = []):LightsNode {
    var lightNodes = new Array<Node>();
    lights = sortLights(lights);

    for (light in lights) {
      var lightNode = this._getLightNodeById(light.id);

      if (lightNode == null) {
        var lightClass = Type.getClass(light);
        var lightNodeClass = LightNodes.get(lightClass);
        if (lightNodeClass == null) {
          lightNodeClass = AnalyticLightNode;
        }
        lightNode = nodeObject(Type.createInstance(lightNodeClass, [light]));
      }

      lightNodes.push(lightNode);
    }

    this.lightNodes = lightNodes;
    this._hash = null;

    return this;
  }
}

class LightNodes extends haxe.ds.WeakMap<Dynamic, Dynamic> {
  public function new() {
    super();
  }
}

private static var LightNodes = new LightNodes();

private static function sortLights(lights:Array<Dynamic>):Array<Dynamic> {
  return lights.sort((a, b) -> a.id - b.id);
}

export var lights = function(lights:Array<Dynamic>):Node {
  return nodeObject(new LightsNode().fromLights(lights));
};

export var lightsNode = nodeProxy(LightsNode);

export function addLightNode(lightClass:Dynamic, lightNodeClass:Dynamic):Void {
  if (LightNodes.exists(lightClass)) {
    Sys.warning("Redefinition of light node " + lightNodeClass.type);
    return;
  }

  if (Type.typeof(lightClass) != TClass) {
    throw new Error("Light " + Type.getClassName(lightClass) + " is not a class");
  }
  if (Type.typeof(lightNodeClass) != TClass || !Reflect.hasField(lightNodeClass, "type")) {
    throw new Error("Light node " + Type.getClassName(lightNodeClass) + " is not a class");
  }

  LightNodes.set(lightClass, lightNodeClass);
}