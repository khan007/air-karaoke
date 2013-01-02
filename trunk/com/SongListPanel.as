package com {
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.DataEvent;
	import flash.events.Event;
	import com.Song;
	
	public class SongListPanel extends Sprite {
		
		public static const START_SONG:String = "StartSong";
		public static const PLAYLIST:String = "Playlist";
		public static const SONG_LIST:String = "SongList";
		private static const PADDING:uint = 5;
		private var _container:Sprite;
		private var _items:Array = new Array();
		private var _selectedSong:Song;
		private var _leftArrow:LeftArrow;
		private var _rightArrow:RightArrow;
		private var _searchPanel:Search;
		private var _songManager:SongManager;
		private var _pageCount:uint;
		private var _offset:int;
		private var _currentList:String = SONG_LIST;
		
		public function SongListPanel(songManager:SongManager) {
			// constructor code
			_songManager = songManager;
			
			_container = new Sprite();
			this.addChild(_container);
			
			_leftArrow = new LeftArrow();
			_rightArrow = new RightArrow();
			_searchPanel = new Search();
			_container.addChild(_searchPanel);
			
			_leftArrow.addEventListener(MouseEvent.CLICK, _onNavigate);
			_rightArrow.addEventListener(MouseEvent.CLICK, _onNavigate);
			_searchPanel.search_txt.addEventListener(Event.CHANGE, _onSearch);
			
			_offset = 0;
		}
		
		private function _showList(list:Array):void {
			_destroyAllItems();
			
			// add heading
			var songItem:SongListItem = new SongListItem("Songs", SongListItem.HEADING);
			songItem.setSize(stage.stageWidth);
			_container.addChild(songItem);
			_items.push(songItem);
			
			// add songs
			var itemHeight:uint = songItem.height;
			_pageCount = Math.floor(stage.stageHeight/itemHeight) - 2;
			var startY:uint = itemHeight;
			for (var i:uint = 0; i < _pageCount && i < list.length; i++) {
				songItem = new SongListItem(list[i]);
				songItem.addEventListener(MouseEvent.CLICK, _onClick);
				_container.addChild(songItem);
				_items.push(songItem);
				songItem.setSize(stage.stageWidth);
				songItem.y = startY ;
				startY += songItem.height;
			}
			
			// get total
			var totalInList:uint;
			switch (_currentList) {
				case SONG_LIST:
					totalInList = _songManager.getSongTotal();
					break;
				case PLAYLIST:
					totalInList = _songManager.getPlaylistTotal();
					break;
			}
			
			if (_offset + _pageCount < totalInList) {
				_container.addChild(_rightArrow);
				_rightArrow.x = stage.stageWidth-_rightArrow.width - PADDING;
				_rightArrow.y = stage.stageHeight-_rightArrow.height - PADDING;
			}
			
			if (_offset > 0) {
				_container.addChild(_leftArrow);
				_leftArrow.x = stage.stageWidth-_leftArrow.width - _leftArrow.width - PADDING*2;
				_leftArrow.y = stage.stageHeight-_leftArrow.height - PADDING;
			}
			
			_searchPanel.x = PADDING;
			_searchPanel.y = stage.stageHeight-_searchPanel.height-PADDING;
			_container.setChildIndex(_searchPanel, _container.numChildren-1);
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
			_showList(_getCurrentList(_offset));
			
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
			_songManager.addToPlaylist(_selectedSong);
			dispatchEvent(new Event(START_SONG));
		}
		
		private function _onSearch(e:Event):void {
			_songManager.findSong(e.target.text);
			_offset = 0;
			_currentList = SONG_LIST;
			var list:Array = _songManager.getSongList(0);
			_showList(list);
		}
		
		private function _onNavigate(e:MouseEvent):void {
			switch (e.target) {
				case _leftArrow:
					_offset -= _pageCount;
					if (_offset < 0) {
						_offset = 0;
					}
					_showList(_getCurrentList(_offset));
					break;
				case _rightArrow:
					_offset += _pageCount;
					_showList(_getCurrentList(_offset));
					break;
			}
		}
		
		public function refreshList():void {			
			// show song list
			_showList(_getCurrentList(_offset));
		}
		
		private function _getCurrentList(_offset:uint = 0):Array {
			switch (_currentList) {
				case PLAYLIST:
					return _songManager.getPlaylist(_offset);
					break;
				case SONG_LIST:
				default:
					return _songManager.getSongList(_offset);
					break;
			}
		}
		
		public function hide():void {
			// hide
			_container.visible = false;
		}
		
		public function show(type:String = null):void {
			if (type != null) {
				_currentList = type;
			}
			_container.visible = true;
			switch (_currentList) {
				case PLAYLIST:
					_offset = 0;
					_showList(_songManager.getPlaylist(0));
					_currentList = PLAYLIST;
					break;
				case SONG_LIST:
				default:
					_showList(_songManager.getSongList(_offset));
					_currentList = SONG_LIST;
					break;
			}
		}

	}
	
}
