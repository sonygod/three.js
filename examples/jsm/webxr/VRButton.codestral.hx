import js.html.Document;
import js.html.Window;
import js.html.Element;
import js.html.HtmlElement;
import js.html.HTMLButtonElement;
import js.html.HTMLAnchorElement;

class VRButton {
    static var xrSessionIsGranted:Bool = false;

    static function createButton(renderer:Dynamic, sessionInit:Dynamic = {}):Element {
        var button:HTMLButtonElement = Document.createElement('button').cast();

        function showEnterVR() {
            var currentSession:Dynamic = null;

            async function onSessionStarted(session:Dynamic) {
                session.addEventListener('end', onSessionEnded);
                await renderer.xr.setSession(session);
                button.textContent = 'EXIT VR';
                currentSession = session;
            }

            function onSessionEnded(_:Dynamic) {
                currentSession.removeEventListener('end', onSessionEnded);
                button.textContent = 'ENTER VR';
                currentSession = null;
            }

            styleButton();

            button.textContent = 'ENTER VR';

            var sessionOptions:Dynamic = {
                ...sessionInit,
                optionalFeatures: [
                    'local-floor',
                    'bounded-floor',
                    'layers',
                    ...(sessionInit.optionalFeatures || [])
                ],
            };

            button.onmouseenter = function (_:Dynamic) {
                button.style.opacity = '1.0';
            };

            button.onmouseleave = function (_:Dynamic) {
                button.style.opacity = '0.5';
            };

            button.onclick = function (_:Dynamic) {
                if (currentSession == null) {
                    navigator.xr.requestSession('immersive-vr', sessionOptions).then(onSessionStarted);
                } else {
                    currentSession.end();
                    if (navigator.xr.offerSession != js.Browser.undefined) {
                        navigator.xr.offerSession('immersive-vr', sessionOptions)
                            .then(onSessionStarted)
                            .catch(function (err:Dynamic) {
                                js.Browser.console.warn(err);
                            });
                    }
                }
            };

            if (navigator.xr.offerSession != js.Browser.undefined) {
                navigator.xr.offerSession('immersive-vr', sessionOptions)
                    .then(onSessionStarted)
                    .catch(function (err:Dynamic) {
                        js.Browser.console.warn(err);
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

        function showVRNotAllowed(exception:Dynamic) {
            disableButton();
            js.Browser.console.warn('Exception when trying to call xr.isSessionSupported', exception);
            button.textContent = 'VR NOT ALLOWED';
        }

        function stylizeElement(element:Element) {
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

        function styleButton() {
            button.style.display = '';
            button.style.cursor = 'pointer';
            button.style.left = 'calc(50% - 50px)';
            button.style.width = '100px';
        }

        if ('xr' in js.Browser.navigator) {
            button.id = 'VRButton';
            button.style.display = 'none';

            stylizeElement(button);

            navigator.xr.isSessionSupported('immersive-vr').then(function (supported:Bool) {
                if (supported) showEnterVR(); else showWebXRNotFound();

                if (supported && VRButton.xrSessionIsGranted) {
                    button.click();
                }
            }).catch(showVRNotAllowed);

            return button;
        } else {
            var message:HTMLAnchorElement = Document.createElement('a').cast();

            if (js.Browser.window.isSecureContext == false) {
                message.href = js.Browser.document.location.href.replace(/^http:/, 'https:');
                message.innerHTML = 'WEBXR NEEDS HTTPS';
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

    static function registerSessionGrantedListener() {
        if (typeof js.Browser.navigator != 'undefined' && 'xr' in js.Browser.navigator) {
            if (js.Browser.navigator.userAgent.match(/WebXRViewer\//i)) return;

            navigator.xr.addEventListener('sessiongranted', function (_:Dynamic) {
                VRButton.xrSessionIsGranted = true;
            });
        }
    }
}

VRButton.registerSessionGrantedListener();