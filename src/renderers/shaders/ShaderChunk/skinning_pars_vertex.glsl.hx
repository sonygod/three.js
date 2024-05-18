package three.shader;

#if (js && three)

import openfl.display.GLShader;

class SkinningParsVertex {

    public function new() {}

    #if USE_SKINNING

    private var bindMatrix:Mat4;
    private var bindMatrixInverse:Mat4;
    private var boneTexture:Texture;

    private function getBoneMatrix(i:Float):Mat4 {
        var size:Int = boneTexture.getWidth();
        var j:Int = Std.int(i) * 4;
        var x:Int = j % size;
        var y:Int = Math.floor(j / size);
        var v1:Vec4 = boneTexture.getPixel(x, y);
        var v2:Vec4 = boneTexture.getPixel(x + 1, y);
        var v3:Vec4 = boneTexture.getPixel(x + 2, y);
        var v4:Vec4 = boneTexture.getPixel(x + 3, y);
        return new Mat4(v1, v2, v3, v4);
    }

    #end

}

#end