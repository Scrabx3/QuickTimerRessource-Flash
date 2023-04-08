
import gfx.events.EventDispatcher;
import gfx.io.GameDelegate;
import gfx.utils.Delegate;
import gfx.ui.NavigationCode;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;

import com.greensock.*;
import com.greensock.easing.*;

class Playground extends MovieClip
{
	public static var CONFIG_PATH: String = "AcheronQTE.json";

	/* STAGE */
	public var background: MovieClip;

	/* Properties */
	public var widget: String;					// MovieClip object to place
	public var widgetOffsetX: Number;		// Height (incl offset) of widget
	public var widgetOffsetY: Number;		// Width ...
	public var widgetSize: Number;

	/* Variables */
	private var _useGamepad: Boolean;
	private var _ready: Boolean;
	private var _eventCount: Number;
	private var _activeClips: Array;
	
	public var dispatchEvent: Function;
	public var addEventListener: Function;

	/* GAME RELATED */
	private var _keyboardKeys: Array;
	private var _gamepadKeys: Array;

	private var _difficulty: Number;
	private var _reacttime: Number;

	/* API */
	public function setup(a_difficulty: Number, a_gamepad: Boolean)
	{
		_useGamepad = a_gamepad;
		_difficulty = a_difficulty;
		_reacttime = 0.012 * (a_difficulty + 1);
	}

	public function create(name: String)
	{
		if (!_ready) {
			setTimeout(Delegate.create(this, create), 10);
			return;
		}

		var nextEvent = _parent.attachMovie(widget, widget + _eventCount++, _parent.getNextHighestDepth());
		// size
		nextEvent._height = nextEvent._width = widgetSize * (Math.random() + 0.5);
		// position
		var isOverlapping = function (coordinates): Boolean {

			
			var valueInRange = function(value: Number, min: Number, max: Number): Boolean {
				return (value >= min) && (value <= max);
			}
			var a = {
				x: coordinates.x,
				y: coordinates.y,
				offset: (nextEvent._width / 2)
			};

			for (var i = 0; i < _activeClips.length; i++) {
				var element = _activeClips[i];
				var b = {
					x: element.x,
					y: element.y,
					offset: (element._width / 2)
				};
				if ((valueInRange(a.x, b.x - b.offset, b.x + b.offset) || valueInRange(b.x, a.x - a.offset, a.x + a.offset)) && 
							(valueInRange(a.y, b.y - b.offset, b.y + b.offset) || valueInRange(b.y, a.y - a.offset, a.y + a.offset))) {
					return true;
				}
			}
			return false;
		}
		var coords = new Object();
		var i = 25;	// rng likes to get stuck, spitting out the same numbers forever
		do {
			coords = {
				x: background._width * Math.random(),
				y: background._height * Math.random()
			};
			this.localToGlobal(coords);
		} while (i --> 0 && isOverlapping(coords))
		nextEvent._x = coords.x;
		nextEvent._y = coords.y;
		// time
		var time = Math.max(_reacttime * (Math.random() * 0.8 + 0.7), 0.1);
		// key
		var key = usesGamepad() ?
			_gamepadKeys[Math.floor(Math.random() * _gamepadKeys.length)] :
			_keyboardKeys[Math.floor(Math.random() * _keyboardKeys.length)]
		nextEvent.targetKey = key;
		// send
		nextEvent.initialize(key, time, Delegate.create(this, endEvent));

		_activeClips.push(nextEvent);
		// trace("nextEvent.x = " + nextEvent._x +  " / y = " + nextEvent._y + " / size = " + nextEvent._height + " / time = " + time + " / key = " + key);
	}

	public function cancelActiveGames()
	{
		for (var i = 0; i < _activeClips.length; i++) {
			var element = _activeClips[i];
			element.forceMeterPercent(0);
			TweenLite.to(element, 0.4, { _alpha: 0, onComplete: onEventFadedOut, onCompleteParams: [element], ease: Linear.ease });
		}
		_activeClips = [];
	}

	/* INIT */
	public function Playground()
	{
		super();

		EventDispatcher.initialize(this)

		_activeClips = [];
		_eventCount = 0;
		_ready = false;
		setup(70);
		
		var lv = new LoadVars();
		lv.onData = function(src: String) {
			var me = this["_this"];
			try {
				// Position Object
				var maxXY:Object = {x:Stage.visibleRect.x + Stage.visibleRect.width - Stage.safeRect.x, y:Stage.visibleRect.y + Stage.visibleRect.height - Stage.safeRect.y};
				var clamp = function(x) {
					return Math.min(0.50, Math.max(x, 0.05));
				}

				var o: Object = JSON.parse(src);
				var coords = o.Coordinates;
				var ratioX = clamp(coords.SpanX ? coords.SpanX : 0.10, 0.05);
				var ratioY = clamp(coords.SpanY ? coords.SpanY : 0.15, 0.05);
				
				var offset = {
					x: maxXY.x * ratioX,
					y: maxXY.y * ratioY
				}
				me._parent.globalToLocal(offset);
				me._x = offset.x;
				me._y = offset.y;
				me._width = Stage.visibleRect.width - 2 * offset.x;
				me._height = Stage.visibleRect.height - 2 * offset.y;
				// trace("_x: " + me._x + " / _y: " + me._y + " / _width: " + me._width + " / _height: " + me._height);

				// Key Codes
				var controls = o.Controls;
				me._keyboardKeys = controls && controls.Keyboard ? controls.Keyboard : [17, 30, 31, 32];
				me._gamepadKeys = controls && controls.Gamepad ? controls.Gamepad : [276, 177, 278, 279];
			} catch(ex) {
				trace(ex.name + ":" + ex.message + ":" + ex.at + ":" + ex.text);
			}

			me._ready = true;
		};
		lv._this = this;
		lv.load(CONFIG_PATH);
	}

	/* GFX */
	public function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		endEvent(_activeClips[0], _activeClips[0].targetKey == details.code);

		return true;
	}

	/* PRIVATE */
	public function endEvent(event, victory: Boolean)
	{
		trace("endEvent; victory = " + victory);
		for (var i = 0; i < _activeClips.length; i++) {
			if (_activeClips[i] != event)
				continue;
			_activeClips.splice(i, 1)

			dispatchEvent({ type: "qteResult", victory: victory, eventCount: _eventCount - _activeClips.length });

			event.forceMeterPercent(0);
			var c = new Color(event);
			if (!victory) {
				c.setRGB(0x80151E);
				TweenLite.to(event, 0.6, { _y: event._y + 30, ease: SlowMo.ease });
			} else {
				c.setRGB(0x00D241);
			}
			TweenLite.to(event, 0.4, { _alpha: 0, onComplete: onEventFadedOut, onCompleteParams: [event], ease: Linear.ease });
			break;
		}
	}

	private function onEventFadedOut(event: Object)
	{
		event.removeMovieClip()
	}

	public function usesGamepad(): Boolean
	{
		return _useGamepad;
	}
}