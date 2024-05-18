package three.js.examples.jsm.nodes.lighting;

import three.core.Node;
import three.nodes.lighting.AnalyticLightNode;
import three.shadernode.ShaderNode;

class LightsNode extends Node {
    public var totalDiffuseNode:Vec3;
    public var totalSpecularNode:Vec3;
    public var outgoingLightNode:Vec3;
    public var lightNodes:Array<AnalyticLightNode>;
    private var _hash:String;

    public function new(lightNodes:Array<AnalyticLightNode> = []) {
        super('vec3');
        totalDiffuseNode = Vec3.temp('totalDiffuse');
        totalSpecularNode = Vec3.temp('totalSpecular');
        outgoingLightNode = Vec3.temp('outgoingLight');
        this.lightNodes = lightNodes;
        _hash = null;
    }

    public function get_hasLight():Bool {
        return lightNodes.length > 0;
    }

    public function getHash():String {
        if (_hash == null) {
            var hash:Array<String> = [];
            for (lightNode in lightNodes) {
                hash.push(lightNode.getHash());
            }
            _hash = 'lights-' + hash.join(',');
        }
        return _hash;
    }

    public function setup(builder:Builder):Vec3 {
        var context = builder.context;
        var lightingModel = context.lightingModel;
        var outgoingLightNode = this.outgoingLightNode;

        if (lightingModel != null) {
            var stack = builder.addStack();
            lightingModel.start(context, stack, builder);

            for (lightNode in lightNodes) {
                lightNode.build(builder);
            }

            lightingModel.indirectDiffuse(context, stack, builder);
            lightingModel.indirectSpecular(context, stack, builder);
            lightingModel.ambientOcclusion(context, stack, builder);

            var backdrop = context.backdrop;
            var backdropAlpha = context.backdropAlpha;
            var reflectedLight = context.reflectedLight;
            var directDiffuse = reflectedLight.directDiffuse;
            var directSpecular = reflectedLight.directSpecular;
            var indirectDiffuse = reflectedLight.indirectDiffuse;
            var indirectSpecular = reflectedLight.indirectSpecular;

            var totalDiffuse = directDiffuse.add(indirectDiffuse);
            if (backdrop != null) {
                if (backdropAlpha != null) {
                    totalDiffuse = Vec3(backdropAlpha.mix(totalDiffuse, backdrop));
                } else {
                    totalDiffuse = Vec3(backdrop);
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

    private function _getLightNodeById(id:Int):AnalyticLightNode {
        for (lightNode in lightNodes) {
            if (lightNode.isAnalyticLightNode && lightNode.light.id == id) {
                return lightNode;
            }
        }
        return null;
    }

    public function fromLights(lights:Array<Dynamic> = []):LightsNode {
        var lightNodes:Array<AnalyticLightNode> = [];
        lights = sortLights(lights);
        for (light in lights) {
            var lightNode = _getLightNodeById(light.id);
            if (lightNode == null) {
                var lightClass:Class<Dynamic> = Type.getClass(light);
                var lightNodeClass:Class<AnalyticLightNode> = LightNodes.get(lightClass) != null ? LightNodes.get(lightClass) : AnalyticLightNode;
                lightNode = nodeObject(new lightNodeClass(light));
            }
            lightNodes.push(lightNode);
        }
        this.lightNodes = lightNodes;
        _hash = null;
        return this;
    }
}

class LightNodes {
    private static var map:WeakMap<Class<Dynamic>, Class<AnalyticLightNode>> = new WeakMap();

    public static function set(lightClass:Class<Dynamic>, lightNodeClass:Class<AnalyticLightNode>):Void {
        if (map.has(lightClass)) {
            Console.warn('Redefinition of light node ' + lightNodeClass.type);
            return;
        }
        if (!Std.isOfType(lightClass, Class)) throw new Error('Light ' + lightClass.name + ' is not a class');
        if (!Std.isOfType(lightNodeClass, Class) || !lightNodeClass.type) throw new Error('Light node ' + lightNodeClass.type + ' is not a class');
        map.set(lightClass, lightNodeClass);
    }

    public static function get(lightClass:Class<Dynamic>):Class<AnalyticLightNode> {
        return map.get(lightClass);
    }

    public static function has(lightClass:Class<Dynamic>):Bool {
        return map.has(lightClass);
    }
}

function sortLights(lights:Array<Dynamic>):Array<Dynamic> {
    return lights.sort(function(a, b) {
        return a.id - b.id;
    });
}

function nodeObject(node:Node):Node {
    return node;
}

function nodeProxy(nodeClass:Class<Node>):Node {
    return Type.createInstance(nodeClass, []);
}

function lights(lights:Array<Dynamic>):LightsNode {
    return nodeObject(new LightsNode().fromLights(lights));
}

function lightsNode():LightsNode {
    return nodeProxy(LightsNode);
}

function addLightNode(lightClass:Class<Dynamic>, lightNodeClass:Class<AnalyticLightNode>):Void {
    LightNodes.set(lightClass, lightNodeClass);
}