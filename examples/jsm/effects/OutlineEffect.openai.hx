package three.effects;

import three js.Lib;
import three js.animation.AnimationClip;
import three js.animation.AnimationMixer;
import three js.animation.KeyframeTrack;
import three js.loaders.LoadingManager;
import three js.loaders.ObjectLoader;
import three js.loaders.TextureLoader;
import three js.math.Euler;
import three js.math.Matrix4;
import three js.math.Quaternion;
import three js.math.Vector2;
import three js.math.Vector3;
import three js.objects.Group;
import three js.objects.Mesh;
import three js.scenes.Scene;
import three js.utils.Utils;

class OutlineEffect {
    public var enabled:Bool;
    public var cache:Map<String, Dynamic>;
    public var originalMaterials:Map<String, Dynamic>;
    public var originalOnBeforeRenders:Map<String, Dynamic>;

    public function new(renderer:Dynamic, parameters:Dynamic = {}) {
        enabled = true;

        var defaultThickness:Float = parameters.defaultThickness != null ? parameters.defaultThickness : 0.003;
        var defaultColor:Vector3 = new Vector3(parameters.defaultColor != null ? parameters.defaultColor : [0, 0, 0]);
        var defaultAlpha:Float = parameters.defaultAlpha != null ? parameters.defaultAlpha : 1.0;
        var defaultKeepAlive:Bool = parameters.defaultKeepAlive != null ? parameters.defaultKeepAlive : false;

        cache = new Map<String, Dynamic>();
        originalMaterials = new Map<String, Dynamic>();
        originalOnBeforeRenders = new Map<String, Dynamic>();

        var uniformsOutline:Dynamic = {
            outlineThickness: { value: defaultThickness },
            outlineColor: { value: defaultColor },
            outlineAlpha: { value: defaultAlpha }
        };

        var vertexShader:Array<String> = [
            '#include <common>',
            '#include <uv_pars_vertex>',
            '#include <displacementmap_pars_vertex>',
            '#include <fog_pars_vertex>',
            '#include <morphtarget_pars_vertex>',
            '#include <skinning_pars_vertex>',
            '#include <logdepthbuf_pars_vertex>',
            '#include <clipping_planes_pars_vertex>',
            'uniform float outlineThickness;',
            'vec4 calculateOutline( vec4 pos, vec3 normal, vec4 skinned ) {',
            '    float thickness = outlineThickness;',
            '    const float ratio = 1.0;', // TODO: support outline thickness ratio for each vertex
            '    vec4 pos2 = projectionMatrix * modelViewMatrix * vec4( skinned.xyz + normal, 1.0 );',
            '    vec4 norm = normalize( pos - pos2 );',
            '    return pos + norm * thickness * pos.w * ratio;',
            '}',
            'void main() {',
            '    #include <uv_vertex>',
            '    #include <beginnormal_vertex>',
            '    #include <morphnormal_vertex>',
            '    #include <skinbase_vertex>',
            '    #include <skinnormal_vertex>',
            '    #include <begin_vertex>',
            '    #include <morphtarget_vertex>',
            '    #include <skinning_vertex>',
            '    #include <displacementmap_vertex>',
            '    #include <project_vertex>',
            '    vec3 outlineNormal = - objectNormal;', // the outline material is always rendered with BackSide
            '    gl_Position = calculateOutline( gl_Position, outlineNormal, vec4( transformed, 1.0 ) );',
            '    #include <logdepthbuf_vertex>',
            '    #include <clipping_planes_vertex>',
            '    #include <fog_vertex>',
            '}'
        ].join('\n');

        var fragmentShader:Array<String> = [
            '#include <common>',
            '#include <fog_pars_fragment>',
            '#include <logdepthbuf_pars_fragment>',
            '#include <clipping_planes_pars_fragment>',
            'uniform vec3 outlineColor;',
            'uniform float outlineAlpha;',
            'void main() {',
            '    #include <clipping_planes_fragment>',
            '    #include <logdepthbuf_fragment>',
            '    gl_FragColor = vec4( outlineColor, outlineAlpha );',
            '    #include <tonemapping_fragment>',
            '    #include <colorspace_fragment>',
            '    #include <fog_fragment>',
            '    #include <premultiplied_alpha_fragment>',
            '}'
        ].join('\n');

        function createMaterial():ShaderMaterial {
            return new ShaderMaterial({
                type: 'OutlineEffect',
                uniforms: Utils.merge([
                    UniformsLib.fog,
                    UniformsLib.displacementmap,
                    uniformsOutline
                ]),
                vertexShader: vertexShader,
                fragmentShader: fragmentShader,
                side: BackSide
            });
        }

        function getOutlineMaterialFromCache(originalMaterial:Dynamic):Dynamic {
            var data:Dynamic = cache[originalMaterial.uuid];

            if (data == null) {
                data = {
                    material: createMaterial(),
                    used: true,
                    keepAlive: defaultKeepAlive,
                    count: 0
                };

                cache[originalMaterial.uuid] = data;
            }

            data.used = true;

            return data.material;
        }

        function getOutlineMaterial(originalMaterial:Dynamic):Dynamic {
            var outlineMaterial:Dynamic = getOutlineMaterialFromCache(originalMaterial);

            originalMaterials[outlineMaterial.uuid] = originalMaterial;

            updateOutlineMaterial(outlineMaterial, originalMaterial);

            return outlineMaterial;
        }

        function isCompatible(object:Dynamic):Bool {
            var geometry:Dynamic = object.geometry;
            var hasNormals:Bool = (geometry != null) && (geometry.attributes.normal != null);

            return (object.isMesh && object.material != null && hasNormals);
        }

        function setOutlineMaterial(object:Dynamic) {
            if (!isCompatible(object)) return;

            if (Std.is(object.material, Array)) {
                for (i in 0...object.material.length) {
                    object.material[i] = getOutlineMaterial(object.material[i]);
                }
            } else {
                object.material = getOutlineMaterial(object.material);
            }

            originalOnBeforeRenders[object.uuid] = object.onBeforeRender;
            object.onBeforeRender = onBeforeRender;
        }

        function restoreOriginalMaterial(object:Dynamic) {
            if (!isCompatible(object)) return;

            if (Std.is(object.material, Array)) {
                for (i in 0...object.material.length) {
                    object.material[i] = originalMaterials[object.material[i].uuid];
                }
            } else {
                object.material = originalMaterials[object.material.uuid];
            }

            object.onBeforeRender = originalOnBeforeRenders[object.uuid];
        }

        function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic) {
            var originalMaterial:Dynamic = originalMaterials[material.uuid];

            if (originalMaterial == null) return;

            updateUniforms(material, originalMaterial);
        }

