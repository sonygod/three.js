import js.Browser.document;
import js.html.Element;
import js.html.HTMLDocument;

import BRDF_Lambert from './BSDF/BRDF_Lambert';
import BRDF_GGX from './BSDF/BRDF_GGX';
import DFGApprox from './BSDF/DFGApprox';
import EnvironmentBRDF from './BSDF/EnvironmentBRDF';
import F_Schlick from './BSDF/F_Schlick';
import Schlick_to_F0 from './BSDF/Schlick_to_F0';
import BRDF_Sheen from './BSDF/BRDF_Sheen';
import LightingModel from '../core/LightingModel';
import { diffuseColor, specularColor, specularF90, roughness, clearcoat, clearcoatRoughness, sheen, sheenRoughness, iridescence, iridescenceIOR, iridescenceThickness, ior, thickness, transmission, attenuationDistance, attenuationColor } from '../core/PropertyNode';
import { transformedNormalView, transformedClearcoatNormalView, transformedNormalWorld } from '../accessors/NormalNode';
import { positionViewDirection, positionWorld } from '../accessors/PositionNode';
import { tslFn, float, vec2, vec3, vec4, mat3, If } from '../shadernode/ShaderNode';
import { cond } from '../math/CondNode';
import { mix, normalize, refract, length, clamp, log2, log, exp, smoothstep } from '../math/MathNode';
import { div } from '../math/OperatorNode';
import { cameraPosition, cameraProjectionMatrix, cameraViewMatrix } from '../accessors/CameraNode';
import { modelWorldMatrix } from '../accessors/ModelNode';
import { viewportResolution } from '../display/ViewportNode';
import { viewportMipTexture } from '../display/ViewportTextureNode';

class FunctionWrapper {
    public var func: Dynamic;
    public function new(func: Dynamic) { this.func = func; }
    public function call(...params: Array<Dynamic>): Dynamic { return this.func(params); }
}

class MathWrapper {
    public static function PI(): Float { return js.Math.PI; }
    public static function sqrt(value: Float): Float { return js.Math.sqrt(value); }
    public static function cos(value: Float): Float { return js.Math.cos(value); }
    public static function sin(value: Float): Float { return js.Math.sin(value); }
}

// ...

// Transmission

var getVolumeTransmissionRay = new FunctionWrapper(tslFn(([n, v, thickness, ior, modelMatrix]) => {
    // Implementation...
}));

var applyIorToRoughness = new FunctionWrapper(tslFn(([roughness, ior]) => {
    // Implementation...
}));

var singleViewportMipTexture = viewportMipTexture();

var getTransmissionSample = new FunctionWrapper(tslFn(([fragCoord, roughness, ior]) => {
    // Implementation...
}));

var volumeAttenuation = new FunctionWrapper(tslFn(([transmissionDistance, attenuationColor, attenuationDistance]) => {
    // Implementation...
}));

var getIBLVolumeRefraction = new FunctionWrapper(tslFn(([n, v, roughness, diffuseColor, specularColor, specularF90, position, modelMatrix, viewMatrix, projMatrix, ior, thickness, attenuationColor, attenuationDistance]) => {
    // Implementation...
}));

// Iridescence

var XYZ_TO_REC709 = mat3(
    3.2404542, - 0.9692660, 0.0556434,
    - 1.5371385, 1.8760108, - 0.2040259,
    - 0.4985314, 0.0415560, 1.0572252
);

function Fresnel0ToIor(fresnel0: vec3): vec3 {
    // Implementation...
}

function IorToFresnel0(transmittedIor: Float, incidentIor: Float): Float {
    // Implementation...
}

var evalIridescence = new FunctionWrapper(tslFn(({ outsideIOR, eta2, cosTheta1, thinFilmThickness, baseF0 }) => {
    // Implementation...
}));

// Sheen

var IBLSheenBRDF = new FunctionWrapper(tslFn(({ normal, viewDir, roughness }) => {
    // Implementation...
}));

var clearcoatF0 = vec3(0.04);
var clearcoatF90 = vec3(1);

// PhysicalLightingModel

class PhysicalLightingModel extends LightingModel {
    public var clearcoat: Bool;
    public var sheen: Bool;
    public var iridescence: Bool;
    public var anisotropy: Bool;
    public var transmission: Bool;
    public var clearcoatRadiance: vec3;
    public var clearcoatSpecularDirect: vec3;
    public var clearcoatSpecularIndirect: vec3;
    public var sheenSpecularDirect: vec3;
    public var sheenSpecularIndirect: vec3;
    public var iridescenceFresnel: vec3;
    public var iridescenceF0: vec3;

    public function new(clearcoat: Bool = false, sheen: Bool = false, iridescence: Bool = false, anisotropy: Bool = false, transmission: Bool = false) {
        super();
        this.clearcoat = clearcoat;
        this.sheen = sheen;
        this.iridescence = iridescence;
        this.anisotropy = anisotropy;
        this.transmission = transmission;
        this.clearcoatRadiance = null;
        this.clearcoatSpecularDirect = null;
        this.clearcoatSpecularIndirect = null;
        this.sheenSpecularDirect = null;
        this.sheenSpecularIndirect = null;
        this.iridescenceFresnel = null;
        this.iridescenceF0 = null;
    }

    public function start(context: Dynamic) {
        // Implementation...
    }

    public function computeMultiscattering(singleScatter: vec3, multiScatter: vec3, specularF90: vec3) {
        // Implementation...
    }

    public function direct({ lightDirection, lightColor, reflectedLight }) {
        // Implementation...
    }

    public function indirectDiffuse({ irradiance, reflectedLight }) {
        // Implementation...
    }

    public function indirectSpecular({ radiance, iblIrradiance, reflectedLight }) {
        // Implementation...
    }

    public function ambientOcclusion({ ambientOcclusion, reflectedLight }) {
        // Implementation...
    }

    public function finish(context: Dynamic) {
        // Implementation...
    }
}