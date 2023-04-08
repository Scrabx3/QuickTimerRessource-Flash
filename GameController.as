import gfx.io.GameDelegate;
import gfx.utils.Delegate;
import gfx.ui.NavigationCode;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;

import com.greensock.*;
import com.greensock.easing.*;

import progressbar;
import Playground;
import JSON;

class GameController extends MovieClip
{
	/* STAGE */
	public var background: MovieClip;
	public var playground: Playground;
	public var progressbar: ProgressBar;

	/* GAME VARS */
	private var _difficulty: Number;
	private var _gameActive: Boolean;
	private var _requiredEvents: Number;

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
		_difficulty = a_difficulty;
		_gameActive = true;
		_requiredEvents = 7 + Math.floor(a_difficulty / 15)

		playground.setup(a_difficulty, a_gamepad);
		makeTimeout();
	}

	/* INIT */
	public function GameController()
	{
		_global.gfxExtensions = true;
		_health = 100.0;
	}

	public function onLoad():Void
	{
		var minXY:Object = {x:Stage.visibleRect.x + Stage.safeRect.x, y:Stage.visibleRect.y + Stage.safeRect.y};
		this.globalToLocal(minXY);

		background._width = Stage.visibleRect.width;
		background._height = Stage.visibleRect.height;
		background._x = minXY.x;
		background._y = minXY.y;

		// trace("x = " + background._y + " / y = " + background._x + " / width = " + background._width + " / height = " + background._height);

		playground.addEventListener("qteResult", this, "onqteResult");

		// setTimeout(Delegate.create(this, testGame), 5000)
	}

	private function testGame()
	{
		Key.addListener(this);
		beginGame(70);
	}

	/* GFX */
	public function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		if (GlobalFunc.IsKeyPressed(details)) {
			switch (details.navEquivalent) {
			case NavigationCode.ESCAPE:
			case NavigationCode.TAB:
			case NavigationCode.BACK:
			case NavigationCode.END:
				cancelGame(false);
				return true;
			default:
				if (playground.handleInput(details, pathToFocus)) {
					return true;
				}
			}
		}

		var nextClip = pathToFocus.shift();
		return nextClip.handleInput(details, pathToFocus);
	}
	
	public function onKeyDown(): Void 
	{
		var key = Key.getCode();
		// type: String, code: Number, value, navEquivalent: String, controllerIdx: Number
		switch (key) {
		case 65:
			{
				var details = new InputDetails("key", 30, "keyDown", NavigationCode.UP, 0);
				handleInput(details);
			}
			break;
		case 83:
			{
				var details = new InputDetails("key", 31, "keyDown", NavigationCode.DOWN, 0);
				handleInput(details);
			}
			break;
		case 68:
			{
				var details = new InputDetails("key", 32, "keyDown", NavigationCode.LEFT, 0);
				handleInput(details);
			}
			break;
		case 87:
			{
				var details = new InputDetails("key", 17, "keyDown", NavigationCode.RIGHT, 0);
				handleInput(details);
			}
			break;
		case Key.TAB:
			{
				var details = new InputDetails("key", key, "keyDown", NavigationCode.TAB, 0);
				handleInput(details);
			}
			break;
		}
	}

	/* PRIVATE */
	private function makeTimeout()
	{
		var delay = (Math.pow(16, Math.random() - 1.3) + 0.5) * 1000;
		setTimeout(Delegate.create(this, createEvent), delay);
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
			Math.pow(_difficulty, 2) * 0.002 :
			-(Math.pow(0.99, _difficulty) * 100 - 5);

		// trace("changeHealth = " + changeHealth + " // health = " + health);
		health += changeHealth;

		// trace("onqteResult; evt.eventCount = " + evt.eventCount);
		if (health == 0) {
			cancelGame(false);
		} else if (evt.eventCount > _requiredEvents) {
			cancelGame(true);
		}
	}

	private function cancelGame(victory)
	{
		_gameActive = false;
		playground.cancelActiveGames();

		if (!victory && health > 0) {
			health = 0;
		}
		TweenLite.to(this, 0.5, {_alpha: 0, ease: Strong.easeOut, onComplete: closeMenu, onCompleteParams: [victory]});
	}

	private function closeMenu()
	{
		skse.CloseMenu("AcheronCustomMenu");
		skse.SendModEvent("AEL_GameEnd", "", 0.0);
	}

}