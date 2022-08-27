package
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.NativeWindowDisplayState;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.InvokeEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.NativeWindowDisplayStateEvent;
	import flash.filesystem.File;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.profiler.showRedrawRegions;
	import flash.system.LoaderContext;
	import project.Menu;
	import project.MenuEvent;
	import project.MenuType;
	import project.SWFData;
	
	public class Main extends Sprite 
	{
		private var file:File;
		private var swf:SWFData;
		
		private var sprite:Sprite;
		private var bitmap:Bitmap;
		private var buffer:BitmapData;
		private var drawMatrix:Matrix;
		private var drawColor:ColorTransform;
		
		private var menu:Menu;
		private var focusRect:Sprite;
		
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
		}
		
		private function onInvoke(e:InvokeEvent):void
		{
			swf = new SWFData();
			
			focusRect = new Sprite();
			focusRect.graphics.beginFill(0);
			focusRect.graphics.drawRect(0, 0, 1000, 1000);
			focusRect.transform.colorTransform = new ColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
			
			menu = new Menu(stage.nativeWindow, this);
			menu.bounds = swf.frameSize;
			menu.addEventListener(MenuEvent.OPEN_FILE, onOpenFile);
			menu.addEventListener(MenuEvent.CHANGE_SCALE, onChangeScale);
			menu.addEventListener(MenuEvent.CHANGE_SPEED, onChangeSpeed);
			menu.addEventListener(MenuEvent.RENDERING_STATE_CHANGE, onRenderingStateChange);
			menu.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING, onDisplayStateChanging);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			
			buffer = new BitmapData(Screen.mainScreen.bounds.width, Screen.mainScreen.bounds.height, false, 0);
			bitmap = new Bitmap(buffer);
			drawMatrix = new Matrix();
			drawColor = new ColorTransform();
			
			sprite = new Sprite();
			sprite.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			
			addChild(focusRect);
			addChild(bitmap);
			addChild(sprite);
			
			menu.antiAliasing = true;
			menu.legacyZoom = false;
			
			setWindowScale(1);
			
			if(e.arguments.length != 0)
			{
				openSWF(new File(e.arguments[0]));
				return;
			}
			
			var onDragEnter:Function = function(e:NativeDragEvent):void { NativeDragManager.acceptDragDrop(focusRect); };
			
			focusRect.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
			focusRect.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, function(e:NativeDragEvent):void
			{
				if(e.clipboard.formats[0] == ClipboardFormats.FILE_LIST_FORMAT)
				{
					focusRect.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
					focusRect.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, arguments.callee);
					
					openSWF(e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0]);
				}
			});
			
			menu.setMenuType(MenuType.BLANK);
		}
		
		private function onOpenFile(e:Event):void
		{
			var selectFile:File = File.applicationDirectory;
			selectFile.browseForOpen("Open", [new FileFilter("SWFファイル", "*.swf")]);
			selectFile.addEventListener(Event.SELECT, function(e:Event):void
			{
				selectFile.removeEventListener(Event.SELECT, arguments.callee);
				openSWF(selectFile);
			});
		}
		
		private function openSWF(file:File):void
		{
			this.file = file;
			file.addEventListener(Event.COMPLETE, onComplete);
			file.load();
		}
		
		private function onComplete(e:Event):void
		{
			swf.parse(file.data);
			
			stage.frameRate = swf.frameRate;
			var backgroundColor:ColorTransform = new ColorTransform();
			backgroundColor.color = swf.backgroundColor;
			focusRect.transform.colorTransform = backgroundColor;
			
			menu.setMenuType(MenuType.PLAYER);
			setWindowScale(1);
			
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				sprite.addChild(loader);
			});
			
			loaderContext.allowCodeImport = true;
			loader.loadBytes(file.data, loaderContext);
		}
		
		private function onFrameConstructed(e:Event):void
		{
			if (menu.antiAliasing == true && menu.legacyZoom == false) { return; }
			
			buffer.lock();
			buffer.fillRect(buffer.rect, focusRect.transform.colorTransform.color);
			if(menu.antiAliasing == false) {
				buffer.drawWithQuality(sprite, drawMatrix, drawColor, null, null, false, StageQuality.LOW);
			}
			else {
				buffer.drawWithQuality(sprite, drawMatrix, drawColor, null, null, false, StageQuality.BEST);
			}
			buffer.unlock();
		}
		
		private function onRenderingStateChange(e:MenuEvent):void
		{
			fitScreen();
			
			drawColor.alphaMultiplier = menu.transparent ? 0.7 : 1.0;;
			bitmap.visible = !menu.antiAliasing || menu.legacyZoom;
			sprite.alpha = bitmap.visible ? 0 : drawColor.alphaMultiplier;
			
			showRedrawRegions(menu.redrawRegions);
		}
		
		private function onChangeScale(e:MenuEvent):void 
		{
			stage.displayState = StageDisplayState.NORMAL;
			setWindowScale(e.item.data as Number);
		}
		
		private function onChangeSpeed(e:MenuEvent):void 
		{
			stage.frameRate = swf.frameRate * Number(e.item.name);
		}
		
		private function onDisplayStateChanging(e:NativeWindowDisplayStateEvent):void 
		{
			// 最大化の代わりにフルスクリーンにする
			if (e.afterDisplayState == NativeWindowDisplayState.MAXIMIZED)
			{
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				e.preventDefault();
			}
		}
		
		private function get contentWidth():int
		{
			return Math.round(swf.frameSize.width / stage.contentsScaleFactor);
		}
		
		private function get contentHeight():int
		{
			return Math.round(swf.frameSize.height / stage.contentsScaleFactor);
		}
		
		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			stage.nativeWindow.bounds = e.afterBounds;
			fitScreen();
			
			e.preventDefault();
		}
		
		private function onFullScreen(e:FullScreenEvent):void 
		{
			if(e.fullScreen == true) {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			else {
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			fitScreen();
		}
		
		private function setWindowScale(value:Number):void
		{
			stage.stageWidth = contentWidth * value;
			stage.stageHeight = contentHeight * value;
			
			fitScreen();
		}
		
		private function fitScreen():void
		{
			var scale:Number = 1;
			
			if (menu.outsiderMode == false) {
				scale = Math.min(stage.stageWidth / contentWidth, stage.stageHeight / contentHeight);
			}
			
			drawMatrix.identity();
			drawMatrix.tx = (stage.stageWidth * stage.contentsScaleFactor / scale - swf.frameSize.width) / 2;
			drawMatrix.ty = (stage.stageHeight * stage.contentsScaleFactor / scale - swf.frameSize.height) / 2;
			
			if(menu.legacyZoom == true)
			{
				bitmap.scaleX = scale / stage.contentsScaleFactor;
				bitmap.scaleY = scale / stage.contentsScaleFactor;
			}
			else
			{
				if(menu.antiAliasing == false) {
					drawMatrix.scale(scale, scale);
				}
				else {
					drawMatrix.scale(scale / stage.contentsScaleFactor, scale / stage.contentsScaleFactor);
				}
				bitmap.scaleX = 1 / stage.contentsScaleFactor;
				bitmap.scaleY = 1 / stage.contentsScaleFactor;
			}
			
			sprite.scaleX = scale / stage.contentsScaleFactor;
			sprite.scaleY = scale / stage.contentsScaleFactor;
			sprite.x = (stage.stageWidth - contentWidth * scale) / 2;
			sprite.y = (stage.stageHeight - contentHeight * scale) / 2;
			
			focusRect.width = stage.stageWidth;
			focusRect.height = stage.stageHeight;
			
			onFrameConstructed(new Event(Event.FRAME_CONSTRUCTED));
		}
	}
}