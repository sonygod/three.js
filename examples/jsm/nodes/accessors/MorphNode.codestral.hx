import three.nodes.core.Node;
import three.nodes.core.constants.NodeUpdateType;
import three.nodes.shadernode.ShaderNode;
import three.nodes.core.UniformNode;
import three.nodes.accessors.ReferenceNode;
import three.nodes.accessors.PositionNode;
import three.nodes.accessors.NormalNode;
import three.nodes.accessors.TextureNode;
import three.nodes.core.IndexNode;
import three.math.Vector2;
import three.math.Vector4;
import three.textures.DataArrayTexture;
import three.textures.Texture;
import three.constants.FloatType;
import three.nodes.utils.LoopNode;

class MorphNode extends Node {
    private var morphTextures:Map<Geometry, {count:Int, texture:Texture, stride:Int, size:Vector2}>;
    private var morphVec4:Vector4;

    public function new(mesh:Mesh) {
        super("void");
        this.mesh = mesh;
        this.morphBaseInfluence = new UniformNode(1);
        this.updateType = NodeUpdateType.OBJECT;
        this.morphTextures = new Map();
        this.morphVec4 = new Vector4();
    }

    private function getEntry(geometry:Geometry):{count:Int, texture:Texture, stride:Int, size:Vector2} {
        var hasMorphPosition = geometry.morphAttributes.position != null;
        var hasMorphNormals = geometry.morphAttributes.normal != null;
        var hasMorphColors = geometry.morphAttributes.color != null;

        var morphAttribute = geometry.morphAttributes.position ?? geometry.morphAttributes.normal ?? geometry.morphAttributes.color;
        var morphTargetsCount = morphAttribute != null ? morphAttribute.length : 0;

        var entry = this.morphTextures.get(geometry);

        if (entry == null || entry.count != morphTargetsCount) {
            if (entry != null) entry.texture.dispose();

            var morphTargets = geometry.morphAttributes.position ?? [];
            var morphNormals = geometry.morphAttributes.normal ?? [];
            var morphColors = geometry.morphAttributes.color ?? [];

            var vertexDataCount = 0;

            if (hasMorphPosition) vertexDataCount = 1;
            if (hasMorphNormals) vertexDataCount = 2;
            if (hasMorphColors) vertexDataCount = 3;

            var width = geometry.attributes.position.count * vertexDataCount;
            var height = 1;

            var maxTextureSize = 4096;

            if (width > maxTextureSize) {
                height = Math.ceil(width / maxTextureSize);
                width = maxTextureSize;
            }

            var buffer = new Float32Array(width * height * 4 * morphTargetsCount);

            var bufferTexture = new DataArrayTexture(buffer, width, height, morphTargetsCount);
            bufferTexture.type = FloatType;
            bufferTexture.needsUpdate = true;

            var vertexDataStride = vertexDataCount * 4;

            for (var i = 0; i < morphTargetsCount; i++) {
                var morphTarget = morphTargets[i];
                var morphNormal = morphNormals[i];
                var morphColor = morphColors[i];

                var offset = width * height * 4 * i;

                for (var j = 0; j < morphTarget.count; j++) {
                    var stride = j * vertexDataStride;

                    if (hasMorphPosition) {
                        this.morphVec4.fromBufferAttribute(morphTarget, j);

                        buffer[offset + stride + 0] = this.morphVec4.x;
                        buffer[offset + stride + 1] = this.morphVec4.y;
                        buffer[offset + stride + 2] = this.morphVec4.z;
                        buffer[offset + stride + 3] = 0;
                    }

                    if (hasMorphNormals) {
                        this.morphVec4.fromBufferAttribute(morphNormal, j);

                        buffer[offset + stride + 4] = this.morphVec4.x;
                        buffer[offset + stride + 5] = this.morphVec4.y;
                        buffer[offset + stride + 6] = this.morphVec4.z;
                        buffer[offset + stride + 7] = 0;
                    }

                    if (hasMorphColors) {
                        this.morphVec4.fromBufferAttribute(morphColor, j);

                        buffer[offset + stride + 8] = this.morphVec4.x;
                        buffer[offset + stride + 9] = this.morphVec4.y;
                        buffer[offset + stride + 10] = this.morphVec4.z;
                        buffer[offset + stride + 11] = morphColor.itemSize == 4 ? this.morphVec4.w : 1;
                    }
                }
            }

            entry = {
                count: morphTargetsCount,
                texture: bufferTexture,
                stride: vertexDataCount,
                size: new Vector2(width, height)
            };

            this.morphTextures.set(geometry, entry);

            geometry.addEventListener('dispose', function() {
                bufferTexture.dispose();
                this.morphTextures.remove(geometry);
            });
        }

        return entry;
    }

    public function setup(builder:Builder) {
        var geometry = builder.geometry;

        var hasMorphPosition = geometry.morphAttributes.position != null;
        var hasMorphNormals = geometry.morphAttributes.normal != null;

        var morphAttribute = geometry.morphAttributes.position ?? geometry.morphAttributes.normal ?? geometry.morphAttributes.color;
        var morphTargetsCount = morphAttribute != null ? morphAttribute.length : 0;

        var { texture: bufferMap, stride, size } = this.getEntry(geometry);

        if (hasMorphPosition) PositionNode.instance.mulAssign(this.morphBaseInfluence);
        if (hasMorphNormals) NormalNode.instance.mulAssign(this.morphBaseInfluence);

        var width = Std.parseInt(size.width);

        LoopNode.loop(morphTargetsCount, function(i:Int) {
            var influence = new ShaderNode.FloatNode(0).toVar();

            if (this.mesh.isInstancedMesh && this.mesh.morphTexture != null) {
                influence.assign(TextureNode.textureLoad(this.mesh.morphTexture, new ShaderNode.IVec2Node(i + 1, IndexNode.instanceIndex)).r);
            } else {
                influence.assign(ReferenceNode.reference("morphTargetInfluences", "float").element(i).toVar());
            }

            if (hasMorphPosition) {
                PositionNode.instance.addAssign(this.getMorph({
                    bufferMap: bufferMap,
                    influence: influence,
                    stride: stride,
                    width: width,
                    depth: i,
                    offset: 0
                }));
            }

            if (hasMorphNormals) {
                NormalNode.instance.addAssign(this.getMorph({
                    bufferMap: bufferMap,
                    influence: influence,
                    stride: stride,
                    width: width,
                    depth: i,
                    offset: 1
                }));
            }
        });
    }

    public function update() {
        if (this.mesh.geometry.morphTargetsRelative) {
            this.morphBaseInfluence.value = 1;
        } else {
            this.morphBaseInfluence.value = 1 - this.mesh.morphTargetInfluences.reduce(function(a, b) return a + b, 0);
        }
    }

    private function getMorph(params:{bufferMap:Texture, influence:ShaderNode.FloatNode, stride:Int, width:Int, depth:Int, offset:Int}):ShaderNode.Vec4Node {
        var texelIndex = new ShaderNode.IntNode(IndexNode.vertexIndex).mul(params.stride).add(params.offset);

        var y = texelIndex.div(params.width);
        var x = texelIndex.sub(y.mul(params.width));

        var bufferAttrib = TextureNode.textureLoad(params.bufferMap, new ShaderNode.IVec2Node(x, y)).depth(params.depth);

        return bufferAttrib.mul(params.influence);
    }
}

export default MorphNode;