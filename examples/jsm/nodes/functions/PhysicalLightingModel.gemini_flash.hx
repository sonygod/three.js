import BSDF.BRDF_Lambert;
import BSDF.BRDF_GGX;
import BSDF.DFGApprox;
import BSDF.EnvironmentBRDF;
import BSDF.F_Schlick;
import BSDF.Schlick_to_F0;
import BSDF.BRDF_Sheen;
import core.LightingModel;
import core.PropertyNode;
import accessors.NormalNode;
import accessors.PositionNode;
import shadernode.ShaderNode;
import math.CondNode;
import math.MathNode;
import math.OperatorNode;
import accessors.CameraNode;
import accessors.ModelNode;
import display.ViewportNode;
import display.ViewportTextureNode;

//
// Transmission
//

var getVolumeTransmissionRay = ShaderNode.tslFn(( [ n, v, thickness, ior, modelMatrix ] ) => {

	// Direction of refracted light.
	var refractionVector = MathNode.vec3( MathNode.refract( v.negate(), MathNode.normalize( n ), OperatorNode.div( 1.0, ior ) ) );

	// Compute rotation-independant scaling of the model matrix.
	var modelScale = MathNode.vec3(
		MathNode.length( modelMatrix[ 0 ].xyz ),
		MathNode.length( modelMatrix[ 1 ].xyz ),
		MathNode.length( modelMatrix[ 2 ].xyz )
	);

	// The thickness is specified in local space.
	return MathNode.normalize( refractionVector ).mul( thickness.mul( modelScale ) );

}).setLayout( {
	name: 'getVolumeTransmissionRay',
	type: 'vec3',
	inputs: [
		{ name: 'n', type: 'vec3' },
		{ name: 'v', type: 'vec3' },
		{ name: 'thickness', type: 'float' },
		{ name: 'ior', type: 'float' },
		{ name: 'modelMatrix', type: 'mat4' }
	]
} );

var applyIorToRoughness = ShaderNode.tslFn(( [ roughness, ior ] ) => {

	// Scale roughness with IOR so that an IOR of 1.0 results in no microfacet refraction and
	// an IOR of 1.5 results in the default amount of microfacet refraction.
	return roughness.mul( MathNode.clamp( ior.mul( 2.0 ).sub( 2.0 ), 0.0, 1.0 ) );

}).setLayout( {
	name: 'applyIorToRoughness',
	type: 'float',
	inputs: [
		{ name: 'roughness', type: 'float' },
		{ name: 'ior', type: 'float' }
	]
} );

var singleViewportMipTexture = ViewportTextureNode.viewportMipTexture();

var getTransmissionSample = ShaderNode.tslFn(( [ fragCoord, roughness, ior ] ) => {

	var transmissionSample = singleViewportMipTexture.uv( fragCoord );
	//const transmissionSample = viewportMipTexture( fragCoord );

	var lod = MathNode.log2( ShaderNode.float( ViewportNode.viewportResolution.x ) ).mul( applyIorToRoughness( roughness, ior ) );

	return transmissionSample.bicubic( lod );

} );

var volumeAttenuation = ShaderNode.tslFn(( [ transmissionDistance, attenuationColor, attenuationDistance ] ) => {

	CondNode.if( attenuationDistance.notEqual( 0 ), () => {

		// Compute light attenuation using Beer's law.
		var attenuationCoefficient = MathNode.log( attenuationColor ).negate().div( attenuationDistance );
		var transmittance = MathNode.exp( attenuationCoefficient.negate().mul( transmissionDistance ) );

		return transmittance;

	} );

	// Attenuation distance is +∞, i.e. the transmitted color is not attenuated at all.
	return MathNode.vec3( 1.0 );

}).setLayout( {
	name: 'volumeAttenuation',
	type: 'vec3',
	inputs: [
		{ name: 'transmissionDistance', type: 'float' },
		{ name: 'attenuationColor', type: 'vec3' },
		{ name: 'attenuationDistance', type: 'float' }
	]
} );

