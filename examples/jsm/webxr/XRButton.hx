package three.js.examples.javascript.webxr;

import js.html.ButtonElement;
import js.html.Document;
import js.html.Event;
import js.html.Navigator;
import js.html.NavigatorXR;
import js.htmlXR.Session;
import js.htmlXR.SessionInit;

class XRButton {
    public static function createButton(renderer:Dynamic, ?sessionInit:SessionInit):ButtonElement {
        var button:ButtonElement = Document.createButtonElement();
        var currentSession:Session = null;

        function showStartXR(mode:String) {
            button.style.display = '';
            button.style.cursor = 'pointer';
            button.style.left = 'calc(50% - 50px)';
            button.style.width = '100px';
            button.textContent = 'START XR';

            button.onmouseenter = function(_) {
                button.style.opacity = '1.0';
            };

            button.onmouseleave = function(_) {
                button.style.opacity = '0.5';
            };

            button.onclick = function(_) {
                if (currentSession == null) {
                    Navigator.xr.requestSession(mode, sessionInit).then(onSessionStarted);
                } else {
                    currentSession.end();
                    if (Navigator.xr.offerSession != null) {
                        Navigator.xr.offerSession(mode, sessionInit).then(onSessionStarted).catchError(function(err) {
                            console.warn(err);
                        });
                    }
                }
            };

            if (Navigator.xr.offerSession != null) {
                Navigator.xr.offerSession(mode, sessionInit).then(onSessionStarted).catchError(function(err) {
                    console.warn(err);
                });
            }
        }

        function onSessionStarted(session:Session) {
            session.addEventListener('end', onSessionEnded);
            renderer.xr.setSession(session);
            button.textContent = 'STOP XR';
            currentSession = session;
        }

        function onSessionEnded(event:Event) {
            currentSession.removeEventListener('end', onSessionEnded);
            button.textContent = 'START XR';
            currentSession = null;
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

        function showXRNotSupported() {
            disableButton();
            button.textContent = 'XR NOT SUPPORTED';
        }

        function showXRNotAllowed(exception:Dynamic) {
            disableButton();
            console.warn('Exception when trying to call xr.isSessionSupported', exception);
            button.textContent = 'XR NOT ALLOWED';
        }

        function stylizeElement(element:Dynamic) {
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

        if (Reflect.hasField(Navigator, 'xr')) {
            button.id = 'XRButton';
            button.style.display = 'none';
            stylizeElement(button);

            Navigator.xr.isSessionSupported('immersive-ar').then(function(supported) {
                if (supported) {
                    showStartXR('immersive-ar');
                } else {
                    Navigator.xr.isSessionSupported('immersive-vr').then(function(supported) {
                        if (supported) {
                            showStartXR('immersive-vr');
                        } else {
                            showXRNotSupported();
                        }
                    }).catchError(showXRNotAllowed);
                }
            }).catchError(showXRNotAllowed);

            return button;
        } else {
            var message:Dynamic = Document.createElement('a');
            if (!window.isSecureContext) {
                message.href = document.location.href.replace(/^http:/, 'https:');
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
}