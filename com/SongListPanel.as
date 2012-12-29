package com {
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.DataEvent;
	import flash.events.Event;
	import com.Song;
	
	public class SongListPanel extends Sprite {
		
		public static const PLAY_SONG:String = "PlaySong";
		private static const PADDING:uint = 5;
		private var _container:Sprite;
		private var _items:Array = new Array();
		private var _list:Array;
		private var _selectedSong:Song;
		private var _leftArrow:LeftArrow;
		private var _rightArrow:RightArrow;
		private var _startIndex:uint;
		private var _endIndex:uint;
		private var _songManager:SongManager;

		public function SongListPanel(songManager:SongManager) {
			// constructor code
			_songManager = songManager;
			
			_container = new Sprite();
			this.addChild(_container);
			
			_leftArrow = new LeftArrow();
			_rightArrow = new RightArrow();
			
			_leftArrow.addEventListener(MouseEvent.CLICK, _onNavigate);
			_rightArrow.addEventListener(MouseEvent.CLICK, _onNavigate);
		}
		
		private function _showList(startIndex:uint = 0):void {
			var list:Array = _songManager.getSongList(startIndex);
			_destroyAllItems();
			
			// add heading
			var songItem:SongListItem = new SongListItem("Songs", SongListItem.HEADING);
			songItem.setSize(stage.stageWidth);
			_container.addChild(songItem);
			_items.push(songItem);
			
			// add songs
			_list = list;
			_startIndex = startIndex;
			var itemHeight:uint = songItem.height;
			var startY:uint = itemHeight;
			var count:uint = 0;
			for (var i:uint = 0; i < list.length && startY + songItem.height < stage.stageHeight; i++) {
				songItem = new SongListItem(list[i]);
				songItem.addEventListener(MouseEvent.CLICK, _onClick);
				_container.addChild(songItem);
				_items.push(songItem);
				songItem.setSize(stage.stageWidth);
				songItem.y = startY ;
				startY += songItem.height;
				count++;
			}
			_endIndex = _startIndex+count;
			
			
			if (_endIndex < _songManager.getTotal() -1) {
				_container.addChild(_rightArrow);
				_rightArrow.x = stage.stageWidth-_rightArrow.width - PADDING;
				_rightArrow.y = stage.stageHeight-_rightArrow.height - PADDING;
			}
			
			if (_startIndex > 0) {
				_container.addChild(_leftArrow);
				_leftArrow.x = stage.stageWidth-_leftArrow.width - _leftArrow.width - PADDING*2;
				_leftArrow.y = stage.stageHeight-_leftArrow.height - PADDING;
			}
		}
		
		private function _destroyAllItems():void {
			if (_container.contains(_leftArrow)) {
				_container.removeChild(_leftArrow);
			}
			if (_container.contains(_rightArrow)) {
				_container.removeChild(_rightArrow);
			}
			
			for (var i:uint = 0; i < _items.length; i++) {
				_items[i].removeEventListener(MouseEvent.CLICK, _onClick);
				_container.removeChild(_items[i]);
				_items[i].unbind();
				_items[i] = null;
			}
			_items = new Array();
		}
		
		public function setSize(w:uint, h:uint):void {
			_showList(_startIndex);
			
			_rightArrow.x = stage.stageWidth-_rightArrow.width - PADDING;
			_rightArrow.y = stage.stageHeight-_rightArrow.height - PADDING;
			_leftArrow.x = stage.stageWidth-_leftArrow.width - _leftArrow.width - PADDING*2;
			_leftArrow.y = stage.stageHeight-_leftArrow.height - PADDING;
		}
		
		public function getSelectedSong():Song {
			return _selectedSong;
		}
		
		private function _onClick(e:MouseEvent):void {
			_selectedSong = e.target.song;
			dispatchEvent(new Event(PLAY_SONG));
		}
		
		private function _onNavigate(e:MouseEvent):void {
			var pageCount:uint = _endIndex - _startIndex;
			switch (e.target) {
				case _leftArrow:
					var startIndex:int = _startIndex-pageCount-1;
					if (startIndex < 0) {
						startIndex = 0;
					}
					_showList(startIndex);
					break;
				case _rightArrow:
					_showList(_endIndex+1);
					break;
			}
		}
		
		public function refreshList():void {			
			// show song list			
			_showList();
		}
		
		public function collapse():void {
			// hide
			_container.visible = false;
		}
		
		public function toggle():void {
			_container.visible = !_container.visible;
		}

	}
	
}