var getIBLVolumeRefraction = ShaderNode.tslFn(( [ n, v, roughness, diffuseColor, specularColor, specularF90, position, modelMatrix, viewMatrix, projMatrix, ior, thickness, attenuationColor, attenuationDistance ] ) => {

	var transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
	var refractedRayExit = position.add( transmissionRay );

	// Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
	var ndcPos = projMatrix.mul( viewMatrix.mul( ShaderNode.vec4( refractedRayExit, 1.0 ) ) );
	var refractionCoords = MathNode.vec2( ndcPos.xy.div( ndcPos.w ) ).toVar();
	refractionCoords.addAssign( 1.0 );
	refractionCoords.divAssign( 2.0 );
	refractionCoords.assign( MathNode.vec2( refractionCoords.x, refractionCoords.y.oneMinus() ) ); // webgpu

	// Sample framebuffer to get pixel the refracted ray hits.
	var transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
	var transmittance = diffuseColor.mul( volumeAttenuation( MathNode.length( transmissionRay ), attenuationColor, attenuationDistance ) );
	var attenuatedColor = transmittance.rgb.mul( transmittedLight.rgb );
	var dotNV = n.dot( v ).clamp();

	// Get the specular component.
	var F = MathNode.vec3( EnvironmentBRDF.EnvironmentBRDF( { // n, v, specularColor, specularF90, roughness
		dotNV,
		specularColor,
		specularF90,
		roughness
	} ) );

	// As less light is transmitted, the opacity should be increased. This simple approximation does a decent job
	// of modulating a CSS background, and has no effect when the buffer is opaque, due to a solid object or clear color.
	var transmittanceFactor = transmittance.r.add( transmittance.g, transmittance.b ).div( 3.0 );

	return ShaderNode.vec4( F.oneMinus().mul( attenuatedColor ), transmittedLight.a.oneMinus().mul( transmittanceFactor ).oneMinus() );

} );

//
// Iridescence
//

// XYZ to linear-sRGB color space
var XYZ_TO_REC709 = MathNode.mat3(
	3.2404542, - 0.9692660, 0.0556434,
	- 1.5371385, 1.8760108, - 0.2040259,
	- 0.4985314, 0.0415560, 1.0572252
);

// Assume air interface for top
// Note: We don't handle the case fresnel0 == 1
var Fresnel0ToIor = ( fresnel0 ) => {

	var sqrtF0 = fresnel0.sqrt();
	return MathNode.vec3( 1.0 ).add( sqrtF0 ).div( MathNode.vec3( 1.0 ).sub( sqrtF0 ) );

};

// ior is a value between 1.0 and 3.0. 1.0 is air interface
var IorToFresnel0 = ( transmittedIor, incidentIor ) => {

	return transmittedIor.sub( incidentIor ).div( transmittedIor.add( incidentIor ) ).pow2();

};

// Fresnel equations for dielectric/dielectric interfaces.
// Ref: https://belcour.github.io/blog/research/2017/05/01/brdf-thin-film.html
// Evaluation XYZ sensitivity curves in Fourier space
var evalSensitivity = ( OPD, shift ) => {

	var phase = OPD.mul( 2.0 * Math.PI * 1.0e-9 );
	var val = MathNode.vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
	var pos = MathNode.vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
	var VAR = MathNode.vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );

	var x = ShaderNode.float( 9.7470e-14 * Math.sqrt( 2.0 * Math.PI * 4.5282e+09 ) ).mul( phase.mul( 2.2399e+06 ).add( shift.x ).cos() ).mul( phase.pow2().mul( - 4.5282e+09 ).exp() );

	var xyz = val.mul( VAR.mul( 2.0 * Math.PI ).sqrt() ).mul( pos.mul( phase ).add( shift ).cos() ).mul( phase.pow2().negate().mul( VAR ).exp() );
	xyz = MathNode.vec3( xyz.x.add( x ), xyz.y, xyz.z ).div( 1.0685e-7 );

	var rgb = XYZ_TO_REC709.mul( xyz );

	return rgb;

};

