package;

import js.three.BackSide;
import js.three.Color;
import js.three.Material;
import js.three.ShaderMaterial;
import js.three.UniformsLib;
import js.three.UniformsUtils;

class OutlineEffect {
    private enabled:Bool;
    private defaultThickness:Float;
    private defaultColor:Color;
    private defaultAlpha:Float;
    private defaultKeepAlive:Bool;
    private cache:Map<String, OutlineMaterialData>;
    private removeThresholdCount:Int;
    private originalMaterials:Map<String, Material>;
    private originalOnBeforeRenders:Map<String, Dynamic>;
    private uniformsOutline:Map<String, Dynamic>;
    private vertexShader:String;
    private fragmentShader:String;

    public function new(renderer:Dynamic, parameters:Map<String, Dynamic> = {}) {
        enabled = true;
        defaultThickness = parameters.defaultThickness.default(0.003);
        defaultColor = parameters.defaultColor.map($it -> new Color().fromArray($it)).default(new Color());
        defaultAlpha = parameters.defaultAlpha.default(1.0);
        defaultKeepAlive = parameters.defaultKeepAlive.default(false);
        cache = new Map();
        removeThresholdCount = 60;
        originalMaterials = new Map();
        originalOnBeforeRenders = new Map();
        uniformsOutline = {
            'outlineThickness' => { 'value' => defaultThickness },
            'outlineColor' => { 'value' => defaultColor },
            'outlineAlpha' => { 'value' => defaultAlpha }
        };
        vertexShader = [
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
            '	float thickness = outlineThickness;',
            '	const float ratio = 1.0;', // TODO: support outline thickness ratio for each vertex
            '	vec4 pos2 = projectionMatrix * modelViewMatrix * vec4( skinned.xyz + normal, 1.0 );',
            // NOTE: subtract pos2 from pos because BackSide objectNormal is negative
            '	vec4 norm = normalize( pos - pos2 );',
            '	return pos + norm * thickness * pos.w * ratio;',
            '}',
            'void main() {',
            '	#include <uv_vertex>',
            '	#include <beginnormal_vertex>',
            '	#include <morphnormal_vertex>',
            '	#include <skinbase_vertex>',
            '	#include <skinnormal_vertex>',
            '	#include <begin_vertex>',
            '	#include <morphtarget_vertex>',
            '	#include <skinning_vertex>',
            '	#include <displacementmap_vertex>',
            '	#include <project_vertex>',
            '	vec3 outlineNormal = - objectNormal;', // the outline material is always rendered with BackSide
            '	gl_Position = calculateOutline( gl_Position, outlineNormal, vec4( transformed, 1.0 ) );',
            '	#include <logdepthbuf_vertex>',
            '	#include <clipping_planes_vertex>',
            '	#include <fog_vertex>',
            '}'
        ].join('\n');
        fragmentShader = [
            '#include <common>',
            '#include <fog_pars_fragment>',
            '#include <logdepthbuf_pars_fragment>',
            '#include <clipping_planes_pars_fragment>',
            'uniform vec3 outlineColor;',
            'uniform float outlineAlpha;',
            'void main() {',
            '	#include <clipping_planes_fragment>',
            '	#include <logdepthbuf_fragment>',
            '	gl_FragColor = vec4( outlineColor, outlineAlpha );',
            '	#include <tonemapping_fragment>',
            '	#include <colorspace_fragment>',
            '	#include <fog_fragment>',
            '	#include <premultiplied_alpha_fragment>',
            '}'
        ].join('\n');
    }

    private function createMaterial():ShaderMaterial {
        return new ShaderMaterial({
            'type' => 'OutlineEffect',
            'uniforms' => UniformsUtils.merge([
                UniformsLib.fog,
                UniformsLib.displacementmap,
                uniformsOutline
            ]),
            'vertexShader' => vertexShader,
            'fragmentShader' => fragmentShader,
            'side' => BackSide
        });
    }

    private function getOutlineMaterialFromCache(originalMaterial:Material):ShaderMaterial {
        var data = cache.get(originalMaterial.uuid);
        if (data == null) {
            data = {
                'material' => createMaterial(),
                'used' => true,
                'keepAlive' => defaultKeepAlive,
                'count' => 0
            };
            cache.set(originalMaterial.uuid, data);
        }
        data.used = true;
        return data.material;
    }

    private function getOutlineMaterial(originalMaterial:Material):ShaderMaterial {
        var outlineMaterial = getOutlineMaterialFromCache(originalMaterial);
        originalMaterials.set(outlineMaterial.uuid, originalMaterial);
        updateOutlineMaterial(outlineMaterial, originalMaterial);
        return outlineMaterial;
    }

    private function isCompatible(object:Dynamic):Bool {
        var geometry = object.geometry;
        var hasNormals = geometry != null && geometry.attributes.normal != null;
        return object.isMesh && object.material != null && hasNormals;
    }

