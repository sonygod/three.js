class GLTFLightsExtension {
    public var parser: Parser;
    public var name: String;
    public var cache: Map<Dynamic>;

    public function new(parser: Parser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_LIGHTS_PUNCTUAL;
        this.cache = { refs: {}, uses: {} };
    }

    public function _markDefs() {
        var nodeDefs = parser.json.nodes;
        for (nodeIndex in 0...nodeDefs.length) {
            var nodeDef = nodeDefs[nodeIndex];
            if (nodeDef.extensions != null && nodeDef.extensions[name] != null && nodeDef.extensions[name].light != null) {
                parser._addNodeRef(cache, nodeDef.extensions[name].light);
            }
        }
    }

    public function _loadLight(lightIndex: Int): Promise<Dynamic> {
        var parser = this.parser;
        var cacheKey = 'light:' + lightIndex;
        var dependency = parser.cache.get(cacheKey);
        if (dependency != null) return dependency;

        var json = parser.json;
        var extensions = (json.extensions != null ? json.extensions[name] : null) as Map<Dynamic>;
        var lightDefs = extensions.lights as Array<Dynamic>;
        var lightDef = lightDefs[lightIndex];
        var lightNode: Dynamic;

        var color = new Color(0xffffff);
        if (lightDef.color != null) color.setRGB(lightDef.color[0], lightDef.color[1], lightDef.color[2], LinearSRGBColorSpace);

        var range = if (lightDef.range != null) lightDef.range else 0;

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
                var lightSpot = lightDef.spot as Map<Float>;
                lightSpot.innerConeAngle = if (lightSpot.innerConeAngle != null) lightSpot.innerConeAngle else 0;
                lightSpot.outerConeAngle = if (lightSpot.outerConeAngle != null) lightSpot.outerConeAngle else Math.PI / 4.0;
                lightNode.angle = lightSpot.outerConeAngle;
                lightNode.penumbra = 1.0 - lightSpot.innerConeAngle / lightSpot.outerConeAngle;
                lightNode.target.position.set(0, 0, -1);
                lightNode.add(lightNode.target);
                break;
            default:
                throw new Error('THREE.GLTFLoader: Unexpected light type: ' + lightDef.type);
        }

        lightNode.position.set(0, 0, 0);
        lightNode.decay = 2;
        assignExtrasToUserData(lightNode, lightDef);
        if (lightDef.intensity != null) lightNode.intensity = lightDef.intensity;
        lightNode.name = parser.createUniqueName(if (lightDef.name != null) lightDef.name else 'light_' + lightIndex);

        dependency = Promise.resolve(lightNode);
        parser.cache.add(cacheKey, dependency);
        return dependency;
    }

    public function getDependency(type: String, index: Int): Promise<Dynamic> {
        if (type != 'light') return null;
        return this._loadLight(index);
    }

    public function createNodeAttachment(nodeIndex: Int): Promise<Dynamic> {
        var self = this;
        var parser = this.parser;
        var json = parser.json;
        var nodeDef = json.nodes[nodeIndex];
        var lightDef = (nodeDef.extensions != null ? nodeDef.extensions[name] : null) as Map<Int>;
        var lightIndex = lightDef.light;
        if (lightIndex == null) return null;

        return this._loadLight(lightIndex).then(function(light) {
            return parser._getNodeRef(self.cache, lightIndex, light);
        });
    }
}