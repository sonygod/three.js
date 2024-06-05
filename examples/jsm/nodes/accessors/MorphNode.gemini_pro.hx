import Node from "../core/Node";
import {NodeUpdateType} from "../core/constants";
import {float, nodeProxy, tslFn} from "../shadernode/ShaderNode";
import {uniform} from "../core/UniformNode";
import {reference} from "./ReferenceNode";
import {positionLocal} from "./PositionNode";
import {normalLocal} from "./NormalNode";
import {textureLoad} from "./TextureNode";
import {instanceIndex, vertexIndex} from "../core/IndexNode";
import {ivec2, int} from "../shadernode/ShaderNode";
import {DataArrayTexture, Vector2, Vector4, FloatType} from "three";
import {loop} from "../utils/LoopNode";

class MorphNode extends Node {

    public mesh:dynamic;
    public morphBaseInfluence:uniform;

    public constructor(mesh:dynamic) {
        super("void");
        this.mesh = mesh;
        this.morphBaseInfluence = uniform(1);
        this.updateType = NodeUpdateType.OBJECT;
    }

    public setup(builder:dynamic):Void {
        var geometry = builder.geometry;

        var hasMorphPosition = geometry.morphAttributes.position != null;
        var hasMorphNormals = geometry.morphAttributes.normal != null;

        var morphAttribute = geometry.morphAttributes.position != null ? geometry.morphAttributes.position : (geometry.morphAttributes.normal != null ? geometry.morphAttributes.normal : geometry.morphAttributes.color);
        var morphTargetsCount = morphAttribute != null ? morphAttribute.length : 0;

        var bufferMap:DataArrayTexture;
        var stride:Int;
        var size:Vector2;
        {
            var entry = getEntry(geometry);
            bufferMap = entry.texture;
            stride = entry.stride;
            size = entry.size;
        }

        if (hasMorphPosition) {
            positionLocal.mulAssign(this.morphBaseInfluence);
        }
        if (hasMorphNormals) {
            normalLocal.mulAssign(this.morphBaseInfluence);
        }

        var width = int(size.width);

        loop(morphTargetsCount, function(i:Int) {
            var influence = float(0).toVar();

            if (this.mesh.isInstancedMesh && (this.mesh.morphTexture != null && this.mesh.morphTexture != null)) {
                influence.assign(textureLoad(this.mesh.morphTexture, ivec2(int(i).add(1), int(instanceIndex))).r);
            } else {
                influence.assign(reference("morphTargetInfluences", "float").element(i).toVar());
            }

            if (hasMorphPosition) {
                positionLocal.addAssign(getMorph({
                    bufferMap: bufferMap,
                    influence: influence,
                    stride: stride,
                    width: width,
                    depth: i,
                    offset: int(0)
                }));
            }

            if (hasMorphNormals) {
                normalLocal.addAssign(getMorph({
                    bufferMap: bufferMap,
                    influence: influence,
                    stride: stride,
                    width: width,
                    depth: i,
                    offset: int(1)
                }));
            }
        });
    }

    public update():Void {
        var morphBaseInfluence = this.morphBaseInfluence;

        if (this.mesh.geometry.morphTargetsRelative) {
            morphBaseInfluence.value = 1;
        } else {
            morphBaseInfluence.value = 1 - this.mesh.morphTargetInfluences.reduce((a, b) => a + b, 0);
        }
    }
}

var morphTextures = new WeakMap();
var morphVec4 = new Vector4();

var getMorph = tslFn(function(params: {bufferMap:DataArrayTexture, influence:dynamic, stride:Int, width:Int, depth:Int, offset:Int}) {
    var texelIndex = int(vertexIndex).mul(params.stride).add(params.offset);

    var y = texelIndex.div(params.width);
    var x = texelIndex.sub(y.mul(params.width));

    var bufferAttrib = textureLoad(params.bufferMap, ivec2(x, y)).depth(params.depth);

    return bufferAttrib.mul(params.influence);
});

function getEntry(geometry:dynamic):{count:Int, texture:DataArrayTexture, stride:Int, size:Vector2} {
    var hasMorphPosition = geometry.morphAttributes.position != null;
    var hasMorphNormals = geometry.morphAttributes.normal != null;
    var hasMorphColors = geometry.morphAttributes.color != null;

    var morphAttribute = geometry.morphAttributes.position != null ? geometry.morphAttributes.position : (geometry.morphAttributes.normal != null ? geometry.morphAttributes.normal : geometry.morphAttributes.color);
    var morphTargetsCount = morphAttribute != null ? morphAttribute.length : 0;

    var entry = morphTextures.get(geometry);

    if (entry == null || entry.count != morphTargetsCount) {
        if (entry != null) entry.texture.dispose();

        var morphTargets = geometry.morphAttributes.position != null ? geometry.morphAttributes.position : [];
        var morphNormals = geometry.morphAttributes.normal != null ? geometry.morphAttributes.normal : [];
        var morphColors = geometry.morphAttributes.color != null ? geometry.morphAttributes.color : [];

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
                    buffer[offset + stride + 11] = morphColor.itemSize == 4 ? morphVec4.w : 1;
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
            morphTextures.delete(geometry);
            geometry.removeEventListener("dispose", disposeTexture);
        }

        geometry.addEventListener("dispose", disposeTexture);
    }

    return entry;
}

export default MorphNode;

export var morphReference = nodeProxy(MorphNode);