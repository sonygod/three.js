import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.lighting.AnalyticLightNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class LightsNode extends Node {

    public var totalDiffuseNode:ShaderNode.vec3;
    public var totalSpecularNode:ShaderNode.vec3;
    public var outgoingLightNode:ShaderNode.vec3;
    public var lightNodes:Array<AnalyticLightNode>;
    private var _hash:String;

    public function new(lightNodes:Array<AnalyticLightNode> = []) {
        super('vec3');
        this.totalDiffuseNode = ShaderNode.vec3().temp('totalDiffuse');
        this.totalSpecularNode = ShaderNode.vec3().temp('totalSpecular');
        this.outgoingLightNode = ShaderNode.vec3().temp('outgoingLight');
        this.lightNodes = lightNodes;
        this._hash = null;
    }

    public function get hasLight():Bool {
        return this.lightNodes.length > 0;
    }

    public function getHash():String {
        if (this._hash === null) {
            var hash:Array<String> = [];
            for (lightNode in this.lightNodes) {
                hash.push(lightNode.getHash());
            }
            this._hash = 'lights-' + hash.join(',');
        }
        return this._hash;
    }

    public function setup(builder:ShaderNode.Builder):ShaderNode.vec3 {
        var context = builder.context;
        var lightingModel = context.lightingModel;
        var outgoingLightNode = this.outgoingLightNode;
        if (lightingModel != null) {
            var lightNodes = this.lightNodes;
            var totalDiffuseNode = this.totalDiffuseNode;
            var totalSpecularNode = this.totalSpecularNode;
            context.outgoingLight = outgoingLightNode;
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
            var directDiffuse = context.reflectedLight.directDiffuse;
            var directSpecular = context.reflectedLight.directSpecular;
            var indirectDiffuse = context.reflectedLight.indirectDiffuse;
            var indirectSpecular = context.reflectedLight.indirectSpecular;
            var totalDiffuse = directDiffuse.add(indirectDiffuse);
            if (backdrop != null) {
                if (backdropAlpha != null) {
                    totalDiffuse = ShaderNode.vec3(backdropAlpha.mix(totalDiffuse, backdrop));
                } else {
                    totalDiffuse = ShaderNode.vec3(backdrop);
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
        for (lightNode in this.lightNodes) {
            if (lightNode.isAnalyticLightNode && lightNode.light.id == id) {
                return lightNode;
            }
        }
        return null;
    }

    public function fromLights(lights:Array<AnalyticLightNode> = []):LightsNode {
        var lightNodes:Array<AnalyticLightNode> = [];
        lights = sortLights(lights);
        for (light in lights) {
            var lightNode = this._getLightNodeById(light.id);
            if (lightNode == null) {
                var lightClass = Type.resolveClass(light.constructor);
                var lightNodeClass = LightNodes.exists(lightClass) ? LightNodes.get(lightClass) : AnalyticLightNode;
                lightNode = ShaderNode.nodeObject(new lightNodeClass(light));
            }
            lightNodes.push(lightNode);
        }
        this.lightNodes = lightNodes;
        this._hash = null;
        return this;
    }

    static public function sortLights(lights:Array<AnalyticLightNode>):Array<AnalyticLightNode> {
        return lights.sort(function(a, b) return a.id - b.id);
    }

    static public function lights(lights:Array<AnalyticLightNode>):ShaderNode.vec3 {
        return ShaderNode.nodeObject(new LightsNode().fromLights(lights));
    }

    static public function lightsNode(lights:Array<AnalyticLightNode>):ShaderNode.vec3 {
        return ShaderNode.nodeProxy(LightsNode);
    }

    static public function addLightNode(lightClass:Class<AnalyticLightNode>, lightNodeClass:Class<AnalyticLightNode>) {
        if (LightNodes.exists(lightClass)) {
            trace('Redefinition of light node ${lightNodeClass.type}');
            return;
        }
        if (Type.resolveClass(lightClass) == null) throw 'Light ${lightClass.name} is not a class';
        if (Type.resolveClass(lightNodeClass) == null || lightNodeClass.type == null) throw 'Light node ${lightNodeClass.type} is not a class';
        LightNodes.set(lightClass, lightNodeClass);
    }
}