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
	/* STAGE */
	public var background: MovieClip;

	/* Properties */
	public var widget: String;	// MovieClip object to place
	public var widgetSize: Number;

	/* Variables */
	public var dispatchEvent: Function;

	private var _eventCount: Number;
	private var _activeClips: Array;

	/* GAME RELATED */
	private var _eventKeys: Array;
	private var _reacttime: Number;

	/* API */
	public function setup(a_difficulty: Number, a_reactmult: Number, a_eventKeys: Array)
	{
		_eventKeys = a_eventKeys;
		_reacttime = (0.019 * (a_difficulty + 1)) * a_reactmult;
	}

	public function create(name: String)
	{
		var nextEvent = _parent.attachMovie(widget, widget + _eventCount++, _parent.getNextHighestDepth());
		// size
		nextEvent._height = nextEvent._width = widgetSize * (Math.random() * 0.5 + 0.7);
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
		var time = Math.max(_reacttime * (Math.random() * 0.7 + 0.8), 0.1);
		// key
		var key = _eventKeys[Math.floor(Math.random() * _eventKeys.length)]
		nextEvent.targetKey = key;
		nextEvent.targetKeyCode = getScaleformCode(key);
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
		setup(70);
	}

	public function setPlaygroundSize(offset)
	{
		// trace("Setting playground with offset: " + offset.x + " / " + offset.y);
		_parent.globalToLocal(offset);
		_x = offset.x;
		_y = offset.y;
		_width = Stage.visibleRect.width - 2 * offset.x;
		_height = Stage.visibleRect.height - 2 * offset.y;
		// trace("_x: " + _x + " / _y: " + _y + " / _width: " + _width + " / _height: " + _height);
	}

	/* GFX */
	public function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		if (details.value != "keyDown")
			return false;

		var codes = _activeClips[0].targetKeyCode;
		var victory = false;
		for (var i = 0; i < codes.length; i++) {
			if (codes[i] == details.code) {
				victory = true;
				break;
			}
		}

		endEvent(_activeClips[0], victory);
		return true;
	}

	/* PRIVATE */
	public function endEvent(event, victory: Boolean)
	{
		// trace("endEvent; victory = " + victory);
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
			// break;
		}
	}

	private function onEventFadedOut(event: Object)
	{
		event.removeMovieClip()
	}

	private function getScaleformCode(key): Array
	{
		var code = [];
		switch(key) {
			case 2: 	//	1
				code = [49];
				break;
			case 3: 	//	2
				code = [50];
				break;
			case 4: 	//	3
				code = [51];
				break;
			case 5: 	//	4
				code = [52];
				break;
			case 6: 	//	5
				code = [53];
				break;
			case 7: 	//	6
				code = [54];
				break;
			case 8: 	//	7
				code = [55];
				break;
			case 9: 	//	8
				code = [56];
				break;
			case 10:	//	9
				code = [57];
				break;
			case 11:  //	0
				code = [48];
				break;
			case 16: 	//	Q
				code = [81];
				break;
			case 19: 	//	R
				code = [82];
				break;
			case 20: 	//	T
				code = [84];
				break;
			case 21: 	//	Y
				code = [89];
				break;
			case 22: 	//	U
				code = [85];
				break;
			case 23: 	//	I
				code = [73];
				break;
			case 24: 	//	O
				code = [79];
				break;
			case 25: 	//	P
				code = [80];
				break;
			case 33: 	//	F
				code = [70];
				break;
			case 34: 	//	G
				code = [71];
				break;
			case 35: 	//	H
				code = [72];
				break;
			case 36: 	//	J
				code = [74];
				break;
			case 37: 	//	K
				code = [75];
				break;
			case 38: 	//	L
				code = [76];
				break;
			case 44: 	//	Z
				code = [90];
				break;
			case 45: 	//	X
				code = [88];
				break;
			case 46: 	//	C
				code = [67];
				break;
			case 47: 	//	V
				code = [86];
				break;
			case 48: 	//	B
				code = [66];
				break;
			case 49: 	//	N
				code = [78];
				break;
			case 50: 	//	M
				code = [77];
				break;
			// Misc
			case 266:	//	DPAD_UP
			case 200:	//	Up Arrow
				code = [38];
				break;
			case 269:	//	DPAD_RIGHT
			case 205:	//	Right Arrow
				code = [39];
				break;
			case 268:	//	DPAD_LEFT
			case 203:	//	Left Arrow
				code = [37];
				break;
			case 267:	//	DPAD_DOWN
			case 208:	//	Down Arrow
				code = [40];
				break;
			// Special Cases
			case 276:	//	A (Controller)
			case 18: 	//	E (Accept)
				code = [13, 69];
				break;
			case 17: 	//	W (Up)
				code = [38, 87];
				break;
			case 32: 	//	D (Right)
				code = [39, 68];
				break;
			case 30: 	//	A (Left)
				code = [37, 65];
				break;
			case 31: 	//	S (Down)
				code = [40, 83];
				break;
			// GamePad (Misc)
			case 272:	//	LEFT_THUMB
				code = [102];
				break;
			case 273:	//	RIGHT_THUMB
				code = [105];
				break;
			case 274:	//	LEFT_SHOULDER
				code = [100]
				break;
			case 275:	//	RIGHT_SHOULDER
				code = [103]
				break;
			case 278:	//	X (Controller)
				code = [98]
				break;
			case 279:	//	Y (Controller)
				code = [99];
				break;
			case 280:	//	LT
				code = [101];
				break;
			case 281:	//	RT
				code = [104]
				break;
			case 277:	//	B (Controller) -- Cancel
			default:
				trace("Invalid SKSE code: " + key);
				return [];
		}
		// trace("Translating SKSE Code: " + key + " to [" + code + "]");
		return code;
	}
}