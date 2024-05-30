package three.js.src.renderers.shaders.ShaderChunk;

class normal_fragment_begin {
    public static function main() {
        var faceDirection:Float = gl_FrontFacing ? 1.0 : -1.0;

        #if (FLAT_SHADED) {
            var fdx:Vec3 = dFdx(vViewPosition);
            var fdy:Vec3 = dFdy(vViewPosition);
            var normal:Vec3 = normalize(cross(fdx, fdy));
        } else {
            var normal:Vec3 = normalize(vNormal);
            #if (DOUBLE_SIDED) {
                normal *= faceDirection;
            }
        }

        #if (defined(USE_NORMALMAP_TANGENTSPACE) || defined(USE_CLEARCOAT_NORMALMAP) || defined(USE_ANISOTROPY)) {
            #if (USE_TANGENT) {
                var tbn:Mat3 = mat3(normalize(vTangent), normalize(vBitangent), normal);
            } else {
                var tbn:Mat3 = getTangentFrame(-vViewPosition, normal,
                    #if (defined(USE_NORMALMAP))
                        vNormalMapUv
                    #elseif (defined(USE_CLEARCOAT_NORMALMAP))
                        vClearcoatNormalMapUv
                    #else
                        vUv
                    #end
                );
            }
            #if (DOUBLE_SIDED && !FLAT_SHADED) {
                tbn[0] *= faceDirection;
                tbn[1] *= faceDirection;
            }
        }

        #if (USE_CLEARCOAT_NORMALMAP) {
            #if (USE_TANGENT) {
                var tbn2:Mat3 = mat3(normalize(vTangent), normalize(vBitangent), normal);
            } else {
                var tbn2:Mat3 = getTangentFrame(-vViewPosition, normal, vClearcoatNormalMapUv);
            }
            #if (DOUBLE_SIDED && !FLAT_SHADED) {
                tbn2[0] *= faceDirection;
                tbn2[1] *= faceDirection;
            }
        }

        // non perturbed normal for clearcoat among others
        var nonPerturbedNormal:Vec3 = normal;
    }
}