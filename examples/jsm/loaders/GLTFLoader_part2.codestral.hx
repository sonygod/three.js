import three.Color;
import three.LinearSRGBColorSpace;
import three.Math;
import three.DirectionalLight;
import three.PointLight;
import three.SpotLight;
import three.assignExtrasToUserData;

class GLTFLightsExtension {
    private var parser:Parser;
    public var name:String = EXTENSIONS.KHR_LIGHTS_PUNCTUAL;
    private var cache:Object = { refs: {}, uses: {} };

    public function new(parser:Parser) {
        this.parser = parser;
    }

    public function _markDefs():Void {
        var parser = this.parser;
        var nodeDefs = parser.json.nodes || [];

        for (var nodeIndex:Int = 0; nodeIndex < nodeDefs.length; nodeIndex++) {
            var nodeDef = nodeDefs[nodeIndex];

            if (nodeDef.extensions && nodeDef.extensions[this.name] && nodeDef.extensions[this.name].light !== null) {
                parser._addNodeRef(this.cache, nodeDef.extensions[this.name].light);
            }
        }
    }

    private function _loadLight(lightIndex:Int):Promise<Object> {
        var parser = this.parser;
        var cacheKey = 'light:' + lightIndex;
        var dependency = parser.cache.get(cacheKey);

        if (dependency != null) return dependency;

        var json = parser.json;
        var extensions = (json.extensions && json.extensions[this.name]) || {};
        var lightDefs = extensions.lights || [];
        var lightDef = lightDefs[lightIndex];
        var lightNode:Object;

        var color = new Color(0xffffff);

        if (lightDef.color != null) color.setRGB(lightDef.color[0], lightDef.color[1], lightDef.color[2], LinearSRGBColorSpace);

        var range = lightDef.range != null ? lightDef.range : 0;

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
                lightDef.spot = lightDef.spot || {};
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

        lightNode.name = parser.createUniqueName(lightDef.name || ('light_' + lightIndex));

        dependency = Promise.resolve(lightNode);

        parser.cache.add(cacheKey, dependency);

        return dependency;
    }

    public function getDependency(type:String, index:Int):Promise<Object> {
        if (type !== 'light') return null;

        return this._loadLight(index);
    }

    public function createNodeAttachment(nodeIndex:Int):Promise<Object> {
        var self = this;
        var parser = this.parser;
        var json = parser.json;
        var nodeDef = json.nodes[nodeIndex];
        var lightDef = (nodeDef.extensions && nodeDef.extensions[this.name]) || {};
        var lightIndex = lightDef.light;

        if (lightIndex == null) return null;

        return this._loadLight(lightIndex).then(function (light) {
            return parser._getNodeRef(self.cache, lightIndex, light);
        });
    }
}