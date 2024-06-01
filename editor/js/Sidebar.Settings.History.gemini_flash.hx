import three.core.Object3D;
import three.editor.Editor;
import ui.UIButton;
import ui.UIBreak;
import ui.UIPanel;
import ui.UIText;
import ui.three.UIBoolean;
import ui.three.UIOutliner;

class SidebarSettingsHistory extends UIPanel {

  public function new( editor : Editor ) {

    super();

    var strings = editor.strings;
    var signals = editor.signals;
    var config = editor.config;
    var history = editor.history;

    add( new UIText( strings.getKey( 'sidebar/history' ).toUpperCase() ) );

    //

    var persistent = new UIBoolean( config.getKey( 'settings/history' ), strings.getKey( 'sidebar/history/persistent' ) );
    persistent.setPosition( 'absolute' ).setRight( '8px' );
    persistent.onChange.add( function( _ ) {

      var value = persistent.getValue();

      config.setKey( 'settings/history', value );

      if ( value ) {

        js.Lib.alert( strings.getKey( 'prompt/history/preserve' ) );

        var lastUndoCmd = history.undos[ history.undos.length - 1 ];
        var lastUndoId = ( lastUndoCmd != null ) ? lastUndoCmd.id : 0;
        editor.history.enableSerialization( lastUndoId );

      } else {

        signals.historyChanged.dispatch();

      }

    } );
    add( persistent );

    add( new UIBreak(), new UIBreak() );

    var ignoreObjectSelectedSignal = false;

    var outliner = new UIOutliner( editor );
    outliner.onChange.add( function( _ ) {

      ignoreObjectSelectedSignal = true;

      history.goToState( Std.parseInt( outliner.getValue() ) );

      ignoreObjectSelectedSignal = false;

    } );
    add( outliner );

    add( new UIBreak() );

    // Clear History

    var option = new UIButton( strings.getKey( 'sidebar/history/clear' ) );
    option.onClick.add( function( _ ) {

      if ( js.Browser.confirm( strings.getKey( 'prompt/history/clear' ) ) ) {

        editor.history.clear();

      }

    } );
    add( option );

    //

    var refreshUI = function() {

      var options = [];

      function buildOption( object : Object3D ) : js.html.Element {

        var option = js.Browser.document.createElement( 'div' );
        Reflect.setProperty( option, 'value', object.id );

        return option;

      }

      for ( i in 0...history.undos.length ) {
        var object = history.undos[ i ];
        var option = buildOption( object );
        option.innerHTML = '&nbsp;' + object.name;
        options.push( option );
      }

      for ( i in 0...history.redos.length ) {
        var object = history.redos[ history.redos.length - 1 - i ];
        var option = buildOption( object );
        option.innerHTML = '&nbsp;' + object.name;
        option.style.opacity = 0.3;
        options.push( option );
      }

      outliner.setOptions( options );

    };

    refreshUI();

    // events

    signals.editorCleared.add( refreshUI );

    signals.historyChanged.add( refreshUI );
    signals.historyChanged.add( function( cmd ) {

      if ( ignoreObjectSelectedSignal ) return;

      outliner.setValue( ( cmd != null ) ? cmd.id : null );

    } );

  }

}