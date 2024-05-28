package;

import openfl.display.DisplayObject;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.VertexBuffer3DData;
import openfl.events.EventDispatcher;

class MyShader extends Shader {
    public function new(context:Context3D, vertexString:String, fragmentString:String) {
        super(context, vertexString, fragmentString);
    }
}

class MyShaderParameter<T> extends ShaderParameter {
    public function new(shader:Shader, name:String, defaultValue:T) {
        super(shader, name, defaultValue);
    }
}

class MyShaderInput extends ShaderInput {
    public function new(shader:Shader, buffer:VertexBuffer3D, index:Int, format:Context3DTextureFormat) {
        super(shader, buffer, index, format);
    }
}

class MyProgram3D extends Program3D {
    public function new(context:Context3D, vertexShaderString:String, fragmentShaderString:String) {
        super(context, vertexShaderString, fragmentShaderString, Context3DProgramType.VERTEX_SHADER, Context3DProgramType.FRAGMENT_SHADER);
    }
}

class MyVertexBuffer3DData extends VertexBuffer3DData {
    public function new(context:Context3D, numVertices:Int, data:Array<Dynamic>) {
        super(context, numVertices, data);
    }
}

class MyVertexBuffer3D extends VertexBuffer3D {
    public function new(context:Context3D, data:VertexBuffer3DData) {
        super(context, data);
    }
}

class MyIndexBuffer3D extends IndexBuffer3D {
    public function new(context:Context3D, numIndices:Int, data:Array<Int>) {
        super(context, numIndices, data);
    }
}

class MyDisplayObject extends DisplayObject {
    public function new() {
        super();
    }
}

class MyEventDispatcher extends EventDispatcher {
    public function new() {
        super();
    }
}