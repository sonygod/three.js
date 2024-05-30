class GLTFLightsExtension {

	var parser:GLTFParser;
	var name:String;
	var cache:{ refs:Dynamic, uses:Dynamic };

	public function new(parser:GLTFParser) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_LIGHTS_PUNCTUAL;
		this.cache = { refs: {}, uses: {} };
	}

	private function _markDefs():Void {
		var nodeDefs = this.parser.json.nodes || [];
		for (nodeIndex in nodeDefs) {
			var nodeDef = nodeDefs[nodeIndex];
			if (nodeDef.extensions && nodeDef.extensions[this.name] && nodeDef.extensions[this.name].light !== undefined) {
				this.parser._addNodeRef(this.cache, nodeDef.extensions[this.name].light);
			}
		}
	}

	private function _loadLight(lightIndex:Int):Promise<Dynamic> {
		var cacheKey = 'light:' + lightIndex;
		var dependency = this.parser.cache.get(cacheKey);
		if (dependency) return dependency;
		var json = this.parser.json;
		var extensions = (json.extensions && json.extensions[this.name]) || {};
		var lightDefs = extensions.lights || [];
		var lightDef = lightDefs[lightIndex];
		var lightNode:Dynamic;
		var color = new Color(0xffffff);
		if (lightDef.color !== undefined) color.setRGB(lightDef.color[0], lightDef.color[1], lightDef.color[2], LinearSRGBColorSpace);
		var range = lightDef.range !== undefined ? lightDef.range : 0;
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
				lightDef.spot = lightDef.spot || {};
				lightDef.spot.innerConeAngle = lightDef.spot.innerConeAngle !== undefined ? lightDef.spot.innerConeAngle : 0;
				lightDef.spot.outerConeAngle = lightDef.spot.outerConeAngle !== undefined ? lightDef.spot.outerConeAngle : Math.PI / 4.0;
				lightNode.angle = lightDef.spot.outerConeAngle;
				lightNode.penumbra = 1.0 - lightDef.spot.innerConeAngle / lightDef.spot.outerConeAngle;
				lightNode.target.position.set(0, 0, -1);
				lightNode.add(lightNode.target);
				break;
			default:
				throw 'THREE.GLTFLoader: Unexpected light type: ' + lightDef.type;
		}
		lightNode.position.set(0, 0, 0);
		lightNode.decay = 2;
		assignExtrasToUserData(lightNode, lightDef);
		if (lightDef.intensity !== undefined) lightNode.intensity = lightDef.intensity;
		lightNode.name = this.parser.createUniqueName(lightDef.name || ('light_' + lightIndex));
		dependency = Promise.resolve(lightNode);
		this.parser.cache.add(cacheKey, dependency);
		return dependency;
	}

	public function getDependency(type:String, index:Int):Dynamic {
		if (type !== 'light') return null;
		return this._loadLight(index);
	}

	public function createNodeAttachment(nodeIndex:Int):Promise<Dynamic> {
		var lightIndex = this.parser.json.nodes[nodeIndex].extensions[this.name].light;
		if (lightIndex === undefined) return null;
		return this._loadLight(lightIndex).then(function(light) {
			return this.parser._getNodeRef(this.cache, lightIndex, light);
		});
	}
}