package three.renderers.shaders;

class DefaultNormalVertexShader {
    public function new() {}

    public function vertex(objectNormal:Vec3, objectTangent:Vec3, batchingMatrix:Mat3, instanceMatrix:Mat3, normalMatrix:Mat3, modelViewMatrix:Mat4) : Vec3 {
        var transformedNormal:Vec3 = objectNormal.clone();
        var transformedTangent:Vec3 = null;

        #if USE_TANGENT
        transformedTangent = objectTangent.clone();
        #end

        #if USE_BATCHING
        var bm:Mat3 = batchingMatrix;
        transformedNormal.x /= bm.col(0).length();
        transformedNormal.y /= bm.col(1).length();
        transformedNormal.z /= bm.col(2).length();
        transformedNormal = bm.multVec(transformedNormal);

        #if USE_TANGENT
        transformedTangent = bm.multVec(transformedTangent);
        #end
        #end

        #if USE_INSTANCING
        var im:Mat3 = instanceMatrix;
        transformedNormal.x /= im.col(0).length();
        transformedNormal.y /= im.col(1).length();
        transformedNormal.z /= im.col(2).length();
        transformedNormal = im.multVec(transformedNormal);

        #if USE_TANGENT
        transformedTangent = im.multVec(transformedTangent);
        #end
        #end

        transformedNormal = normalMatrix.multVec(transformedNormal);

        #if FLIP_SIDED
        transformedNormal.scale(-1);
        #end

        #if USE_TANGENT
        transformedTangent = (modelViewMatrix.multVec4(new Vec4(transformedTangent, 0.0))).xyz();

        #if FLIP_SIDED
        transformedTangent.scale(-1);
        #end
        #end

        return transformedNormal;
    }
}