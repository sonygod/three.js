import h3d.Matrix4;
import h3d.Vector2;
import h3d.Vector4;
import js.Browser;
import js.lib.three.Clock;
import js.lib.three.Color;
import js.lib.three.Material;
import js.lib.three.Mesh;
import js.lib.three.RepeatWrapping;
import js.lib.three.ShaderMaterial;
import js.lib.three.TextureLoader;
import js.lib.three.UniformsLib;
import js.lib.three.UniformsUtils;

class Water extends Mesh {
    public isWater: Bool;
    public type: String;
    public scope: Water;
    public color: Color;
    public textureWidth: Int;
    public textureHeight: Int;
    public clipBias: Float;
    public flowDirection: Vector2;
    public flowSpeed: Float;
    public reflectivity: Float;
    public scale: Float;
    public shader: { name: String, uniforms: { [key: String]: { type: String, value: ?Color | Float | Matrix4 | Vector4 | String } }, vertexShader: String, fragmentShader: String };
    public textureLoader: TextureLoader;
    public flowMap: ?Texture;
    public normalMap0: Texture;
    public normalMap1: Texture;
    public cycle: Float;
    public halfCycle: Float;
    public textureMatrix: Matrix4;
    public clock: Clock;
    public reflector: Reflector;
    public refractor: Refractor;
    public material: Material;
    public function new(geometry: { }, options: { color: ?Color, textureWidth: ?Int, textureHeight: ?Int, clipBias: ?Float, flowDirection: ?Vector2, flowSpeed: ?Float, reflectivity: ?Float, scale: ?Float, shader: ?{ name: String, uniforms: { [key: String]: { type: String, value: ?Color | Float | Matrix4 | Vector4 | String } }, vertexShader: String, fragmentShader: String } }) {
        super(geometry);
        this.isWater = true;
        this.type = 'Water';
        this.scope = this;
        this.color = options.color != null ? options.color : new Color(0xFFFFFF);
        this.textureWidth = options.textureWidth != null ? options.textureWidth : 512;
        this.textureHeight = options.textureHeight != null ? options.textureHeight : 512;
        this.clipBias = options.clipBias != null ? options.clipBias : 0.0;
        this.flowDirection = options.flowDirection != null ? options.flowDirection : new Vector2(1.0, 0.0);
        this.flowSpeed = options.flowSpeed != null ? options.flowSpeed : 0.03;
        this.reflectivity = options.reflectivity != null ? options.reflectivity : 0.02;
        this.scale = options.scale != null ? options.scale : 1.0;
        this.shader = options.shader != null ? options.shader : Water.WaterShader;
        this.textureLoader = new TextureLoader();
        this.flowMap = options.flowMap;
        this.normalMap0 = options.normalMap0 != null ? options.normalMap0 : this.textureLoader.load('textures/water/Water_1_M_Normal.jpg');
        this.normalMap1 = options.normalMap1 != null ? options.normalMap1 : this.textureLoader.load('textures/water/Water_2_M_Normal.jpg');
        this.cycle = 0.15;
        this.halfCycle = this.cycle * 0.5;
        this.textureMatrix = new Matrix4();
        this.clock = new Clock();
        if (Reflector == null) {
            Browser.console.error('THREE.Water: Required component Reflector not found.');
            return;
        }
        if (Refractor == null) {
            Browser.console.error('THREE.Water: Required component Refractor not found.');
            return;
        }
        this.reflector = new Reflector(geometry, { textureWidth: this.textureWidth, textureHeight: this.textureHeight, clipBias: this.clipBias });
        this.refractor = new Refractor(geometry, { textureWidth: this.textureWidth, textureHeight: this.textureHeight, clipBias: this.clipBias });
        this.reflector.matrixAutoUpdate = false;
        this.refractor.matrixAutoUpdate = false;
        this.material = new ShaderMaterial({ name: this.shader.name, uniforms: UniformsUtils.merge([UniformsLib['fog'], this.shader.uniforms]), vertexShader: this.shader.vertexShader, fragmentShader: this.shader.fragmentShader, transparent: true, fog: true });
        if (this.flowMap != null) {
            this.material.defines.USE_FLOWMAP = '';
            this.material.uniforms['tFlowMap'] = { type: 't', value: this.flowMap };
        } else {
            this.material.uniforms['flowDirection'] = { type: 'v2', value: this.flowDirection };
        }
        this.normalMap0.wrapS = this.normalMap0.wrapT = RepeatWrapping.Repeat;
        this.normalMap1.wrapS = this.normalMap1.wrapT = RepeatWrapping.Repeat;
        this.material.uniforms['tReflectionMap'].value = this.reflector.getRenderTarget().texture;
        this.material.uniforms['tRefractionMap'].value = this.refractor.getRenderTarget().texture;
        this.material.uniforms['tNormalMap0'].value = this.normalMap0;
        this.material.uniforms['tNormalMap1'].value = this.normalMap1;
        this.material.uniforms['color'].value = this.color;
        this.material.uniforms['reflectivity'].value = this.reflectivity;
        this.material.uniforms['textureMatrix'].value = this.textureMatrix;
        this.material.uniforms['config'].value.x = 0.0;
        this.material.uniforms['config'].value.y = this.halfCycle;
        this.material.uniforms['config'].value.z = this.halfCycle;
        this.material.uniforms['config'].value.w = this.scale;
        this.onBeforeRender = function (renderer, scene, camera) {
            this.updateTextureMatrix(camera);
            this.updateFlow();
            this.visible = false;
            this.reflector.matrixWorld.copy(this.matrixWorld);
            this.refractor.matrixWorld.copy(this.matrixWorld);
            this.reflector.onBeforeRender(renderer, scene, camera);
            this.refractor.onBeforeRender(renderer, scene, camera);
            this.visible = true;
        };
    }
    public function updateTextureMatrix(camera: { projectionMatrix: Matrix4, matrixWorldInverse: Matrix4 }) {
        this.textureMatrix.set(0.5, 0.0, 0.0, 0.5, 0.0, 0.5, 0.0, 0.5, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.0, 1.0);
        this.textureMatrix.multiply(camera.projectionMatrix);
        this.textureMatrix.multiply(camera.matrixWorldInverse);
        this.textureMatrix.multiply(this.matrixWorld);
    }
    public function updateFlow() {
        var delta = this.clock.getDelta();
        var config = this.material.uniforms['config'];
        config.value.x += this.flowSpeed * delta;
        config.value.y = config.value.x + this.halfCycle;
        if (config.value.x >= this.cycle) {
            config.value.x = 0.0;
            config.value.y = this.halfCycle;
        } else if (config.value.y >= this.cycle) {
            config.value.y -= this.cycle;
        }
    }
}
class Reflector {
    public matrixAutoUpdate: Bool;
    public matrixWorld: Matrix4;
    public function new(geometry: { }, options: { textureWidth: Int, textureHeight: Int, clipBias: Float }) {
        this.matrixAutoUpdate = false;
    }
    public function getRenderTarget() {
        return null;
    }
    public function onBeforeRender(renderer: { }, scene: { }, camera: { }) {
    }
}
class Refractor {
    public matrixAutoUpdate: Bool;
    public matrixWorld: Matrix4;
    public function new(geometry: { }, options: { textureWidth: Int, textureHeight: Int, clipBias: Float }) {
        this.matrixAutoUpdate = false;
    }
    public function getRenderTarget() {
        return null;
    }
    public function onBeforeRender(renderer: { }, scene: { }, camera: { }) {
    }
}
Water.WaterShader = { name: 'WaterShader', uniforms: { 'color': { type: 'c', value: null }, 'reflectivity': { type: 'f', value: 0.0 }, 'tReflectionMap': { type: 't', value: null }, 'tRefractionMap': { type: 't', value: null }, 'tNormalMap0': { type: 't', value: null }, 'tNormalMap1': { type: 't', value: null }, 'textureMatrix': { type: 'm4', value: null }, 'config': { type: 'v4', value: new Vector4() } }, vertexShader: '#include <common>\n#include <fog_pars_vertex>\n#include <logdepthbuf_pars_vertex>\n\nuniform mat4 textureMatrix;\n\nvarying vec4 vCoord;\nvarying vec2 vUv;\nvarying vec3 vToEye;\n\nvoid main() {\n\n    vUv = uv;\n    vCoord = textureMatrix * vec4( position, 1.0 );\n\n    vec4 worldPosition = modelMatrix * vec4( position, 1.0 );\n    vToEye = cameraPosition - worldPosition.xyz;\n\n    vec4 mvPosition = viewMatrix * worldPosition; // used in fog_vertex\n    gl_Position = projectionMatrix * mvPosition;\n\n    #include <logdepthbuf_vertex>\n    #include <fog_vertex>\n\n}', fragmentShader: '#include <common>\n#include <fog_pars_fragment>\n#include <logdepthbuf_pars_fragment>\n\nuniform sampler2D tReflectionMap;\nuniform sampler2D tRefractionMap;\nuniform sampler2D tNormalMap0;\nuniform sampler2D tNormalMap1;\n\n#ifdef USE_FLOWMAP\n    uniform sampler2D tFlowMap;\n#else\n    uniform vec2 flowDirection;\n#endif\n\nuniform vec3 color;\nuniform float reflectivity;\nuniform vec4 config;\n\nvarying vec4 vCoord;\nvarying vec2 vUv;\nvarying vec3 vToEye;\n\nvoid main() {\n\n    #include <logdepthbuf_fragment>\n\n    float flowMapOffset0 = config.x;\n    float flowMapOffset1 = config.y;\n    float halfCycle = config.z;\n    float scale = config.w;\n\n    vec3 toEye = normalize( vToEye );\n\n    // determine flow direction\n    vec2 flow;\n    #ifdef USE_FLOWMAP\n        flow = texture2D( tFlowMap, vUv ).rg * 2.0 - 1.0;\n    #else\n        flow = flowDirection;\n    #endif\n    flow.x *= - 1.0;\n\n    // sample normal maps (distort uvs with flowdata)\n    vec4 normalColor0 = texture2D( tNormalMap0, ( vUv * scale ) + flow * flowMapOffset0 );\n    vec4 normalColor1 = texture2D( tNormalMap1, ( vUv * scale ) + flow * flowMapOffset1 );\n\n    // linear interpolate to get the final normal color\n    float flowLerp = abs( halfCycle - flowMapOffset0 ) / halfCycle;\n    vec4 normalColor = mix( normalColor0, normalColor1, flowLerp );\n\n    // calculate normal vector\n    vec3 normal = normalize( vec3( normalColor.r * 2.0 - 1.0, normalColor.b,  normalColor.g * 2.0 - 1.0 ) );\n\n    // calculate the fresnel term to blend reflection and refraction maps\n    float theta = max( dot( toEye, normal ), 0.0 );\n    float reflectance = reflectivity + ( 1.0 - reflectivity ) * pow( ( 1.0 - theta ), 5.0 );\n\n    // calculate final uv coords\n    vec3 coord = vCoord.xyz / vCoord.w;\n    vec2 uv = coord.xy + coord.z * normal.xz * 0.05;\n\n    vec4 reflectColor = texture2D( tReflectionMap, vec2( 1.0 - uv.x, uv.y ) );\n    vec4 refractColor = texture2D( tRefractionMap, uv );\n\n    // multiply water color with the mix of both textures\n    gl_FragColor = vec4( color, 1.0 ) * mix( refractColor, reflectColor, reflectance );\n\n    #include <tonemapping_fragment>\n    #include <colorspace_fragment>\n    #include <fog_fragment>\n\n}' };