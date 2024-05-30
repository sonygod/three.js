package three.js.nodes.accessors;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.core.UniformNode;
import three.js.nodes.PositionNode;
import three.js.nodes.NormalNode;
import three.js.nodes.TextureNode;
import three.js.core.IndexNode;
import three.js.utils.LoopNode;

class MorphNode extends Node {
    public var mesh:Mesh;
    public var morphBaseInfluence:UniformNode;

    public function new(mesh:Mesh) {
        super('void');
        this.mesh = mesh;
        this.morphBaseInfluence = UniformNode.create(1);
        this.updateType = NodeUpdateType.OBJECT;
    }

    public function setup(builder:{geometry:Geometry}) {
        var geometry:Geometry = builder.geometry;
        var hasMorphPosition:Bool = geometry.morphAttributes.position != null;
        var hasMorphNormals:Bool = geometry.morphAttributes.normal != null;

        var morphAttribute:Array<Dynamic> = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
        var morphTargetsCount:Int = morphAttribute != null ? morphAttribute.length : 0;

        var morphEntry:MorphEntry = getEntry(geometry);

        if (hasMorphPosition) {
            PositionNode.getInstance().mulAssign(morphBaseInfluence);
        }
        if (hasMorphNormals) {
            NormalNode.getInstance().mulAssign(morphBaseInfluence);
        }

        var width:Int = morphEntry.size.width;

        LoopNode.loop(morphTargetsCount, function(i:Int) {
            var influence:FloatNode = FloatNode.create(0);

            if (mesh.isInstancedMesh && mesh.morphTexture != null) {
                influence.assign(TextureNode.getInstance().load(mesh.morphTexture, ivec2(i + 1, IndexNode.getInstance().instanceIndex)).r);
            } else {
                influence.assign(ReferenceNode.getInstance('morphTargetInfluences', 'float').element(i).toVar());
            }

            if (hasMorphPosition) {
                PositionNode.getInstance().addAssign(getMorph({
                    bufferMap: morphEntry.texture,
                    influence: influence,
                    stride: morphEntry.stride,
                    width: width,
                    depth: i,
                    offset: 0
                }));
            }

            if (hasMorphNormals) {
                NormalNode.getInstance().addAssign(getMorph({
                    bufferMap: morphEntry.texture,
                    influence: influence,
                    stride: morphEntry.stride,
                    width: width,
                    depth: i,
                    offset: 1
                }));
            }
        });
    }

    public function update() {
        var morphBaseInfluence:UniformNode = this.morphBaseInfluence;
        if (mesh.geometry.morphTargetsRelative) {
            morphBaseInfluence.value = 1;
        } else {
            morphBaseInfluence.value = 1 - mesh.morphTargetInfluences.reduce(function(a:Float, b:Float) {
                return a + b;
            }, 0);
        }
    }

    static public function getEntry(geometry:Geometry):MorphEntry {
        // ...
    }

    static private function getMorph(params:{bufferMap:Texture, influence:Float, stride:Int, width:Int, depth:Int, offset:Int}):Float {
        // ...
    }
}

class MorphEntry {
    public var count:Int;
    public var texture:Texture;
    public var stride:Int;
    public var size:Vector2;
}

typedef MorphEntry = {
    count:Int,
    texture:Texture,
    stride:Int,
    size:Vector2
}