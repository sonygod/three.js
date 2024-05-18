package renderers.shaders.ShaderChunk;

class SkinningVertex
{
    #if USE_SKINNING

    public function new()
    {
        var skinVertex:Vec4 = bindMatrix * new Vec4(transformed, 1.0);

        var skinned:Vec4 = new Vec4(0.0, 0.0, 0.0, 0.0);
        skinned += boneMatX * skinVertex * skinWeight.x;
        skinned += boneMatY * skinVertex * skinWeight.y;
        skinned += boneMatZ * skinVertex * skinWeight.z;
        skinned += boneMatW * skinVertex * skinWeight.w;

        transformed = (bindMatrixInverse * skinned).xyz;
    }

    #end
}