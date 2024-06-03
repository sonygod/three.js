import js.html.HTMLDocument;
import js.html.HTMLButtonElement;
import js.html.SVGElement;
import js.html.SVGPathElement;
import js.html.HTMLDivElement;
import js.html.HTMLElement;
import js.html.Window;
import js.html.Navigator;

class ARButton {
    public static function createButton(renderer: Dynamic, ?sessionInit: js.html.XRSessionInit): HTMLButtonElement {
        var document: HTMLDocument = js.Browser.document;
        var button: HTMLButtonElement = document.createElement('button').cast();

        function showStartAR(/*device*/) {
            if (js.Boot.field(sessionInit, "domOverlay") == null) {
                var overlay: HTMLDivElement = document.createElement('div').cast();
                overlay.style.display = 'none';
                document.body.appendChild(overlay);

                var svg: SVGElement = document.createElementNS('http://www.w3.org/2000/svg', 'svg').cast();
                svg.setAttribute('width', '38');
                svg.setAttribute('height', '38');
                svg.style.position = 'absolute';
                svg.style.right = '20px';
                svg.style.top = '20px';
                svg.addEventListener('click', function() {
                    currentSession.end();
                });
                overlay.appendChild(svg);

                var path: SVGPathElement = document.createElementNS('http://www.w3.org/2000/svg', 'path').cast();
                path.setAttribute('d', 'M 12,12 L 28,28 M 28,12 12,28');
                path.setAttribute('stroke', '#fff');
                path.setAttribute('stroke-width', '2');
                svg.appendChild(path);

                if (js.Boot.field(sessionInit, "optionalFeatures") == null) {
                    js.Boot.field(sessionInit, "optionalFeatures") = [];
                }

                sessionInit.optionalFeatures.push('dom-overlay');
                sessionInit.domOverlay = {root: overlay};
            }

            var currentSession: Dynamic = null;

            async function onSessionStarted(session: Dynamic) {
                session.addEventListener('end', onSessionEnded);

                renderer.xr.setReferenceSpaceType('local');

                await renderer.xr.setSession(session);

                button.textContent = 'STOP AR';
                sessionInit.domOverlay.root.style.display = '';

                currentSession = session;
            }

            function onSessionEnded(/*event*/) {
                currentSession.removeEventListener('end', onSessionEnded);

                button.textContent = 'START AR';
                sessionInit.domOverlay.root.style.display = 'none';

                currentSession = null;
            }

            button.style.display = '';

            button.style.cursor = 'pointer';
            button.style.left = 'calc(50% - 50px)';
            button.style.width = '100px';

            button.textContent = 'START AR';

            button.onmouseenter = function() {
                button.style.opacity = '1.0';
            };

            button.onmouseleave = function() {
                button.style.opacity = '0.5';
            };

            button.onclick = function() {
                if (currentSession == null) {
                    navigator.xr.requestSession('immersive-ar', sessionInit).then(onSessionStarted);
                } else {
                    currentSession.end();

                    if (js.Boot.field(navigator.xr, "offerSession") != null) {
                        navigator.xr.offerSession('immersive-ar', sessionInit)
                            .then(onSessionStarted)
                            .catch(function(err) {
                                js.lib.Console.warn(err);
                            });
                    }
                }
            };

            if (js.Boot.field(navigator.xr, "offerSession") != null) {
                navigator.xr.offerSession('immersive-ar', sessionInit)
                    .then(onSessionStarted)
                    .catch(function(err) {
                        js.lib.Console.warn(err);
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

        function showARNotSupported() {
            disableButton();

            button.textContent = 'AR NOT SUPPORTED';
        }

        function showARNotAllowed(exception: Dynamic) {
            disableButton();

            js.lib.Console.warn('Exception when trying to call xr.isSessionSupported', exception);

            button.textContent = 'AR NOT ALLOWED';
        }

        function stylizeElement(element: HTMLElement) {
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

        var navigator: Navigator = js.Browser.window.navigator;

        if (Reflect.hasField(navigator, 'xr')) {
            button.id = 'ARButton';
            button.style.display = 'none';

            stylizeElement(button);

            navigator.xr.isSessionSupported('immersive-ar').then(function(supported) {
                if (supported) {
                    showStartAR();
                } else {
                    showARNotSupported();
                }
            }).catch(showARNotAllowed);

            return button;
        } else {
            var message: HTMLElement = document.createElement('a').cast();

            if (js.Browser.window.isSecureContext == false) {
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