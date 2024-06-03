class WebGLRenderer {

	// ... other code ...

	clear( color:Bool, depth:Bool, stencil:Bool ):Void {

		var bits:Int = 0;

		if ( color ) {

			var clearColor = background.getClearColor();
			var a = background.getClearAlpha();
			var r = clearColor.r;
			var g = clearColor.g;
			var b = clearColor.b;

			if ( isUnsignedType ) {

				uintClearColor[ 0 ] = r;
				uintClearColor[ 1 ] = g;
				uintClearColor[ 2 ] = b;
				uintClearColor[ 3 ] = a;
				_gl.clearBufferuiv( _gl.COLOR, 0, uintClearColor );

			} else {

				intClearColor[ 0 ] = r;
				intClearColor[ 1 ] = g;
				intClearColor[ 2 ] = b;
				intClearColor[ 3 ] = a;
				_gl.clearBufferiv( _gl.COLOR, 0, intClearColor );

			}

		} else {

			bits |= _gl.COLOR_BUFFER_BIT;

		}

		if ( depth ) bits |= _gl.DEPTH_BUFFER_BIT;
		if ( stencil ) {

			bits |= _gl.STENCIL_BUFFER_BIT;
			this.state.buffers.stencil.setMask( 0xffffffff );

		}

		_gl.clear( bits );

	}

	clearColor():Void {

		this.clear( true, false, false );

	}

	clearDepth():Void {

		this.clear( false, true, false );

	}

	clearStencil():Void {

		this.clear( false, false, true );

	}

	// ... other code ...

}