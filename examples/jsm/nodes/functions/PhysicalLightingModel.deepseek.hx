package three.examples.jsm.nodes.functions;

import three.examples.jsm.nodes.BSDF.BRDF_Lambert;
import three.examples.jsm.nodes.BSDF.BRDF_GGX;
import three.examples.jsm.nodes.BSDF.DFGApprox;
import three.examples.jsm.nodes.BSDF.EnvironmentBRDF;
import three.examples.jsm.nodes.BSDF.F_Schlick;
import three.examples.jsm.nodes.BSDF.Schlick_to_F0;
import three.examples.jsm.nodes.BSDF.BRDF_Sheen;
import three.examples.jsm.nodes.core.LightingModel;
import three.examples.jsm.nodes.core.PropertyNode;
import three.examples.jsm.nodes.accessors.NormalNode;
import three.examples.jsm.nodes.accessors.PositionNode;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.examples.jsm.nodes.math.CondNode;
import three.examples.jsm.nodes.math.MathNode;
import three.examples.jsm.nodes.math.OperatorNode;
import three.examples.jsm.nodes.display.ViewportNode;
import three.examples.jsm.nodes.display.ViewportTextureNode;

class PhysicalLightingModel extends LightingModel {

    public function new(clearcoat:Bool = false, sheen:Bool = false, iridescence:Bool = false, anisotropy:Bool = false, transmission:Bool = false) {
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

    public function start(context:Dynamic) {

        if (this.clearcoat) {

            this.clearcoatRadiance = ShaderNode.vec3().temp('clearcoatRadiance');
            this.clearcoatSpecularDirect = ShaderNode.vec3().temp('clearcoatSpecularDirect');
            this.clearcoatSpecularIndirect = ShaderNode.vec3().temp('clearcoatSpecularIndirect');

        }

        if (this.sheen) {

            this.sheenSpecularDirect = ShaderNode.vec3().temp('sheenSpecularDirect');
            this.sheenSpecularIndirect = ShaderNode.vec3().temp('sheenSpecularIndirect');

        }

        if (this.iridescence) {

            var dotNVi = NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection).clamp();

            this.iridescenceFresnel = evalIridescence({
                outsideIOR: ShaderNode.float(1.0),
                eta2: PropertyNode.iridescenceIOR,
                cosTheta1: dotNVi,
                thinFilmThickness: PropertyNode.iridescenceThickness,
                baseF0: PropertyNode.specularColor
            });

            this.iridescenceF0 = Schlick_to_F0({
                f: this.iridescenceFresnel,
                f90: ShaderNode.float(1.0),
                dotVH: dotNVi
            });

        }

        if (this.transmission) {

            var position = PositionNode.positionWorld;
            var v = PositionNode.cameraPosition.sub(PositionNode.positionWorld).normalize(); // TODO: Create Node for this, same issue in MaterialX
            var n = NormalNode.transformedNormalWorld;

            context.backdrop = getIBLVolumeRefraction(
                n,
                v,
                PropertyNode.roughness,
                PropertyNode.diffuseColor,
                PropertyNode.specularColor,
                ShaderNode.float(1), // specularF90
                position, // positionWorld
                PropertyNode.modelWorldMatrix, // modelMatrix
                PositionNode.cameraViewMatrix, // viewMatrix
                PositionNode.cameraProjectionMatrix, // projMatrix
                PropertyNode.ior,
                PropertyNode.thickness,
                PropertyNode.attenuationColor,
                PropertyNode.attenuationDistance
            );

            context.backdropAlpha = transmission;

            PropertyNode.diffuseColor.a.mulAssign(MathNode.mix(ShaderNode.float(1), context.backdrop.a, transmission));

        }
    }

    // Fdez-Ag�era's "Multiple-Scattering Microfacet Model for Real-Time Image Based Lighting"
    // Approximates multiscattering in order to preserve energy.
    // http://www.jcgt.org/published/0008/01/03/

    public function computeMultiscattering(singleScatter:ShaderNode.vec3, multiScatter:ShaderNode.vec3, specularF90:ShaderNode.vec3) {

        var dotNV = NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection).clamp(); // @ TODO: Move to core dotNV

        var fab = DFGApprox({
            roughness: PropertyNode.roughness,
            dotNV: dotNV
        });

        var Fr = this.iridescenceF0 ? PropertyNode.iridescence.mix(PropertyNode.specularColor, this.iridescenceF0) : PropertyNode.specularColor;

        var FssEss = Fr.mul(fab.x).add(PropertyNode.specularF90.mul(fab.y));

        var Ess = fab.x.add(fab.y);
        var Ems = Ess.oneMinus();

        var Favg = PropertyNode.specularColor.add(PropertyNode.specularColor.oneMinus().mul(ShaderNode.float(0.047619))); // 1/21
        var Fms = FssEss.mul(Favg).div(Ems.mul(Favg).oneMinus());

