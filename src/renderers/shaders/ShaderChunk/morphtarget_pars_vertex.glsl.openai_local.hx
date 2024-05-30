#if USE_MORPHTARGETS

	#if !USE_INSTANCING_MORPH

		uniform morphTargetBaseInfluence:Float;
		uniform morphTargetInfluences:Array<Float>;

	#end

	uniform morphTargetsTexture:sampler2DArray;
	uniform morphTargetsTextureSize:Vector<Int>;

	function getMorph(vertexIndex:Int, morphTargetIndex:Int, offset:Int):Vector4 {
		var texelIndex:Int = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		var y:Int = texelIndex / morphTargetsTextureSize.x;
		var x:Int = texelIndex - y * morphTargetsTextureSize.x;

		var morphUV:Vector<Int> = [x, y, morphTargetIndex];
		return texelFetch(morphTargetsTexture, morphUV, 0);
	}

#end