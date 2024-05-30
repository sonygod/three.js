class VRButton {
    static function createButton(renderer:Dynamic, sessionInit:Dynamic = {}) {
        var button = window.document.createElement("button");
        function showEnterVR(/*device*/) {
            var currentSession:Dynamic = null;
            async function onSessionStarted(session:Dynamic) {
                session.addEventListener("end", onSessionEnded);
                await renderer.xr.setSession(session);
                button.textContent = "EXIT VR";
                currentSession = session;
            }
            function onSessionEnded(/*event*/) {
                currentSession.removeEventListener("end", onSessionEnded);
                button.textContent = "ENTER VR";
                currentSession = null;
            }
            button.style.display = "";
            button.style.cursor = "pointer";
            button.style.left = "calc(50% - 50px)";
            button.style.width = "100px";
            button.textContent = "ENTER VR";
            var sessionOptions = {
                ...sessionInit,
                optionalFeatures: [
                    "local-floor",
                    "bounded-floor",
                    "layers",
                    ...(sessionInit.optionalFeatures || [])
                ]
            };
            button.onmouseenter = function() {
                button.style.opacity = "1.0";
            };
            button.onmouseleave = function() {
                button.style.opacity = "0.5";
            };
            button.onclick = function() {
                if (currentSession == null) {
                    navigator.xr.requestSession("immersive-vr", sessionOptions).then(onSessionStarted);
                } else {
                    currentSession.end();
                    if (navigator.xr.offerSession != null) {
                        navigator.xr.offerSession("immersive-vr", sessionOptions)
                            .then(onSessionStarted)
                            .catch(function(err) {
                                trace(err);
                            });
                    }
                }
            };
            if (navigator.xr.offerSession != null) {
                navigator.xr.offerSession("immersive-vr", sessionOptions)
                    .then(onSessionStarted)
                    .catch(function(err) {
                        trace(err);
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
        function showWebXRNotFound() {
            disableButton();
            button.textContent = "VR NOT SUPPORTED";
        }
        function showVRNotAllowed(exception:Dynamic) {
            disableButton();
            trace("Exception when trying to call xr.isSessionSupported: " + exception);
            button.textContent = "VR NOT ALLOWED";
        }
        function stylizeElement(element:Dynamic) {
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
        if ("xr" in navigator) {
            button.id = "VRButton";
            button.style.display = "none";
            stylizeElement(button);
            navigator.xr.isSessionSupported("immersive-vr").then(function(supported) {
                if (supported) {
                    showEnterVR();
                } else {
                    showWebXRNotFound();
                }
                if (supported && VRButton.xrSessionIsGranted) {
                    button.click();
                }
            }).catch(showVRNotAllowed);
            return button;
        } else {
            var message = window.document.createElement("a");
            if (window.isSecureContext == false) {
                message.href = window.document.location.href.replace(/^http:/, "https:");
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
    static function registerSessionGrantedListener() {
        if (typeof navigator != "undefined" && "xr" in navigator) {
            if (/WebXRViewer\//i.test(navigator.userAgent)) {
                return;
            }
            navigator.xr.addEventListener("sessiongranted", function() {
                VRButton.xrSessionIsGranted = true;
            });
        }
    }
    static var xrSessionIsGranted:Bool = false;
    static function __init__() {
        registerSessionGrantedListener();
    }
}