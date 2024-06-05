import js.html.Document;
import js.html.Element;
import js.html.Navigator;
import js.html.NavigatorXr;
import js.html.Node;
import js.html.Window;
import js.lib.promise.Promise;
import js.lib.promise.Promise_Impl_;
import js.lib.promise.Promise_Impl_.PromiseHandler;
import js.lib.promise.Promise_Impl_.PromiseHandler0;
import js.lib.promise.Promise_Impl_.PromiseHandler1;
import js.lib.promise.Promise_Impl_.PromiseHandler2;

class XRButton {
    public static function createButton(renderer: Dynamic, sessionInit: Dynamic): Element {
        var button = Document.current.createElement("button");

        var currentSession = null;

        var onSessionStarted = function(session: Dynamic): Promise<Dynamic> {
            session.addEventListener("end", onSessionEnded);
            return Promise_Impl_.resolve(renderer.xr.setSession(session));
        };

        var onSessionEnded = function(/*event*/): Void {
            currentSession.removeEventListener("end", onSessionEnded);
            button.textContent = "STOP XR";
            currentSession = null;
        };

        button.style.display = "";
        button.style.cursor = "pointer";
        button.style.left = "calc(50% - 50px)";
        button.style.width = "100px";
        button.textContent = "START XR";

        var sessionOptions = {
            ...sessionInit,
            optionalFeatures: [
                "local-floor",
                "bounded-floor",
                "layers",
                ...(sessionInit.optionalFeatures || [])
            ],
        };

        button.onmouseenter = function() {
            button.style.opacity = "1.0";
        };

        button.onmouseleave = function() {
            button.style.opacity = "0.5";
        };

        button.onclick = function() {
            if (currentSession === null) {
                navigator.xr.requestSession("immersive-ar", sessionOptions)
                    .then(onSessionStarted);
            } else {
                currentSession.end();
                if (navigator.xr.offerSession !== undefined) {
                    navigator.xr.offerSession("immersive-ar", sessionOptions)
                        .then(onSessionStarted)
                        .catch(function(err) {
                            console.warn(err);
                        });
                }
            }
        };

        if (navigator.xr.offerSession !== undefined) {
            navigator.xr.offerSession("immersive-ar", sessionOptions)
                .then(onSessionStarted)
                .catch(function(err) {
                    console.warn(err);
                });
        }

        var disableButton = function(): Void {
            button.style.display = "";
            button.style.cursor = "auto";
            button.style.left = "calc(50% - 75px)";
            button.style.width = "150px";
            button.onmouseenter = null;
            button.onmouseleave = null;
            button.onclick = null;
        };

        var showXRNotSupported = function(): Void {
            disableButton();
            button.textContent = "XR NOT SUPPORTED";
        };

        var showXRNotAllowed = function(exception: Dynamic): Void {
            disableButton();
            console.warn("Exception when trying to call xr.isSessionSupported", exception);
            button.textContent = "XR NOT ALLOWED";
        };

        var stylizeElement = function(element: Element): Void {
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
        };

        if ("xr" in navigator) {
            button.id = "XRButton";
            button.style.display = "none";
            stylizeElement(button);
            navigator.xr.isSessionSupported("immersive-ar")
                .then(function(supported: Bool) {
                    if (supported) {
                        showStartXR("immersive-ar");
                    } else {
                        navigator.xr.isSessionSupported("immersive-vr")
                            .then(function(supported: Bool) {
                                if (supported) {
                                    showStartXR("immersive-vr");
                                } else {
                                    showXRNotSupported();
                                }
                            }).catch(showXRNotAllowed);
                    }
                }).catch(showXRNotAllowed);
            return button;
        } else {
            var message = Document.current.createElement("a");
            if (Window.current.isSecureContext === false) {
                message.href = Document.current.location.href.replace(/^http:/, "https:");
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