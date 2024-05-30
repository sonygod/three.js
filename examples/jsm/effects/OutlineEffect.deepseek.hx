package three.js.examples.jsm.effects;

import three.js.BackSide;
import three.js.Color;
import three.js.ShaderMaterial;
import three.js.UniformsLib;
import three.js.UniformsUtils;

class OutlineEffect {

    public var enabled:Bool;
    public var autoClear:Bool;
    public var domElement:Dynamic;
    public var shadowMap:Dynamic;

    private var cache:Dynamic;
    private var originalMaterials:Dynamic;
    private var originalOnBeforeRenders:Dynamic;
    private var renderer:Dynamic;

    public function new(renderer:Dynamic, parameters:Dynamic = null) {

        this.enabled = true;

        var defaultThickness = parameters != null && parameters.defaultThickness != null ? parameters.defaultThickness : 0.003;
        var defaultColor = new Color().fromArray(parameters != null && parameters.defaultColor != null ? parameters.defaultColor : [0, 0, 0]);
        var defaultAlpha = parameters != null && parameters.defaultAlpha != null ? parameters.defaultAlpha : 1.0;
        var defaultKeepAlive = parameters != null && parameters.defaultKeepAlive != null ? parameters.defaultKeepAlive : false;

        this.cache = {};
        this.originalMaterials = {};
        this.originalOnBeforeRenders = {};
        this.renderer = renderer;

        var uniformsOutline = {
            outlineThickness: { value: defaultThickness },
            outlineColor: { value: defaultColor },
            outlineAlpha: { value: defaultAlpha }
        };

        var vertexShader = [
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
            '   float thickness = outlineThickness;',
            '   const float ratio = 1.0;',
            '   vec4 pos2 = projectionMatrix * modelViewMatrix * vec4( skinned.xyz + normal, 1.0 );',
            '   vec4 norm = normalize( pos - pos2 );',
            '   return pos + norm * thickness * pos.w * ratio;',
            '}',

            'void main() {',

            '   #include <uv_vertex>',

            '   #include <beginnormal_vertex>',
            '   #include <morphnormal_vertex>',
            '   #include <skinbase_vertex>',
            '   #include <skinnormal_vertex>',

            '   #include <begin_vertex>',
            '   #include <morphtarget_vertex>',
            '   #include <skinning_vertex>',
            '   #include <displacementmap_vertex>',
            '   #include <project_vertex>',

            '   vec3 outlineNormal = - objectNormal;',

            '   gl_Position = calculateOutline( gl_Position, outlineNormal, vec4( transformed, 1.0 ) );',

            '   #include <logdepthbuf_vertex>',
            '   #include <clipping_planes_vertex>',
            '   #include <fog_vertex>',

            '}'

        ].join('\n');

        var fragmentShader = [

            '#include <common>',
            '#include <fog_pars_fragment>',
            '#include <logdepthbuf_pars_fragment>',
            '#include <clipping_planes_pars_fragment>',

            'uniform vec3 outlineColor;',
            'uniform float outlineAlpha;',

            'void main() {',

            '   #include <clipping_planes_fragment>',
            '   #include <logdepthbuf_fragment>',

            '   gl_FragColor = vec4( outlineColor, outlineAlpha );',

            '   #include <tonemapping_fragment>',
            '   #include <colorspace_fragment>',
            '   #include <fog_fragment>',
            '   #include <premultiplied_alpha_fragment>',

            '}'

        ].join('\n');

        function createMaterial() {

            return new ShaderMaterial({
                type: 'OutlineEffect',
                uniforms: UniformsUtils.merge([
                    UniformsLib['fog'],
                    UniformsLib['displacementmap'],
                    uniformsOutline
                ]),
                vertexShader: vertexShader,
                fragmentShader: fragmentShader,
                side: BackSide
            });

        }

        function getOutlineMaterialFromCache(originalMaterial) {

            var data = cache[originalMaterial.uuid];

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

        function getOutlineMaterial(originalMaterial) {

            var outlineMaterial = getOutlineMaterialFromCache(originalMaterial);

            originalMaterials[outlineMaterial.uuid] = originalMaterial;

            updateOutlineMaterial(outlineMaterial, originalMaterial);

            return outlineMaterial;

        }

        function isCompatible(object) {

            var geometry = object.geometry;
            var hasNormals = (geometry != null) && (geometry.attributes.normal != null);

            return (object.isMesh == true && object.material != null && hasNormals == true);

        }

        function setOutlineMaterial(object) {

            if (isCompatible(object) == false) return;

            if (object.material instanceof Array) {

                for (var i = 0, il = object.material.length; i < il; i++) {

                    object.material[i] = getOutlineMaterial(object.material[i]);

                }

            } else {

                object.material = getOutlineMaterial(object.material);

            }

            originalOnBeforeRenders[object.uuid] = object.onBeforeRender;
            object.onBeforeRender = onBeforeRender;

        }

        function restoreOriginalMaterial(object) {

            if (isCompatible(object) == false) return;

            if (object.material instanceof Array) {

                for (var i = 0, il = object.material.length; i < il; i++) {

                    object.material[i] = originalMaterials[object.material[i].uuid];

                }

            } else {

                object.material = originalMaterials[object.material.uuid];

            }

            object.onBeforeRender = originalOnBeforeRenders[object.uuid];

        }

        function onBeforeRender(renderer, scene, camera, geometry, material) {

            var originalMaterial = originalMaterials[material.uuid];

            if (originalMaterial == null) return;

            updateUniforms(material, originalMaterial);

        }

        function updateUniforms(material, originalMaterial) {

            var outlineParameters = originalMaterial.userData.outlineParameters;

            material.uniforms.outlineAlpha.value = originalMaterial.opacity;

            if (outlineParameters != null) {

                if (outlineParameters.thickness != null) material.uniforms.outlineThickness.value = outlineParameters.thickness;
                if (outlineParameters.color != null) material.uniforms.outlineColor.value.fromArray(outlineParameters.color);
                if (outlineParameters.alpha != null) material.uniforms.outlineAlpha.value = outlineParameters.alpha;

            }

            if (originalMaterial.displacementMap) {

                material.uniforms.displacementMap.value = originalMaterial.displacementMap;
                material.uniforms.displacementScale.value = originalMaterial.displacementScale;
                material.uniforms.displacementBias.value = originalMaterial.displacementBias;

            }

        }

        function updateOutlineMaterial(material, originalMaterial) {

            if (material.name == 'invisible') return;

            var outlineParameters = originalMaterial.userData.outlineParameters;

            material.fog = originalMaterial.fog;
            material.toneMapped = originalMaterial.toneMapped;
            material.premultipliedAlpha = originalMaterial.premultipliedAlpha;
            material.displacementMap = originalMaterial.displacementMap;

            if (outlineParameters != null) {

                if (originalMaterial.visible == false) {

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

            if (originalMaterial.wireframe == true || originalMaterial.depthTest == false) material.visible = false;

            if (originalMaterial.clippingPlanes) {

                material.clipping = true;

                material.clippingPlanes = originalMaterial.clippingPlanes;
                material.clipIntersection = originalMaterial.clipIntersection;
                material.clipShadows = originalMaterial.clipShadows;

            }

            material.version = originalMaterial.version;

        }

        function cleanupCache() {

            var keys = Object.keys(originalMaterials);

            for (var i = 0, il = keys.length; i < il; i++) {

                originalMaterials[keys[i]] = null;

            }

            keys = Object.keys(originalOnBeforeRenders);

            for (var i = 0, il = keys.length; i < il; i++) {

                originalOnBeforeRenders[keys[i]] = null;

            }

            keys = Object.keys(cache);

            for (var i = 0, il = keys.length; i < il; i++) {

                var key = keys[i];

                if (cache[key].used == false) {

                    cache[key].count++;

                    if (cache[key].keepAlive == false && cache[key].count > 60) {

                        delete cache[key];

                    }

                } else {

                    cache[key].used = false;
                    cache[key].count = 0;

                }

            }

        }

        this.render = function(scene, camera) {

            if (this.enabled == false) {

                renderer.render(scene, camera);
                return;

            }

            var currentAutoClear = renderer.autoClear;
            renderer.autoClear = this.autoClear;

            renderer.render(scene, camera);

            renderer.autoClear = currentAutoClear;

            this.renderOutline(scene, camera);

        };

        this.renderOutline = function(scene, camera) {

            var currentAutoClear = renderer.autoClear;
            var currentSceneAutoUpdate = scene.matrixWorldAutoUpdate;
            var currentSceneBackground = scene.background;
            var currentShadowMapEnabled = renderer.shadowMap.enabled;

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

        };

        this.clear = function(color, depth, stencil) {

            renderer.clear(color, depth, stencil);

        };

        this.getPixelRatio = function() {

            return renderer.getPixelRatio();

        };

        this.setPixelRatio = function(value) {

            renderer.setPixelRatio(value);

        };

        this.getSize = function(target) {

            return renderer.getSize(target);

        };

        this.setSize = function(width, height, updateStyle) {

            renderer.setSize(width, height, updateStyle);

        };

        this.setViewport = function(x, y, width, height) {

            renderer.setViewport(x, y, width, height);

        };

        this.setScissor = function(x, y, width, height) {

            renderer.setScissor(x, y, width, height);

        };

        this.setScissorTest = function(boolean) {

            renderer.setScissorTest(boolean);

        };

        this.setRenderTarget = function(renderTarget) {

            renderer.setRenderTarget(renderTarget);

        };

    }

}