import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;

class PoissonDenoiseShader {

    public static var name:String = "PoissonDenoiseShader";

    public static var defines:haxe.ds.StringMap = new haxe.ds.StringMap();
    public static var uniforms:haxe.ds.StringMap = new haxe.ds.StringMap();

    public static function new() {
        defines.set("SAMPLES", 16);
        defines.set("SAMPLE_VECTORS", generatePdSamplePointInitializer(16, 2, 1));
        defines.set("NORMAL_VECTOR_TYPE", 1);
        defines.set("DEPTH_VALUE_SOURCE", 0);

        uniforms.set("tDiffuse", { value: null });
        uniforms.set("tNormal", { value: null });
        uniforms.set("tDepth", { value: null });
        uniforms.set("tNoise", { value: null });
        uniforms.set("resolution", { value: new Vector2() });
        uniforms.set("cameraProjectionMatrixInverse", { value: new Matrix4() });
        uniforms.set("lumaPhi", { value: 5. });
        uniforms.set("depthPhi", { value: 5. });
        uniforms.set("normalPhi", { value: 5. });
        uniforms.set("radius", { value: 4. });
        uniforms.set("index", { value: 0 });
    }

    public static var vertexShader:String = `
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    `;

    public static var fragmentShader:String = `
        // The rest of the fragment shader code...
    `;

    public static function generatePdSamplePointInitializer(samples:Int, rings:Int, radiusExponent:Float):String {
        var poissonDisk = generateDenoiseSamples(samples, rings, radiusExponent);

        var glslCode:String = "vec3[SAMPLES](";

        for (var i:Int = 0; i < samples; i++) {
            var sample = poissonDisk[i];
            glslCode += `vec3(${sample.x}, ${sample.y}, ${sample.z})${(i < samples - 1) ? ',' : ')'}`;
        }

        return glslCode;
    }

    public static function generateDenoiseSamples(numSamples:Int, numRings:Int, radiusExponent:Float):Array<Vector3> {
        var samples = new Array<Vector3>();

        for (var i:Int = 0; i < numSamples; i++) {
            var angle = 2 * Math.PI * numRings * i / numSamples;
            var radius = Math.pow(i / (numSamples - 1), radiusExponent);
            samples.push(new Vector3(Math.cos(angle), Math.sin(angle), radius));
        }

        return samples;
    }
}