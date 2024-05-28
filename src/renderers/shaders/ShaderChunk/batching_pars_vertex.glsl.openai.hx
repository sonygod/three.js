#if (js && threejs)

// Assume we're targeting JavaScript and using three.js

import js.html GLenum;
import js.html.GL;
import js.html.Texture;
import js.html.WebGLRenderingContext;

class ShaderChunk {
  #if USE_BATCHING
  public static function getBatchingMatrix(i:Float):Mat4 {
    var size:Int = WebGLRenderingContext.activeTexture(0).getWidth();
    var j:Int = Std.int(i) * 4;
    var x:Int = j % size;
    var y:Int = Std.int(j / size);
    var v1:Vec4 = WebGLRenderingContext.texelFetch(0, x, y, 0);
    var v2:Vec4 = WebGLRenderingContext.texelFetch(0, x + 1, y, 0);
    var v3:Vec4 = WebGLRenderingContext.texelFetch(0, x + 2, y, 0);
    var v4:Vec4 = WebGLRenderingContext.texelFetch(0, x + 3, y, 0);
    return new Mat4(v1, v2, v3, v4);
  }
  #end

  #if USE_BATCHING_COLOR
  public static function getBatchingColor(i:Float):Vec3 {
    var size:Int = WebGLRenderingContext.activeTexture(0).getWidth();
    var j:Int = Std.int(i);
    var x:Int = j % size;
    var y:Int = Std.int(j / size);
    var color:Vec3 = WebGLRenderingContext.texelFetch(0, x, y, 0);
    return color;
  }
  #end
}

#end