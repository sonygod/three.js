@:glsl
class DefaultNormalVertex {
    @:uniform var objectNormal:Vec3;
    @:uniform var objectTangent:Vec3;
    @:uniform var batchingMatrix:Mat3;
    @:uniform var instanceMatrix:Mat3;
    @:uniform var normalMatrix:Mat3;
    @:uniform var modelViewMatrix:Mat4;

    @:varying var transformedNormal:Vec3;
    @:varying var transformedTangent:Vec3;

    public function new() {}

    public function vertex():Void {
        transformedNormal = objectNormal;

        #if USE_TANGENT
        var transformedTangent = objectTangent;
        #end

        #if USE_BATCHING
        var bm:Mat3 = batchingMatrix;
        transformedNormal /= new Vec3(dot(bm[0], bm[0]), dot(bm[1], bm[1]), dot(bm[2], bm[2]));
        transformedNormal = bm * transformedNormal;

        #if USE_TANGENT
        transformedTangent = bm * transformedTangent;
        #end
        #end

        #if USE_INSTANCING
        var im:Mat3 = instanceMatrix;
        transformedNormal /= new Vec3(dot(im[0], im[0]), dot(im[1], im[1]), dot(im[2], im[2]));
        transformedNormal = im * transformedNormal;

        #if USE_TANGENT
        transformedTangent = im * transformedTangent;
        #end
        #end

        transformedNormal = normalMatrix * transformedNormal;

        #if FLIP_SIDED
        transformedNormal = -transformedNormal;
        #end

        #if USE_TANGENT
        transformedTangent = (modelViewMatrix * new Vec4(transformedTangent, 0.0)).xyz;

        #if FLIP_SIDED
        transformedTangent = -transformedTangent;
        #end
        #end
    }
}