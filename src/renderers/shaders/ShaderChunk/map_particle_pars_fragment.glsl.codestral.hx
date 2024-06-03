#if defined(USE_POINTS_UV)

var vUv:Vec2;

#else

#if defined(USE_MAP) || defined(USE_ALPHAMAP)

var uvTransform:Mat3;

#end

#end

#if defined(USE_MAP)

var map:Texture;

#end

#if defined(USE_ALPHAMAP)

var alphaMap:Texture;

#end