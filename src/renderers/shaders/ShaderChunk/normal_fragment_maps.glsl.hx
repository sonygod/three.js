package renderers.shaders.ShaderChunk;

class NormalFragmentMaps {
    public function new() {}

    #if USE_NORMALMAP_OBJECTSPACE

    public function getNormal(normalMap:Texture, vNormalMapUv:Vec2, vViewPosition:Vec3, faceDirection:Int, normalMatrix:Mat3):Vec3 {
        var normal:Vec3 = new Vec3();
        normal.x = texture2D(normalMap, vNormalMapUv).x * 2.0 - 1.0;
        normal.y = texture2D(normalMap, vNormalMapUv).y * 2.0 - 1.0;
        normal.z = texture2D(normalMap, vNormalMapUv).z * 2.0 - 1.0;

        #if FLIP_SIDED
        normal.x = -normal.x;
        normal.y = -normal.y;
        normal.z = -normal.z;
        #end

        #if DOUBLE_SIDED
        normal.x *= faceDirection;
        normal.y *= faceDirection;
        normal.z *= faceDirection;
        #end

        normal = normalize(normalMatrix * normal);
        return normal;

    }

    #elseif defined(USE_NORMALMAP_TANGENTSPACE)

    public function getNormal(normalMap:Texture, vNormalMapUv:Vec2, tbn:Mat3, normalScale:Float):Vec3 {
        var mapN:Vec3 = new Vec3();
        mapN.x = texture2D(normalMap, vNormalMapUv).x * 2.0 - 1.0;
        mapN.y = texture2D(normalMap, vNormalMapUv).y * 2.0 - 1.0;
        mapN.z = texture2D(normalMap, vNormalMapUv).z * 2.0 - 1.0;
        mapN.x *= normalScale;
        mapN.y *= normalScale;
        var normal:Vec3 = normalize(tbn * mapN);
        return normal;

    }

    #elseif defined(USE_BUMPMAP)

    public function getNormal(vViewPosition:Vec3, normal:Vec3, dHdxy_fwd:Vec2, faceDirection:Int):Vec3 {
        return perturbNormalArb(vViewPosition, normal, dHdxy_fwd, faceDirection);
    }

    #end
}