import TangentNode.tangentView;
import BitangentNode.bitangentView;
import NormalNode.normalView;
import NormalNode.transformedNormalView;
import ShaderNode.mat3;
import MathNode.mix;
import PropertyNode.anisotropy;
import PropertyNode.anisotropyB;
import PropertyNode.roughness;
import PositionNode.positionViewDirection;

class AccessorsUtils {
    public static var TBNViewMatrix:mat3 = mat3(tangentView, bitangentView, normalView);

    public static var parallaxDirection:Dynamic = positionViewDirection.mul(TBNViewMatrix);
    public static function parallaxUV(uv:Dynamic, scale:Dynamic):Dynamic {
        return uv.sub(parallaxDirection.mul(scale));
    }

    public static var transformedBentNormalView:Dynamic = ( () -> {
        // https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy
        let bentNormal:Dynamic = anisotropyB.cross(positionViewDirection);
        bentNormal = bentNormal.cross(anisotropyB).normalize();
        bentNormal = mix(bentNormal, transformedNormalView, anisotropy.mul(roughness.oneMinus()).oneMinus().pow2().pow2()).normalize();
        return bentNormal;
    } )();
}