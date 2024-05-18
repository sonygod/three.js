class UIInteger extends UIElement {

	constructor( number ) {

		super( document.createElement( 'input' ) );

		this.dom.style.cursor = 'ns-resize';
		this.dom.className = 'Number';
		this.dom.value = '0';

		this.dom.setAttribute( 'autocomplete', 'off' );

		this.value = 0;

		this.min = - Infinity;
		this.max = Infinity;

		this.step = 1;
		this.nudge = 1;

		this.setValue( number );

		const scope = this;

		const changeEvent = new Event( 'change', { bubbles: true, cancelable: true } );

		let distance = 0;
		let onMouseDownValue = 0;

		const pointer = { x: 0, y: 0 };
		const prevPointer = { x: 0, y: 0 };

		function onMouseDown( event ) {

			if ( document.activeElement === scope.dom ) return;

			event.preventDefault();

			distance = 0;

			onMouseDownValue = scope.value;

			prevPointer.x = event.clientX;
			prevPointer.y = event.clientY;

			document.addEventListener( 'mousemove', onMouseMove );
			document.addEventListener( 'mouseup', onMouseUp );

		}

		function onMouseMove( event ) {

			const currentValue = scope.value;

			pointer.x = event.clientX;
			pointer.y = event.clientY;

			distance += ( pointer.x - prevPointer.x ) - ( pointer.y - prevPointer.y );

			let value = onMouseDownValue + ( distance / ( event.shiftKey ? 5 : 50 ) ) * scope.step;
			value = Math.min( scope.max, Math.max( scope.min, value ) ) | 0;

			if ( currentValue !== value ) {

				scope.setValue( value );
				scope.dom.dispatchEvent( changeEvent );

			}

			prevPointer.x = event.clientX;
			prevPointer.y = event.clientY;

		}

		function onMouseUp() {

			document.removeEventListener( 'mousemove', onMouseMove );
			document.removeEventListener( 'mouseup', onMouseUp );

			if ( Math.abs( distance ) < 2 ) {

				scope.dom.focus();
				scope.dom.select();

			}

		}

		function onChange() {

			scope.setValue( scope.dom.value );

		}

		function onFocus() {

			scope.dom.style.backgroundColor = '';
			scope.dom.style.cursor = '';

		}

		function onBlur() {

			scope.dom.style.backgroundColor = 'transparent';
			scope.dom.style.cursor = 'ns-resize';

		}

		function onKeyDown( event ) {

			event.stopPropagation();

			switch ( event.code ) {

				case 'Enter':
					scope.dom.blur();
					break;

				case 'ArrowUp':
					event.preventDefault();
					scope.setValue( scope.getValue() + scope.nudge );
					scope.dom.dispatchEvent( changeEvent );
					break;

				case 'ArrowDown':
					event.preventDefault();
					scope.setValue( scope.getValue() - scope.nudge );
					scope.dom.dispatchEvent( changeEvent );
					break;

			}

		}

		onBlur();

		this.dom.addEventListener( 'keydown', onKeyDown );
		this.dom.addEventListener( 'mousedown', onMouseDown );
		this.dom.addEventListener( 'change', onChange );
		this.dom.addEventListener( 'focus', onFocus );
		this.dom.addEventListener( 'blur', onBlur );

	}

	getValue() {

		return this.value;

	}

	setValue( value ) {

		if ( value !== undefined ) {

			value = parseInt( value );

			this.value = value;
			this.dom.value = value;

		}

		return this;

	}

	setStep( step ) {

		this.step = parseInt( step );

		return this;

	}

	setNudge( nudge ) {

		this.nudge = nudge;

		return this;

	}

	setRange( min, max ) {

		this.min = min;
		this.max = max;

		return this;

	}

}