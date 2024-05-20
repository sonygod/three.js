class SkinbaseVertex {
    public static var USE_SKINNING:Bool;

    public static function getBoneMatrix(skinIndex:Float):Mat4 {
        var boneMatX:Mat4 = getBoneMatrix(skinIndex.x);
        var boneMatY:Mat4 = getBoneMatrix(skinIndex.y);
        var boneMatZ:Mat4 = getBoneMatrix(skinIndex.z);
        var boneMatW:Mat4 = getBoneMatrix(skinIndex.w);

        return boneMatX; // 这里只是返回boneMatX，因为boneMatY, boneMatZ, boneMatW没有被使用
    }
}