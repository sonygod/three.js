package three.js.examples.jsm.nodes.materials;

import three.js.core.UniformNode;
import three.js.accessors.CameraNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.ModelNode;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;
import three.js.SpriteMaterial;

class SpriteNodeMaterial extends NodeMaterial {
    public var isSpriteNodeMaterial:Bool = true;
    public var lights:Bool = false;
    public var normals:Bool = false;
    public var positionNode:Null<ShaderNode> = null;
    public var rotationNode:Null<ShaderNode> = null;
    public var scaleNode:Null<ShaderNode> = null;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new SpriteMaterial());
        setValues(parameters);
    }

    public function setupPosition(object:Dynamic, context:Dynamic):Mat4 {
        var positionNode:ShaderNode = this.positionNode;
        var rotationNode:ShaderNode = this.rotationNode;
        var scaleNode:ShaderNode = this.scaleNode;
        var vertex:ShaderNode = PositionNode.positionLocal;
        var mvPosition:Vec3 = ModelNode.modelViewMatrix.mult Vec3.create(positionNode != null ? positionNode : 0);
        var scale:Vec2 = new Vec2(ModelNode.modelWorldMatrix[0].xyz.length(), ModelNode.modelWorldMatrix[1].xyz.length());
        if (scaleNode != null) {
            scale = scale.mult(scaleNode);
        }
        var alignedPosition:Vec2 = vertex.xy;
        if (object.center != null && object.center.isVector2) {
            alignedPosition = alignedPosition.sub(UniformNode.uniform(object.center).sub(0.5));
        }
        alignedPosition = alignedPosition.mult(scale);
        var rotation:Float = rotationNode != null ? rotationNode : MaterialNode.materialRotation;
        var rotatedPosition:Vec2 = alignedPosition.rotate(rotation);
        mvPosition = Vec4.create(mvPosition.xy.add(rotatedPosition), mvPosition.zw);
        var modelViewProjection:Mat4 = CameraNode.cameraProjectionMatrix.mult(mvPosition);
        context.vertex = vertex;
        return modelViewProjection;
    }

    public override function copy(source:SpriteNodeMaterial):SpriteNodeMaterial {
        this.positionNode = source.positionNode;
        this.rotationNode = source.rotationNode;
        this.scaleNode = source.scaleNode;
        return super.copy(source);
    }
}

registerNodeMaterial('SpriteNodeMaterial', SpriteNodeMaterial);