    private function setOutlineMaterial(object:Dynamic) {
        if (!isCompatible(object)) {
            return;
        }
        if (object.material instanceof Array) {
            for (i in 0...object.material.length) {
                object.material[i] = getOutlineMaterial(object.material[i]);
            }
        } else {
            object.material = getOutlineMaterial(object.material);
        }
        originalOnBeforeRenders.set(object.uuid, object.onBeforeRender);
        object.onBeforeRender = onBeforeRender;
    }

    private function restoreOriginalMaterial(object:Dynamic) {
        if (!isCompatible(object)) {
            return;
        }
        if (object.material instanceof Array) {
            for (i in 0...object.material.length) {
                object.material[i] = originalMaterials.get(object.material[i].uuid);
            }
        } else {
            object.material = originalMaterials.get(object.material.uuid);
        }
        object.onBeforeRender = originalOnBeforeRenders.get(object.uuid);
    }

    private function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic) {
        var originalMaterial = originalMaterials.get(material.uuid);
        if (originalMaterial == null) {
            return;
        }
        updateUniforms(material, originalMaterial);
    }

    private function updateUniforms(material:Material, originalMaterial:Material) {
        var outlineParameters = originalMaterial.userData.outlineParameters;
        material.uniforms.outlineAlpha.value = originalMaterial.opacity;
        if (outlineParameters != null) {
            if (outlineParameters.thickness != null) {
                material.uniforms.outlineThickness.value = outlineParameters.thickness;
            }
            if (outlineParameters.color != null) {
                material.uniforms.outlineColor.value.fromArray(outlineParameters.color);
            }
            if (outlineParameters.alpha != null) {
                material.uniforms.outlineAlpha.value = outlineParameters.alpha;
            }
        }
        if (originalMaterial.displacementMap) {
            material.uniforms.displacementMap.value = originalMaterial.displacementMap;
            material.uniforms.displacementScale.value = originalMaterial.displacementScale;
            material.uniforms.displacementBias.value = originalMaterial.displacementBias;
        }
    }

    private function updateOutlineMaterial(material:Material, originalMaterial:Material) {
        if (material.name == 'invisible') {
            return;
        }
        var outlineParameters = originalMaterial.userData.outlineParameters;
        material.fog = originalMaterial.fog;
        material.toneMapped = originalMaterial.toneMapped;
        material.premultipliedAlpha = originalMaterial.premultipliedAlpha;
        material.displacementMap = originalMaterial.displacementMap;
        if (outlineParameters != null) {
            if (originalMaterial.visible == false) {
                material.visible = false;
            } else {
                material.visible = outlineParameters.visible.default(true);
            }
            material.transparent = (outlineParameters.alpha != null && outlineParameters.alpha < 1.0) ? true : originalMaterial.transparent;
            if (outlineParameters.keepAlive != null) {
                cache.get(originalMaterial.uuid).keepAlive = outlineParameters.keepAlive;
            }
        } else {
            material.transparent = originalMaterial.transparent;
            material.visible = originalMaterial.visible;
        }
        if (originalMaterial.wireframe || originalMaterial.depthTest == false) {
            material.visible = false;
        }
        if (originalMaterial.clippingPlanes) {
            material.clipping = true;
            material.clippingPlanes = originalMaterial.clippingPlanes;
            material.clipIntersection = originalMaterial.clipIntersection;
            material.clipShadows = originalMaterial.clipShadows;
        }
        material.version = originalMaterial.version;
    }

    private function cleanupCache() {
        var keys:Array<String>;
        // clear originalMaterials
        keys = originalMaterials.keys();
        for (key in keys) {
            originalMaterials.set(key, null);
        }
        // clear originalOnBeforeRenders
        keys = originalOnBeforeRenders.keys();
        for (key in keys) {
            originalOnBeforeRenders.set(key, null);
        }
        // remove unused outlineMaterial from cache
        keys = cache.keys();
        for (key in keys) {
            var data = cache.get(key);
            if (!data.used) {
                data.count++;
                if (!data.keepAlive && data.count > removeThresholdCount) {
                    cache.remove(key);
                }
            } else {
                data.used = false;
                data.count = 0;
            }
        }
    }

    public function render(scene:Dynamic, camera:Dynamic) {
        if (!enabled) {
            renderer.render(scene, camera);
            return;
        }
        var currentAutoClear = renderer.autoClear;
        renderer.autoClear = autoClear;
        renderer.render(scene, camera);
        renderer.autoClear = currentAutoClear;
        renderOutline(scene, camera);
    }

    public function renderOutline(scene:Dynamic, camera:Dynamic) {
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
    }

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

    public function setViewport(x:Int, y:Int, width:Int, height:Int) {
        renderer.setViewport(x, y, width, height);
    }

    public function setScissor(x:Int, y:Int, width:Int, height:Int) {
        renderer.setScissor(x, y, width, height);
    }

    public function setScissorTest(boolean:Bool) {
        renderer.setScissorTest(boolean);
    }

    public function setRenderTarget(renderTarget:Dynamic) {
        renderer.setRenderTarget(renderTarget);
    }
}

class OutlineMaterialData {
    public var material:ShaderMaterial;
    public var used:Bool;
    public var keepAlive:Bool;
    public var count:Int;
}