        function updateUniforms(material:Dynamic, originalMaterial:Dynamic) {
            material.uniforms.outlineAlpha.value = originalMaterial.opacity;

            var outlineParameters:Dynamic = originalMaterial.userData.outlineParameters;

            if (outlineParameters != null) {
                if (outlineParameters.thickness != null) material.uniforms.outlineThickness.value = outlineParameters.thickness;
                if (outlineParameters.color != null) material.uniforms.outlineColor.value.fromArray(outlineParameters.color);
                if (outlineParameters.alpha != null) material.uniforms.outlineAlpha.value = outlineParameters.alpha;
            }

            if (originalMaterial.displacementMap != null) {
                material.uniforms.displacementMap.value = originalMaterial.displacementMap;
                material.uniforms.displacementScale.value = originalMaterial.displacementScale;
                material.uniforms.displacementBias.value = originalMaterial.displacementBias;
            }
        }

        function updateOutlineMaterial(material:Dynamic, originalMaterial:Dynamic) {
            if (material.name == 'invisible') return;

            var outlineParameters:Dynamic = originalMaterial.userData.outlineParameters;

            material.fog = originalMaterial.fog;
            material.toneMapped = originalMaterial.toneMapped;
            material.premultipliedAlpha = originalMaterial.premultipliedAlpha;
            material.displacementMap = originalMaterial.displacementMap;

            if (outlineParameters != null) {
                if (!originalMaterial.visible) {
                    material.visible = false;
                } else {
                    material.visible = (outlineParameters.visible != null) ? outlineParameters.visible : true;
                }

                material.transparent = (outlineParameters.alpha != null && outlineParameters.alpha < 1.0) ? true : originalMaterial.transparent;

                if (outlineParameters.keepAlive != null) cache[originalMaterial.uuid].keepAlive = outlineParameters.keepAlive;
            } else {
                material.transparent = originalMaterial.transparent;
                material.visible = originalMaterial.visible;
            }

            if (originalMaterial.wireframe || !originalMaterial.depthTest) material.visible = false;

            if (originalMaterial.clippingPlanes != null) {
                material.clipping = true;
                material.clippingPlanes = originalMaterial.clippingPlanes;
                material.clipIntersection = originalMaterial.clipIntersection;
                material.clipShadows = originalMaterial.clipShadows;
            }

            material.version = originalMaterial.version; // update outline material if necessary
        }

