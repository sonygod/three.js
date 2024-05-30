import LightingModel from '../core/LightingModel.js';
import F_Schlick from './BSDF/F_Schlick.js';
import BRDF_Lambert from './BSDF/BRDF_Lambert.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { transformedNormalView } from '../accessors/NormalNode.js';
import { materialSpecularStrength } from '../accessors/MaterialNode.js';
import { shininess, specularColor } from '../core/PropertyNode.js';
import { positionViewDirection } from '../accessors/PositionNode.js';
import { tslFn, float } from '../shadernode/ShaderNode.js';

var G_BlinnPhong_Implicit = function() {
  return float( 0.25 );
}

var D_BlinnPhong = tslFn( function( { dotNH } ) {
  return shininess.mul( float( 0.5 ) ).add( 1.0 ).mul( float( 1 / Math.PI ) ).mul( dotNH.pow( shininess ) );
} );

var BRDF_BlinnPhong = tslFn( function( { lightDirection } ) {
  var halfDir = lightDirection.add( positionViewDirection ).normalize();
  var dotNH = transformedNormalView.dot( halfDir ).clamp();
  var dotVH = positionViewDirection.dot( halfDir ).clamp();
  var F = F_Schlick( { f0: specularColor, f90: 1.0, dotVH } );
  var G = G_BlinnPhong_Implicit();
  var D = D_BlinnPhong( { dotNH } );
  return F.mul( G ).mul( D );
} );

class PhongLightingModel extends LightingModel {
  var specular:Bool;
  public function new( specular:Bool = true ) {
    super();
    this.specular = specular;
  }
  public function direct( { lightDirection, lightColor, reflectedLight } ) {
    var dotNL = transformedNormalView.dot( lightDirection ).clamp();
    var irradiance = dotNL.mul( lightColor );
    reflectedLight.directDiffuse.addAssign( irradiance.mul( BRDF_Lambert( { diffuseColor: diffuseColor.rgb } ) ) );
    if ( this.specular === true ) {
      reflectedLight.directSpecular.addAssign( irradiance.mul( BRDF_BlinnPhong( { lightDirection } ) ).mul( materialSpecularStrength ) );
    }
  }
  public function indirectDiffuse( { irradiance, reflectedLight } ) {
    reflectedLight.indirectDiffuse.addAssign( irradiance.mul( BRDF_Lambert( { diffuseColor } ) ) );
  }
}

export default PhongLightingModel;