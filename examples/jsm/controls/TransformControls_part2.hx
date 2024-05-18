import haxe.ds.EnumValue;

class TransformControlsGizmo extends haxe.lime.Component {

	public var isTransformControlsGizmo:Bool;
	public var type:String;

	public var gizmoMaterial:MeshMaterial;
	public var gizmoLineMaterial:LineMaterial;
	public var matInvisible:MeshMaterial;
	public var matHelper:LineMaterial;
	public var matRed:MeshMaterial;
	public var matGreen:MeshMaterial;
	public var matBlue:MeshMaterial;
	public var matRedTransparent:MeshMaterial;
	public var matGreenTransparent:MeshMaterial;
	public var matBlueTransparent:MeshMaterial;
	public var matWhiteTransparent:MeshMaterial;
	public var matYellowTransparent:MeshMaterial;
	public var matYellow:MeshMaterial;
	public var matGray:MeshMaterial;

	public var arrowGeometry:CylinderGeometry;
	public var scaleHandleGeometry:BoxGeometry;
	public var lineGeometry:BufferGeometry;
	public var lineGeometry2:CylinderGeometry;
	public var circleGeometry:Dynamic;
	public var translateHelperGeometry:Dynamic;

	public var gizmoTranslate:Dynamic;
	public var pickerTranslate:Dynamic;
	public var helperTranslate:Dynamic;
	public var gizmoRotate:Dynamic;
	public var helperRotate:Dynamic;
	public var pickerRotate:Dynamic;
	public var gizmoScale:Dynamic;
	public var pickerScale:Dynamic;
	public var helperScale:Dynamic;

	public function new() {
		super();

		this.isTransformControlsGizmo = true;
		this.type = 'TransformControlsGizmo';

		// shared materials
		gizmoMaterial = new MeshMaterial( { depthTest: false, depthWrite: false, fog: false, toneMapped: false, transparent: true } );
		gizmoLineMaterial = new LineMaterial( { depthTest: false, depthWrite: false, fog: false, toneMapped: false, transparent: true } );

		// Make unique material for each axis/color
		matInvisible = gizmoMaterial.clone();
		matInvisible.opacity = 0.15;

		matHelper = gizmoLineMaterial.clone();
		matHelper.opacity = 0.5;

		matRed = gizmoMaterial.clone();
		matRed.color.setHex( 0xff0000 );

		matGreen = gizmoMaterial.clone();
		matGreen.color.setHex( 0x00ff00 );

		matBlue = gizmoMaterial.clone();
		matBlue.color.setHex( 0x0000ff );

		matRedTransparent = gizmoMaterial.clone();
		matRedTransparent.color.setHex( 0xff0000 );
		matRedTransparent.opacity = 0.5;

		matGreenTransparent = gizmoMaterial.clone();
		matGreenTransparent.color.setHex( 0x00ff00 );
		matGreenTransparent.opacity = 0.5;

		matBlueTransparent = gizmoMaterial.clone();
		matBlueTransparent.color.setHex( 0x0000ff );
		matBlueTransparent.opacity = 0.5;

		matWhiteTransparent = gizmoMaterial.clone();
		matWhiteTransparent.opacity = 0.25;

		matYellowTransparent = gizmoMaterial.clone();
		matYellowTransparent.color.setHex( 0xffff00 );
		matYellowTransparent.opacity = 0.25;

		matYellow = gizmoMaterial.clone();
		matYellow.color.setHex( 0xffff00 );

		matGray = gizmoMaterial.clone();
		matGray.color.setHex( 0x787878 );

		// reusable geometry
		arrowGeometry = new CylinderGeometry( 0, 0.04, 0.1, 12 );
		arrowGeometry.translate( 0, 0.05, 0 );

		scaleHandleGeometry = new BoxGeometry( 0.08, 0.08, 0.08 );
		scaleHandleGeometry.translate( 0, 0.04, 0 );

		lineGeometry = new BufferGeometry();
		lineGeometry.setAttribute( 'position', new Float32BufferAttribute( [ 0, 0, 0,	1, 0, 0 ], 3 ) );

		lineGeometry2 = new CylinderGeometry( 0.0075, 0.0075, 0.5, 3 );
		lineGeometry2.translate( 0, 0.25, 0 );

		circleGeometry = function( radius:Float, arc:Float) {
			var geometry = new TorusGeometry( radius, 0.0075, 3, 64, arc * Math.PI * 2 );
			geometry.rotateY( Math.PI / 2 );
			geometry.rotateX( Math.PI / 2 );
			return geometry;
		};

		// Special geometry for transform helper. If scaled with position vector it spans from [0,0,0] to position
		translateHelperGeometry = function() {
			var geometry = new BufferGeometry();

			geometry.setAttribute( 'position', new Float32BufferAttribute( [ 0, 0, 0, 1, 1, 1 ], 3 ) );

			return geometry;
		};

		// Gizmo definitions - custom hierarchy definitions for setupGizmo() function
		gizmoTranslate = {
			X: [
				[ new Mesh( arrowGeometry, matRed ), [ 0.5, 0, 0 ], [ 0, 0, - Math.PI / 2 ]],
				[ new Mesh( arrowGeometry, matRed ), [ - 0.5, 0, 0 ], [ 0, 0, Math.PI / 2 ]],
				[ new Mesh( lineGeometry2, matRed ), [ 0, 0, 0 ], [ 0, 0, - Math.PI / 2 ]]
			],
			Y: [
				[ new Mesh( arrowGeometry, matGreen ), [ 0, 0.5, 0 ]],
				[ new Mesh( arrowGeometry, matGreen ), [ 0, - 0.5, 0 ], [ Math.PI, 0, 0 ]],
				[ new Mesh( lineGeometry2, matGreen ) ]
			],
			Z: [
				[ new Mesh( arrowGeometry, matBlue ), [ 0, 0, 0.5 ], [ Math.PI / 2, 0, 0 ]],
				[ new Mesh( arrowGeometry, matBlue ), [ 0, 0, - 0.5 ], [ - Math.PI / 2, 0, 0 ]],
				[ new Mesh( lineGeometry2, matBlue ), null, [ Math.PI / 2, 0, 0 ]]
			],
			XYZ: [
				[ new Mesh( new OctahedronGeometry( 0.1, 0 ), matWhiteTransparent.clone() ), [ 0, 0, 0 ]]
			],
			XY: [
				[ new Mesh( new BoxGeometry( 0.15, 0.15, 0.01 ), matBlueTransparent.clone() ), [ 0.15, 0.15, 0 ]]
			],
			YZ: [
				[ new Mesh( new BoxGeometry( 0.15, 0.15, 0.01 ), matRedTransparent.clone() ), [ 0, 0.15, 0.15 ], [ 0, Math.PI / 2, 0 ]]
			],
			XZ: [
				[ new Mesh( new BoxGeometry( 0.15, 0.15, 0.01 ), matGreenTransparent.clone() ), [ 0.15, 0, 0.15 ], [ - Math.PI / 2, 0, 0 ]]
			]
		};

		// ... continue defining the rest of the variables and functions

	}

	// ... continue implementing the rest of the methods

}