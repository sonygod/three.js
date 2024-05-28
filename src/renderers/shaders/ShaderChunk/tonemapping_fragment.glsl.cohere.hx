import openfl.display.DisplayObject;
import openfl.display.OpenGLView;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class Shader extends EventDispatcher {

	public var context:Context3D;
	public var program:Program3D;
	public var isReady:Bool;
	private var _onContext:Function;

	public function new(context:Context3D, vertexSrc:String, fragmentSrc:String) {
		super();

		this.context = context;
		this._onContext = onContext;

		if (context.driverInfo.vendor == Context3DDriverInfoVendor.NVIDIA) {
			vertexSrc = vertexSrc.replace("#define PI 3.14159265", "#define PI 3.1415926");
		}

		context.addEventListener(Event.CONTEXT3D_CREATE, _onContext);

		context.dispose();
		context.submit();
	}

	private function onContext(e:Event):Void {
		context.removeEventListener(Event.CONTEXT3D_CREATE, _onContext);

		program = context.createProgram();
		program.upload(vertexSrc, fragmentSrc);

		isReady = true;
		dispatchEvent(new Event(Event.COMPLETE));
	}
}