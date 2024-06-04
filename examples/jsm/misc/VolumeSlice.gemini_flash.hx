import three.extras.geometries.PlaneGeometry;
import three.materials.MeshBasicMaterial;
import three.math.Matrix4;
import three.objects.Mesh;
import three.textures.Texture;
import three.textures.TextureWrapMode;
import three.textures.TextureFilter;
import three.constants.Constants;

/**
 * This class has been made to hold a slice of a volume data
 * @class
 * @param   {Volume} volume    The associated volume
 * @param   {Int}       [index=0] The index of the slice
 * @param   {String}       [axis='z']      For now only 'x', 'y' or 'z' but later it will change to a normal vector
 * @see Volume
 */
class VolumeSlice {

	public var volume:Volume;
	public var index:Int;
	public var axis:String;

	public var canvas:html.Canvas;
	public var ctx:html.CanvasRenderingContext2D;
	public var canvasBuffer:html.Canvas;
	public var ctxBuffer:html.CanvasRenderingContext2D;
	public var mesh:Mesh;
	public var geometry:PlaneGeometry;

	public var geometryNeedsUpdate:Bool = true;

	public var iLength:Int;
	public var jLength:Int;
	public var sliceAccess:Dynamic;
	public var matrix:Matrix4;

	public function new( volume:Volume, index:Int = 0, axis:String = 'z' ) {

		this.volume = volume;
		this.index = index;
		this.axis = axis;

		this.canvas = new html.Canvas();
		this.canvasBuffer = new html.Canvas();
		this.updateGeometry();

		var canvasMap = new Texture( this.canvas );
		canvasMap.minFilter = TextureFilter.Linear;
		canvasMap.wrapS = canvasMap.wrapT = TextureWrapMode.ClampToEdge;
		canvasMap.colorSpace = Constants.SRGBColorSpace;
		var material = new MeshBasicMaterial( { map: canvasMap, side: Constants.DoubleSide, transparent: true } );
		this.mesh = new Mesh( this.geometry, material );
		this.mesh.matrixAutoUpdate = false;
		this.repaint();

	}

	/**
	 * @member {Function} repaint Refresh the texture and the geometry if geometryNeedsUpdate is set to true
	 * @memberof VolumeSlice
	 */
	public function repaint():Void {

		if ( this.geometryNeedsUpdate ) {

			this.updateGeometry();

		}

		var iLength = this.iLength;
		var jLength = this.jLength;
		var sliceAccess = this.sliceAccess;
		var volume = this.volume;
		var canvas = this.canvasBuffer;
		var ctx = this.ctxBuffer;


		// get the imageData and pixel array from the canvas
		var imgData = ctx.getImageData( 0, 0, iLength, jLength );
		var data = imgData.data;
		var volumeData = volume.data;
		var upperThreshold = volume.upperThreshold;
		var lowerThreshold = volume.lowerThreshold;
		var windowLow = volume.windowLow;
		var windowHigh = volume.windowHigh;

		// manipulate some pixel elements
		var pixelCount = 0;

		if ( volume.dataType == 'label' ) {

			//this part is currently useless but will be used when colortables will be handled
			for ( j in 0...jLength ) {

				for ( i in 0...iLength ) {

					var label = volumeData[ sliceAccess( i, j ) ];
					label = label >= this.volume.colorMap.length ? ( label % this.volume.colorMap.length ) + 1 : label;
					var color = this.volume.colorMap[ label ];
					data[ 4 * pixelCount ] = ( color >> 24 ) & 0xff;
					data[ 4 * pixelCount + 1 ] = ( color >> 16 ) & 0xff;
					data[ 4 * pixelCount + 2 ] = ( color >> 8 ) & 0xff;
					data[ 4 * pixelCount + 3 ] = color & 0xff;
					pixelCount ++;

				}

			}

		} else {

			for ( j in 0...jLength ) {

				for ( i in 0...iLength ) {

					var value = volumeData[ sliceAccess( i, j ) ];
					var alpha = 0xff;
					//apply threshold
					alpha = upperThreshold >= value ? ( lowerThreshold <= value ? alpha : 0 ) : 0;
					//apply window level
					value = Math.floor( 255 * ( value - windowLow ) / ( windowHigh - windowLow ) );
					value = value > 255 ? 255 : ( value < 0 ? 0 : value | 0 );

					data[ 4 * pixelCount ] = value;
					data[ 4 * pixelCount + 1 ] = value;
					data[ 4 * pixelCount + 2 ] = value;
					data[ 4 * pixelCount + 3 ] = alpha;
					pixelCount ++;

				}

			}

		}

		ctx.putImageData( imgData, 0, 0 );
		this.ctx.drawImage( canvas, 0, 0, iLength, jLength, 0, 0, this.canvas.width, this.canvas.height );


		this.mesh.material.map.needsUpdate = true;

	}

	/**
	 * @member {Function} Refresh the geometry according to axis and index
	 * @see Volume.extractPerpendicularPlane
	 * @memberof VolumeSlice
	 */
	public function updateGeometry():Void {

		var extracted = this.volume.extractPerpendicularPlane( this.axis, this.index );
		this.sliceAccess = extracted.sliceAccess;
		this.jLength = extracted.jLength;
		this.iLength = extracted.iLength;
		this.matrix = extracted.matrix;

		this.canvas.width = extracted.planeWidth;
		this.canvas.height = extracted.planeHeight;
		this.canvasBuffer.width = this.iLength;
		this.canvasBuffer.height = this.jLength;
		this.ctx = this.canvas.getContext( '2d' );
		this.ctxBuffer = this.canvasBuffer.getContext( '2d' );

		if ( this.geometry != null ) this.geometry.dispose(); // dispose existing geometry

		this.geometry = new PlaneGeometry( extracted.planeWidth, extracted.planeHeight );

		if ( this.mesh != null ) {

			this.mesh.geometry = this.geometry;
			//reset mesh matrix
			this.mesh.matrix.identity();
			this.mesh.applyMatrix4( this.matrix );

		}

		this.geometryNeedsUpdate = false;

	}

}