        singleScatter.addAssign(FssEss);
        multiScatter.addAssign(Fms.mul(Ems));

    }

    public function direct(lightDirection:ShaderNode.vec3, lightColor:ShaderNode.vec3, reflectedLight:Dynamic) {

        var dotNL = NormalNode.transformedNormalView.dot(lightDirection).clamp();
        var irradiance = dotNL.mul(lightColor);

        if (this.sheen) {

            this.sheenSpecularDirect.addAssign(irradiance.mul(BRDF_Sheen({
                lightDirection: lightDirection
            })));

        }

        if (this.clearcoat) {

            var dotNLcc = NormalNode.transformedClearcoatNormalView.dot(lightDirection).clamp();
            var ccIrradiance = dotNLcc.mul(lightColor);

            this.clearcoatSpecularDirect.addAssign(ccIrradiance.mul(BRDF_GGX({
                lightDirection: lightDirection,
                f0: ShaderNode.vec3(0.04),
                f90: ShaderNode.vec3(1),
                roughness: PropertyNode.clearcoatRoughness,
                normalView: NormalNode.transformedClearcoatNormalView
            })));

        }

        reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert({
            diffuseColor: PropertyNode.diffuseColor.rgb
        })));

        reflectedLight.directSpecular.addAssign(irradiance.mul(BRDF_GGX({
            lightDirection: lightDirection,
            f0: PropertyNode.specularColor,
            f90: ShaderNode.float(1),
            roughness: PropertyNode.roughness,
            iridescence: this.iridescence,
            f: this.iridescenceFresnel,
            USE_IRIDESCENCE: this.iridescence,
            USE_ANISOTROPY: this.anisotropy
        })));

    }

    public function indirectDiffuse(irradiance:ShaderNode.vec3, reflectedLight:Dynamic) {

        reflectedLight.indirectDiffuse.addAssign(irradiance.mul(BRDF_Lambert({
            diffuseColor: PropertyNode.diffuseColor
        })));

    }

    public function indirectSpecular(radiance:ShaderNode.vec3, iblIrradiance:ShaderNode.vec3, reflectedLight:Dynamic) {

        if (this.sheen) {

            this.sheenSpecularIndirect.addAssign(iblIrradiance.mul(
                PropertyNode.sheen,
                IBLSheenBRDF({
                    normal: NormalNode.transformedNormalView,
                    viewDir: PositionNode.positionViewDirection,
                    roughness: PropertyNode.sheenRoughness
                })
            ));

        }

        if (this.clearcoat) {

            var dotNVcc = NormalNode.transformedClearcoatNormalView.dot(PositionNode.positionViewDirection).clamp();

            var clearcoatEnv = EnvironmentBRDF({
                dotNV: dotNVcc,
                specularColor: ShaderNode.vec3(0.04),
                specularF90: ShaderNode.vec3(1),
                roughness: PropertyNode.clearcoatRoughness
            });

            this.clearcoatSpecularIndirect.addAssign(this.clearcoatRadiance.mul(clearcoatEnv));

        }

        // Both indirect specular and indirect diffuse light accumulate here

        var singleScattering = ShaderNode.vec3().temp('singleScattering');
        var multiScattering = ShaderNode.vec3().temp('multiScattering');
        var cosineWeightedIrradiance = iblIrradiance.mul(ShaderNode.float(1 / Math.PI));

        this.computeMultiscattering(singleScattering, multiScattering, PropertyNode.specularF90);

        var totalScattering = singleScattering.add(multiScattering);

        var diffuse = PropertyNode.diffuseColor.mul(totalScattering.r.max(totalScattering.g).max(totalScattering.b).oneMinus());

        reflectedLight.indirectSpecular.addAssign(radiance.mul(singleScattering));
        reflectedLight.indirectSpecular.addAssign(multiScattering.mul(cosineWeightedIrradiance));

        reflectedLight.indirectDiffuse.addAssign(diffuse.mul(cosineWeightedIrradiance));

    }

    public function ambientOcclusion(ambientOcclusion:ShaderNode.vec3, reflectedLight:Dynamic) {

        var dotNV = NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection).clamp(); // @ TODO: Move to core dotNV

        var aoNV = dotNV.add(ambientOcclusion);
        var aoExp = PropertyNode.roughness.mul(ShaderNode.float(-16.0)).oneMinus().negate().exp2();

        var aoNode = ambientOcclusion.sub(aoNV.pow(aoExp).oneMinus()).clamp();

        if (this.clearcoat) {

            this.clearcoatSpecularIndirect.mulAssign(ambientOcclusion);

        }

        if (this.sheen) {

            this.sheenSpecularIndirect.mulAssign(ambientOcclusion);

        }

        reflectedLight.indirectDiffuse.mulAssign(ambientOcclusion);
        reflectedLight.indirectSpecular.mulAssign(aoNode);

    }

    public function finish(context:Dynamic) {

        var outgoingLight = context.outgoingLight;

        if (this.clearcoat) {

            var dotNVcc = NormalNode.transformedClearcoatNormalView.dot(PositionNode.positionViewDirection).clamp();

            var Fcc = F_Schlick({
                dotVH: dotNVcc,
                f0: ShaderNode.vec3(0.04),
                f90: ShaderNode.vec3(1)
            });

            var clearcoatLight = outgoingLight.mul(PropertyNode.clearcoat.mul(Fcc).oneMinus()).add(this.clearcoatSpecularDirect.add(this.clearcoatSpecularIndirect).mul(PropertyNode.clearcoat));

            outgoingLight.assign(clearcoatLight);

        }

        if (this.sheen) {

            var sheenEnergyComp = PropertyNode.sheen.r.max(PropertyNode.sheen.g).max(PropertyNode.sheen.b).mul(ShaderNode.float(0.157)).oneMinus();
            var sheenLight = outgoingLight.mul(sheenEnergyComp).add(this.sheenSpecularDirect, this.sheenSpecularIndirect);

            outgoingLight.assign(sheenLight);

        }

    }

}