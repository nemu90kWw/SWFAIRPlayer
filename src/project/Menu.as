package project 
{
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FullScreenEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Keyboard;
	import project.MenuEvent;

	public class Menu extends EventDispatcher
	{
		private var nativeWindow:NativeWindow;
		
		private var blankMenu:NativeMenu = new NativeMenu();
		private var playerMenu:NativeMenu = new NativeMenu();
		
		private var blankFileMenu:NativeMenu = new NativeMenu();
		private var playerFileMenu:NativeMenu = new NativeMenu();
		private var displayMenu:NativeMenu = new NativeMenu();
		private var debugMenu:NativeMenu = new NativeMenu();
		private var speedMenu:NativeMenu = new NativeMenu();
		private var helpMenu:NativeMenu = new NativeMenu();
		
		private var scaleChangeMenuItems:Vector.<NativeMenuItem> = new Vector.<NativeMenuItem>;
		private var fullScreenItem:NativeMenuItem;
		private var antiAliasingItem:NativeMenuItem;
		private var legacyZoomItem:NativeMenuItem;
		private var redrawRegionItem:NativeMenuItem;
		private var outsiderItem:NativeMenuItem;
		private var transparentItem:NativeMenuItem;
		
		public var bounds:Rectangle;
		
		public function get antiAliasing():Boolean {
			return antiAliasingItem.checked;
		}
		
		public function set antiAliasing(value:Boolean):void
		{
			antiAliasingItem.checked = value;
			dispatchEvent(new MenuEvent(MenuEvent.RENDERING_STATE_CHANGE, false, false, antiAliasingItem));
		}
		
		public function get legacyZoom():Boolean {
			return legacyZoomItem.checked;
		}
		
		public function set legacyZoom(value:Boolean):void
		{
			legacyZoomItem.checked = value;
			dispatchEvent(new MenuEvent(MenuEvent.RENDERING_STATE_CHANGE, false, false, legacyZoomItem));
		}
		
		public function get redrawRegions():Boolean {
			return redrawRegionItem.checked;
		}
		
		public function set redrawRegions(value:Boolean):void
		{
			redrawRegionItem.checked = value;
			dispatchEvent(new MenuEvent(MenuEvent.RENDERING_STATE_CHANGE, false, false, redrawRegionItem));
		}
		
		public function get outsiderMode():Boolean {
			return outsiderItem.checked;
		}
		
		public function set outsiderMode(value:Boolean):void
		{
			outsiderItem.checked = value;
			dispatchEvent(new MenuEvent(MenuEvent.RENDERING_STATE_CHANGE, false, false, outsiderItem));
		}
		
		public function get transparent():Boolean {
			return transparentItem.checked;
		}
		
		public function set transparent(value:Boolean):void
		{
			transparentItem.checked = value;
			dispatchEvent(new MenuEvent(MenuEvent.RENDERING_STATE_CHANGE, false, false, transparentItem));
		}
		
		private function createMenuItem(label:String, mnemonic:String = ""):NativeMenuItem
		{
			var item:NativeMenuItem = new NativeMenuItem(label);
			
			if (mnemonic != "")
			{
				item.label += "(" + mnemonic + ")";
				item.mnemonicIndex = item.label.length - 2;
			}
			
			return item;
		}
		
		private function createSeparator():NativeMenuItem
		{
			return new NativeMenuItem("", true);
		}
		
		private function addSubMenu(menu:NativeMenu, submenu:NativeMenu, label:String, mnemonic:String = ""):NativeMenuItem
		{
			var item:NativeMenuItem = menu.addSubmenu(submenu, label);
			
			if (mnemonic != "")
			{
				item.label += "(" + mnemonic + ")";
				item.mnemonicIndex = item.label.length - 2;
			}
			
			return item;
		}
		
		public function Menu(nativeWindow:NativeWindow, root:Sprite)
		{
			this.nativeWindow = nativeWindow;
			
			// ファイル
			blankFileMenu.addItem(createMenuItem("開く", "O")).addEventListener(Event.SELECT, openFile);
			var exit:Function = function(e:Event):void {
				NativeApplication.nativeApplication.exit();
			};
			blankFileMenu.addItem(createMenuItem("終了", "X")).addEventListener(Event.SELECT, exit);
			playerFileMenu.addItem(createMenuItem("終了", "X")).addEventListener(Event.SELECT, exit);
			
			// 表示
			for (var i:int = 1; i <= 5; i++ )
			{
				var item:NativeMenuItem = displayMenu.addItem(createMenuItem(i + "00%"));
				item.data = i;
				item.addEventListener(Event.SELECT, function(e:Event):void {
					dispatchEvent(new MenuEvent(MenuEvent.CHANGE_SCALE, e.bubbles, e.cancelable, e.target as NativeMenuItem));
				});
				scaleChangeMenuItems.push(item);
			}
			displayMenu.addItem(createSeparator());
			fullScreenItem = displayMenu.addItem(createMenuItem("フルスクリーン", "S"))
			displayMenu.addItem(createSeparator());
			antiAliasingItem = displayMenu.addItem(createMenuItem("アンチエイリアス", "A"));
			legacyZoomItem = displayMenu.addItem(createMenuItem("レガシーズーム", "L"));
			displayMenu.addItem(createSeparator());
			displayMenu.addSubmenu(debugMenu, "デバッグ");
			
			redrawRegionItem = debugMenu.addItem(createMenuItem("再描画領域を表示"));
			outsiderItem = debugMenu.addItem(createMenuItem("カメラ範囲外の状態を確認"));
			transparentItem = debugMenu.addItem(createMenuItem("シェイプ透過"));
			
			fullScreenItem.keyEquivalent = "\renter";
			fullScreenItem.keyEquivalentModifiers = [Keyboard.ALTERNATE];
			
			fullScreenItem.addEventListener(Event.SELECT, toggleFullScreen);
			antiAliasingItem.addEventListener(Event.SELECT, function():void { antiAliasing = !antiAliasing; });
			legacyZoomItem.addEventListener(Event.SELECT, function():void { legacyZoom = !legacyZoom; });
			redrawRegionItem.addEventListener(Event.SELECT, function():void { redrawRegions = !redrawRegions; });
			outsiderItem.addEventListener(Event.SELECT, function():void { outsiderMode = !outsiderMode; });
			transparentItem.addEventListener(Event.SELECT, function():void { transparent = !transparent; });
			
			// 倍速モード
			var speedRates:Array = [0.3, 0.5, 0.8, 1.0, 1.5, 2.0, 3.0, 4.0];
			speedRates.forEach(function(num:Number, i:int, array:Array):void
			{
				var item:NativeMenuItem = speedMenu.addItem(createMenuItem("x" + num.toFixed(1)));
				item.name = num.toFixed(1);
			});
			speedMenu.addEventListener(Event.SELECT, changeSpeed);
			speedMenu.getItemByName("1.0").checked = true;
			
			// ヘルプ
			helpMenu.addItem(createMenuItem("GitHubを表示...")).addEventListener(Event.SELECT, function(e:Event):void {
				navigateToURL(new URLRequest("https://github.com/nemu90kWw/SWFAIRPlayer"));
			});
			
			addSubMenu(playerMenu, playerFileMenu, "ファイル", "F");
			addSubMenu(playerMenu, displayMenu, "表示", "V");
			addSubMenu(playerMenu, speedMenu, "倍速モード", "S");
			addSubMenu(playerMenu, helpMenu, "ヘルプ", "H");
			
			addSubMenu(blankMenu, blankFileMenu, "ファイル", "F");
			addSubMenu(blankMenu, displayMenu, "表示", "V");
			addSubMenu(blankMenu, helpMenu, "ヘルプ", "H");
			
			nativeWindow.stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, onResize);
			
			root.contextMenu = displayMenu;
		}
		
		public function setMenuType(type:String):void
		{
			switch(type)
			{
			case MenuType.BLANK:
				nativeWindow.menu = blankMenu;
				break;
			case MenuType.PLAYER:
				nativeWindow.menu = playerMenu;
				break;
			}
		}
		
		private function onFullScreen(e:FullScreenEvent):void 
		{
			fullScreenItem.checked = e.fullScreen;
		}
		
		private function openFile(e:Event):void
		{
			dispatchEvent(new MenuEvent(MenuEvent.OPEN_FILE, false, false, e.target as NativeMenuItem));
		}
		
		private function changeSpeed(e:Event):void
		{
			dispatchEvent(new MenuEvent(MenuEvent.CHANGE_SPEED, false, false, e.target as NativeMenuItem));
			for each(var item:NativeMenuItem in speedMenu.items) {
				item.checked = item.name == (e.target as NativeMenuItem).name;
			}
		}
		
		public function onResize(e:NativeWindowBoundsEvent):void
		{
			if(bounds == null) { return; }
			
			for each(var item:NativeMenuItem in scaleChangeMenuItems) {
				item.checked = nativeWindow.stage.stageWidth / Math.round(bounds.width / nativeWindow.stage.contentsScaleFactor) == int(item.data) && nativeWindow.stage.stageHeight / Math.round(bounds.height / nativeWindow.stage.contentsScaleFactor) == int(item.data);
			}
		}
		
		private function toggleFullScreen(e:Event):void
		{
			if (fullScreenItem.checked == false) {
				nativeWindow.stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, true, true));
			}
			else {
				nativeWindow.stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, false, true));
			}
		}
	}
}