import three.Color;
import three.ShaderMaterial;
import three.UniformsLib;
import three.UniformsUtils;
import three.BackSide;

/**
 * Reference: https://en.wikipedia.org/wiki/Cel_shading
 *
 * API
 *
 * 1. Traditional
 *
 * const effect = new OutlineEffect( renderer );
 *
 * function render() {
 *
 * 	effect.render( scene, camera );
 *
 * }
 *
 * 2. VR compatible
 *
 * const effect = new OutlineEffect( renderer );
 * let renderingOutline = false;
 *
 * scene.onAfterRender = function () {
 *
 * 	if ( renderingOutline ) return;
 *
 * 	renderingOutline = true;
 *
 * 	effect.renderOutline( scene, camera );
 *
 * 	renderingOutline = false;
 *
 * };
 *
 * function render() {
 *
 * 	renderer.render( scene, camera );
 *
 * }
 *
 * // How to set default outline parameters
 * new OutlineEffect( renderer, {
 * 	defaultThickness: 0.01,
 * 	defaultColor: [ 0, 0, 0 ],
 * 	defaultAlpha: 0.8,
 * 	defaultKeepAlive: true // keeps outline material in cache even if material is removed from scene
 * } );
 *
 * // How to set outline parameters for each material
 * material.userData.outlineParameters = {
 * 	thickness: 0.01,
 * 	color: [ 0, 0, 0 ],
 * 	alpha: 0.8,
 * 	visible: true,
 * 	keepAlive: true
 * };
 */
class OutlineEffect {
  public var enabled:Bool = true;

  public var cache:Map<String, { material:ShaderMaterial, used:Bool, keepAlive:Bool, count:Int }> = new Map();
  public var originalMaterials:Map<String, ShaderMaterial> = new Map();
  public var originalOnBeforeRenders:Map<String, Dynamic<Void->Void>> = new Map();

  public function new(renderer:Dynamic, ?parameters:Dynamic = null) {
    var defaultThickness = parameters != null && parameters.defaultThickness != null ? parameters.defaultThickness : 0.003;
    var defaultColor = parameters != null && parameters.defaultColor != null ? new Color().fromArray(parameters.defaultColor) : new Color(0, 0, 0);
    var defaultAlpha = parameters != null && parameters.defaultAlpha != null ? parameters.defaultAlpha : 1.0;
    var defaultKeepAlive = parameters != null && parameters.defaultKeepAlive != null ? parameters.defaultKeepAlive : false;

    var removeThresholdCount = 60;

    //this.cache = cache;  // for debug

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

      '}',

    ].join('\n');

