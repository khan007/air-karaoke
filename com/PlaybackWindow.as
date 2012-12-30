package com{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageDisplayState;
	import flash.display.StageAlign;
	import flash.display.Sprite;
	import flash.display.DisplayObject;

	public class PlaybackWindow extends NativeWindow {

		private var _bkg:Sprite;
		private var _children:Array;

		public function PlaybackWindow() {
			// constructor code
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			options.systemChrome = NativeWindowSystemChrome.STANDARD;
			options.transparent = false;
			super(options);

			// setup stage
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.mouseChildren = false;
			stage.doubleClickEnabled = true;
			stage.addEventListener(Event.RESIZE, _onStageResize);
			stage.addEventListener(MouseEvent.DOUBLE_CLICK, _onDoubleClick);

			// window setup
			stage.nativeWindow.addEventListener(Event.CLOSING, _onCloseWindow);

			_bkg = new Sprite();
			_bkg.graphics.beginFill(0x000000);
			_bkg.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			_bkg.graphics.endFill();
			stage.addChild(_bkg);

			_children = new Array();

		}

		public function addChild(clip:DisplayObject):void {
			stage.addChild(clip);

			if (_children.indexOf(clip) < 0) {
				_children.push(clip);
			}

			_onStageResize(null);
		}
		public function addChildAt(clip:DisplayObject, index:uint):void {
			this.addChild(clip);
			stage.setChildIndex(clip, index);
			stage.setChildIndex(_bkg, 0);
		}

		public function removeChild(clip:DisplayObject):void {
			if (stage.contains(clip)) {
				stage.removeChild(clip);
			}
			if (_children.indexOf(clip) > -1) {
				_children.splice(_children.indexOf(clip), 1);
			}
		}

		public function setSize(w:uint, h:uint):void {
			stage.nativeWindow.width = stage.stageWidth = w;
			stage.nativeWindow.height = stage.stageHeight = h;
		}

		private function _onStageResize(e:Event):void {
			for (var i:uint = 0; i < _children.length; i++) {
				_children[i].setSize(stage.stageWidth, stage.stageHeight);
			}

			_bkg.graphics.beginFill(0x000000);
			_bkg.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			_bkg.graphics.endFill();
		}

		private function _onCloseWindow(e:Event):void {
			e.preventDefault();
			this.visible = false;
			dispatchEvent(new Event(Event.CLOSE));
		}

		private function _onDoubleClick(e:Event):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			} else {
				stage.displayState = StageDisplayState.NORMAL;
			}

		}

	}

}