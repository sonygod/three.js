package three.js.examples.jm.loaders;

import three.js.loaders.GLTFLoader;

class GLTFLightsExtension {
    public var parser:GLTFParser;
    public var name:String = EXTENSIONS.KHR_LIGHTS_PUNCTUAL;

    // Object3D instance caches
    public var cache:{ refs:Map<Int, Dynamic>, uses:Map<Int, Dynamic> } = { refs:new Map(), uses:new Map() };

    public function new(parser:GLTFParser) {
        this.parser = parser;
    }

    public function _markDefs():Void {
        var nodeDefs:Array<Dynamic> = parser.json.nodes;
        for (nodeIndex in 0...nodeDefs.length) {
            var nodeDef:Dynamic = nodeDefs[nodeIndex];
            if (nodeDef.extensions != null && nodeDef.extensions[name] != null && nodeDef.extensions[name].light != null) {
                parser._addNodeRef(cache, nodeDef.extensions[name].light);
            }
        }
    }

    public function _loadLight(lightIndex:Int):Promise<Light> {
        var cacheKey:String = 'light:' + lightIndex;
        var dependency:Promise<Light> = parser.cache.get(cacheKey);
        if (dependency != null) return dependency;

        var json:Dynamic = parser.json;
        var extensions:Dynamic = json.extensions != null ? json.extensions[name] : {};
        var lightDefs:Array<Dynamic> = extensions.lights;
        var lightDef:Dynamic = lightDefs[lightIndex];
        var light:Light;

        var color:Color = new Color(0xffffff);
        if (lightDef.color != null) color.setRGB(lightDef.color[0], lightDef.color[1], lightDef.color[2], LinearSRGBColorSpace);

        var range:Float = lightDef.range != null ? lightDef.range : 0;

        switch (lightDef.type) {
            case 'directional':
                light = new DirectionalLight(color);
                light.target.position.set(0, 0, -1);
                light.add(light.target);
                break;
            case 'point':
                light = new PointLight(color);
                light.distance = range;
                break;
            case 'spot':
                light = new SpotLight(color);
                light.distance = range;
                lightDef.spot = lightDef.spot != null ? lightDef.spot : {};
                lightDef.spot.innerConeAngle = lightDef.spot.innerConeAngle != null ? lightDef.spot.innerConeAngle : 0;
                lightDef.spot.outerConeAngle = lightDef.spot.outerConeAngle != null ? lightDef.spot.outerConeAngle : Math.PI / 4.0;
                light.angle = lightDef.spot.outerConeAngle;
                light.penumbra = 1.0 - lightDef.spot.innerConeAngle / lightDef.spot.outerConeAngle;
                light.target.position.set(0, 0, -1);
                light.add(light.target);
                break;
            default:
                throw new Error('THREE.GLTFLoader: Unexpected light type: ' + lightDef.type);
        }

        light.position.set(0, 0, 0);
        light.decay = 2;

        assignExtrasToUserData(light, lightDef);

        if (lightDef.intensity != null) light.intensity = lightDef.intensity;

        light.name = parser.createUniqueName(lightDef.name != null ? lightDef.name : 'light_' + lightIndex);

        dependency = Promise.resolve(light);
        parser.cache.add(cacheKey, dependency);

        return dependency;
    }

    public function getDependency(type:String, index:Int):Promise<Dynamic> {
        if (type != 'light') return null;

        return _loadLight(index);
    }

    public function createNodeAttachment(nodeIndex:Int):Promise<Dynamic> {
        var self:GLTFLightsExtension = this;
        var parser:GLTFParser = this.parser;
        var json:Dynamic = parser.json;
        var nodeDef:Dynamic = json.nodes[nodeIndex];
        var lightDef:Dynamic = nodeDef.extensions != null ? nodeDef.extensions[name] : {};
        var lightIndex:Int = lightDef.light;

        if (lightIndex == null) return null;

        return _loadLight(lightIndex).then(function(light:Light) {
            return parser._getNodeRef(self.cache, lightIndex, light);
        });
    }
}