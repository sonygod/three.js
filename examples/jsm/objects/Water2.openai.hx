package three.objects;

import three.Clock;
import three.Color;
import three.Matrix4;
import three.Mesh;
import three.RepeatWrapping;
import three.ShaderMaterial;
import three.TextureLoader;
import three.UniformsLib;
import three.UniformsUtils;
import three.Vector2;
import three.Vector4;
import three.objects.Reflector;
import three.objects.Refractor;

class Water extends Mesh {
    public var isWater:Bool;
    public var type:String;

    public function new(geometry:Geometry, ?options:Dynamic) {
        super(geometry);

        isWater = true;
        type = 'Water';

        var color:Color = options.color != null ? new Color(options.color) : new Color(0xFFFFFF);
        var textureWidth:Int = options.textureWidth != null ? options.textureWidth : 512;
        var textureHeight:Int = options.textureHeight != null ? options.textureHeight : 512;
        var clipBias:Float = options.clipBias != null ? options.clipBias : 0;
        var flowDirection:Vector2 = options.flowDirection != null ? options.flowDirection : new Vector2(1, 0);
        var flowSpeed:Float = options.flowSpeed != null ? options.flowSpeed : 0.03;
        var reflectivity:Float = options.reflectivity != null ? options.reflectivity : 0.02;
        var scale:Float = options.scale != null ? options.scale : 1;
        var shader:Dynamic = options.shader != null ? options.shader : Water.WaterShader;

        var textureLoader:TextureLoader = new TextureLoader();

        var flowMap:Texture = options.flowMap != null ? options.flowMap : null;
        var normalMap0:Texture = options.normalMap0 != null ? options.normalMap0 : textureLoader.load('textures/water/Water_1_M_Normal.jpg');
        var normalMap1:Texture = options.normalMap1 != null ? options.normalMap1 : textureLoader.load('textures/water/Water_2_M_Normal.jpg');

        var cycle:Float = 0.15;
        var halfCycle:Float = cycle * 0.5;
        var textureMatrix:Matrix4 = new Matrix4();
        var clock:Clock = new Clock();

        var reflector:Reflector = new Reflector(geometry, {
            textureWidth: textureWidth,
            textureHeight: textureHeight,
            clipBias: clipBias
        });

        var refractor:Refractor = new Refractor(geometry, {
            textureWidth: textureWidth,
            textureHeight: textureHeight,
            clipBias: clipBias
        });

        reflector.matrixAutoUpdate = false;
        refractor.matrixAutoUpdate = false;

        material = new ShaderMaterial({
            name: shader.name,
            uniforms: UniformsUtils.merge([
                UniformsLib.fog,
                shader.uniforms
            ]),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            transparent: true,
            fog: true
        });

        if (flowMap != null) {
            material.defines.USE_FLOWMAP = '';
            material.uniforms.tFlowMap = { type: 't', value: flowMap };
        } else {
            material.uniforms.flowDirection = { type: 'v2', value: flowDirection };
        }

        normalMap0.wrapS = normalMap0.wrapT = RepeatWrapping;
        normalMap1.wrapS = normalMap1.wrapT = RepeatWrapping;

        material.uniforms.tReflectionMap = { value: reflector.getRenderTarget().texture };
        material.uniforms.tRefractionMap = { value: refractor.getRenderTarget().texture };
        material.uniforms.tNormalMap0 = { value: normalMap0 };
        material.uniforms.tNormalMap1 = { value: normalMap1 };

        material.uniforms.color = { value: color };
        material.uniforms.reflectivity = { value: reflectivity };
        material.uniforms.textureMatrix = { value: textureMatrix };

        material.uniforms.config = { value: new Vector4(0, halfCycle, halfCycle, scale) };

        onBeforeRender = function(renderer:Renderer, scene:Scene, camera:Camera) {
            updateTextureMatrix(camera);
            updateFlow();

            visible = false;

            reflector.matrixWorld.copy(matrixWorld);
            refractor.matrixWorld.copy(matrixWorld);

            reflector.onBeforeRender(renderer, scene, camera);
            refractor.onBeforeRender(renderer, scene, camera);

            visible = true;
        };

        function updateTextureMatrix(camera:Camera) {
            textureMatrix.set(
                0.5, 0.0, 0.0, 0.5,
                0.0, 0.5, 0.0, 0.5,
                0.0, 0.0, 0.5, 0.5,
                0.0, 0.0, 0.0, 1.0
            );

            textureMatrix.multiply(camera.projectionMatrix);
            textureMatrix.multiply(camera.matrixWorldInverse);
            textureMatrix.multiply(matrixWorld);
        }

        function updateFlow() {
            var delta:Float = clock.getDelta();
            var config:Vector4 = material.uniforms.config.value;

            config.x += flowSpeed * delta;
            config.y = config.x + halfCycle;

            if (config.x >= cycle) {
                config.x = 0;
                config.y = halfCycle;
            } else if (config.y >= cycle) {
                config.y = config.y - cycle;
            }
        }
    }
}

