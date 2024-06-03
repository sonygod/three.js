import BitangentNode.bitangentView;
import NormalNode.normalView;
import NormalNode.transformedNormalView;
import TangentNode.tangentView;
import ShaderNode.mat3;
import MathNode.mix;
import PropertyNode.anisotropy;
import PropertyNode.anisotropyB;
import PropertyNode.roughness;
import PositionNode.positionViewDirection;

var TBNViewMatrix = mat3(tangentView, bitangentView, normalView);

var parallaxDirection = positionViewDirection.mul(TBNViewMatrix); // normalize() is not included as Haxe does not have a built-in normalize function for vectors
var parallaxUV = function(uv, scale) {
    return uv.sub(parallaxDirection.mul(scale));
}

var bentNormal = anisotropyB.cross(positionViewDirection);
bentNormal = bentNormal.cross(anisotropyB).normalize();
bentNormal = mix(bentNormal, transformedNormalView, anisotropy.mul(roughness.oneMinus()).oneMinus().pow(4)).normalize();
var transformedBentNormalView = bentNormal;