var transformedNormal:Float = objectNormal;
#if USE_TANGENT
var transformedTangent:Float = objectTangent;
#end

#if USE_BATCHING
var bm:Float = new Float(batchingMatrix);
transformedNormal /= new Float([dot(bm[0], bm[0]), dot(bm[1], bm[1]), dot(bm[2], bm[2])]);
transformedNormal = bm * transformedNormal;
#if USE_TANGENT
transformedTangent = bm * transformedTangent;
#end
#end

#if USE_INSTANCING
var im:Float = new Float(instanceMatrix);
transformedNormal /= new Float([dot(im[0], im[0]), dot(im[1], im[1]), dot(im[2], im[2])]);
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
transformedTangent = (modelViewMatrix * new Float([transformedTangent, 0.0])).xyz;
#if FLIP_SIDED
transformedTangent = -transformedTangent;
#end
#end