var evalIridescence = ShaderNode.tslFn( ( { outsideIOR, eta2, cosTheta1, thinFilmThickness, baseF0 } ) => {

	// Force iridescenceIOR -> outsideIOR when thinFilmThickness -> 0.0
	var iridescenceIOR = MathNode.mix( outsideIOR, eta2, MathNode.smoothstep( 0.0, 0.03, thinFilmThickness ) );
	// Evaluate the cosTheta on the base layer (Snell law)
	var sinTheta2Sq = outsideIOR.div( iridescenceIOR ).pow2().mul( ShaderNode.float( 1 ).sub( cosTheta1.pow2() ) );

	// Handle TIR:
	var cosTheta2Sq = ShaderNode.float( 1 ).sub( sinTheta2Sq );
	/*if ( cosTheta2Sq < 0.0 ) {

			return vec3( 1.0 );

	}*/

	var cosTheta2 = cosTheta2Sq.sqrt();

	// First interface
	var R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
	var R12 = F_Schlick.F_Schlick( { f0: R0, f90: 1.0, dotVH: cosTheta1 } );
	//const R21 = R12;
	var T121 = R12.oneMinus();
	var phi12 = iridescenceIOR.lessThan( outsideIOR ).cond( Math.PI, 0.0 );
	var phi21 = ShaderNode.float( Math.PI ).sub( phi12 );

	// Second interface
	var baseIOR = Fresnel0ToIor( baseF0.clamp( 0.0, 0.9999 ) ); // guard against 1.0
	var R1 = IorToFresnel0( baseIOR, iridescenceIOR.toVec3() );
	var R23 = F_Schlick.F_Schlick( { f0: R1, f90: 1.0, dotVH: cosTheta2 } );
	var phi23 = MathNode.vec3(
		baseIOR.x.lessThan( iridescenceIOR ).cond( Math.PI, 0.0 ),
		baseIOR.y.lessThan( iridescenceIOR ).cond( Math.PI, 0.0 ),
		baseIOR.z.lessThan( iridescenceIOR ).cond( Math.PI, 0.0 )
	);

	// Phase shift
	var OPD = iridescenceIOR.mul( thinFilmThickness, cosTheta2, 2.0 );
	var phi = MathNode.vec3( phi21 ).add( phi23 );

	// Compound terms
	var R123 = R12.mul( R23 ).clamp( 1e-5, 0.9999 );
	var r123 = R123.sqrt();
	var Rs = T121.pow2().mul( R23 ).div( MathNode.vec3( 1.0 ).sub( R123 ) );

	// Reflectance term for m = 0 (DC term amplitude)
	var C0 = R12.add( Rs );
	var I = C0;

	// Reflectance term for m > 0 (pairs of diracs)
	var Cm = Rs.sub( T121 );
	for ( var m = 1; m <= 2; ++ m ) {

		Cm = Cm.mul( r123 );
		var Sm = evalSensitivity( ShaderNode.float( m ).mul( OPD ), ShaderNode.float( m ).mul( phi ) ).mul( 2.0 );
		I = I.add( Cm.mul( Sm ) );

	}

	// Since out of gamut colors might be produced, negative color values are clamped to 0.
	return I.max( MathNode.vec3( 0.0 ) );

} ).setLayout( {
	name: 'evalIridescence',
	type: 'vec3',
	inputs: [
		{ name: 'outsideIOR', type: 'float' },
		{ name: 'eta2', type: 'float' },
		{ name: 'cosTheta1', type: 'float' },
		{ name: 'thinFilmThickness', type: 'float' },
		{ name: 'baseF0', type: 'vec3' }
	]
} );

//
//	Sheen
//

