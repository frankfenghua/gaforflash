﻿/*
 * Copyright 2008 Adobe Systems Inc., 2008 Google Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Contributor(s):
 *   Zwetan Kjukov <zwetan@gmail.com>.
 *   Marc Alcaraz <ekameleon@gmail.com>.
 */

package com.google.analytics.debug
{
    import com.google.analytics.GATracker;
    import com.google.analytics.core.GIFRequest;
    import com.google.analytics.debug;
    
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.net.URLRequest;
    import flash.ui.Keyboard;
    import flash.utils.getTimer;
    
    import system.diagnostics.VirtualMachine;
    
    /**
     * The Layout class is a helper who manages
     * as a factory all visual display in the application.
     */
    public class Layout
    {
        private var _display:DisplayObject;
        private var _mainPanel:Panel;
        
        private var _hasWarning:Boolean;
        private var _hasInfo:Boolean;
        private var _hasDebug:Boolean;
        private var _infoQueue:Array;
        private var _maxCharPerLine:int = 85;
        private var _warningQueue:Array;
        
        /**
         * The Debug reference of this Layout.
         */
        public var visualDebug:Debug;
        
        /**
         * Creates a new Layout instance.
         */
        public function Layout( display:DisplayObject )
        {
            super();
            _display   = display;
            _hasWarning = false;
            _hasInfo    = false;
            _hasDebug   = false;
            _warningQueue = [];
            _infoQueue    = [];
        }
        
        public function init():void
        {
            var spaces:int = 10;
            var W:uint = _display.stage.stageWidth - (spaces*2);
            var H:uint = _display.stage.stageHeight - (spaces*2);
            //var W:uint = 400;
            //var H:uint = 300;
            var mp:Panel = new Panel( "analytics", W, H );
                mp.alignement = Align.top;
                mp.stickToEdge = false;
                mp.title = "Google Analytics v" + GATracker.version;
            
            _mainPanel = mp;
            addToStage( mp );
            bringToFront( mp );
            //_mainPanel.onToggle(); //toggle on start
            createVisualDebug();
            
            _display.stage.addEventListener( KeyboardEvent.KEY_DOWN, onKey, false, 0, true );
        }
        
        public function destroy():void
        {
            debug.layout = null;
            _mainPanel.close();
            VirtualMachine.garbageCollection();
        }
        
        private function onKey( event:KeyboardEvent = null ):void
        {
            switch( event.keyCode )
            {
                case Keyboard.SPACE:
                _mainPanel.visible = !_mainPanel.visible;
                break;
                
                case Keyboard.BACKSPACE:
                trace( "## destroying the layout ##" );
                destroy();
                break;
            }
        }
        
        private function _clearInfo( event:Event ):void
        {
            _hasInfo = false;
            
            if( _infoQueue.length > 0 )
            {
                createInfo( _infoQueue.shift() );
            }
        }
        
        private function _clearWarning( event:Event ):void
        {
            _hasWarning = false;
            if( _warningQueue.length > 0 )
            {
                createWarning( _warningQueue.shift() );
            }
        }
        
        private function _filterMaxChars( message:String, maxCharPerLine:int = 0 ):String
        {
            var CRLF:String = "\n";
            var output:Array = [];
            var lines:Array = message.split(CRLF);
            var line:String;
            
            if( maxCharPerLine == 0 )
            {
                maxCharPerLine = _maxCharPerLine;
            }
            
            for( var i:int = 0; i<lines.length; i++ )
            {
                line = lines[i];
                while( line.length > maxCharPerLine )
                {
                    output.push( line.substr(0,maxCharPerLine) );
                    line = line.substring(maxCharPerLine);
                }
                output.push( line );
            }
            return output.join(CRLF);
        }
        
        /**
         * The protected custom trace method.
         */
        protected function trace( message:String ):void
        {
            var messages:Array = [];
            var pre0:String = getTimer() + " - ";
            var pre1:String = new Array(pre0.length).join(" ") + " ";
            
            if( message.indexOf("\n") > -1 )
            {
                var msgs:Array = message.split("\n");
                for( var j:int = 0; j<msgs.length; j++ )
                {
                    if( msgs[j] == "" )
                    {
                        continue;
                    }
                    
                    if( j == 0 )
                    {
                        messages.push( pre0 + msgs[j] );
                    }
                    else
                    {
                        messages.push( pre1 + msgs[j] );
                    }
                }
            }
            else
            {
                messages.push( pre0 + message );
            }
            
            var len:int = messages.length ;
            for( var i:int = 0; i<len ; i++ )
            {
                public::trace( messages[i] );
            }
        }
        
        /**
         * Adds to stage the specified visual display.
         */
        public function addToStage( visual:DisplayObject ):void
        {
            _display.stage.addChild( visual );
        }
        
        public function addToPanel( name:String, visual:DisplayObject ):void
        {
            var d:DisplayObject = _display.stage.getChildByName( name );
            
            if( d )
            {
                var panel:Panel = d as Panel;
                panel.addData( visual );
            }
            else
            {
                trace( "panel \""+name+"\" not found" );
            }
        }
        
        /**
         * Brings to front the specified visual display.
         */
        public function bringToFront( visual:DisplayObject ):void
        {
            _display.stage.setChildIndex( visual, _display.stage.numChildren - 1 );
        }
        
        public function isAvailable():Boolean
        {
            return _display.stage != null;
        }
        
        /**
         * Creates a debug message in the debug display.
         */
        public function createVisualDebug():void
        {
            if( !visualDebug )
            {
                visualDebug = new Debug();
                visualDebug.alignement = Align.bottom;
                visualDebug.stickToEdge = true;
                addToPanel( "analytics", visualDebug );
                _hasDebug = true;
            }
        }
        
        public function createPanel( name:String, width:uint, height:uint ):void
        {
            var p:Panel = new Panel( name, width, height );
                p.alignement = Align.center;
                p.stickToEdge = false;
            
            addToStage( p );
            bringToFront( p );
        }
        
        /**
         * Creates an info message in the debug display.
         */        
        public function createInfo( message:String ):void
        {
            if( _hasInfo || !isAvailable() )
            {
                _infoQueue.push( message );
                return;
            }
            
            message = _filterMaxChars( message );
            _hasInfo = true;
            var i:Info = new Info( message );
            addToPanel( "analytics", i );
            
            i.addEventListener( Event.REMOVED_FROM_STAGE, _clearInfo );
            
            if( _hasDebug )
            {
                visualDebug.write( message );
            }
            
            if( debug.trace )
            {
                trace( message );
            }
        }
        
        /**
         * Creates a warning message in the debug display.
         */
        public function createWarning( message:String ):void
        {
            if( _hasWarning || !isAvailable() )
            {
                _warningQueue.push( message );
                return;
            }
            _hasWarning = true;
            var w:Warning = new Warning( message );
            addToPanel( "analytics", w );
            
            w.addEventListener( Event.REMOVED_FROM_STAGE, _clearWarning );
            if( _hasDebug )
            {
                visualDebug.writeBold( message );
            }
            if( debug.trace )
            {
                trace( "## " + message + " ##" );
            }
        }
        
        /**
         * Creates an alert message in the debug display.
         */
        public function createAlert( message:String ):void
        {
            message = _filterMaxChars( message );
            var a:Alert = new Alert( message, [ new AlertAction("Close","close","close") ] );
            addToPanel( "analytics", a );
            
            if( _hasDebug )
            {
                visualDebug.writeBold( message );
            }
            if( debug.trace )
            {
                trace( "##" + message + " ##" );
            }
        }
        
        /**
         * Creates a failure alert message in the debug display.
         */
        public function createFailureAlert( message:String ):void
        {
            var actionClose:AlertAction;
            
            if( debug.verbose )
            {
                message = _filterMaxChars( message );
                actionClose = new AlertAction("Close","close","close");
            }
            else
            {
                actionClose = new AlertAction("X","close","close");
            }
            
            var fa:Alert = new FailureAlert( message, [ actionClose ] );
            addToPanel( "analytics", fa );
            
            if( _hasDebug )
            {
                if( debug.verbose )
                {
                    message = message.split("\n").join("");
                    message = _filterMaxChars( message, 66 );
                }
                visualDebug.writeBold( message );
            }
            
            if( debug.trace )
            {
                trace( "## " + message + " ##" );
            }
        }
        
        /**
         * Creates a success alert message in the debug display.
         */
        public function createSuccessAlert( message:String ):void
        {
            var actionClose:AlertAction;
            
            if( debug.verbose )
            {
                message = _filterMaxChars( message );
                actionClose = new AlertAction("Close","close","close");
            }
            else
            {
                actionClose = new AlertAction("X","close","close");
            }
            var sa:Alert = new SuccessAlert( message, [ actionClose ] );
            addToPanel( "analytics", sa );
            
            if( _hasDebug )
            {
                if( debug.verbose )
                {
                    message = message.split("\n").join("");
                    message = _filterMaxChars( message, 66 );
                }
                visualDebug.writeBold( message );
            }
            
            if( debug.trace )
            {
                trace( "## " + message + " ##" );
            }
        }
        
        /**
         * Creates a GIFRequest alert message in the debug display.
         */
        public function createGIFRequestAlert( message:String, request:URLRequest, ref:GIFRequest ):void
        {
            
            var f:Function = function():void
            {
                ref.sendRequest( request );
            };
            
            message = _filterMaxChars( message );
            var gra:GIFRequestAlert = new GIFRequestAlert( message, [ new AlertAction("OK","ok",f),
                                                                      new AlertAction("Cancel","cancel","close") ] );
            
            addToPanel( "analytics", gra );
            if( _hasDebug )
            {
                visualDebug.write( message );
            }
            
            if( debug.trace )
            {
                trace( "##" + message + " ##" );
            }
        }
        
    }
}

