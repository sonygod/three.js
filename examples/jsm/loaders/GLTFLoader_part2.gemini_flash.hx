import three.Lights.Light;
import three.Lights.DirectionalLight;
import three.Lights.PointLight;
import three.Lights.SpotLight;
import three.math.Color;
import three.GLTFLoader;
import js.lib.Promise;

class GLTFLightsExtension {

    public var parser : GLTFLoader;
    public var name : String;
    public var cache : Dynamic;

    public function new(parser) {
        this.parser = parser;
        this.name = GLTFLoader.EXTENSIONS.KHR_LIGHTS_PUNCTUAL;

        this.cache = { refs: {}, uses: {} };
    }

    function _markDefs() {
        var nodeDefs = this.parser.json.nodes;
        if (nodeDefs != null) {
            for (nodeIndex in 0...nodeDefs.length) {
                var nodeDef = nodeDefs[nodeIndex];
                if (nodeDef.extensions != null && Reflect.hasField(nodeDef.extensions, this.name) && nodeDef.extensions[this.name].light != null) {
                    this.parser._addNodeRef(this.cache, nodeDef.extensions[this.name].light);
                }
            }
        }
    }

    function _loadLight(lightIndex : Int) : Promise<Light> {
        var cacheKey = 'light:' + lightIndex;
        var dependency = this.parser.cache.get(cacheKey);
        if (dependency != null) {
            return dependency;
        }

        var json = this.parser.json;
        var extensions = (json.extensions != null && Reflect.hasField(json.extensions, this.name)) ? json.extensions[this.name] : {};
        var lightDefs = extensions.lights != null ? extensions.lights : [];
        var lightDef = lightDefs[lightIndex];
        var lightNode : Light = null;
        var color = new Color(0xffffff);

        if (lightDef.color != null) {
            color.setRGB(lightDef.color[0], lightDef.color[1], lightDef.color[2]);
        }

        var range = (lightDef.range != null) ? lightDef.range : 0;

        switch (lightDef.type) {
            case 'directional':
                lightNode = new DirectionalLight(color);
                lightNode.target.position.set(0, 0, -1);
                lightNode.add(lightNode.target);
            case 'point':
                lightNode = new PointLight(color);
                lightNode.distance = range;
            case 'spot':
                lightNode = new SpotLight(color);
                lightNode.distance = range;

                lightDef.spot = (lightDef.spot != null) ? lightDef.spot : {};
                lightDef.spot.innerConeAngle = (lightDef.spot.innerConeAngle != null) ? lightDef.spot.innerConeAngle : 0;
                lightDef.spot.outerConeAngle = (lightDef.spot.outerConeAngle != null) ? lightDef.spot.outerConeAngle : Math.PI / 4.0;

                lightNode.angle = lightDef.spot.outerConeAngle;
                lightNode.penumbra = 1.0 - lightDef.spot.innerConeAngle / lightDef.spot.outerConeAngle;
                lightNode.target.position.set(0, 0, -1);
                lightNode.add(lightNode.target);
            case _:
                throw 'THREE.GLTFLoader: Unexpected light type: ' + lightDef.type;
        }

        lightNode.position.set(0, 0, 0);
        lightNode.decay = 2;

        this.parser.assignExtrasToUserData(lightNode, lightDef);

        if (lightDef.intensity != null) {
            lightNode.intensity = lightDef.intensity;
        }

        lightNode.name = this.parser.createUniqueName((lightDef.name != null) ? lightDef.name : ('light_' + lightIndex));

        dependency = Promise.resolve(lightNode);
        this.parser.cache.add(cacheKey, dependency);
        return dependency;
    }

    public function getDependency(type : String, index : Int) : Promise<Light> {
        if (type != 'light') {
            return null;
        }
        return this._loadLight(index);
    }

    public function createNodeAttachment(nodeIndex : Int) : Promise<Light> {
        var json = this.parser.json;
        var nodeDef = json.nodes[nodeIndex];
        var lightDef = (nodeDef.extensions != null && Reflect.hasField(nodeDef.extensions, this.name)) ? nodeDef.extensions[this.name] : {};
        var lightIndex = lightDef.light;

        if (lightIndex == null) {
            return null;
        }
        var self = this;
        return this._loadLight(lightIndex).then(function(light) {
            return self.parser._getNodeRef(self.cache, lightIndex, light);
        });
    }

}