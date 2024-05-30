package three.js.examples.jsm.helpers;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.Line;
import three.js.LineBasicMaterial;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.BackSide;

class RectAreaLightHelper extends Line {
	
	public var light:Dynamic;
	public var color:Dynamic;
	public var type:String;

	public function new(light:Dynamic, color:Dynamic = null) {
		super();
		
		var positions:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];
		
		var geometry:BufferGeometry = new BufferGeometry();
		geometry.setAttribute('position', new Float32BufferAttribute(new Vector<Float>(positions), 3));
		geometry.computeBoundingSphere();
		
		var material:LineBasicMaterial = new LineBasicMaterial({fog: false});
		
		super(geometry, material);
		
		this.light = light;
		this.color = color; // optional hardwired color for the helper
		this.type = 'RectAreaLightHelper';
		
		var positions2:Array<Float> = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
		
		var geometry2:BufferGeometry = new BufferGeometry();
		geometry2.setAttribute('position', new Float32BufferAttribute(new Vector<Float>(positions2), 3));
		geometry2.computeBoundingSphere();
		
		add(new Mesh(geometry2, new MeshBasicMaterial({side: BackSide, fog: false})));
	}
	
	override public function updateMatrixWorld():Void {
		scale.set(0.5 * light.width, 0.5 * light.height, 1);
		
		if (color != null) {
			material.color.set(color);
			children[0].material.color.set(color);
		} else {
			material.color.copy(light.color).multiplyScalar(light.intensity);
			
			// prevent hue shift
			var c:Vector3 = material.color;
			var max:Float = Math.max(c.x, c.y, c.z);
			if (max > 1) c.multiplyScalar(1 / max);
			
			children[0].material.color.copy(material.color);
		}
		
		// ignore world scale on light
		matrixWorld.extractRotation(light.matrixWorld).scale(scale).copyPosition(light.matrixWorld);
		
		children[0].matrixWorld.copy(matrixWorld);
	}
	
	override public function dispose():Void {
		geometry.dispose();
		material.dispose();
		children[0].geometry.dispose();
		children[0].material.dispose();
	}
}