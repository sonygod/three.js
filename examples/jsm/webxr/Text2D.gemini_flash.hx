import three.core.Object3D;
import three.materials.MeshBasicMaterial;
import three.geometries.PlaneGeometry;
import three.meshes.Mesh;
import three.textures.Texture;
import three.core.CanvasTexture;
import three.constants.Side;

class TextCreator {
	static function createText(message:String, height:Float):Object3D {
		var canvas = new Canvas(1, 1);
		var context = canvas.getContext(Canvas.Context2D);
		var metrics = null;
		var textHeight = 100;
		context.font = 'normal ' + textHeight + 'px Arial';
		metrics = context.measureText(message);
		var textWidth = metrics.width;
		canvas.width = textWidth;
		canvas.height = textHeight;
		context.font = 'normal ' + textHeight + 'px Arial';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillStyle = '#ffffff';
		context.fillText(message, textWidth / 2, textHeight / 2);

		var texture = new Texture(new CanvasTexture(canvas));
		texture.needsUpdate = true;

		var material = new MeshBasicMaterial({
			color: 0xffffff,
			side: Side.DoubleSide,
			map: texture,
			transparent: true
		});
		var geometry = new PlaneGeometry((height * textWidth) / textHeight, height);
		var plane = new Mesh(geometry, material);
		return plane;
	}
}

class Canvas {
	public var canvas:html.Canvas;

	public function new(width:Int, height:Int) {
		canvas = new html.Canvas();
		canvas.width = width;
		canvas.height = height;
	}

	public function getContext(type:String):html.CanvasRenderingContext2D {
		return canvas.getContext(type);
	}
}


**Explanation:**

1. **Import necessary classes:** We import the relevant classes from the Haxe Three.js library.
2. **Create a `TextCreator` class:** We encapsulate the text creation logic within a class named `TextCreator`.
3. **Create a `Canvas` class:** We define a simple `Canvas` class to handle creating and interacting with HTML Canvas elements.
4. **Create the canvas and context:** We create a `Canvas` object with initial dimensions and obtain its 2D context.
5. **Measure text dimensions:** We set the font, measure the text width, and update the canvas dimensions accordingly.
6. **Draw text:** We draw the text on the canvas using the 2D context.
7. **Create a Three.js texture:** We create a `Texture` object using the `CanvasTexture` class, which wraps the canvas element.
8. **Create a basic material:** We create a `MeshBasicMaterial` with the texture and set the necessary properties.
9. **Create a plane geometry:** We create a `PlaneGeometry` with the appropriate dimensions based on the text width and height.
10. **Create a mesh:** Finally, we create a `Mesh` object using the plane geometry and the material.
11. **Return the mesh:** The `createText` method returns the created mesh object.

**Usage:**


import TextCreator;

var textMesh = TextCreator.createText("Hello, World!", 100);