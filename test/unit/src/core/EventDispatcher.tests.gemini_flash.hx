import qunit.QUnit;

class EventDispatcher {
	public var _listeners:Map<String,Array<Dynamic>> = new Map();

	public function new() {}

	public function addEventListener( type:String, listener:Dynamic ):Void {
		if ( !_listeners.exists( type ) ) {
			_listeners.set( type, new Array<Dynamic>() );
		}
		_listeners.get( type ).push( listener );
	}

	public function hasEventListener( type:String, listener:Dynamic ):Bool {
		if ( !_listeners.exists( type ) ) return false;
		return _listeners.get( type ).indexOf( listener ) != -1;
	}

	public function removeEventListener( type:String, listener:Dynamic ):Void {
		if ( !_listeners.exists( type ) ) return;
		_listeners.get( type ).remove( listener );
	}

	public function dispatchEvent( event:Dynamic ):Void {
		if ( !_listeners.exists( event.type ) ) return;
		for ( listener in _listeners.get( event.type ) ) {
			listener();
		}
	}
}

class TestEventDispatcher {
	static function main() {
		QUnit.module( "Core", function() {
			QUnit.module( "EventDispatcher", function() {
				QUnit.test( "Instancing", function( assert ) {
					var object = new EventDispatcher();
					assert.ok( object != null, "Can instantiate an EventDispatcher." );
				} );

				QUnit.test( "addEventListener", function( assert ) {
					var eventDispatcher = new EventDispatcher();
					var listener = {};
					eventDispatcher.addEventListener( "anyType", listener );

					assert.ok( eventDispatcher._listeners.get( "anyType" ).length == 1, "listener with unknown type was added" );
					assert.ok( eventDispatcher._listeners.get( "anyType" )[ 0 ] == listener, "listener with unknown type was added" );

					eventDispatcher.addEventListener( "anyType", listener );

					assert.ok( eventDispatcher._listeners.get( "anyType" ).length == 1, "can't add one listener twice to same type" );
					assert.ok( eventDispatcher._listeners.get( "anyType" )[ 0 ] == listener, "listener is still there" );
				} );

				QUnit.test( "hasEventListener", function( assert ) {
					var eventDispatcher = new EventDispatcher();
					var listener = {};
					eventDispatcher.addEventListener( "anyType", listener );

					assert.ok( eventDispatcher.hasEventListener( "anyType", listener ), "listener was found" );
					assert.ok( ! eventDispatcher.hasEventListener( "anotherType", listener ), "listener was not found which is good" );
				} );

				QUnit.test( "removeEventListener", function( assert ) {
					var eventDispatcher = new EventDispatcher();
					var listener = {};

					assert.ok( eventDispatcher._listeners == null, "there are no listeners by default" );

					eventDispatcher.addEventListener( "anyType", listener );
					assert.ok( eventDispatcher._listeners.get( "anyType" ).length == 1, "if a listener was added, there is a new key" );

					eventDispatcher.removeEventListener( "anyType", listener );
					assert.ok( eventDispatcher._listeners.get( "anyType" ).length == 0, "listener was deleted" );

					eventDispatcher.removeEventListener( "unknownType", listener );
					assert.ok( eventDispatcher._listeners.get( "unknownType" ) == null, "unknown types will be ignored" );

					eventDispatcher.removeEventListener( "anyType", null );
					assert.ok( eventDispatcher._listeners.get( "anyType" ).length == 0, "undefined listeners are ignored" );
				} );

				QUnit.test( "dispatchEvent", function( assert ) {
					var eventDispatcher = new EventDispatcher();
					var callCount = 0;
					var listener = function() {
						callCount++;
					};

					eventDispatcher.addEventListener( "anyType", listener );
					assert.ok( callCount == 0, "no event, no call" );

					eventDispatcher.dispatchEvent( { type: "anyType" } );
					assert.ok( callCount == 1, "one event, one call" );

					eventDispatcher.dispatchEvent( { type: "anyType" } );
					assert.ok( callCount == 2, "two events, two calls" );
				} );
			} );
		} );
	}
}