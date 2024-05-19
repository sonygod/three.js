package three.js.examples.jm.nodes.accessors;

import three.js.nodes.BitangentNode;
import three.js.nodes.NormalNode;
import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;
import three.js.core.PropertyNode;
import three.js.nodes.PositionNode;

class AccessorsUtils {

    static var TBNViewMatrix = new Mat3(
        TangentNode.tangentView,
        BitangentNode.bitangentView,
        NormalNode.normalView
    );

    static var parallaxDirection = PositionNode.positionViewDirection.mul(TBNViewMatrix); ///*.normalize()*/
    static function parallaxUV(uv:Vec2, scale:Float) {
        return uv.sub(parallaxDirection.mul(scale));
    }

    static var transformedBentNormalView = (() -> {

        // https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy

        var bentNormal = PropertyNode.anisotropyB.cross(PositionNode.positionViewDirection);
        bentNormal = bentNormal.cross(PropertyNode.anisotropyB).normalize();
        bentNormal = MathNode.mix(bentNormal, NormalNode.transformedNormalView, PropertyNode.anisotropy.mul(PropertyNode.roughness.oneMinus()).oneMinus().pow(2).pow(2)).normalize();

        return bentNormal;

    })();

}