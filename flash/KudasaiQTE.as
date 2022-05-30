import com.greensock.*;
import com.greensock.plugins.*;
// animation logic based on "spinning loading bar"
// -> https://github.com/Osmosis-Wrench/flash-examples

class KudasaiQTE extends MovieClip {
	// UI Elements:
	private var smallQTE:MovieClip;
	private var roundQTE:MovieClip;

	var _minX:Number;
	var _minY:Number;
	var _maxX:Number;
	var _maxY:Number;

	// Animation Vars
	var MeterTimeline:TimelineLite;
	var percent:Number;

	// Game Vars
	private var targetkey:Number;
	private var qtebase:MovieClip;

	private var _active:Boolean;

	// Misc Vars
	private var _testLoopID:Number;
	private var _tweenLoopID:Number;

	// Initialization:
	private function KudasaiQTE() {
		super();
		// constructor code
		_active = false;
		_visible = false;
		_alpha = 0;

		smallQTE._visible = false;
		roundQTE._visible = false;
		smallQTE._alpha = 75;
		roundQTE._alpha = 75;

		MeterTimeline = new TimelineLite({paused:true});
	}

	public function onLoad():Void {
		// _testLoopID = setInterval(this, "Test", 500);
		// Stage.scaleMode = "noScale";

		// var stageObj = new Object();
		// Stage.addListener(stageObj);
		// stageObj.onResize = function()
		// {
		// 	_root.playground._width = Stage.width;
		// 	_root.playground._height = Stage.height;
		// };
		// stageObj.onResize();
	}

	private function Test():Void {
		clearInterval(_testLoopID);
		_minX = 384;
		_minY = 216;
		_maxX = 1536;
		_maxY = 864;
		Key.addListener(this);
		CreateGame(5,30);
		_visible = true;
	}

	public function onKeyDown():Void {
		var ascii = Key.getAscii();
		if (ascii == 97) {
			KeyDown(targetkey);
		} else {
			KeyDown(ascii);
		}
	}

	/**
	 * SKSE
	 */
	// Update the Display Key & move it to the desired Position on Screen, then start the Timer
	public function CreateGame(time:Number, key:Number):Void {
		this.targetkey = key;
		if (key <= 275 || key > 278) {
			qtebase = smallQTE;
		} else {
			qtebase = roundQTE;
		}
		qtebase.input.gotoAndStop(targetkey);
		// Set new Position
		var rangeX = _maxX - _minX;
		var rangeY = _maxY - _minY;
		var newX = Math.random() * rangeX + _minX;
		var newY = Math.random() * rangeY + _minY;
		trace("new X Position = " + newX);
		trace("new Y Position = " + newY);
		// new delay
		var delay = Math.random() * 0.7 + 0.2;
		trace("Delay = " + delay);
		TweenLite.to(this, delay, {_y:newY, _x:newX, onComplete: _root.main.CreateTween, onCompleteParams:[time, this]});
	}

	// Invoked by the .dll on the first Keyboard/Controller Input. Only Invoked once per iteration
	public function KeyDown(keyID:Number):Void {
		if (!_active) {
			return;
		}
		_active = false;
		var result = keyID == targetkey
		trace("Game End -> Result = " + result);
		setMeterPercent(100);
		TweenLite.to(this, 0.2, {_alpha:0, onComplete: _root.main.Callback, onCompleteParams:[result, this]});
	}

	// called by .dll when the game is supposed to end for w/e reason
	public function ShutDown():Void {
		if (!_active) {
			return;
		}
		_active = false;
		_alpha = 0;
	}

	// true for win, false for loss
	// overwritten by the .dll
	public function Callback(victory:Boolean, mc:MovieClip):Void {
		if (victory) {
			trace("Win Game");
		} else {
			trace("Fail Game");
		}
		mc.CreateGame(5,30);
	}

	/**
	 * Animation
	 */
	public function CreateTween(time:Number, mc:MovieClip):Void {
		// clearInterval(_tweenLoopID);
		trace("Create Tween -> Duration = " + time);
		mc.qtebase._visible = true;
		mc._alpha = 100;
		mc._active = true;

		mc.percent = 360 / 100;
		mc.setMeterPercent(0);
		mc.updateMeterPercent(100,time);
	}

	// sets the meter percentage to a specific value, think of it like jumping straight to that value without a tween.
	public function setMeterPercent(DesiredPercent:Number):Void {
		MeterTimeline.clear();
		DesiredPercent = doValueClamp(DesiredPercent);
		qtebase.timer.spinner._rotation = percent * DesiredPercent;
		checkApplyMask();
	}

	// makes the meter tween to a specific value
	public function updateMeterPercent(DesiredPercent:Number, meterDuration:Number):Void {
		DesiredPercent = doValueClamp(DesiredPercent);
		if (!MeterTimeline.isActive()) {
			MeterTimeline.clear();
			MeterTimeline.progress(0);
			MeterTimeline.restart();
		}
		MeterTimeline.to(qtebase.timer.spinner,meterDuration,{_rotation:(percent * DesiredPercent), onUpdate:doUpdate, onUpdateParams:[this], onComplete:doComplete, onCompleteParams:[this], onReverseComplete:doComplete, onReverseCompleteParams:[this], onStart:doStart, onStartParams:[this]});
		MeterTimeline.play();
	}

	public function checkApplyMask():Void {
		if (qtebase.timer.spinner._rotation <= 0) {
			qtebase.timer.spinner_mask._rotation = 0;
			qtebase.timer.spinner_half._alpha = 100;
		} else {
			qtebase.timer.spinner_mask._rotation = 180;
			qtebase.timer.spinner_half._alpha = 0;
		}
	}

	// fires when a TweenLite completes the tween ( both forwards and reverse )
	public function doComplete(mc:MovieClip):Void {
		trace("end");
		mc.KeyDown(-1);
	}

	// fires when a TweenLite starts the tween.
	public function doStart(mc:MovieClip):Void {
		// trace("start");
	}

	// clamp values > 100 at 100 and values <= 0 to 0.01;
	// because of how flash handles angles, we let 0% == 0.01 so that it still appears to be 0 but it doesn't break our mask check.
	public function doValueClamp(clampValue:Number):Number {
		return clampValue > 100 ? 100 : (clampValue <= 0 ? 0.01 : clampValue);
	}

	// fires when a TweenLite makes a new stage in the tween.
	private function doUpdate(mc:MovieClip):Void {
		mc.checkApplyMask();
	}

	/**
	 * Misc
	 */
	private function clamp(x:Number, min:Number, max:Number):Number {
		if (x > max) {
			return max;
		}
		return x < min ? min : x;
	}

}