import haxe.Serializer;
import haxe.Unserializer;
import js.Browser.Worker;
import js.Browser.Window;
import js.html.Audio;
import js.html.CanvasElement;
import js.html.CustomEvent;
import js.html.DivElement;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.HTMLCollection;
import js.html.HTMLElement;
import js.html.HTMLVideoElement;
import js.html.Image;
import js.html.MediaError;
import js.html.Node;
import js.html.Text;
import js.html.Video;
import js.html._Audio;
import js.lib.File;
import js.lib.FileReader;
import js.lib.XMLHttpRequest;
import js.node.Fs;
import js.NodeC.Fs;
import js.NodeC.Http;
import js.NodeC.Path;
import js.NodeC.Process;
import js.NodeC.Url;
import js.NodeC.ChildProcess;
import js.NodeC.Events;
import js.NodeC.Fs.Stats;
import js.NodeC.Http.ClientRequest;
import js.NodeC.Http.IncomingMessage;
import js.NodeC.Http.Server;
import js.NodeC.Http.ServerResponse;
import js.NodeC.Net.Socket;
import js.NodeC.Os;
import js.NodeC.Path.FsPath;
import js.NodeC.Stream.Writable;
import js.NodeC.Url.UrlObject;
import js.NodeC.ChildProcess.ChildProcess;
import js.NodeC.Events.EventEmitter;
import js.NodeC.Fs.ReadStream;
import js.NodeC.Fs.WriteStream;
import js.NodeC.Http.RequestOptions;
import js.NodeC.Net.TcpNetConnectOpts;
import js.NodeC.Os.TmpDirOptions;
import js.NodeC.Path.PlatformPath;
import js.NodeC.Stream.WritableOptions;
import js.NodeC.Url.Url;
import js.NodeC.ChildProcess.SpawnOptions;
import js.NodeC.ChildProcess.SpawnSyncOptions;
import js.NodeC.ChildProcess.SpawnSyncReturns;
import js.NodeC.Events.Listener;
import js.NodeC.Fs.NoParamCallback;
import js.NodeC.Fs.PathLike;
import js.NodeC.Fs.RmOptions;
import js.NodeC.Fs.WriteFileOptions;
import js.NodeC.Http.Agent;
import js.NodeC.Http.ClientRequestArgs;
import js.NodeC.Http.RequestOptionsOrString;
import js.NodeC.Net.Lookup;
import js.NodeC.Net.Service;
import js.NodeC.Net.SocketConnectOpts;
import js.NodeC.Os.NetworkInterfaceInfo;
import js.NodeC.Os.UserInfo;
import js.NodeC.Path.Buffer;
import js.NodeC.Path.PathLike;
import js.NodeC.Process.ProcessRelease;
import js.NodeC.Process.Signal;
import js.NodeC.Stream.Readable;
import js.NodeC.Stream.Stream;
import js.NodeC.Url.UrlWithParsedQuery;
import js.Node.Buffer;
import js.Node.ChildProcess;
import js.Node.Cluster;
import js.Node.Crypto;
import js.Node.Events;
import js.Node.Fs;
import js.Node.Http;
import js.Node.Net;
import js.Node.Os;
import js.Node.Path;
import js.Node.Process;
import js.Node.Querystring;
import js.Node.Readline;
import js.Node.Stream;
import js.Node.StringDecoder;
import js.Node.Timers;
import js.Node.Tls;
import js.Node.Url;
import js.Node.Util;
import js.Node.Vm;
import js.sys.ArrayBuffer;
import js.sys.ArrayUtils;
import js.sys.Byte;
import js.sys.Date;
import js.sys.Error;
import js.sys.Function;
import js.sys.Int32Array;
import js.sys.Math;
import js.sys.Reflect;
import js.sys.RegExp;
import js.sys.StringTools;
import js.sys.Uint8Array;
import js.sys.WeakMap;
import js.sys.WeakSet;
import js.Browser.Location;
import js.Browser.Navigator;
import js.Browser.Performance;
import js.Browser.Screen;
import js.Browser.Window;
import js.Browser.History;
import js.Browser.Location;
import js.Browser.Navigator;
import js.Browser.Performance;
import js.Browser.Screen;
import js.Browser.Window;
import js.Browser.MsBrowser;
import js.Browser.MsBrowser.MSInputMethodContext;
import js.Browser.MsBrowser.MSGesture;
import js.Browser.MsBrowser.MSManipulationViews;
import js.Browser.MsBrowser.MSMediaKeyMessageEvent;
import js.Browser.MsBrowser.MSMediaKeys;
import js.Browser.MsBrowser.MSPointerEvent;
import js.Browser.MsBrowser.MSTouchAction;
import js.Browser.MsBrowser.MSTouchActionListener;
import js.Browser.MsBrowser.MSTouchActions;
import js.Browser.MsBrowser.MSTouchEvent;
import js.Browser.MsBrowser.MSWebViewAsyncOperation;
import js.Browser.MsBrowser.MSWebViewAsyncOperationResultGetParameter;
import js.Browser.MsBrowser.MSWebViewAsyncOperationWithResultCallback;
import js.Browser.MsBrowser.MSWebViewAsyncOperationWithSyncCallback;
import js.Browser.MsBrowser.MSWebViewSettings;
import js.Browser.MsBrowser.MSWebViewUnviewableContentIdentifiedEvent;
import js.Browser.MsBrowser.MSWebView;
import js.Browser.MsBrowser.MSXMLHttpRequestUpload;
import js.Browser.MsBrowser.MSXMLHttpRequest;
import js.Browser.WebKit;
import js.Browser.WebKit.WebKitAnimationEvent;
import js.Browser.WebKit.WebKitAnimationEvents;
import js.Browser.WebKit.WebKitAnimationPlayer;
import js.Browser.WebKit.WebKitAnimationPlayers;
import js.Browser.WebKit.WebKitCSSMatrix;
import js.Browser.WebKit.WebKitCSSRegionRule;
import js.Browser.WebKit.WebKitCSSRule;
import js.Browser.WebKit.WebKitCSSRuleList;
import js.Browser.WebKit.WebKitCSSStyleDeclaration;
import js.Browser.WebKit.WebKitCSSStyleSheet;
import js{
const cacheName = 'threejs-editor';

const assets = [
	'./',

	'./manifest.json',
	'./images/icon.png',

	'../files/favicon.ico',

	'../build/three.module.js',

	'../examples/jsm/controls/TransformControls.js',

	'../examples/jsm/libs/chevrotain.module.min.js',
	'../examples/jsm/libs/fflate.module.js',

	'../examples/jsm/libs/draco/draco_decoder.js',
	'../examples/jsm/libs/draco/draco_decoder.wasm',
	'../examples/jsm/libs/draco/draco_encoder.js',
	'../examples/jsm/libs/draco/draco_wasm_wrapper.js',

	'../examples/jsm/libs/draco/gltf/draco_decoder.js',
	'../examples/jsm/libs/draco/gltf/draco_decoder.wasm',
	'../examples/jsm/libs/draco/gltf/draco_wasm_wrapper.js',

	'../examples/jsm/libs/meshopt_decoder.module.js',

	'../examples/jsm/libs/mikktspace.module.js',

	'../examples/jsm/libs/motion-controllers.module.js',

	'../examples/jsm/libs/rhino3dm/rhino3dm.wasm',
	'../examples/jsm/libs/rhino3dm/rhino3dm.js',

	'../examples/jsm/loaders/3DMLoader.js',
	'../examples/jsm/loaders/3MFLoader.js',
	'../examples/jsm/loaders/AMFLoader.js',
	'../examples/jsm/loaders/ColladaLoader.js',
	'../examples/jsm/loaders/DRACOLoader.js',
	'../examples/jsm/loaders/FBXLoader.js',
	'../examples/jsm/loaders/GLTFLoader.js',
	'../examples/jsm/loaders/KMZLoader.js',
	'../examples/jsm/loaders/KTX2Loader.js',
	'../examples/jsm/loaders/MD2Loader.js',
	'../examples/jsm/loaders/OBJLoader.js',
	'../examples/jsm/loaders/MTLLoader.js',
	'../examples/jsm/loaders/PCDLoader.js',
	'../examples/jsm/loaders/PLYLoader.js',
	'../examples/jsm/loaders/RGBELoader.js',
	'../examples/jsm/loaders/STLLoader.js',
	'../examples/jsm/loaders/SVGLoader.js',
	'../examples/jsm/loaders/TGALoader.js',
	'../examples/jsm/loaders/TDSLoader.js',
	'../examples/jsm/loaders/USDZLoader.js',
	'../examples/jsm/loaders/VOXLoader.js',
	'../examples/jsm/loaders/VRMLLoader.js',
	'../examples/jsm/loaders/VTKLoader.js',
	'../examples/jsm/loaders/XYZLoader.js',

	'../examples/jsm/curves/NURBSCurve.js',
	'../examples/jsm/curves/NURBSUtils.js',

	'../examples/jsm/interactive/HTMLMesh.js',
	'../examples/jsm/interactive/InteractiveGroup.js',

	'../examples/jsm/environments/RoomEnvironment.js',

	'../examples/jsm/exporters/DRACOExporter.js',
	'../examples/jsm/exporters/GLTFExporter.js',
	'../examples/jsm/exporters/OBJExporter.js',
	'../examplesFreq.js',
	'./js/Sidebar.Project.App.js',
	'./js/Sidebar.Project.Image.js',
	'./js/Sidebar.Project.Video.js',
	'./js/Sidebar.Settings.js',
	'./js/Sidebar.Settings.History.js',
	'./js/Sidebar.Settings.Shortcuts.js',
	'./js/Sidebar.Properties.js',
	'./js/Sidebar.Object.js',
	'./js/Sidebar.Object.Animation.js',
	'./js/Sidebar.Geometry.js',
	'./js/Sidebar.Geometry.BufferGeometry.js',
	'./js/Sidebar.Geometry.Modifiers.js',
	'./js/Sidebar.Geometry.BoxGeometry.js',
	'./js/Sidebar.Geometry.CapsuleGeometry.js',
	'./js/Sidebar.Geometry.CircleGeometry.js',
	'./js/Sidebar.Geometry.CylinderGeometry.js',
	'./js/Sidebar.Geometry.DodecahedronGeometry.js',
	'./js/Sidebar.Geometry.ExtrudeGeometry.js',
	'./js/Sidebar.Geometry.IcosahedronGeometry.js',
	'./js/Sidebar.Geometry.LatheGeometry.js',
	'./js/Sidebar.Geometry.OctahedronGeometry.js',
	'./js/Sidebar.Geometry.PlaneGeometry.js',
	'./js/Sidebar.Geometry.RingGeometry.js',
	'./js/Sidebar.Geometry.SphereGeometry.js',
	'./js/Sidebar.Geometry.ShapeGeometry.js',
	'./js/Sidebar.Geometry.TetrahedronGeometry.js',
	'./js/Sidebar.Geometry.TorusGeometry.js',
	'./js/Sidebar.Geometry.TorusKnotGeometry.js',
	'./js/Sidebar.Geometry.TubeGeometry.js',
	'./js/Sidebar.Material.js',
	'./js/Sidebar.Material.BooleanProperty.js',
	'./js/Sidebar.Material.ColorProperty.js',
	'./js/Sidebar.Material.ConstantProperty.js',
	'./js/Sidebar.Material.MapProperty.js',
	'./js/Sidebar.Material.NumberProperty.js',
	'./js/Sidebar.Material.Program.js',
	'./js/Sidebar.Script.js',
	'./js/Strings.js',
	'./js/Toolbar.js',
	'./js/Viewport.js',
	'./js/Viewport.Controls.js',
	'./js/Viewport.Info.js',
	'./js/Viewport.ViewHelper.js',
	'./js/Viewport.XR.js',

	'./js/Command.js',
	'./js/commands/AddObjectCommand.js',
	'./js/commands/RemoveObjectCommand.js',
	'./js/commands/MoveObjectCommand.js',
	'./js/commands/SetPositionCommand.js',
	'./js/commands/SetRotationCommand.js',
	'./js/commands/SetScaleCommand.js',
	'./js/commands/SetValueCommand.js',
	'./js/commands/SetUuidCommand.js',
	'./js/commands/SetColorCommand.js',
	'./js/commands/SetGeometryCommand.js',
	'./js/commands/SetGeometryValueCommand.js',
	'./js/commands/MultiCmdsCommand.js',
	'./js/commands/AddScriptCommand.js',
	'./js/commands/RemoveScriptCommand.js',
	'./js/commands/SetScriptValueCommand.js',
	'./js/commands/SetMaterialCommand.js',
	'./js/commands/SetMaterialColorCommand.js',
	'./js/commands/SetMaterialMapCommand.js',
	'./js/commands/SetMaterialValueCommand.js',
	'./js/commands/SetMaterialVectorCommand.js',
	'./js/commands/SetSceneCommand.js',
	'./js/commands/Commands.js',

	//

	'./examples/arkanoid.app.json',
	'./examples/camera.app.json',
	'./examples/particles.app.json',
	'./examples/pong.app.json',
	'./examples/shaders.app.json'

];

self.addEventListener( 'install', function () {
	var cache = caches.open( cacheName );

	for ( var i = 0; i < assets.length; i++ ) {
		var asset = assets[i];
		cache.add( asset );
	}
} );

self.addEventListener( 'fetch', function ( event ) {
	var request = event.request;

	if ( request.url.startsWith( 'chrome-extension' ) ) return;

	event.respondWith( networkFirst( request ) );
} );

function networkFirst( request ) {
	return fetch( request ).then( function ( response ) {
		if ( request.url.endsWith( 'editor/' ) || request.url.endsWith( 'editor/index.html' ) ) { // copied from coi-serviceworker
			var newHeaders = new Headers( response.headers );
			newHeaders.set( 'Cross-Origin-Embedder-Policy', 'require-corp' );
			newHeaders.set( 'Cross-Origin-Opener-Policy', 'same-origin' );

			response = new Response( response.body, { status: response.status, statusText: response.statusText, headers: newHeaders } );
		}

		if ( request.method === 'GET' ) {
			caches.open( cacheName ).then( function ( cache ) {
				cache.put( request, response.clone() );
			} );
		}

		return response;
	} ).catch( function () {
		return caches.match( request ).then( function ( cachedResponse ) {
			if ( cachedResponse === undefined ) {
				console.warn( '[SW] Not cached:', request.url );
			}

			return cachedResponse;
		} );
	} );
}