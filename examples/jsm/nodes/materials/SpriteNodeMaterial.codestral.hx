import NodeMaterial;
import UniformNode.uniform;
import CameraNode.cameraProjectionMatrix;
import MaterialNode.materialRotation;
import ModelNode.modelViewMatrix;
import ModelNode.modelWorldMatrix;
import PositionNode.positionLocal;
import ShaderNode.float;
import ShaderNode.vec2;
import ShaderNode.vec3;
import ShaderNode.vec4;
import three.SpriteMaterial;

class SpriteNodeMaterial extends NodeMaterial {
    public var positionNode:Dynamic;
    public var rotationNode:Dynamic;
    public var scaleNode:Dynamic;

    public function new(parameters:Dynamic) {
        super();

        this.isSpriteNodeMaterial = true;

        this.lights = false;
        this.normals = false;

        this.positionNode = null;
        this.rotationNode = null;
        this.scaleNode = null;

        var defaultValues = new SpriteMaterial();
        this.setDefaultValues(defaultValues);

        this.setValues(parameters);
    }

    public function setupPosition(object:Dynamic, context:Dynamic):Dynamic {
        var vertex = positionLocal;
        var mvPosition = modelViewMatrix.mul(vec3(this.positionNode != null ? this.positionNode : 0));
        var scale = vec2(modelWorldMatrix[0].xyz.length(), modelWorldMatrix[1].xyz.length());

        if (this.scaleNode != null) {
            scale = scale.mul(this.scaleNode);
        }

        var alignedPosition = vertex.xy;

        if (object.center != null && Reflect.hasField(object.center, "isVector2") && object.center.isVector2) {
            alignedPosition = alignedPosition.sub(uniform(object.center).sub(0.5));
        }

        alignedPosition = alignedPosition.mul(scale);

        var rotation = float(this.rotationNode != null ? this.rotationNode : materialRotation);

        var rotatedPosition = alignedPosition.rotate(rotation);

        mvPosition = vec4(mvPosition.xy.add(rotatedPosition), mvPosition.zw);

        var modelViewProjection = cameraProjectionMatrix.mul(mvPosition);

        context.vertex = vertex;

        return modelViewProjection;
    }

    public function copy(source:SpriteNodeMaterial):SpriteNodeMaterial {
        this.positionNode = source.positionNode;
        this.rotationNode = source.rotationNode;
        this.scaleNode = source.scaleNode;

        return super.copy(source);
    }
}