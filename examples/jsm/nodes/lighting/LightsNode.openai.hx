package three.js.examples.jsm.nodes.lighting;

import three.js.core.Node;
import three.js.nodes.lighting.AnalyticLightNode;
import three.js.shadernode.ShaderNode;

class LightsNode extends Node
{
    private var totalDiffuseNode:ShaderNode;
    private var totalSpecularNode:ShaderNode;
    private var outgoingLightNode:ShaderNode;
    private var lightNodes:Array<AnalyticLightNode>;
    private var _hash:String;

    public function new(lightNodes:Array<AnalyticLightNode> = [])
    {
        super('vec3');
        this.totalDiffuseNode = ShaderNode.temp('totalDiffuse');
        this.totalSpecularNode = ShaderNode.temp('totalSpecular');
        this.outgoingLightNode = ShaderNode.temp('outgoingLight');
        this.lightNodes = lightNodes;
        this._hash = null;
    }

    public function get_hasLight():Bool
    {
        return lightNodes.length > 0;
    }

    public function getHash():String
    {
        if (_hash == null)
        {
            var hash:Array<String> = [];
            for (lightNode in lightNodes)
            {
                hash.push(lightNode.getHash());
            }
            _hash = 'lights-' + hash.join(',');
        }
        return _hash;
    }

    public function setup(builder:Builder):ShaderNode
    {
        var context:Dynamic = builder.context;
        var lightingModel:Dynamic = context.lightingModel;
        var outgoingLightNode:ShaderNode = this.outgoingLightNode;

        if (lightingModel != null)
        {
            var stack:Dynamic = builder.addStack();
            lightingModel.start(context, stack, builder);

            for (lightNode in lightNodes)
            {
                lightNode.build(builder);
            }

            lightingModel.indirectDiffuse(context, stack, builder);
            lightingModel.indirectSpecular(context, stack, builder);
            lightingModel.ambientOcclusion(context, stack, builder);

            var backdrop:Dynamic = context.backdrop;
            var backdropAlpha:Dynamic = context.backdropAlpha;
            var directDiffuse:ShaderNode = context.reflectedLight.directDiffuse;
            var indirectDiffuse:ShaderNode = context.reflectedLight.indirectDiffuse;
            var directSpecular:ShaderNode = context.reflectedLight.directSpecular;
            var indirectSpecular:ShaderNode = context.reflectedLight.indirectSpecular;

            var totalDiffuse:ShaderNode = directDiffuse.add(indirectDiffuse);

            if (backdrop != null)
            {
                if (backdropAlpha != null)
                {
                    totalDiffuse = ShaderNode.mix(backdropAlpha, totalDiffuse, backdrop);
                }
                else
                {
                    totalDiffuse = ShaderNode.create(backdrop);
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

    private function _getLightNodeById(id:Int):AnalyticLightNode
    {
        for (lightNode in lightNodes)
        {
            if (lightNode.isAnalyticLightNode && lightNode.light.id == id)
            {
                return lightNode;
            }
        }
        return null;
    }

    public function fromLights(lights:Array<Dynamic> = []):LightsNode
    {
        lights = sortLights(lights);
        var lightNodes:Array<AnalyticLightNode> = [];

        for (light in lights)
        {
            var lightNode:AnalyticLightNode = _getLightNodeById(light.id);
            if (lightNode == null)
            {
                var lightClass:Dynamic = light.constructor;
                var lightNodeClass:Dynamic = LightNodes.get(lightClass);
                if (lightNodeClass == null) lightNodeClass = AnalyticLightNode;
                lightNode = nodeObject(new lightNodeClass(light));
            }
            lightNodes.push(lightNode);
        }

        this.lightNodes = lightNodes;
        _hash = null;
        return this;
    }

    static var LightNodes:Map<Dynamic, Dynamic> = new Map();

    static public function addLightNode(lightClass:Dynamic, lightNodeClass:Dynamic)
    {
        if (LightNodes.exists(lightClass))
        {
            trace('Redefinition of light node ' + lightNodeClass.type);
            return;
        }
        if (!Std.isOfType(lightClass, Type.getClass(Type.getClassName(Type.getClass(lightClass)))))
        {
            throw new Error('Light ' + lightClass.name + ' is not a class');
        }
        if (!Std.isOfType(lightNodeClass, Type.getClass(Type.getClassName(Type.getClass(lightNodeClass)))))
        {
            throw new Error('Light node ' + lightNodeClass.type + ' is not a class');
        }
        LightNodes.set(lightClass, lightNodeClass);
    }
}

static function sortLights(lights:Array<Dynamic>):Array<Dynamic>
{
    return lights.sort(function(a, b) {
        return a.id - b.id;
    });
}

// Export aliases
extern class lights {
    static public function fromLights(lights:Array<Dynamic>):LightsNode
    {
        return nodeObject(new LightsNode().fromLights(lights));
    }
}

extern class lightsNode {
    static public function nodeProxy():LightsNode
    {
        return nodeProxy(LightsNode);
    }
}