    var fragmentShader = [

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

    var createMaterial = function() {
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
    };

    var getOutlineMaterialFromCache = function(originalMaterial:ShaderMaterial) {
      var data = cache.get(originalMaterial.uuid);

      if (data == null) {
        data = {
          material: createMaterial(),
          used: true,
          keepAlive: defaultKeepAlive,
          count: 0
        };

        cache.set(originalMaterial.uuid, data);
      }

      data.used = true;

      return data.material;
    };

    var getOutlineMaterial = function(originalMaterial:ShaderMaterial) {
      var outlineMaterial = getOutlineMaterialFromCache(originalMaterial);

      originalMaterials.set(outlineMaterial.uuid, originalMaterial);

      updateOutlineMaterial(outlineMaterial, originalMaterial);

      return outlineMaterial;
    };

    var isCompatible = function(object:Dynamic) {
      var geometry = object.geometry;
      var hasNormals = (geometry != null) && (geometry.attributes.normal != null);

      return (object.isMesh == true && object.material != null && hasNormals == true);
    };

    var setOutlineMaterial = function(object:Dynamic) {
      if (isCompatible(object) == false) return;

      if (Reflect.is(object.material, Array)) {
        for (i in 0...object.material.length) {
          object.material[i] = getOutlineMaterial(object.material[i]);
        }
      } else {
        object.material = getOutlineMaterial(object.material);
      }

      originalOnBeforeRenders.set(object.uuid, object.onBeforeRender);
      object.onBeforeRender = onBeforeRender;
    };

    var restoreOriginalMaterial = function(object:Dynamic) {
      if (isCompatible(object) == false) return;

      if (Reflect.is(object.material, Array)) {
        for (i in 0...object.material.length) {
          object.material[i] = originalMaterials.get(object.material[i].uuid);
        }
      } else {
        object.material = originalMaterials.get(object.material.uuid);
      }

      object.onBeforeRender = originalOnBeforeRenders.get(object.uuid);
    };

    var onBeforeRender = function(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:ShaderMaterial) {
      var originalMaterial = originalMaterials.get(material.uuid);

      // just in case
      if (originalMaterial == null) return;

      updateUniforms(material, originalMaterial);
    };

    var updateUniforms = function(material:ShaderMaterial, originalMaterial:ShaderMaterial) {
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
    };

    var updateOutlineMaterial = function(material:ShaderMaterial, originalMaterial:ShaderMaterial) {
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

        if (outlineParameters.keepAlive != null) cache.get(originalMaterial.uuid).keepAlive = outlineParameters.keepAlive;
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

      material.version = originalMaterial.version; // update outline material if necessary
    };

    var cleanupCache = function() {
      var keys:Array<String>;

      // clear originialMaterials
      keys = originalMaterials.keys();

      for (i in 0...keys.length) {
        originalMaterials.remove(keys[i]);
      }

      // clear originalOnBeforeRenders
      keys = originalOnBeforeRenders.keys();

      for (i in 0...keys.length) {
        originalOnBeforeRenders.remove(keys[i]);
      }

      // remove unused outlineMaterial from cache
      keys = cache.keys();

      for (i in 0...keys.length) {
        var key = keys[i];

        if (cache.get(key).used == false) {
          cache.get(key).count++;

          if (cache.get(key).keepAlive == false && cache.get(key).count > removeThresholdCount) {
            cache.remove(key);
          }
        } else {
          cache.get(key).used = false;
          cache.get(key).count = 0;
        }
      }
    };

    this.render = function(scene:Dynamic, camera:Dynamic) {
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

    this.renderOutline = function(scene:Dynamic, camera:Dynamic) {
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

    /*
     * See #9918
     *
     * The following property copies and wrapper methods enable
     * OutlineEffect to be called from other *Effect, like
     *
     * effect = new StereoEffect( new OutlineEffect( renderer ) );
     *
     * function render () {
     *
	 	 * 	effect.render( scene, camera );
     *
     * }
     */
    this.autoClear = renderer.autoClear;
    this.domElement = renderer.domElement;
    this.shadowMap = renderer.shadowMap;

    this.clear = function(color:Dynamic, depth:Dynamic, stencil:Dynamic) {
      renderer.clear(color, depth, stencil);
    };

    this.getPixelRatio = function() {
      return renderer.getPixelRatio();
    };

    this.setPixelRatio = function(value:Float) {
      renderer.setPixelRatio(value);
    };

    this.getSize = function(target:Dynamic) {
      return renderer.getSize(target);
    };

    this.setSize = function(width:Int, height:Int, updateStyle:Bool) {
      renderer.setSize(width, height, updateStyle);
    };

    this.setViewport = function(x:Int, y:Int, width:Int, height:Int) {
      renderer.setViewport(x, y, width, height);
    };

    this.setScissor = function(x:Int, y:Int, width:Int, height:Int) {
      renderer.setScissor(x, y, width, height);
    };

    this.setScissorTest = function(boolean:Bool) {
      renderer.setScissorTest(boolean);
    };

    this.setRenderTarget = function(renderTarget:Dynamic) {
      renderer.setRenderTarget(renderTarget);
    };
  }
}