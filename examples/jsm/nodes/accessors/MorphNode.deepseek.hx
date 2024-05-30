import three.Node;
import three.core.NodeUpdateType;
import three.shadernode.ShaderNode;
import three.core.UniformNode;
import three.core.IndexNode;
import three.utils.LoopNode;
import three.core.constants.NodeUpdateType;
import three.core.DataArrayTexture;
import three.core.Vector2;
import three.core.Vector4;
import three.core.FloatType;

class MorphNode extends Node {

    public var mesh:Dynamic;
    public var morphBaseInfluence:UniformNode;

    public function new(mesh:Dynamic) {
        super('void');
        this.mesh = mesh;
        this.morphBaseInfluence = new UniformNode(1);
        this.updateType = NodeUpdateType.OBJECT;
    }

    public function setup(builder:Dynamic) {
        var geometry = builder.geometry;
        var hasMorphPosition = geometry.morphAttributes.position !== undefined;
        var hasMorphNormals = geometry.morphAttributes.normal !== undefined;
        var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
        var morphTargetsCount = (morphAttribute !== undefined) ? morphAttribute.length : 0;
        var entry = getEntry(geometry);
        var texture = entry.texture;
        var stride = entry.stride;
        var size = entry.size;
        var width = Std.int(size.width);
        var bufferMap = texture;
        var depth = Std.int(IndexNode.instanceIndex);
        var offset = Std.int(0);
        var influence = new ShaderNode.float(0).toVar();
        var i = Std.int(0);

        if (hasMorphPosition) {
            positionLocal.mulAssign(this.morphBaseInfluence);
        }
        if (hasMorphNormals) {
            normalLocal.mulAssign(this.morphBaseInfluence);
        }

        LoopNode.loop(morphTargetsCount, ({i}) -> {
            if (this.mesh.isInstancedMesh && (this.mesh.morphTexture !== null && this.mesh.morphTexture !== undefined)) {
                influence.assign(ShaderNode.textureLoad(this.mesh.morphTexture, new ShaderNode.ivec2(i.add(1), IndexNode.instanceIndex)).r);
            } else {
                influence.assign(reference('morphTargetInfluences', 'float').element(i).toVar());
            }

            if (hasMorphPosition) {
                positionLocal.addAssign(getMorph({
                    bufferMap: bufferMap,
                    influence: influence,
                    stride: stride,
                    width: width,
                    depth: depth,
                    offset: offset
                }));
            }

            if (hasMorphNormals) {
                normalLocal.addAssign(getMorph({
                    bufferMap: bufferMap,
                    influence: influence,
                    stride: stride,
                    width: width,
                    depth: depth,
                    offset: offset
                }));
            }
        });
    }

    public function update() {
        var morphBaseInfluence = this.morphBaseInfluence;
        if (this.mesh.geometry.morphTargetsRelative) {
            morphBaseInfluence.value = 1;
        } else {
            morphBaseInfluence.value = 1 - this.mesh.morphTargetInfluences.reduce((a, b) -> a + b, 0);
        }
    }
}

static var morphTextures = new WeakMap();
static var morphVec4 = new Vector4();

static function getEntry(geometry:Dynamic) {
    // ...
}

static function getMorph(params:Dynamic) {
    // ...
}

three.addNodeClass('MorphNode', MorphNode);