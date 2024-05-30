import three.THREE;

function createText(message:String, height:Float):THREE.Mesh {

	var canvas = js.Browser.document.createElement('canvas');
	var context = canvas.getContext('2d');
	var metrics:js.html.TextMetrics = null;
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

	var texture = new THREE.Texture(canvas);
	texture.needsUpdate = true;

	var material = new THREE.MeshBasicMaterial({
		color: 0xffffff,
		side: THREE.DoubleSide,
		map: texture,
		transparent: true,
	});
	var geometry = new THREE.PlaneGeometry((height * textWidth) / textHeight, height);
	var plane = new THREE.Mesh(geometry, material);
	return plane;

}

@:keep
@:noCompletion
@:keep(if js.Browser.document.createElement)
@:keep(if js.html.CanvasRenderingContext2D.measureText)
@:keep(if js.html.CanvasRenderingContext2D.fillText)
@:keep(if js.html.CanvasRenderingContext2D.font)
@:keep(if js.html.CanvasRenderingContext2D.textAlign)
@:keep(if js.html.CanvasRenderingContext2D.textBaseline)
@:keep(if js.html.CanvasRenderingContext2D.fillStyle)
@:keep(if THREE.Texture.needsUpdate)
@:keep(if THREE.MeshBasicMaterial.color)
@:keep(if THREE.MeshBasicMaterial.side)
@:keep(if THREE.MeshBasicMaterial.map)
@:keep(if THREE.MeshBasicMaterial.transparent)
@:keep(if THREE.PlaneGeometry.width)
@:keep(if THREE.PlaneGeometry.height)
@:keep(if THREE.Mesh.geometry)
@:keep(if THREE.Mesh.material)