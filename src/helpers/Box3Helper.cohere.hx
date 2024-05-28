import js.Browser.Window;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.TextureBase;
import openfl.errors.Error;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openflCoeffs.geom.Matrix3D;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.system.Security;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class Box3Helper extends LineSegments {
	public var box:Dynamic;
	public var type:String;

	public function new ( box:Dynamic, color:Int = 0xffff00 ) {
		super();

		var indices = [ 0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7 ];
		var positions = [ 1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, 1, 1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1 ];

		var geometry = new BufferGeometry();
		geometry.setIndex( new BufferAttribute( indices, 1 ) );
		geometry.setAttribute( 'position', new Float32BufferAttribute( positions, 3 ) );

		super( geometry, new LineBasicMaterial( { color: color, toneMapped: false } ) );

		this.box = box;
		this.type = 'Box3Helper';
		this.geometry.computeBoundingSphere();
	}

	public function updateMatrixWorld ( force:Bool ) {
		var box = this.box;

		if (box.isEmpty()) return;

		box.getCenter( this.position );
		box.getSize( this.scale );

		this.scale.multiplyScalar( 0.5 );

		super.updateMatrixWorld( force );
	}

	public function dispose () {
		this.geometry.dispose();
		this.material.dispose();
	}
}