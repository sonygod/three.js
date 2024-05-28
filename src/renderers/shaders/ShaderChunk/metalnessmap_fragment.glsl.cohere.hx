function metalnessFactor(vMetalnessMapUv:Vec2, metalness:Float, metalnessMap:TextureBase):Float {
	var texelMetalness:Float = metalnessMap.getData(vMetalnessMapUv);
	return texelMetalness * metalness;
}