class WaterShader {
    public static var name:String = 'WaterShader';

    public static var uniforms:Dynamic = {
        color: { type: 'c', value: null },
        reflectivity: { type: 'f', value: 0 },
        tReflectionMap: { type: 't', value: null },
        tRefractionMap: { type: 't', value: null },
        tNormalMap0: { type: 't', value: null },
        tNormalMap1: { type: 't', value: null },
        textureMatrix: { type: 'm4', value: null },
        config: { type: 'v4', value: new Vector4() }
    };

    public static var vertexShader:String = /* glsl */
        "
        #include <common>
        #include <fog_pars_vertex>
        #include <logdepthbuf_pars_vertex>

        uniform mat4 textureMatrix;

        varying vec4 vCoord;
        varying vec2 vUv;
        varying vec3 vToEye;

        void main() {
            vUv = uv;
            vCoord = textureMatrix * vec4(position, 1.0);

            vec4 worldPosition = modelMatrix * vec4(position, 1.0);
            vToEye = cameraPosition - worldPosition.xyz;

            vec4 mvPosition = viewMatrix * worldPosition; // used in fog_vertex
            gl_Position = projectionMatrix * mvPosition;

            #include <logdepthbuf_vertex>
            #include <fog_vertex>
        }
        ";

    public static var fragmentShader:String = /* glsl */
        "
        #include <common>
        #include <fog_pars_fragment>
        #include <logdepthbuf_pars_fragment>

        uniform sampler2D tReflectionMap;
        uniform sampler2D tRefractionMap;
        uniform sampler2D tNormalMap0;
        uniform sampler2D tNormalMap1;

        #ifdef USE_FLOWMAP
            uniform sampler2D tFlowMap;
        #else
            uniform vec2 flowDirection;
        #endif

        uniform vec3 color;
        uniform float reflectivity;
        uniform vec4 config;

        varying vec4 vCoord;
        varying vec2 vUv;
        varying vec3 vToEye;

        void main() {
            #include <logdepthbuf_fragment>

            float flowMapOffset0 = config.x;
            float flowMapOffset1 = config.y;
            float halfCycle = config.z;
            float scale = config.w;

            vec3 toEye = normalize(vToEye);

            // determine flow direction
            vec2 flow;
            #ifdef USE_FLOWMAP
                flow = texture2D(tFlowMap, vUv).rg * 2.0 - 1.0;
            #else
                flow = flowDirection;
            #endif
            flow.x *= -1.0;

            // sample normal maps (distort uvs with flowdata)
            vec4 normalColor0 = texture2D(tNormalMap0, (vUv * scale) + flow * flowMapOffset0);
            vec4 normalColor1 = texture2D(tNormalMap1, (vUv * scale) + flow * flowMapOffset1);

            // linear interpolate to get the final normal color
            float flowLerp = abs(halfCycle - flowMapOffset0) / halfCycle;
            vec4 normalColor = mix(normalColor0, normalColor1, flowLerp);

            // calculate normal vector
            vec3 normal = normalize(vec3(normalColor.r * 2.0 - 1.0, normalColor.b, normalColor.g * 2.0 - 1.0));

            // calculate the fresnel term to blend reflection and refraction maps
            float theta = max(dot(toEye, normal), 0.0);
            float reflectance = reflectivity + (1.0 - reflectivity) * pow((1.0 - theta), 5.0);

            // calculate final uv coords
            vec3 coord = vCoord.xyz / vCoord.w;
            vec2 uv = coord.xy + coord.z * normal.xz * 0.05;

            vec4 reflectColor = texture2D(tReflectionMap, vec2(1.0 - uv.x, uv.y));
            vec4 refractColor = texture2D(tRefractionMap, uv);

            // multiply water color with the mix of both textures
            gl_FragColor = vec4(color, 1.0) * mix(refractColor, reflectColor, reflectance);

            #include <tonemapping_fragment>
            #include <colorspace_fragment>
            #include <fog_fragment>
        }
        ";
}