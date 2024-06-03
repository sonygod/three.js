import js.Browser.console;
import js.Array;
import js.html.ArrayBuffer;
import js.html.Float32Array;

class GLTFLightExtension {
    private var writer: Dynamic;
    private var name: String;
    private var json: Dynamic;
    private var extensionsUsed: Dynamic;

    public function new(writer: Dynamic) {
        this.writer = writer;
        this.name = 'KHR_lights_punctual';
        this.json = writer.json;
        this.extensionsUsed = writer.extensionsUsed;
    }

    public function writeNode(light: Dynamic, nodeDef: Dynamic): Void {
        if (!light.isLight) return;

        if (!light.isDirectionalLight && !light.isPointLight && !light.isSpotLight) {
            trace('THREE.GLTFExporter: Only directional, point, and spot lights are supported.', light);
            return;
        }

        var lightDef = { };

        if (light.name) lightDef.name = light.name;

        var colorArray: Array<Float> = new Array<Float>();
        colorArray.push(light.color.r);
        colorArray.push(light.color.g);
        colorArray.push(light.color.b);
        lightDef.color = colorArray;

        lightDef.intensity = light.intensity;

        if (light.isDirectionalLight) {
            lightDef.type = 'directional';
        } else if (light.isPointLight) {
            lightDef.type = 'point';
            if (light.distance > 0) lightDef.range = light.distance;
        } else if (light.isSpotLight) {
            lightDef.type = 'spot';
            if (light.distance > 0) lightDef.range = light.distance;

            var spot = { };
            spot.innerConeAngle = (1.0 - light.penumbra) * light.angle;
            spot.outerConeAngle = light.angle;
            lightDef.spot = spot;
        }

        if (light.decay !== undefined && light.decay !== 2) {
            trace('THREE.GLTFExporter: Light decay may be lost. glTF is physically-based, and expects light.decay=2.');
        }

        if (light.target && (light.target.parent !== light || light.target.position.x !== 0 || light.target.position.y !== 0 || light.target.position.z !== -1)) {
            trace('THREE.GLTFExporter: Light direction may be lost. For best results, make light.target a child of the light with position 0,0,-1.');
        }

        if (!this.extensionsUsed[this.name]) {
            if (this.json.extensions == null) this.json.extensions = { };
            this.json.extensions[this.name] = { lights: [] };
            this.extensionsUsed[this.name] = true;
        }

        var lights = this.json.extensions[this.name].lights;
        lights.push(lightDef);

        if (nodeDef.extensions == null) nodeDef.extensions = { };
        nodeDef.extensions[this.name] = { light: lights.length - 1 };
    }
}