package three.src.renderers.shaders.ShaderChunk;

@:build(macro.Library.export())
class skinnormal_vertex {
    public static inline function main() {
        #if (USE_SKINNING) {
            var skinMatrix:Float32Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
            skinMatrix = Math.add(skinMatrix, Math.mul(skinWeight.x, boneMatX));
            skinMatrix = Math.add(skinMatrix, Math.mul(skinWeight.y, boneMatY));
            skinMatrix = Math.add(skinMatrix, Math.mul(skinWeight.z, boneMatZ));
            skinMatrix = Math.add(skinMatrix, Math.mul(skinWeight.w, boneMatW));
            skinMatrix = Math.mul(Math.mul(bindMatrixInverse, skinMatrix), bindMatrix);

            objectNormal = Math.xyz(Math.mul(skinMatrix, Math.vec4(objectNormal, 0.0)));

            #if (USE_TANGENT) {
                objectTangent = Math.xyz(Math.mul(skinMatrix, Math.vec4(objectTangent, 0.0)));
            }
        }
        return '';
    }
}