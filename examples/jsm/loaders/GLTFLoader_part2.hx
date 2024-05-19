package three.js.examples.jlm.loaders;

import three.js.loaders.GLTFLoader;
import three.js.math.Color;
import three.js.lights.DirectionalLight;
import three.js.lights.PointLight;
import three.js.lights.SpotLight;
import three.js.math.Vector3;

class GLTFLightsExtension {
    private var parser:GLTFLoader;
    private var name:String;
    private var cache:Dynamic;

    public function new(parser:GLTFLoader) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_LIGHTS_PUNCTUAL;
        this.cache = { refs: {}, uses: {} };
    }

    private function _markDefs():Void {
        var parser = this.parser;
        var nodeDefs:Array<Dynamic> = this.parser.json.nodes;

        for (nodeIndex in 0...nodeDefs.length) {
            var nodeDef:Dynamic = nodeDefs[nodeIndex];

            if (nodeDef.extensions != null && nodeDef.extensions[this.name] != null && nodeDef.extensions[this.name].light != null) {
                parser._addNodeRef(this.cache, nodeDef.extensions[this.name].light);
            }
        }
    }

    private function _loadLight(lightIndex:Int):Promise<Light> {
        var parser = this.parser;
        var cacheKey:String = 'light:' + lightIndex;
        var dependency:Promise<Light> = parser.cache.get(cacheKey);

        if (dependency != null) return dependency;

        var json:Dynamic = parser.json;
        var extensions:Dynamic = json.extensions != null ? json.extensions[this.name] : {};
        var lightDefs:Array<Dynamic> = extensions.lights;
        var lightDef:Dynamic = lightDefs[lightIndex];
        var lightNode:Light;

        var color:Color = new Color(0xffffff);

        if (lightDef.color != null) color.setRGB(lightDef.color[0], lightDef.color[1], lightDef.color[2], LinearSRGBColorSpace);

        var range:Float = lightDef.range != null ? lightDef.range : 0;

        switch (lightDef.type) {
            case 'directional':
                lightNode = new DirectionalLight(color);
                lightNode.target.position.set(0, 0, -1);
                lightNode.add(lightNode.target);
                break;

            case 'point':
                lightNode = new PointLight(color);
                lightNode.distance = range;
                break;

            case 'spot':
                lightNode = new SpotLight(color);
                lightNode.distance = range;

                // Handle spotlight properties.
                lightDef.spot = lightDef.spot != null ? lightDef.spot : {};
                lightDef.spot.innerConeAngle = lightDef.spot.innerConeAngle != null ? lightDef.spot.innerConeAngle : 0;
                lightDef.spot.outerConeAngle = lightDef.spot.outerConeAngle != null ? lightDef.spot.outerConeAngle : Math.PI / 4.0;
                lightNode.angle = lightDef.spot.outerConeAngle;
                lightNode.penumbra = 1.0 - lightDef.spot.innerConeAngle / lightDef.spot.outerConeAngle;
                lightNode.target.position.set(0, 0, -1);
                lightNode.add(lightNode.target);
                break;

            default:
                throw new Error('THREE.GLTFLoader: Unexpected light type: ' + lightDef.type);
        }

        // Some lights (e.g. spot) default to a position other than the origin. Reset the position
        // here, because node-level parsing will only override position if explicitly specified.
        lightNode.position.set(0, 0, 0);

        lightNode.decay = 2;

        assignExtrasToUserData(lightNode, lightDef);

        if (lightDef.intensity != null) lightNode.intensity = lightDef.intensity;

        lightNode.name = parser.createUniqueName(lightDef.name != null ? lightDef.name : ('light_' + lightIndex));

        dependency = Promise.resolve(lightNode);

        parser.cache.add(cacheKey, dependency);

        return dependency;
    }

    public function getDependency(type:String, index:Int):Promise<Dynamic> {
        if (type != 'light') return null;

        return _loadLight(index);
    }

    public function createNodeAttachment(nodeIndex:Int):Promise<Dynamic> {
        var self:GLTFLightsExtension = this;
        var parser:GLTFLoader = this.parser;
        var json:Dynamic = parser.json;
        var nodeDef:Dynamic = json.nodes[nodeIndex];
        var lightDef:Dynamic = nodeDef.extensions != null ? nodeDef.extensions[this.name] : {};
        var lightIndex:Int = lightDef.light;

        if (lightIndex == null) return null;

        return _loadLight(lightIndex).then(function(light:Light) {
            return parser._getNodeRef(self.cache, lightIndex, light);
        });
    }
}