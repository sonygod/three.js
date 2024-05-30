class XRButton {

    static function createButton(renderer:Dynamic, sessionInit:Dynamic = {}):Dynamic {

        var button = js.Browser.document.createElement('button');

        function showStartXR(mode:String) {

            var currentSession:Dynamic = null;

            function onSessionStarted(session:Dynamic) {

                session.addEventListener('end', onSessionEnded);

                renderer.xr.setSession(session).then(function() {

                    button.textContent = 'STOP XR';

                    currentSession = session;

                });

            }

            function onSessionEnded() {

                currentSession.removeEventListener('end', onSessionEnded);

                button.textContent = 'START XR';

                currentSession = null;

            }

            button.style.display = '';

            button.style.cursor = 'pointer';
            button.style.left = 'calc(50% - 50px)';
            button.style.width = '100px';

            button.textContent = 'START XR';

            var sessionOptions = {
                ...sessionInit,
                optionalFeatures: [
                    'local-floor',
                    'bounded-floor',
                    'layers',
                    ...(sessionInit.optionalFeatures || [])
                ],
            };

            button.onmouseenter = function () {

                button.style.opacity = '1.0';

            };

            button.onmouseleave = function () {

                button.style.opacity = '0.5';

            };

            button.onclick = function () {

                if (currentSession === null) {

                    navigator.xr.requestSession(mode, sessionOptions)
                        .then(onSessionStarted);

                } else {

                    currentSession.end();

                    if (navigator.xr.offerSession !== undefined) {

                        navigator.xr.offerSession(mode, sessionOptions)
                            .then(onSessionStarted)
                            .catch(function(err) {

                                js.Browser.console.warn(err);

                            });

                    }

                }

            };

            if (navigator.xr.offerSession !== undefined) {

                navigator.xr.offerSession(mode, sessionOptions)
                    .then(onSessionStarted)
                    .catch(function(err) {

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

        function showXRNotSupported() {

            disableButton();

            button.textContent = 'XR NOT SUPPORTED';

        }

        function showXRNotAllowed(exception:Dynamic) {

            disableButton();

            js.Browser.console.warn('Exception when trying to call xr.isSessionSupported', exception);

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

        if ('xr' in js.Browser.navigator) {

            button.id = 'XRButton';
            button.style.display = 'none';

            stylizeElement(button);

            js.Browser.navigator.xr.isSessionSupported('immersive-ar')
                .then(function(supported:Bool) {

                    if (supported) {

                        showStartXR('immersive-ar');

                    } else {

                        js.Browser.navigator.xr.isSessionSupported('immersive-vr')
                            .then(function(supported:Bool) {

                                if (supported) {

                                    showStartXR('immersive-vr');

                                } else {

                                    showXRNotSupported();

                                }

                            }).catch(showXRNotAllowed);

                    }

                }).catch(showXRNotAllowed);

            return button;

        } else {

            var message = js.Browser.document.createElement('a');

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

}