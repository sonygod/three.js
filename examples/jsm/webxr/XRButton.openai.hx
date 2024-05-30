package three.js.examples.jsm.webxr;

import js.html.ButtonElement;
import js.html.Document;
import js.html.Navigator;
import js.html.Element;
import js.html.Event;
import js.html.MouseEvent;
import js.lib.Promise;

class XRButton {

  static function createButton(renderer:Dynamic, sessionInit:Dynamic = {}):ButtonElement {

    var button:ButtonElement = Document.createElement('button');

    function showStartXR(mode:String) {
      var currentSession:Null<XRSession> = null;

      async function onSessionStarted(session:XRSession) {
        session.addEventListener('end', onSessionEnded);
        await renderer.xr.setSession(session);
        button.textContent = 'STOP XR';
        currentSession = session;
      }

      function onSessionEnded(event:Event) {
        currentSession.removeEventListener('end', onSessionEnded);
        button.textContent = 'START XR';
        currentSession = null;
      }

      button.style.display = '';
      button.style.cursor = 'pointer';
      button.style.left = 'calc(50% - 50px)';
      button.style.width = '100px';

      button.textContent = 'START XR';

      var sessionOptions:Dynamic = {
        ...sessionInit,
        optionalFeatures: [
          'local-floor',
          'bounded-floor',
          'layers',
          ...(sessionInit.optionalFeatures || [])
        ],
      };

      button.onmouseenter = function (_) {
        button.style.opacity = '1.0';
      };

      button.onmouseleave = function (_) {
        button.style.opacity = '0.5';
      };

      button.onclick = function (_) {
        if (currentSession == null) {
          Navigator.xr.requestSession(mode, sessionOptions)
            .then(onSessionStarted);
        } else {
          currentSession.end();
          if (Navigator.xr.offerSession != null) {
            Navigator.xr.offerSession(mode, sessionOptions)
              .then(onSessionStarted)
              .catchError(function (err) {
                console.warn(err);
              });
          }
        }
      };
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

    function showXRNotAllowed(exception:Event) {
      disableButton();
      console.warn('Exception when trying to call xr.isSessionSupported', exception);
      button.textContent = 'XR NOT ALLOWED';
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

    if (Reflect.hasField(Navigator, 'xr')) {
      button.id = 'XRButton';
      button.style.display = 'none';

      stylizeElement(button);

      Navigator.xr.isSessionSupported('immersive-ar')
        .then(function (supported:Bool) {
          if (supported) {
            showStartXR('immersive-ar');
          } else {
            Navigator.xr.isSessionSupported('immersive-vr')
              .then(function (supported:Bool) {
                if (supported) {
                  showStartXR('immersive-vr');
                } else {
                  showXRNotSupported();
                }
              })
              .catchError(showXRNotAllowed);
          }
        })
        .catchError(showXRNotAllowed);

      return button;
    } else {
      var message:Element = Document.createElement('a');

      if (!window.isSecureContext) {
        message.href = Document.location.href.replace(/^http:/, 'https:');
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