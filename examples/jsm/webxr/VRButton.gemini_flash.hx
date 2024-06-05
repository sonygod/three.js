class VRButton {

	static function createButton(renderer:Dynamic, sessionInit:Dynamic = {}):Dynamic {

		var button = Html.createElement('button');

		function showEnterVR(device:Dynamic):Void {

			var currentSession:Dynamic = null;

			function onSessionStarted(session:Dynamic):Void {

				session.addEventListener('end', onSessionEnded);

				js.Browser.window.requestAnimationFrame(function() {
					renderer.xr.setSession(session);
					button.textContent = 'EXIT VR';
					currentSession = session;
				});

			}

			function onSessionEnded(event:Dynamic):Void {

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

			var sessionOptions = {
				...sessionInit,
				optionalFeatures: [
					'local-floor',
					'bounded-floor',
					'layers',
					...(sessionInit.optionalFeatures || [])
				],
			};

			button.onmouseenter = function() {

				button.style.opacity = '1.0';

			};

			button.onmouseleave = function() {

				button.style.opacity = '0.5';

			};

			button.onclick = function() {

				if (currentSession == null) {

					navigator.xr.requestSession('immersive-vr', sessionOptions).then(onSessionStarted);

				} else {

					currentSession.end();

					if (navigator.xr.offerSession != null) {

						navigator.xr.offerSession('immersive-vr', sessionOptions)
							.then(onSessionStarted)
							.catch(function(err:Dynamic) {

								console.warn(err);

							});

					}

				}

			};

			if (navigator.xr.offerSession != null) {

				navigator.xr.offerSession('immersive-vr', sessionOptions)
					.then(onSessionStarted)
					.catch(function(err:Dynamic) {

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

		if ('xr' in js.Browser.window.navigator) {

			button.id = 'VRButton';
			button.style.display = 'none';

			stylizeElement(button);

			js.Browser.window.navigator.xr.isSessionSupported('immersive-vr').then(function(supported:Bool) {

				if (supported) {
					showEnterVR(null);
				} else {
					showWebXRNotFound();
				}

				if (supported && VRButton.xrSessionIsGranted) {

					button.click();

				}

			}).catch(showVRNotAllowed);

			return button;

		} else {

			var message = Html.createElement('a');

			if (js.Browser.window.isSecureContext == false) {

				message.href = js.Browser.window.location.href.replace(/^http:/, 'https:');
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

		if (js.Browser.window.navigator != null && 'xr' in js.Browser.window.navigator) {

			// WebXRViewer (based on Firefox) has a bug where addEventListener
			// throws a silent exception and aborts execution entirely.
			if (js.Browser.window.navigator.userAgent.match(/WebXRViewer\//i) != null) return;

			js.Browser.window.navigator.xr.addEventListener('sessiongranted', function() {

				VRButton.xrSessionIsGranted = true;

			});

		}

	}

	static var xrSessionIsGranted:Bool = false;

	static function main() {
		registerSessionGrantedListener();
	}

}

VRButton.main();