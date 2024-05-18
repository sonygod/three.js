package three.js.examples.jsm.webxr;

import js.Browser;
import js.html.ButtonElement;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.Navigator;
import js.html XRSession;
import js.Promise;

class VRButton {
  static var xrSessionIsGranted:Bool = false;

  static function createButton(renderer:Dynamic, ?sessionInit:Dynamic):ButtonElement {
    var button:ButtonElement = Browser.document.createElement('button');

    function showEnterVR(?device:Dynamic) {
      var currentSession:XRSession = null;

      function onSessionStarted(session:XRSession) {
        session.addEventListener('end', onSessionEnded);
        renderer.xr.setSession(session);
        button.textContent = 'EXIT VR';
        currentSession = session;
      }

      function onSessionEnded(event:Event) {
        currentSession.removeEventListener('end', onSessionEnded);
        button.textContent = 'ENTER VR';
        currentSession = null;
      }

      button.style.display = '';
      button.style.cursor = 'pointer';
      button.style.left = 'calc(50% - 50px)';
      button.style.width = '100px';
      button.textContent = 'ENTER VR';

      var sessionOptions:Dynamic = {
        optionalFeatures: [
          'local-floor',
          'bounded-floor',
          'layers',
          ...(sessionInit.optionalFeatures || [])
        ]
      };

      button.onmouseenter = function () {
        button.style.opacity = '1.0';
      };

      button.onmouseleave = function () {
        button.style.opacity = '0.5';
      };

      button.onclick = function () {
        if (currentSession === null) {
          Navigator.xr.requestSession('immersive-vr', sessionOptions).then(onSessionStarted);
        } else {
          currentSession.end();
          if (Navigator.xr.offerSession != null) {
            Navigator.xr.offerSession('immersive-vr', sessionOptions)
              .then(onSessionStarted)
              .catchError(function (err) {
                console.warn(err);
              });
          }
        }
      };

      if (Navigator.xr.offerSession != null) {
        Navigator.xr.offerSession('immersive-vr', sessionOptions)
          .then(onSessionStarted)
          .catchError(function (err) {
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

    function showVRNotAllowed(exception:Dynamic) {
      disableButton();
      console.warn('Exception when trying to call xr.isSessionSupported', exception);
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

    if (Browser.navigator.xr != null) {
      button.id = 'VRButton';
      button.style.display = 'none';
      stylizeElement(button);

      Browser.navigator.xr.isSessionSupported('immersive-vr')
        .then(function (supported:Bool) {
          if (supported) showEnterVR() else showWebXRNotFound();
          if (supported && VRButton.xrSessionIsGranted) button.click();
        })
        .catchError(showVRNotAllowed);

      return button;
    } else {
      var message:Element = Browser.document.createElement('a');
      if (!Browser.window.isSecureContext) {
        message.href = Browser.window.location.href.replace(/^http:/, 'https:');
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

  static function registerSessionGrantedListener() {
    if (Browser.navigator.xr != null) {
      // WebXRViewer (based on Firefox) has a bug where addEventListener
      // throws a silent exception and aborts execution entirely.
      if (~Browser.navigator.userAgent.indexOf('WebXRViewer/')) return;

      Browser.navigator.xr.addEventListener('sessiongranted', function () {
        VRButton.xrSessionIsGranted = true;
      });
    }
  }

  static function main() {
    registerSessionGrantedListener();
  }
}