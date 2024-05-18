package three.js.examples.javascript.nodes.accessors;

import three.js.core.Node.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shader.ShaderNode;
import three.js.core.UniformNode;
import three.js.nodes.ReferenceNode;
import three.js.nodes.PositionNode;
import three.js.nodes.NormalNode;
import three.js.nodes.TextureNode;
import three.js.core.IndexNode;
import three.js.utils.LoopNode;
import three.js.DataArrayTexture;
import three.js.Vector2;
import three.js.Vector4;
import three.js.FloatType;

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
        var geometry:Dynamic = builder.geometry;
        var hasMorphPosition:Bool = geometry.morphAttributes.position != null;
        var hasMorphNormals:Bool = geometry.morphAttributes.normal != null;

        var morphAttribute:Dynamic = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
        var morphTargetsCount:Int = morphAttribute != null ? morphAttribute.length : 0;

        // nodes
        var entry:Dynamic = getEntry(geometry);

        if (hasMorphPosition) positionLocal.mulAssign(this.morphBaseInfluence);
        if (hasMorphNormals) normalLocal.mulAssign(this.morphBaseInfluence);

        var width:Int = Std.int(entry.size.width);

        LoopNode.loop(morphTargetsCount, function(i:Int) {
            var influence:ShaderNode = ShaderNode.float(0).toVar();

            if (this.mesh.isInstancedMesh && this.mesh.morphTexture != null) {
                influence.assign(TextureNode.textureLoad(this.mesh.morphTexture, new Vector2(i + 1, instanceIndex)).r);
            } else {
                influence.assign(ReferenceNode.reference('morphTargetInfluences', 'float').element(i).toVar());
            }

            if (hasMorphPosition) {
                positionLocal.addAssign(getMorph({
                    bufferMap: entry.texture,
                    influence: influence,
                    stride: entry.stride,
                    width: width,
                    depth: i,
                    offset: 0
                }));
            }

            if (hasMorphNormals) {
                normalLocal.addAssign(getMorph({
                    bufferMap: entry.texture,
                    influence: influence,
                    stride: entry.stride,
                    width: width,
                    depth: i,
                    offset: 1
                }));
            }
        });
    }

    public function update() {
        var morphBaseInfluence:UniformNode = this.morphBaseInfluence;

        if (this.mesh.geometry.morphTargetsRelative) {
            morphBaseInfluence.value = 1;
        } else {
            morphBaseInfluence.value = 1 - this.mesh.morphTargetInfluences.reduce(function(a:Float, b:Float) {
                return a + b;
            }, 0);
        }
    }
}

function getMorph(params:Dynamic):ShaderNode {
    var texelIndex:ShaderNode = ShaderNode.int(vertexIndex).mul(params.stride).add(params.offset);

    var y:ShaderNode = texelIndex.div(params.width);
    var x:ShaderNode = texelIndex.sub(y.mul(params.width));

    var bufferAttrib:ShaderNode = TextureNode.textureLoad(params.bufferMap, new Vector2(x, y)).depth(params.depth);

    return bufferAttrib.mul(params.influence);
}

function getEntry(geometry:Dynamic):Dynamic {
    var hasMorphPosition:Bool = geometry.morphAttributes.position != null;
    var hasMorphNormals:Bool = geometry.morphAttributes.normal != null;
    var hasMorphColors:Bool = geometry.morphAttributes.color != null;

    var morphAttribute:Dynamic = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
    var morphTargetsCount:Int = morphAttribute != null ? morphAttribute.length : 0;

    var entry:Dynamic = morphTextures.get(geometry);

    if (entry == null || entry.count != morphTargetsCount) {
        if (entry != null) entry.texture.dispose();

        var morphTargets:Array<Dynamic> = geometry.morphAttributes.position || [];
        var morphNormals:Array<Dynamic> = geometry.morphAttributes.normal || [];
        var morphColors:Array<Dynamic> = geometry.morphAttributes.color || [];

        var vertexDataCount:Int = 0;

        if (hasMorphPosition) vertexDataCount = 1;
        if (hasMorphNormals) vertexDataCount = 2;
        if (hasMorphColors) vertexDataCount = 3;

        var width:Int = geometry.attributes.position.count * vertexDataCount;
        var height:Int = 1;

        var maxTextureSize:Int = 4096; // @TODO: Use 'capabilities.maxTextureSize'

        if (width > maxTextureSize) {
            height = Math.ceil(width / maxTextureSize);
            width = maxTextureSize;
        }

        var buffer:Float32Array = new Float32Array(width * height * 4 * morphTargetsCount);

        var bufferTexture:DataArrayTexture = new DataArrayTexture(buffer, width, height, morphTargetsCount);
        bufferTexture.type = FloatType;
        bufferTexture.needsUpdate = true;

        // fill buffer

        var vertexDataStride:Int = vertexDataCount * 4;

        for (i in 0...morphTargetsCount) {
            var morphTarget:Dynamic = morphTargets[i];
            var morphNormal:Dynamic = morphNormals[i];
            var morphColor:Dynamic = morphColors[i];

            var offset:Int = width * height * 4 * i;

            for (j in 0...morphTarget.count) {
                var stride:Int = j * vertexDataStride;

                if (hasMorphPosition) {
                    morphVec4.fromBufferAttribute(morphTarget, j);

                    buffer[offset + stride + 0] = morphVec4.x;
                    buffer[offset + stride + 1] = morphVec4.y;
                    buffer[offset + stride + 2] = morphVec4.z;
                    buffer[offset + stride + 3] = 0;
                }

                if (hasMorphNormals) {
                    morphVec4.fromBufferAttribute(morphNormal, j);

                    buffer[offset + stride + 4] = morphVec4.x;
                    buffer[offset + stride + 5] = morphVec4.y;
                    buffer[offset + stride + 6] = morphVec4.z;
                    buffer[offset + stride + 7] = 0;
                }

                if (hasMorphColors) {
                    morphVec4.fromBufferAttribute(morphColor, j);

                    buffer[offset + stride + 8] = morphVec4.x;
                    buffer[offset + stride + 9] = morphVec4.y;
                    buffer[offset + stride + 10] = morphVec4.z;
                    buffer[offset + stride + 11] = (morphColor.itemSize == 4) ? morphVec4.w : 1;
                }
            }
        }

        entry = {
            count: morphTargetsCount,
            texture: bufferTexture,
            stride: vertexDataCount,
            size: new Vector2(width, height)
        };

        morphTextures.set(geometry, entry);

        function disposeTexture() {
            bufferTexture.dispose();

            morphTextures.remove(geometry);

            geometry.removeEventListener('dispose', disposeTexture);
        }

        geometry.addEventListener('dispose', disposeTexture);
    }

    return entry;
}

var morphTextures:WeakMap<Dynamic, Dynamic> = new WeakMap();

var morphVec4:Vector4 = new Vector4();