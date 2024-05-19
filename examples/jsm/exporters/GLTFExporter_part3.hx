package three.js.examples.jsm.exporters;

import haxe.Json;

class GLTFLightExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_lights_punctual';
    }

    public function writeNode(light:Dynamic, nodeDef:Dynamic) {
        if (!light.isLight) return;

        if (!light.isDirectionalLight && !light.isPointLight && !light.isSpotLight) {
            trace('THREE.GLTFExporter: Only directional, point, and spot lights are supported.', light);
            return;
        }

        var writer:Dynamic = this.writer;
        var json:Dynamic = writer.json;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var lightDef:Dynamic = {};

        if (light.name != null) lightDef.name = light.name;

        lightDef.color = light.color.toArray();

        lightDef.intensity = light.intensity;

        if (light.isDirectionalLight) {
            lightDef.type = 'directional';

        } else if (light.isPointLight) {
            lightDef.type = 'point';

            if (light.distance > 0) lightDef.range = light.distance;

        } else if (light.isSpotLight) {
            lightDef.type = 'spot';

            if (light.distance > 0) lightDef.range = light.distance;

            lightDef.spot = {};
            lightDef.spot.innerConeAngle = (1.0 - light.penumbra) * light.angle;
            lightDef.spot.outerConeAngle = light.angle;
        }

        if (light.decay != null && light.decay != 2) {
            trace('THREE.GLTFExporter: Light decay may be lost. glTF is physically-based, and expects light.decay=2.');
        }

        if (light.target != null && (light.target.parent != light || light.target.position.x != 0 || light.target.position.y != 0 || light.target.position.z != -1)) {
            trace('THREE.GLTFExporter: Light direction may be lost. For best results, make light.target a child of the light with position 0,0,-1.');
        }

        if (!extensionsUsed.exists(this.name)) {
            json.extensions = json.extensions || {};
            json.extensions[this.name] = { lights: [] };
            extensionsUsed[this.name] = true;
        }

        var lights:Array<Dynamic> = json.extensions[this.name].lights;
        lights.push(lightDef);

        nodeDef.extensions = nodeDef.extensions || {};
        nodeDef.extensions[this.name] = { light: lights.length - 1 };
    }
}