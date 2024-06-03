#if USE_BATCHING
attribute float batchId;
uniform highp sampler2D batchingTexture;
function getBatchingMatrix(i:Float):Mat4 {
    var size = textureSize(batchingTexture, 0).x;
    var j = Std.int(i) * 4;
    var x = j % size;
    var y = j / size;
    var v1 = texelFetch(batchingTexture, new IntVec2(x, y), 0);
    var v2 = texelFetch(batchingTexture, new IntVec2(x + 1, y), 0);
    var v3 = texelFetch(batchingTexture, new IntVec2(x + 2, y), 0);
    var v4 = texelFetch(batchingTexture, new IntVec2(x + 3, y), 0);
    return new Mat4(v1, v2, v3, v4);
}
#end

#if USE_BATCHING_COLOR
uniform sampler2D batchingColorTexture;
function getBatchingColor(i:Float):Vec3 {
    var size = textureSize(batchingColorTexture, 0).x;
    var j = Std.int(i);
    var x = j % size;
    var y = j / size;
    return texelFetch(batchingColorTexture, new IntVec2(x, y), 0).rgb;
}
#end