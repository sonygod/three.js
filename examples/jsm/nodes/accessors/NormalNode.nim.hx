import three.nodes.core.AttributeNode;
import three.nodes.core.VaryingNode;
import three.nodes.core.PropertyNode;
import three.nodes.accessors.CameraNode;
import three.nodes.accessors.ModelNode;
import three.nodes.shadernode.ShaderNode;

class NormalNode {
    public static var normalGeometry:AttributeNode<Vec3> = AttributeNode.attribute<Vec3>( 'normal', Vec3( 0, 1, 0 ) );
    public static var normalLocal:VaryingNode<Vec3> = VaryingNode.varying<Vec3>( normalGeometry ).toVar<Vec3>( 'normalLocal' );
    public static var normalView:VaryingNode<Vec3> = VaryingNode.varying<Vec3>( ModelNode.modelNormalMatrix.mul( normalLocal ), 'normalView' ).normalize();
    public static var normalWorld:VaryingNode<Vec3> = VaryingNode.varying<Vec3>( normalView.transformDirection( CameraNode.cameraViewMatrix ), 'normalWorld' ).normalize();
    public static var transformedNormalView:PropertyNode<Vec3> = PropertyNode.property<Vec3>( 'vec3', 'transformedNormalView' );
    public static var transformedNormalWorld:Vec3 = transformedNormalView.transformDirection( CameraNode.cameraViewMatrix ).normalize();
    public static var transformedClearcoatNormalView:PropertyNode<Vec3> = PropertyNode.property<Vec3>( 'vec3', 'transformedClearcoatNormalView' );
}