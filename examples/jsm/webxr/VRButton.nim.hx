class VRButton {

	static var xrSessionIsGranted:Bool = false;

	static function createButton(renderer:Dynamic, sessionInit:Dynamic = null):Dynamic {

		var button:Dynamic = js.Browser.document.createElement('button');

		function showEnterVR(/*device*/):Void {

			var currentSession:Dynamic = null;

			function onSessionStarted(session:Dynamic):Void {

				session.addEventListener('end', onSessionEnded);

				renderer.xr.setSession(session);
				button.textContent = 'EXIT VR';

				currentSession = session;

			}

			function onSessionEnded(/*event*/):Void {

				currentSession.removeEventListener('end', onSessionEnded);

				button.textContent = 'ENTER VR';

				currentSession = null;

			}

			//

			button.style.display = '';

			button.style.cursor = 'pointer';
			button.style.left = 'calc(50% - 50px)';
			button.style.width = '100px';

			button.textContent = 'ENTER VR';

			// WebXR's requestReferenceSpace only works if the corresponding feature
			// was requested at session creation time. For simplicity, just ask for
			// the interesting ones as optional features, but be aware that the
			// requestReferenceSpace call will fail if it turns out to be unavailable.
			// ('local' is always available for immersive sessions and doesn't need to
			// be requested separately.)

			var sessionOptions:Dynamic = {
				...sessionInit,
				optionalFeatures: [
					'local-floor',
					'bounded-floor',
					'layers',
					...(sessionInit.optionalFeatures || [])
				],
			};

			button.onmouseenter = function():Void {

				button.style.opacity = '1.0';

			};

			button.onmouseleave = function():Void {

				button.style.opacity = '0.5';

			};

			button.onclick = function():Void {

				if (currentSession === null) {

					navigator.xr.requestSession('immersive-vr', sessionOptions).then(onSessionStarted);

				} else {

					currentSession.end();

					if (navigator.xr.offerSession !== undefined) {

						navigator.xr.offerSession('immersive-vr', sessionOptions)
							.then(onSessionStarted)
							.catch(function(err) {

								console.warn(err);

							});

					}

				}

			};

			if (navigator.xr.offerSession !== undefined) {

				navigator.xr.offerSession('immersive-vr', sessionOptions)
					.then(onSessionStarted)
					.catch(function(err) {

						console.warn(err);

					});

			}

		}

		function disableButton():Void {

			button.style.display = '';

			button.style.cursor = 'auto';
			button.style.left = 'calc(50% - 75px)';
			button.style.width = '150px';

			button.onmouseenter = null;
			button.onmouseleave = null;

			button.onclick = null;

		}

		function showWebXRNotFound():Void {

			disableButton();

			button.textContent = 'VR NOT SUPPORTED';

		}

		function showVRNotAllowed(exception:Dynamic):Void {

			disableButton();

			console.warn('Exception when trying to call xr.isSessionSupported', exception);

			button.textContent = 'VR NOT ALLOWED';

		}

		function stylizeElement(element:Dynamic):Void {

			element.style.position = 'absolute';
			element.style.bottom = '20px';
			element.style.padding = '12px 6px';
			element.style.border = '1px solid #fff';
			element.style.borderRadius = '4px';
			element.style.background = 'rgba(0,0,0,0.1)';
			element.style.color = '#fff';
			element.style.font = 'normal 13px sans-serif';
			element.style.textAlign = 'center';
			element.style.opacity = '0.5';
			element.style.outline = 'none';
			element.style.zIndex = '999';

		}

		if ('xr' in navigator) {

			button.id = 'VRButton';
			button.style.display = 'none';

			stylizeElement(button);

			navigator.xr.isSessionSupported('immersive-vr').then(function(supported:Bool) {

				supported ? showEnterVR() : showWebXRNotFound();

				if (supported && VRButton.xrSessionIsGranted) {

					button.click();

				}

			}).catch(showVRNotAllowed);

			return button;

		} else {

			var message:Dynamic = js.Browser.document.createElement('a');

			if (js.Browser.window.isSecureContext === false) {

				message.href = js.Browser.document.location.href.replace(/^http:/, 'https:');
				message.innerHTML = 'WEBXR NEEDS HTTPS'; // TODO Improve message

			} else {

				message.href = 'https://immersiveweb.dev/';
				message.innerHTML = 'WEBXR NOT AVAILABLE';

			}

			message.style.left = 'calc(50% - 90px)';
			message.style.width = '180px';
			message.style.textDecoration = 'none';

			stylizeElement(message);

			return message;

		}

	}

	static function registerSessionGrantedListener():Void {

		if (typeof navigator !== 'undefined' && 'xr' in navigator) {

			// WebXRViewer (based on Firefox) has a bug where addEventListener
			// throws a silent exception and aborts execution entirely.
			if (/WebXRViewer\//i.test(navigator.userAgent)) return;

			navigator.xr.addEventListener('sessiongranted', function():Void {

				VRButton.xrSessionIsGranted = true;

			});

		}

	}

}

VRButton.registerSessionGrantedListener();