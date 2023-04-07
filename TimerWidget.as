import com.greensock.*;
import com.greensock.easing.*;

import gfx.ui.InputDetails;
import gfx.ui.NavigationCode;

// based on https://github.com/Osmosis-Wrench/flash-examples/blob/main/spinning_loading_bar
class TimerWidget extends MovieClip
{	
	/* STAGE */
	public var mask: MovieClip;
	public var button: MovieClip;
	
	public var spinner: MovieClip;
	public var spinner_mask: MovieClip;
	public var spinner_half: MovieClip;

	/* VARIABLE */
	private var MeterTimeline: TimelineLite;
	private var onResult: Function;

	/* INIT */
	public function TimerWidget()
	{
		super();

		spinner = mask.spinner;
		spinner_mask = mask.spinner_mask;
		spinner_half = mask.spinner_half;

		MeterTimeline = new TimelineLite({paused:true});
	}

	/* API */
	public function initialize(a_keyid: Number, a_time: Number, a_onResult: Function)
	{
		button.gotoAndStop(a_keyid);

		forceMeterPercent(0);
		setMeterPercent(a_time, 100, true);

		onResult = a_onResult;
	}

	public function forceMeterPercent(targetPct: Number): Void
	{
		MeterTimeline.clear();
		targetPct = doValueClamp(targetPct);
		spinner._rotation = 3.6 * targetPct;
		checkApplyMask();
	}

	public function setMeterPercent(duration: Number, targetPct: Number, reverse: Boolean):Void
	{
		targetPct = doValueClamp(targetPct);
		if (!MeterTimeline.isActive())
		{
			MeterTimeline.clear();
			MeterTimeline.progress(0);
			MeterTimeline.restart();
		}
		MeterTimeline.to(spinner,duration,{_rotation:(3.6 * targetPct),onUpdate:doUpdate, onUpdateParams:[this], onComplete:doComplete, onCompleteParams:[this], onReverseComplete:doComplete, onReverseCompleteParams:[this], onStart:doStart, onStartParams:[this], ease:Linear.easeNone, reversed: reverse})
		MeterTimeline.play();
	}

	public function stopMeter() { MeterTimeline.stop(); }
	public function resumeMeter() { MeterTimeline.resume(); }
	
	/* PRIVATE */

	private function checkApplyMask(): Void
	{
		if (spinner._rotation <= 0){
			spinner_mask._rotation = 0;
			spinner_half._alpha = 100;
		} else {
			spinner_mask._rotation = 180;
			spinner_half._alpha = 0;
		}
	}
	
	// clamp values > 100 at 100 and values <= 0 to 0.01;
	// because of how flash handles angles, we let 0% == 0.01 so that it still appears to be 0 but it doesn't break our mask check.
	private function doValueClamp(clampValue:Number):Number
	{
		return clampValue > 100 ? 100 : (clampValue <= 0 ? 0.01 : clampValue);
	}
	
	// fires when a TweenLite makes a new stage in the tween.
	private function doUpdate(mc: MovieClip): Void
	{
		mc.checkApplyMask();
	}
	
	// fires when a TweenLite completes the tween ( both forwards and reverse )
	private function doComplete(mc: MovieClip): Void
	{
		// trace("end");
		mc.onResult(mc, false);
	}
	
	// fires when a TweenLite starts the tween.
	private function doStart(mc: MovieClip): Void
	{
		// trace("start");
	}
}