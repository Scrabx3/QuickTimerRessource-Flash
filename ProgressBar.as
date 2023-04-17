import com.greensock.TimelineLite;
import com.greensock.easing.*;

class ProgressBar extends MovieClip
{
	/* STAGE */
	public var mask: MovieClip;

	/* VARIABLES */
	private var MeterTimeline:TimelineLite;
	private var _1pct:Number;

	/* INIT */
	public function ProgressBar()
	{
		super();

		MeterTimeline = new TimelineLite({paused:true});
	}

	public function setPosition()
	{
		this._width = Stage.visibleRect.width + 2;
		this._y = (Stage.visibleRect.y + Stage.visibleRect.height) - this._height + 2;
		this._x = Stage.visibleRect.x;

		_1pct = mask._width / 100;
		// trace("ProgessBar: Y = " + this._y + " | X = " + this._x + " | Width = " + this._width + " | Height = " + this._height);
	}

	/* API */
	public function forceMeterPercent(a_targetpct:Number):Void
	{
		MeterTimeline.clear();
		a_targetpct = Math.min(100, Math.max(a_targetpct, 0));
		mask._width = _1pct * a_targetpct;
	}

	public function setMeterPercent(a_targetpct:Number):Void
	{
		a_targetpct = Math.min(100, Math.max(a_targetpct, 0));

		if (!MeterTimeline.isActive()) {
			MeterTimeline.clear();
			MeterTimeline.progress(0);
			MeterTimeline.restart();
		}
		MeterTimeline.to(mask, 1.3, {_width: _1pct * a_targetpct, ease: Quint.easeOut }, MeterTimeline.time());
		MeterTimeline.play();
	}

}