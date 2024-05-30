package three.js.examples.jsm.webxr;

import js.html.ButtonElement;
import js.html.Document;
import js.html.Element;
import js.html.Navigator;
import js.html.Window;
import js.Browser.console;

class VRButton {

	public static function createButton(renderer: Dynamic, ?sessionInit: {}) {

		var button: ButtonElement = Document.createElement("button");

		function showEnterVR() {

			var currentSession: Dynamic = null;

			async function onSessionStarted(session: Dynamic) {

				session.addEventListener("end", onSessionEnded);
				await renderer.xr.setSession(session);
				button.textContent = 'EXIT VR';

				currentSession = session;

			}

			function onSessionEnded(event: Dynamic) {

				currentSession.removeEventListener("end", onSessionEnded);
				button.textContent = 'ENTER VR';
				currentSession = null;

			}

			button.style.display = '';
			button.style.cursor = 'pointer';
			button.style.left = 'calc(50% - 50px)';
			button.style.width = '100px';
			button.textContent = 'ENTER VR';

			var sessionOptions: {} = {
				...sessionInit,
				optionalFeatures: [
					'local-floor',
					'bounded-floor',
					'layers',
					...(sessionInit.optionalFeatures || [])
				],
			};

			button.addEventListener("mouseenter", function(_) {
				button.style.opacity = '1.0';
			});

			button.addEventListener("mouseleave", function(_) {
				button.style.opacity = '0.5';
			});

			button.addEventListener("click", function(_) {

				if (currentSession === null) {
					Navigator.xr.requestSession('immersive-vr', sessionOptions).then(onSessionStarted);
				} else {
					currentSession.end();
					if (Navigator.xr.offerSession !== undefined) {
						Navigator.xr.offerSession('immersive-vr', sessionOptions)
							.then(onSessionStarted)
							.catch(function(err: Dynamic) {
								console.warn(err);
							});
					}
				}

			});

			if (Navigator.xr.offerSession !== undefined) {
				Navigator.xr.offerSession('immersive-vr', sessionOptions)
					.then(onSessionStarted)
					.catch(function(err: Dynamic) {
						console.warn(err);
					});
			}

		}

		function disableButton() {

			button.style.display = '';
			button.style.cursor = 'auto';
			button.style.left = 'calc(50% - 75px)';
			button.style.width = '150px';
			button.onmouseenter = null;
			button.onmouseleave = null;
			button.onclick = null;

		}

		function showWebXRNotFound() {

			disableButton();
			button.textContent = 'VR NOT SUPPORTED';

		}

		function showVRNotAllowed(exception: Dynamic) {

			disableButton();
			console.warn('Exception when trying to call xr.isSessionSupported', exception);
			button.textContent = 'VR NOT ALLOWED';

		}

		function stylizeElement(element: Element) {

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

		if ('xr' in Navigator) {

			button.id = 'VRButton';
			button.style.display = 'none';

			stylizeElement(button);

			Navigator.xr.isSessionSupported('immersive-vr').then(function(supported: Bool) {

				supported ? showEnterVR() : showWebXRNotFound();

				if (supported && VRButton.xrSessionIsGranted) {
					button.dispatchEvent(new js.html.MouseEvent("click"));
				}

			}).catch(showVRNotAllowed);

			return button;

		} else {

			var message: Element = Document.createElement("a");

			if (!Window.isSecureContext) {

				message.href = Window.location.href.replace(/^http:/, 'https:');
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

	public static function registerSessionGrantedListener() {

		if (Navigator.xr != null) {

			if (/WebXRViewer\b/i.test(Navigator.userAgent)) return;

			Navigator.xr.addEventListener("sessiongranted", function(_) {
				VRButton.xrSessionIsGranted = true;
			});

		}

	}

	public static var xrSessionIsGranted: Bool = false;

	static function main() {

		registerSessionGrantedListener();

	}

}