// This is a curve-fit approxmation to the "Charlie sheen" BRDF integrated over the hemisphere from
// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF". The analysis can be found
// in the Sheen section of https://drive.google.com/file/d/1T0D1VSyR4AllqIJTQAraEIzjlb5h4FKH/view?usp=sharing
var IBLSheenBRDF = ShaderNode.tslFn( ( { normal, viewDir, roughness } ) => {

	var dotNV = normal.dot( viewDir ).saturate();

	var r2 = roughness.pow2();

	var a = CondNode.cond(
		roughness.lessThan( 0.25 ),
		ShaderNode.float( - 339.2 ).mul( r2 ).add( ShaderNode.float( 161.4 ).mul( roughness ) ).sub( 25.9 ),
		ShaderNode.float( - 8.48 ).mul( r2 ).add( ShaderNode.float( 14.3 ).mul( roughness ) ).sub( 9.95 )
	);

	var b = CondNode.cond(
		roughness.lessThan( 0.25 ),
		ShaderNode.float( 44.0 ).mul( r2 ).sub( ShaderNode.float( 23.7 ).mul( roughness ) ).add( 3.26 ),
		ShaderNode.float( 1.97 ).mul( r2 ).sub( ShaderNode.float( 3.27 ).mul( roughness ) ).add( 0.72 )
	);

	var DG = CondNode.cond( roughness.lessThan( 0.25 ), 0.0, ShaderNode.float( 0.1 ).mul( roughness ).sub( 0.025 ) ).add( a.mul( dotNV ).add( b ).exp() );

	return DG.mul( 1.0 / Math.PI ).saturate();

} );

var clearcoatF0 = MathNode.vec3( 0.04 );
var clearcoatF90 = MathNode.vec3( 1 );

//

class PhysicalLightingModel extends LightingModel {

	public clearcoat:Bool;
	public sheen:Bool;
	public iridescence:Bool;
	public anisotropy:Bool;
	public transmission:Bool;

	public clearcoatRadiance:ShaderNode.Vec3;
	public clearcoatSpecularDirect:ShaderNode.Vec3;
	public clearcoatSpecularIndirect:ShaderNode.Vec3;
	public sheenSpecularDirect:ShaderNode.Vec3;
	public sheenSpecularIndirect:ShaderNode.Vec3;
	public iridescenceFresnel:ShaderNode.Vec3;
	public iridescenceF0:ShaderNode.Vec3;

