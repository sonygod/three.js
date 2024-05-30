class GLTFLightExtension {
    var writer: GLTFWriter;
    var name: String = 'KHR_lights_punctual';

    public function new(writer: GLTFWriter) {
        this.writer = writer;
    }

    public function writeNode(light: Light, nodeDef: InterleavedBuffer) {
        if (!light.isLight) return;

        if (!light.isDirectionalLight && !light.isPointLight && !light.isSpotLight) {
            trace('GLTFExporter: Only directional, point, and spot lights are supported.', light);
            return;
        }

        var json = writer.json;
        var extensionsUsed = writer.extensionsUsed;

        var lightDef = {
            name: light.name,
            color: light.color.toArray(),
            intensity: light.intensity
        };

        if (light.isDirectionalLight) {
            lightDef.type = 'directional';
        } else if (light.isPointLight) {
            lightDef.type = 'point';
            if (light.distance > 0) lightDef.range = light.distance;
        } else if (light.isSpotLight) {
            lightDef.type = 'spot';
            if (light.distance > 0) lightDef.range = light.distance;
            lightDef.spot = {
                innerConeAngle: (1.0 - light.penumbra) * light.angle,
                outerConeAngle: light.angle
            };
        }

        if (light.decay != null && light.decay != 2) {
            trace('GLTFExporter: Light decay may be lost. glTF is physically-based, and expects light.decay=2.');
        }

        if (light.target != null && (light.target.parent != light || light.target.position.x != 0 || light.target.position.y != 0 || light.target.position.z != -1)) {
            trace('GLTFExporter: Light direction may be lost. For best results, make light.target a child of the light with position 0,0,-1.');
        }

        if (!extensionsUsed.exists(name)) {
            json.extensions = json.extensions ?? { };
            json.extensions[name] = { lights: [] };
            extensionsUsed[name] = true;
        }

        var lights = json.extensions[name].lights;
        lights.push(lightDef);

        nodeDef.extensions = nodeDef.extensions ?? { };
        nodeDef.extensions[name] = { light: lights.length - 1 };
    }
}