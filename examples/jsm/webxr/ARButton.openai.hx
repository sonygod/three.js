package three.js.examples.jsm.webxr;

import js.html.ButtonElement;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.lib.svg.SVGElement;
import js.lib.svg.SVGPathElement;
import js.lib.svg.SVGSVGElement;
import js.navigator.XR;

class ARButton {
    static function createButton(renderer:Dynamic, ?sessionInit:Dynamic) {
        var button:ButtonElement = Document.get_document().createElement("button");
        var sessionInitDefault:Dynamic = {};

        function showStartAR() {
            if (sessionInit.domOverlay == null) {
                var overlay:Element = Document.get_document().createElement("div");
                overlay.style.display = "none";
                Document.get_document().body.appendChild(overlay);

                var svg:SVGSVGElement = Document.get_document().createElementNS("http://www.w3.org/2000/svg", "svg");
                svg.setAttribute("width", "38");
                svg.setAttribute("height", "38");
                svg.style.position = "absolute";
                svg.style.right = "20px";
                svg.style.top = "20px";
                svg.addEventListener("click", function(_) {
                    currentSession.end();
                });
                overlay.appendChild(svg);

                var path:SVGPathElement = Document.get_document().createElementNS("http://www.w3.org/2000/svg", "path");
                path.setAttribute("d", "M 12,12 L 28,28 M 28,12 12,28");
                path.setAttribute("stroke", "#fff");
                path.setAttribute("stroke-width", "2");
                svg.appendChild(path);

                if (sessionInit.optionalFeatures == null) {
                    sessionInit.optionalFeatures = [];
                }

                sessionInit.optionalFeatures.push("dom-overlay");
                sessionInit.domOverlay = { root: overlay };
            }

            var currentSession:XRSession = null;

            function onSessionStarted(session:XRSession) {
                session.addEventListener("end", onSessionEnded);
                renderer.xr.setReferenceSpaceType("local");
                renderer.xr.setSession(session).then(_ -> {
                    button.textContent = "STOP AR";
                    sessionInit.domOverlay.root.style.display = "";
                    currentSession = session;
                });
            }

            function onSessionEnded(_) {
                currentSession.removeEventListener("end", onSessionEnded);
                button.textContent = "START AR";
                sessionInit.domOverlay.root.style.display = "none";
                currentSession = null;
            }

            button.style.display = "";
            button.style.cursor = "pointer";
            button.style.left = "calc(50% - 50px)";
            button.style.width = "100px";
            button.textContent = "START AR";

            button.onmouseenter = function(_) {
                button.style.opacity = "1.0";
            };

            button.onmouseleave = function(_) {
                button.style.opacity = "0.5";
            };

            button.onclick = function(_) {
                if (currentSession == null) {
                    XR.navigator.requestSession("immersive-ar", sessionInit).then(onSessionStarted);
                } else {
                    currentSession.end();
                    if (XR.navigator.offerSession != null) {
                        XR.navigator.offerSession("immersive-ar", sessionInit).then(onSessionStarted).catch(function(err) {
                            console.warn(err);
                        });
                    }
                }
            };

            if (XR.navigator.offerSession != null) {
                XR.navigator.offerSession("immersive-ar", sessionInit).then(onSessionStarted).catch(function(err) {
                    console.warn(err);
                });
            }
        }

        function disableButton() {
            button.style.display = "";
            button.style.cursor = "auto";
            button.style.left = "calc(50% - 75px)";
            button.style.width = "150px";
            button.onmouseenter = null;
            button.onmouseleave = null;
            button.onclick = null;
        }

        function showARNotSupported() {
            disableButton();
            button.textContent = "AR NOT SUPPORTED";
        }

        function showARNotAllowed(exception:Dynamic) {
            disableButton();
            console.warn("Exception when trying to call xr.isSessionSupported", exception);
            button.textContent = "AR NOT ALLOWED";
        }

        function stylizeElement(element:Element) {
            element.style.position = "absolute";
            element.style.bottom = "20px";
            element.style.padding = "12px 6px";
            element.style.border = "1px solid #fff";
            element.style.borderRadius = "4px";
            element.style.background = "rgba(0,0,0,0.1)";
            element.style.color = "#fff";
            element.style.font = "normal 13px sans-serif";
            element.style.textAlign = "center";
            element.style.opacity = "0.5";
            element.style.outline = "none";
            element.style.zIndex = "999";
        }

        if (Reflect.hasField(XR.navigator, "xr")) {
            button.id = "ARButton";
            button.style.display = "none";
            stylizeElement(button);

            XR.navigator.xr.isSessionSupported("immersive-ar").then(function(supported) {
                if (supported) showStartAR(); else showARNotSupported();
            }).catch(showARNotAllowed);

            return button;
        } else {
            var message:Element = Document.get_document().createElement("a");
            if (window.isSecureContext == false) {
                message.href = Document.get_document().URL.replace(/^http:/, 'https:');
                message.innerHTML = "WEBXR NEEDS HTTPS";
            } else {
                message.href = "https://immersiveweb.dev/";
                message.innerHTML = "WEBXR NOT AVAILABLE";
            }

            message.style.left = "calc(50% - 90px)";
            message.style.width = "180px";
            message.style.textDecoration = "none";

            stylizeElement(message);

            return message;
        }
    }
}