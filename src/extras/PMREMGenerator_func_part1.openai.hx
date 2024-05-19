import lime.graphics.cairo.CairoGraphics;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.Display;
import lime.text.Font;
import lime.text.FontMetrics;
import lime.text.TextLayout;
import lime.ui.KeyCode;
import lime.ui.KeyboardEvent;
import lime.ui.DownloadEvent;

var imagePath = "data/test.png";
var fontStylePath = "data/NotoSans-Regular.ttf";

class Main {
	
	static var canvas:Canvas;
	static var ctx:Context;
	static var image:Image;
	static var font:Font;
	static var fontMetrics:FontMetrics;
	static var textLayout:TextLayout;
	static var bufferSize:Size;
	static var scale:Float;
	
	static function main() {
		var display = new Display();
		display.initCairo();
		
		canvas = CairoGraphics.createSurface(display.width, display.height);
		ctx = canvas.getContext("2d");
		
		var imagePath = "data/test.png";
		var image = Image.createFromString(lime.Assets.getText(imagePath));
		
		var fontStylePath = "data/NotoSans-Regular.ttf";
		font = Font.fromFile(fontStylePath);
		font.setPointSize(30);
		fontMetrics = font.createMetrics();
		
		textLayout = new TextLayout();
		textLayout.setFont(font);
		textLayout.setFontMetrics(fontMetrics);
		
		bufferSize = new lime.Vector2(display.width, display.height);
		scale = Math.min(bufferSize.x / image.width, bufferSize.y / image.height);
		
		drawCanvas();
		
		display.onRender = render;
		display.onKeyDown = onKeyDown;
		display.onKeyUp = onKeyUp;
		display.onMouseDown = onMouseDown;
		display.onMouseMove = onMouseMove;
		display.onMouseUp = onMouseUp;
		display.onMouseWheel = onMouseWheel;
		display.onTouchStart = onTouchStart;
		display.onTouchMove = onTouchMove;
		display.onTouchEnd = onTouchEnd;
		display.onDownload = onDownload;
		display.createWindow();
	}
	
	static function render(display:Display) {
		display.blitSurface(canvas.surface, 0, 0, display.width, display.height);
	}
	
	static function onKeyDown(event:KeyboardEvent) {
		if(event.keyCode == KeyCode.ESCAPE) {
			display.close();
		}
	}
	
	static function onKeyUp(event:KeyboardEvent) {
		
	}
	
	static function onMouseDown(event:MouseEvent) {
		
	}
	
	static function onMouseMove(event:MouseEvent) {
		
	}
	
	static function onMouseUp(event:MouseEvent) {
		
	}
	
	static function onMouseWheel(event:MouseEvent) {
		
	}
	
	static function onTouchStart(event:TouchEvent) {
		
	}
	
	static function onTouchMove(event:TouchEvent) {
		
	}
	
	static function onTouchEnd(event:TouchEvent) {
		
	}
	
	static function onDownload(event:DownloadEvent) {
		canvas.surface.saveToPNG("output.png", event.bytes);
	}
	
	static function drawCanvas() {
		ctx.save();
		ctx.clearRect(0, 0, bufferSize.width, bufferSize.height);
		
		ctx.drawImage(image, 0, 0,
			image.width * scale, image.height * scale);
		
		ctx.fillText("Hello, Haxe!", 50, 50);
		
		ctx.restore();
	}
}