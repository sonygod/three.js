class ARButton {

  static function createButton(renderer: Dynamic, sessionInit: Dynamic = {}) {

    var button = js.Browser.document.createElement('button');

    function showStartAR(/*device*/) {

      if (Reflect.field(sessionInit, 'domOverlay') == null) {

        var overlay = js.Browser.document.createElement('div');
        overlay.style.display = 'none';
        js.Browser.document.body.appendChild(overlay);

        var svg = js.Browser.document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', '38');
        svg.setAttribute('height', '38');
        svg.style.position = 'absolute';
        svg.style.right = '20px';
        svg.style.top = '20px';
        svg.addEventListener('click', function() {

          currentSession.end();

        });
        overlay.appendChild(svg);

        var path = js.Browser.document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', 'M 12,12 L 28,28 M 28,12 12,28');
        path.setAttribute('stroke', '#fff');
        path.setAttribute('stroke-width', '2');
        svg.appendChild(path);

        if (Reflect.field(sessionInit, 'optionalFeatures') == null) {

          sessionInit.optionalFeatures = [];

        }

        sessionInit.optionalFeatures.push('dom-overlay');
        sessionInit.domOverlay = { root: overlay };

      }

      //

      var currentSession = null;

      function onSessionStarted(session: Dynamic) {

        session.addEventListener('end', onSessionEnded);

        renderer.xr.setReferenceSpaceType('local');

        renderer.xr.setSession(session);

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

      //

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

          if (Reflect.field(navigator.xr, 'offerSession') != null) {

            navigator.xr.offerSession('immersive-ar', sessionInit)
              .then(onSessionStarted)
              .catch(function(err) {

                js.Browser.console.warn(err);

              });

          }

        }

      };

      if (Reflect.field(navigator.xr, 'offerSession') != null) {

        navigator.xr.offerSession('immersive-ar', sessionInit)
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

    function showARNotSupported() {

      disableButton();

      button.textContent = 'AR NOT SUPPORTED';

    }

    function showARNotAllowed(exception: Dynamic) {

      disableButton();

      js.Browser.console.warn('Exception when trying to call xr.isSessionSupported', exception);

      button.textContent = 'AR NOT ALLOWED';

    }

    function stylizeElement(element: Dynamic) {

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

      button.id = 'ARButton';
      button.style.display = 'none';

      stylizeElement(button);

      navigator.xr.isSessionSupported('immersive-ar').then(function(supported) {

        supported ? showStartAR() : showARNotSupported();

      }).catch(showARNotAllowed);

      return button;

    } else {

      var message = js.Browser.document.createElement('a');

      if (js.Browser.window.isSecureContext == false) {

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