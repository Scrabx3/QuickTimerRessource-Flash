import gfx.managers.FocusHandler;
import gfx.io.GameDelegate;
import gfx.utils.Delegate;
import gfx.ui.NavigationCode;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;

import com.greensock.*;
import com.greensock.easing.*;
import JSON;

class GameController extends MovieClip
{
	public static var CONFIG_PATH: String = "AcheronEL_QTE.json";

	/* SKSE */
	public var sendModEvent: Function;
	public var closeMenu: Function;

	/* STAGE */
	public var bg: MovieClip;
	public var playground: MovieClip;
	public var progressbar: MovieClip;

	/* VARS */
	private var _ready: Boolean;
	private var _dummyMC: MovieClip;

	/* GAME VARS */
	private var _gameActive: Boolean;
	private var _difficulty: Number;

	private var _requiredEvents: Number;
	private var _eventCountAdd: Number;
	private var _reactMult: Number;
	private var _delayMult: Number;

	private var _keyboardKeys: Array;
	private var _gamepadKeys: Array;

	private var _damageMult: Number;
	private var _regenMult: Number;
	private var _health: Number;
	public function set health(a_newhealth: Number)
	{
		_health = Math.max(0, Math.min(100, a_newhealth));
		progressbar.setMeterPercent(_health);
	}
	public function get health()
	{
		return _health;
	}

	/* API */
	public function beginGame(a_difficulty: Number, a_gamepad: Boolean): Void
	{
		trace("begin acheron qte game with difficulty: " + a_difficulty + " | gamepad? " + a_gamepad)
		_difficulty = a_difficulty;
		_gameActive = true;
		_requiredEvents = Math.max(7 + Math.floor(a_difficulty / 15) + _eventCountAdd, 3);

		var keys = a_gamepad ? _gamepadKeys : _keyboardKeys;
		playground.setup(a_difficulty, _reactMult, keys);
		makeTimeout();
	}

	/* INIT */
	public function GameController()
	{
		super();

		_dummyMC = this.createEmptyMovieClip("dummyMC", this.getNextHighestDepth());
		_dummyMC._alpha = 100;
		
		FocusHandler.instance.setFocus(this, 0);

		var lv = new LoadVars();
		lv.onData = function(src: String) {
			var me = this["_this"];
			try {
				// Position Object
				var maxXY:Object = {x:Stage.visibleRect.x + Stage.visibleRect.width - Stage.safeRect.x, y:Stage.visibleRect.y + Stage.visibleRect.height - Stage.safeRect.y};
				var clamp = function(x, min, max) {
					return Math.min(max, Math.max(x, min));
				}

				var o: Object = JSON.parse(src);
				var coords = o.Coordinates;
				var ratioX = clamp(coords.SpanX ? coords.SpanX : 0.10, 0.05, 0.45);
				var ratioY = clamp(coords.SpanY ? coords.SpanY : 0.15, 0.05, 0.45);
				var offset = {
					x: maxXY.x * ratioX,
					y: maxXY.y * ratioY
				}
				me.playground.setPlaygroundSize(offset);

				// Settings
				var settings = o.Multipliers;
				me._damageMult = Math.max(settings.Damage != undefined ? settings.Damage : 0.10, 0.00);
				me._regenMult =	Math.max(settings.Regeneration != undefined ? settings.Regeneration : 0.10, 0.00);
				me._delayMult = clamp(settings.Delay != undefined ? settings.Delay : 0.10, 0.5, 2.0);
				me._reactMult =	clamp(settings.Time != undefined ? settings.Time : 0.10, 0.5, 5);
				me._eventCountAdd =	settings.Events != undefined ? settings.Events : 0;

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

	public function onLoad():Void
	{
		_global.gfxExtensions = true;
		progressbar.setPosition();
		health = 100;

		playground.addEventListener("qteResult", this, "onqteResult");

		// setTimeout(Delegate.create(this, testGame), 5000)
	}

	private function testGame()
	{
		beginGame(100);
	}

	/* GFX */
	public function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		if (details.value != "keyDown") {
			var nextClip = pathToFocus.shift();
			if (nextClip.handleInput(details, pathToFocus))
				return true;

			return false;
		}
		// trace(details.toString());
		if (!_gameActive)
			return false;

		if (GlobalFunc.IsKeyPressed(details) && (details.navEquivalent == NavigationCode.TAB || details.navEquivalent == NavigationCode.SHIFT_TAB)) {
			cancelGame(false)
			return true;
		}

		return playground.handleInput(details, pathToFocus);
	}

	/* PRIVATE */
	private function makeTimeout()
	{
		if (!_ready) {
			setTimeout(Delegate.create(this, makeTimeout), 10);
			return;
		}

		var delay = (Math.pow(16, Math.random() - 1.3) + 0.5) * _delayMult;
		TweenLite.to(_dummyMC, delay, {_alpha: 0, onComplete: makeTimeoutFinish, onCompleteParams: [this]});
		// setTimeout(Delegate.create(this, createEvent), delay * 1000);
		// loopID = setInterval(this, "createEvent", delay * 1000)
	}
	public function makeTimeoutFinish(mc: MovieClip)
	{
		_dummyMC._alpha = 100;
		mc.createEvent()
	}

	private function createEvent()
	{
		if (!_gameActive)
			return;

		playground.create();
		makeTimeout();
	}

	// { type: "qteResult", victory, eventCount }
	private function onqteResult(evt)
	{
		if (!_gameActive)
			return;

		var changeHealth = evt.victory ? 
			(Math.pow(_difficulty, 2) * 0.002) * _regenMult :
			-((Math.pow(0.99, _difficulty) * 100 - 5) * _damageMult);

		// trace("changeHealth = " + changeHealth + " // health = " + health);
		health += changeHealth;

		// trace("onqteResult; evt.eventCount = " + evt.eventCount);
		if (health == 0) {
			cancelGame(false);
		} else if (evt.eventCount > _requiredEvents) {
			cancelGame(true);
		}
	}

	private function cancelGame(victory: Boolean)
	{
		_gameActive = false;
		playground.cancelActiveGames();

		if (!victory && health > 0) {
			health = 0;
		}
		TweenLite.to(this, 0.5, {_alpha: 0, ease: Strong.easeOut, onComplete: gameEnd, onCompleteParams: [victory]});
	}

	public function gameEnd(victory: Boolean)
	{
		trace("AcheronEL QTE: Close Menu; victory: " + victory);
		skse.SendModEvent("AEL_GameEnd", "", victory ? 1.0 : 0.0, 0);
		skse.CloseMenu("AcheronCustomMenu");
	}

}