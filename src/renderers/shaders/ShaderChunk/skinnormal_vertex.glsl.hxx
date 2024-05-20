class SkinNormalVertexShader {
    static var shader:String =
        #if USE_SKINNING
            var skinMatrix:Mat4 = Mat4.identity();
            skinMatrix = Mat4.add(skinMatrix, Mat4.mulS(skinWeight.x, boneMatX));
            skinMatrix = Mat4.add(skinMatrix, Mat4.mulS(skinWeight.y, boneMatY));
            skinMatrix = Mat4.add(skinMatrix, Mat4.mulS(skinWeight.z, boneMatZ));
            skinMatrix = Mat4.add(skinMatrix, Mat4.mulS(skinWeight.w, boneMatW));
            skinMatrix = Mat4.mul(Mat4.mul(bindMatrixInverse, skinMatrix), bindMatrix);

            objectNormal = Mat4.mulV(skinMatrix, Vec4.make(objectNormal, 0.0)).toVec3();

            #if USE_TANGENT
                objectTangent = Mat4.mulV(skinMatrix, Vec4.make(objectTangent, 0.0)).toVec3();
            #end
        #end;
}