	public function new( clearcoat = false, sheen = false, iridescence = false, anisotropy = false, transmission = false ) {
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

	override public function start( context:LightingModel.LightingContext ) {

		if ( this.clearcoat === true ) {

			this.clearcoatRadiance = ShaderNode.vec3().temp( 'clearcoatRadiance' );
			this.clearcoatSpecularDirect = ShaderNode.vec3().temp( 'clearcoatSpecularDirect' );
			this.clearcoatSpecularIndirect = ShaderNode.vec3().temp( 'clearcoatSpecularIndirect' );

		}

		if ( this.sheen === true ) {

			this.sheenSpecularDirect = ShaderNode.vec3().temp( 'sheenSpecularDirect' );
			this.sheenSpecularIndirect = ShaderNode.vec3().temp( 'sheenSpecularIndirect' );

		}

		if ( this.iridescence === true ) {

			var dotNVi = NormalNode.transformedNormalView.dot( PositionNode.positionViewDirection ).clamp();

			this.iridescenceFresnel = evalIridescence( {
				outsideIOR: ShaderNode.float( 1.0 ),
				eta2: PropertyNode.iridescenceIOR,
				cosTheta1: dotNVi,
				thinFilmThickness: PropertyNode.iridescenceThickness,
				baseF0: PropertyNode.specularColor
			} );

			this.iridescenceF0 = Schlick_to_F0.Schlick_to_F0( { f: this.iridescenceFresnel, f90: 1.0, dotVH: dotNVi } );

		}

		if ( this.transmission === true ) {

			var position = PositionNode.positionWorld;
			var v = CameraNode.cameraPosition.sub( PositionNode.positionWorld ).normalize(); // TODO: Create Node for this, same issue in MaterialX
			var n = NormalNode.transformedNormalWorld;

			context.backdrop = getIBLVolumeRefraction(
				n,
				v,
				PropertyNode.roughness,
				PropertyNode.diffuseColor,
				PropertyNode.specularColor,
				PropertyNode.specularF90, // specularF90
				position, // positionWorld
				ModelNode.modelWorldMatrix, // modelMatrix
				CameraNode.cameraViewMatrix, // viewMatrix
				CameraNode.cameraProjectionMatrix, // projMatrix
				PropertyNode.ior,
				PropertyNode.thickness,
				PropertyNode.attenuationColor,
				PropertyNode.attenuationDistance
			);

			context.backdropAlpha = PropertyNode.transmission;

			PropertyNode.diffuseColor.a.mulAssign( MathNode.mix( 1, context.backdrop.a, PropertyNode.transmission ) );

		}

	}

	// Fdez-Agüera's "Multiple-Scattering Microfacet Model for Real-Time Image Based Lighting"
	// Approximates multiscattering in order to preserve energy.
	// http://www.jcgt.org/published/0008/01/03/

	public function computeMultiscattering( singleScatter:ShaderNode.Vec3, multiScatter:ShaderNode.Vec3, specularF90:ShaderNode.Vec3 ) {

		var dotNV = NormalNode.transformedNormalView.dot( PositionNode.positionViewDirection ).clamp(); // @ TODO: Move to core dotNV

		var fab = DFGApprox.DFGApprox( { roughness: PropertyNode.roughness, dotNV: dotNV } );

		var Fr = this.iridescenceF0 != null ? PropertyNode.iridescence.mix( PropertyNode.specularColor, this.iridescenceF0 ) : PropertyNode.specularColor;

		var FssEss = Fr.mul( fab.x ).add( specularF90.mul( fab.y ) );

		var Ess = fab.x.add( fab.y );
		var Ems = Ess.oneMinus();

		var Favg = PropertyNode.specularColor.add( PropertyNode.specularColor.oneMinus().mul( 0.047619 ) ); // 1/21
		var Fms = FssEss.mul( Favg ).div( Ems.mul( Favg ).oneMinus() );

		singleScatter.addAssign( FssEss );
		multiScatter.addAssign( Fms.mul( Ems ) );

	}

	override public function direct( params:LightingModel.DirectLightingParams ) {

		var dotNL = NormalNode.transformedNormalView.dot( params.lightDirection ).clamp();
		var irradiance = dotNL.mul( params.lightColor );

		if ( this.sheen === true ) {

			this.sheenSpecularDirect.addAssign( irradiance.mul( BRDF_Sheen.BRDF_Sheen( { lightDirection: params.lightDirection } ) ) );

		}

		if ( this.clearcoat === true ) {

			var dotNLcc = NormalNode.transformedClearcoatNormalView.dot( params.lightDirection ).clamp();
			var ccIrradiance = dotNLcc.mul( params.lightColor );

			this.clearcoatSpecularDirect.addAssign( ccIrradiance.mul( BRDF_GGX.BRDF_GGX( { lightDirection: params.lightDirection, f0: clearcoatF0, f90: clearcoatF90, roughness: PropertyNode.clearcoatRoughness, normalView: NormalNode.transformedClearcoatNormalView } ) ) );

		}

		params.reflectedLight.directDiffuse.addAssign( irradiance.mul( BRDF_Lambert.BRDF_Lambert( { diffuseColor: PropertyNode.diffuseColor.rgb } ) ) );

		params.reflectedLight.directSpecular.addAssign( irradiance.mul( BRDF_GGX.BRDF_GGX( { lightDirection: params.lightDirection, f0: PropertyNode.specularColor, f90: 1, roughness: PropertyNode.roughness, iridescence: this.iridescence, f: this.iridescenceFresnel, USE_IRIDESCENCE: this.iridescence, USE_ANISOTROPY: this.anisotropy } ) ) );

	}

	override public function indirectDiffuse( params:LightingModel.IndirectDiffuseLightingParams ) {

		params.reflectedLight.indirectDiffuse.addAssign( params.irradiance.mul( BRDF_Lambert.BRDF_Lambert( { diffuseColor: PropertyNode.diffuseColor } ) ) );

	}

	override public function indirectSpecular( params:LightingModel.IndirectSpecularLightingParams ) {

		if ( this.sheen === true ) {

			this.sheenSpecularIndirect.addAssign( params.iblIrradiance.mul(
				PropertyNode.sheen,
				IBLSheenBRDF( {
					normal: NormalNode.transformedNormalView,
					viewDir: PositionNode.positionViewDirection,
					roughness: PropertyNode.sheenRoughness
				} )
			) );

		}

		if ( this.clearcoat === true ) {

			var dotNVcc = NormalNode.transformedClearcoatNormalView.dot( PositionNode.positionViewDirection ).clamp();

			var clearcoatEnv = EnvironmentBRDF.EnvironmentBRDF( {
				dotNV: dotNVcc,
				specularColor: clearcoatF0,
				specularF90: clearcoatF90,
				roughness: PropertyNode.clearcoatRoughness
			} );

			this.clearcoatSpecularIndirect.addAssign( this.clearcoatRadiance.mul( clearcoatEnv ) );

		}

		// Both indirect specular and indirect diffuse light accumulate here

		var singleScattering = ShaderNode.vec3().temp( 'singleScattering' );
		var multiScattering = ShaderNode.vec3().temp( 'multiScattering' );
		var cosineWeightedIrradiance = params.iblIrradiance.mul( 1 / Math.PI );

		this.computeMultiscattering( singleScattering, multiScattering, PropertyNode.specularF90 );

		var totalScattering = singleScattering.add( multiScattering );

		var diffuse = PropertyNode.diffuseColor.mul( totalScattering.r.max( totalScattering.g ).max( totalScattering.b ).oneMinus() );

		params.reflectedLight.indirectSpecular.addAssign( params.radiance.mul( singleScattering ) );
		params.reflectedLight.indirectSpecular.addAssign( multiScattering.mul( cosineWeightedIrradiance ) );

		params.reflectedLight.indirectDiffuse.addAssign( diffuse.mul( cosineWeightedIrradiance ) );

	}

	override public function ambientOcclusion( params:LightingModel.AmbientOcclusionLightingParams ) {

		var dotNV = NormalNode.transformedNormalView.dot( PositionNode.positionViewDirection ).clamp(); // @ TODO: Move to core dotNV

		var aoNV = dotNV.add( params.ambientOcclusion );
		var aoExp = PropertyNode.roughness.mul( - 16.0 ).oneMinus().negate().exp2();

		var aoNode = params.ambientOcclusion.sub( aoNV.pow( aoExp ).oneMinus() ).clamp();

		if ( this.clearcoat === true ) {

			this.clearcoatSpecularIndirect.mulAssign( params.ambientOcclusion );

		}

		if ( this.sheen === true ) {

			this.sheenSpecularIndirect.mulAssign( params.ambientOcclusion );

		}

		params.reflectedLight.indirectDiffuse.mulAssign( params.ambientOcclusion );
		params.reflectedLight.indirectSpecular.mulAssign( aoNode );

	}

	override public function finish( context:LightingModel.LightingContext ) {

		var outgoingLight = context.outgoingLight;

		if ( this.clearcoat === true ) {

			var dotNVcc = NormalNode.transformedClearcoatNormalView.dot( PositionNode.positionViewDirection ).clamp();

			var Fcc = F_Schlick.F_Schlick( {
				dotVH: dotNVcc,
				f0: clearcoatF0,
				f90: clearcoatF90
			} );

			var clearcoatLight = outgoingLight.mul( PropertyNode.clearcoat.mul( Fcc ).oneMinus() ).add( this.clearcoatSpecularDirect.add( this.clearcoatSpecularIndirect ).mul( PropertyNode.clearcoat ) );

			outgoingLight.assign( clearcoatLight );

		}

		if ( this.sheen === true ) {

			var sheenEnergyComp = PropertyNode.sheen.r.max( PropertyNode.sheen.g ).max( PropertyNode.sheen.b ).mul( 0.157 ).oneMinus();
			var sheenLight = outgoingLight.mul( sheenEnergyComp ).add( this.sheenSpecularDirect, this.sheenSpecularIndirect );

			outgoingLight.assign( sheenLight );

		}

	}

}

class PhysicalLightingModel {

	public static function new( clearcoat:Bool = false, sheen:Bool = false, iridescence:Bool = false, anisotropy:Bool = false, transmission:Bool = false ):PhysicalLightingModel {
		return new PhysicalLightingModel( clearcoat, sheen, iridescence, anisotropy, transmission );
	}

}

export default PhysicalLightingModel;