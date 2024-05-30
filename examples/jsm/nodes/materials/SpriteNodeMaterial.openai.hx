package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.NodeMaterial;
import three.js.examples.jsm.core.UniformNode;
import three.js.accessors.CameraNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.ModelNode;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

import three.SpriteMaterial;

class SpriteNodeMaterial extends NodeMaterial {

    public var isSpriteNodeMaterial:Bool = true;

    public var lights:Bool = false;
    public var normals:Bool = false;

    public var positionNode:Node = null;
    public var rotationNode:Node = null;
    public var scaleNode:Node = null;

    public function new(?parameters:Dynamic) {
        super();

        var defaultValues:SpriteMaterial = new SpriteMaterial();

        setDefaultValues(defaultValues);
        setValues(parameters);
    }

    public function setupPosition(object:Dynamic, context:Dynamic):Void {
        var positionNode:Node = this.positionNode;
        var rotationNode:Node = this.rotationNode;
        var scaleNode:Node = this.scaleNode;

        var vertex:ShaderNode = positionLocal;

        var mvPosition:Vec4 = modelViewMatrix.multiply(new Vec3(positionNode != null ? positionNode : 0));

        var scale:Vec2 = new Vec2(modelWorldMatrix[0].xyz.length(), modelWorldMatrix[1].xyz.length());

        if (scaleNode != null) {
            scale = scale.multiply(scaleNode);
        }

        var alignedPosition:Vec2 = vertex.xy;

        if (object.center != null && Std.is(object.center, Vec2)) {
            alignedPosition = alignedPosition.subtract(uniform(object.center).subtract(0.5));
        }

        alignedPosition = alignedPosition.multiply(scale);

        var rotation:Float = rotationNode != null ? rotationNode : materialRotation;

        var rotatedPosition:Vec2 = alignedPosition.rotate(rotation);

        mvPosition = new Vec4(mvPosition.xy.add(rotatedPosition), mvPosition.zw);

        var modelViewProjection:Mat4 = cameraProjectionMatrix.multiply(mvPosition);

        context.vertex = vertex;

        return modelViewProjection;
    }

    override public function copy(source:SpriteNodeMaterial):SpriteNodeMaterial {
        this.positionNode = source.positionNode;
        this.rotationNode = source.rotationNode;
        this.scaleNode = source.scaleNode;

        return super.copy(source);
    }
}

addNodeMaterial("SpriteNodeMaterial", SpriteNodeMaterial);