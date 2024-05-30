package three.js.src.renderers.shaders.ShaderChunk;

import three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.IncidentLight;
import three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.ReflectedLight;

class lights_phong_pars_fragment {
    public static var __name__ = ['three', 'js', 'src', 'renderers', 'shaders', 'ShaderChunk', 'lights_phong_pars_fragment'];

    public static function main() {
        var vViewPosition = new three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vViewPosition();

        class BlinnPhongMaterial {
            public var diffuseColor:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3;
            public var specularColor:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3;
            public var specularShininess:Float;
            public var specularStrength:Float;

            public function new() {
                this.diffuseColor = new three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3();
                this.specularColor = new three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3();
            }
        }

        function RE_Direct_BlinnPhong(directLight:IncidentLight, geometryPosition:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryNormal:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryViewDir:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryClearcoatNormal:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {
            var dotNL = Math.max(0, geometryNormal.dot(directLight.direction));
            var irradiance = dotNL * directLight.color;

            reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);

            reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess) * material.specularStrength;
        }

        function RE_IndirectDiffuse_BlinnPhong(irradiance:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryPosition:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryNormal:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryViewDir:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, geometryClearcoatNormal:three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {
            reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
        }

        #define RE_Direct RE_Direct_BlinnPhong;
        #define RE_IndirectDiffuse RE_IndirectDiffuse_BlinnPhong;
    }
}