package three.shader;

#if (js && (desktop || mobile))

class BatchingParsVertex {
  #if USE_BATCHING
  @:attrib('batchId') public var batchId:Float;

  @:uniform('batchingTexture') public var batchingTexture:haxe.ds.IntMap<haxe.io.Bytes>;

  public function getBatchingMatrix(i:Float):haxe.math.Matrix4 {
    var size:Int = batchingTexture.width;
    var j:Int = Std.int(i) * 4;
    var x:Int = j % size;
    var y:Int = Math.floor(j / size);
    var v1:Vector4 = batchingTexture.getPixel(x, y);
    var v2:Vector4 = batchingTexture.getPixel(x + 1, y);
    var v3:Vector4 = batchingTexture.getPixel(x + 2, y);
    var v4:Vector4 = batchingTexture.getPixel(x + 3, y);
    return new haxe.math.Matrix4(v1.x, v2.x, v3.x, v4.x, v1.y, v2.y, v3.y, v4.y, v1.z, v2.z, v3.z, v4.z, v1.w, v2.w, v3.w, v4.w);
  }
  #end

  #if USE_BATCHING_COLOR
  @:uniform('batchingColorTexture') public var batchingColorTexture:haxe.ds.IntMap<haxe.io.Bytes>;

  public function getBatchingColor(i:Float):Vector3 {
    var size:Int = batchingColorTexture.width;
    var j:Int = Std.int(i);
    var x:Int = j % size;
    var y:Int = Math.floor(j / size);
    var color:Vector4 = batchingColorTexture.getPixel(x, y);
    return new Vector3(color.x, color.y, color.z);
  }
  #end
}

#end