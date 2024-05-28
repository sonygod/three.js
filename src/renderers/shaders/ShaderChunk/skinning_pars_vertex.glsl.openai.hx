package three.js.src.renderers.shaders.ShaderChunk;

#if USE_SKINNING

uniform var bindMatrix:Mat4;
uniform var bindMatrixInverse:Mat4;

uniform var boneTexture:Texture2D;

function getBoneMatrix(i:Float):Mat4 {
  var size:Int = boneTexture.width;
  var j:Int = Std.int(i) * 4;
  var x:Int = j % size;
  var y:Int = j / size;
  var v1:Vec4 = boneTexture.getPixel(x, y);
  var v2:Vec4 = boneTexture.getPixel(x + 1, y);
  var v3:Vec4 = boneTexture.getPixel(x + 2, y);
  var v4:Vec4 = boneTexture.getPixel(x + 3, y);
  return new Mat4(v1, v2, v3, v4);
}

#end