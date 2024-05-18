package three.shader;

#if USE_BATCHING
attribute batchId:Float;

uniform batchingTexture:Texture;

function getBatchingMatrix(i:Float):Mat4 {
    var size:Int = batchingTexture.get_width();
    var j:Int = Std.int(i) * 4;
    var x:Int = j % size;
    var y:Int = j / size;
    var v1:Vec4 = batchingTexture.getPixel(x, y);
    var v2:Vec4 = batchingTexture.getPixel(x + 1, y);
    var v3:Vec4 = batchingTexture.getPixel(x + 2, y);
    var v4:Vec4 = batchingTexture.getPixel(x + 3, y);
    return new Mat4(v1, v2, v3, v4);
}

#end

#if USE_BATCHING_COLOR
uniform batchingColorTexture:Texture;

function getBatchingColor(i:Float):Vec3 {
    var size:Int = batchingColorTexture.get_width();
    var j:Int = Std.int(i);
    var x:Int = j % size;
    var y:Int = j / size;
    var color:Vec4 = batchingColorTexture.getPixel(x, y);
    return new Vec3(color.x, color.y, color.z);
}

#end