class NormalFragmentBegin {
    public static var faceDirection(gl_FrontFacing:Bool):Float {
        return if (gl_FrontFacing) 1.0 else -1.0;
    }

    public static function normal(vViewPosition:Vec3, vNormal:Vec3, faceDirection:Float, FLAT_SHADED:Bool, DOUBLE_SIDED:Bool):Vec3 {
        var normal:Vec3;

        if (FLAT_SHADED) {
            var fdx:Vec3 = dFdx(vViewPosition);
            var fdy:Vec3 = dFdy(vViewPosition);
            normal = Vec3.normalize(Vec3.cross(fdx, fdy));
        } else {
            normal = Vec3.normalize(vNormal);
            if (DOUBLE_SIDED) {
                normal = Vec3.multiplyScalar(normal, faceDirection);
            }
        }

        return normal;
    }

    // ... 其他函数和变量转换 ...
}