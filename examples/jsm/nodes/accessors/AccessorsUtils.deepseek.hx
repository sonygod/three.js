import three.js.examples.jsm.nodes.accessors.BitangentNode;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.TangentNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.math.MathNode;
import three.js.examples.jsm.core.PropertyNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;

class AccessorsUtils {

    static var TBNViewMatrix = ShaderNode.mat3( TangentNode.tangentView, BitangentNode.bitangentView, NormalNode.normalView );

    static var parallaxDirection = PositionNode.positionViewDirection.mul( TBNViewMatrix );
    static function parallaxUV(uv:Dynamic, scale:Dynamic):Dynamic {
        return uv.sub( parallaxDirection.mul( scale ) );
    }

    static var transformedBentNormalView = (function() {

        var bentNormal = PropertyNode.anisotropyB.cross( PositionNode.positionViewDirection );
        bentNormal = bentNormal.cross( PropertyNode.anisotropyB ).normalize();
        bentNormal = MathNode.mix( bentNormal, NormalNode.transformedNormalView, PropertyNode.anisotropy.mul( PropertyNode.roughness.oneMinus() ).oneMinus().pow2().pow2() ).normalize();

        return bentNormal;

    })();

}