        function cleanupCache() {
            var keys:Array<String> = [];

            for (key in cache.keys()) {
                keys.push(key);
            }

            for (i in 0...keys.length) {
                var key:String = keys[i];

                if (!cache[key].used) {
                    cache[key].count++;

                    if (!cache[key].keepAlive && cache[key].count > 60) {
                        cache.remove(key);
                    }
                } else {
                    cache[key].used = false;
                    cache[key].count = 0;
                }
            }

            keys = [];

            for (key in originalMaterials.keys()) {
                keys.push(key);
            }

            for (i in 0...keys.length) {
                originalMaterials.remove(keys[i]);
            }

            keys = [];

            for (key in originalOnBeforeRenders.keys()) {
                keys.push(key);
            }

            for (i in 0...keys.length) {
                originalOnBeforeRenders.remove(keys[i]);
            }
        }

        public function render(scene:Dynamic, camera:Dynamic) {
            if (!enabled) {
                renderer.render(scene, camera);
                return;
            }

            var currentAutoClear:Bool = renderer.autoClear;
            renderer.autoClear = this.autoClear;

            renderer.render(scene, camera);

            renderer.autoClear = currentAutoClear;

            renderOutline(scene, camera);
        }

        public function renderOutline(scene:Dynamic, camera:Dynamic) {
            var currentAutoClear:Bool = renderer.autoClear;
            var currentSceneAutoUpdate:Bool = scene.matrixWorldAutoUpdate;
            var currentSceneBackground:Dynamic = scene.background;
            var currentShadowMapEnabled:Bool = renderer.shadowMap.enabled;

            scene.matrixWorldAutoUpdate = false;
            scene.background = null;
            renderer.autoClear = false;
            renderer.shadowMap.enabled = false;

            scene.traverse(setOutlineMaterial);

            renderer.render(scene, camera);

            scene.traverse(restoreOriginalMaterial);

            cleanupCache();

            scene.matrixWorldAutoUpdate = currentSceneAutoUpdate;
            scene.background = currentSceneBackground;
            renderer.autoClear = currentAutoClear;
            renderer.shadowMap.enabled = currentShadowMapEnabled;
        }

        // See #9918
        public var autoClear:Bool;
        public var domElement:Dynamic;
        public var shadowMap:Dynamic;

        public function clear(color:Dynamic, depth:Dynamic, stencil:Dynamic) {
            renderer.clear(color, depth, stencil);
        }

        public function getPixelRatio():Float {
            return renderer.getPixelRatio();
        }

        public function setPixelRatio(value:Float) {
            renderer.setPixelRatio(value);
        }

        public function getSize(target:Dynamic):Dynamic {
            return renderer.getSize(target);
        }

        public function setSize(width:Int, height:Int, updateStyle:Bool) {
            renderer.setSize(width, height, updateStyle);
        }

        public function setViewport(x:Float, y:Float, width:Float, height:Float) {
            renderer.setViewport(x, y, width, height);
        }

        public function setScissor(x:Float, y:Float, width:Float, height:Float) {
            renderer.setScissor(x, y, width, height);
        }

        public function setScissorTest(enabled:Bool) {
            renderer.setScissorTest(enabled);
        }

        public function setRenderTarget(renderTarget:Dynamic) {
            renderer.setRenderTarget(renderTarget);
        }
    }
}