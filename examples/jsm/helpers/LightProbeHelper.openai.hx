package three.js.helpers;

import three.js.Mesh;
import three.js.ShaderMaterial;
import three.js.SphereGeometry;

class LightProbeHelper extends Mesh {

    public var lightProbe:Dynamic;
    public var size:Float;
    public var type:String;

    public function new(lightProbe:Dynamic, size:Float) {
        super(new SphereGeometry(1, 32, 16), createMaterial(lightProbe, size));
        this.lightProbe = lightProbe;
        this.size = size;
        this.type = "LightProbeHelper";
        onBeforeRender();
    }

    private function createMaterial(lightProbe:Dynamic, size:Float):ShaderMaterial {
        var material = new ShaderMaterial({
            type: 'LightProbeHelperMaterial',
            uniforms: {
                sh: { value: lightProbe.sh.coefficients },
                intensity: { value: lightProbe.intensity }
            },
            vertexShader: [
                'varying vec3 vNormal;',
                'void main() {',
                '    vNormal = normalize( normalMatrix * normal );',
                '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
                '}'
            ].join('\n'),
            fragmentShader: [
                '#define RECIPROCAL_PI 0.318309886',
                'vec3 inverseTransformDirection( in vec3 normal, in mat4 matrix ) {',
                '    return normalize( ( vec4( normal, 0.0 ) * matrix ).xyz );',
                '}',
                'vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {',
                '    // normal is assumed to have unit length',
                '    float x = normal.x, y = normal.y, z = normal.z;',
                '    vec3 result = shCoefficients[ 0 ] * 0.886227;',
                '    result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;',
                '    result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;',
                '    result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;',
                '    result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;',
                '    result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;',
                '    result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );',
                '    result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;',
                '    result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );',
                '    return result;',
                '}',
                'uniform vec3 sh[ 9 ];', // sh coefficients
                'uniform float intensity;', // light probe intensity
                'varying vec3 vNormal;',
                'void main() {',
                '    vec3 normal = normalize( vNormal );',
                '    vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );',
                '    vec3 irradiance = shGetIrradianceAt( worldNormal, sh );',
                '    vec3 outgoingLight = RECIPROCAL_PI * irradiance * intensity;',
                '    gl_FragColor = linearToOutputTexel( vec4( outgoingLight, 1.0 ) );',
                '}'
            ].join('\n')
        });
        return material;
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }

    public function onBeforeRender() {
        position.copy(lightProbe.position);
        scale.set(1, 1, 1).multiplyScalar(size);
        material.uniforms.intensity.value = lightProbe.intensity;
    }
}