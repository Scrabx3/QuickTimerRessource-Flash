import com.greensock.*;
import com.greensock.plugins.*;
// animation logic based on "spinning loading bar"
// -> https://github.com/Osmosis-Wrench/flash-examples

class KudasaiQTE extends MovieClip {

	// Constants:
	public static var CLASS_REF = KudasaiQTE;
	public static var LINKAGE_ID:String = "KudasaiQTE";

	// UI Elements:
	private var smallQTE:MovieClip;
	private var roundQTE:MovieClip;

	private var _minX:Number;
	private var _minY:Number;
	private var _maxX:Number;
	private var _maxY:Number;

	// Animation Vars
	var timer:MovieClip;
	var spinner:MovieClip;
	var spinner_mask:MovieClip;
	var spinner_half:MovieClip;

	var MeterTimeline:TimelineLite;
	var percent:Number;

	// Game Vars
	private var targetkey:Number;
	private var qtebase:MovieClip;

	// Misc Vars
	private var _loopID:Number;

	// Initialization:
	private function KudasaiQTE() {
		super();
		// constructor code
		smallQTE._visible = false;
		roundQTE._visible = false;
		_visible = false;

		MeterTimeline = new TimelineLite({paused:true});
	}

	private function onLoad():Void {
		//_loopID = setInterval(this, "Test", 1500);
	}

	private function Test():Void {
		clearInterval(_loopID);
		Prepare(0.3);
		Key.addListener(this);
		CreateGame(10,276);
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
	// Prepare the Widget to display Keys
	public function Prepare(offset:Number) {
		_minX = 1920 * offset;
		_minY = 1080 * offset;
		_maxX = 1920 - _minX;
		_maxY = 1080 - _minY;

		_visible = true;
	}

	// Create a new QTE with the given key & time
	public function CreateGame(time:Number, key:Number):Void {
		this.targetkey = key;
		if (key <= 275 || key > 278) {
			qtebase = smallQTE;
		} else {
			qtebase = roundQTE;
		}
		setposition(qtebase);
		qtebase.gotoAndStop(1);
		qtebase.input.gotoAndStop(targetkey);

		timer = qtebase.timer;
		spinner = timer.spinner;
		spinner_mask = timer.spinner_mask;
		spinner_half = timer.spinner_half;

		qtebase._visible = true;
		CreateTween(time);
	}

	public function KeyDown(keyID:Number):Void {
		trace("KeyDown -> " + keyID);
		if (qtebase._currentFrame > 1 || !_visible) {
			return;
		}
		var correct = keyID == targetkey;
		FadeOut();
		Hit(correct);
	}

	/**
	 * Game
	 */
	private function setposition(qte:MovieClip):Void {
		var rangeX = _maxX - _minX;
		var rangeY = _maxY - _minY;
		var newX = Math.random() * rangeX + _minX;
		var newY = Math.random() * rangeY + _minY;
		// trace("newX = " + newX);
		// trace("newY = " + newY);
		_x = newX;
		_y = newY;
	}

	// private function createinputwindow():Number {
	// 	var x = Math.random() * 10 - 5;
	// 	var penalty = (-0.01) * Math.pow(x, 2) + (0.7 / difficulty);
	// 	// trace("inputwindow -> x = " + x);
	// 	// trace("inputwindoe -> pentalty = " + pentalty);
	// 	return penalty < 0.2 ? 0.2 : penalty;
	// }

	// true for win, false for loss
	// overwritten by the .dll
	public function Hit(victory:Boolean):Void {
		if (victory) {
			trace("Win Game");
		} else {
			trace("Fail Game");
		}
	}

	public function FailGameConditional():Void {
		if (qtebase._currentFrame > 1) {
			trace("FGC -> Already registered outcome");
			return;
		}
		FadeOut();
		Hit(false);
	}

	private function FadeOut():Void
	{
		qtebase.nextFrame();
	}

	/**
	 * Animation
	 */
	public function CreateTween(duration:Number):Void {
		trace("Create Tween -> Duration = " + duration);
		percent = 360 / 100;
		setMeterPercent(0);
		updateMeterPercent(100,duration);
	}

	// sets the meter percentage to a specific value, think of it like jumping straight to that value without a tween.
	public function setMeterPercent(DesiredPercent:Number):Void {
		MeterTimeline.clear();
		DesiredPercent = doValueClamp(DesiredPercent);
		spinner._rotation = percent * DesiredPercent;
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
		MeterTimeline.to(spinner,meterDuration,{_rotation:(percent * DesiredPercent), onUpdate:doUpdate, onUpdateParams:[this], onComplete:doComplete, onCompleteParams:[this], onReverseComplete:doComplete, onReverseCompleteParams:[this], onStart:doStart, onStartParams:[this]});
		MeterTimeline.play();
	}

	public function checkApplyMask():Void {
		if (spinner._rotation <= 0) {
			spinner_mask._rotation = 0;
			spinner_half._alpha = 100;
		} else {
			spinner_mask._rotation = 180;
			spinner_half._alpha = 0;
		}
	}

	// fires when a TweenLite completes the tween ( both forwards and reverse )
	public function doComplete(mc:MovieClip):Void {
		// trace("end");
		mc.FailGameConditional();
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