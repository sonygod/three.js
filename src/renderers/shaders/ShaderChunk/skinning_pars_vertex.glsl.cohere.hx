#if USE_SKINNING

	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;

	uniform highp sampler2D boneTexture;

	mat4 function getBoneMatrix( i : Float ) {

		var size = textureSize( boneTexture, 0 ).x;
		var j = Std.int( i ) * 4;
		var x = j % size;
		var y = j / size;
		var v1 = texelFetch( boneTexture, { x: x, y: y }, 0 );
		var v2 = texelFetch( boneTexture, { x: x + 1, y: y }, 0 );
		var v3 = texelFetch( boneTexture, { x: x + 2, y: y }, 0 );
		var v4 = texelFetch( boneTexture, { x: x + 3, y: y }, 0 );

		return { v1, v2, v3, v4 };

	}

#end