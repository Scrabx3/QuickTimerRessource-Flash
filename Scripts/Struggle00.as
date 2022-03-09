import gfx.ui.InputDetails;
import gfx.ui.NavigationCode;
import Shared.GlobalFunc;

class Scripts.Struggle00 extends MovieClip {
	var StrugglyKeyboard:MovieClip;// main widget for keyboard QTEs
	var StrugglyRound:MovieClip;// copy of keyboard but for round buttons (gamepad)
	var KeyInputs:MovieClip;// <- Stores all the Key Icons
	var RoundInputs:MovieClip;// equivalent of KeyInputs but on StrugglyRound

	private var potentialkeys:Array;// array of keys that can be displayed
	private var difficulty:Number;// difficulty modifier
	private var hits:Number;// number of hits for the game to end

	private var _minX:Number;
	private var _maxX:Number;
	private var _minY:Number;
	private var _maxY:Number;

	private var targetkey:Number;
	private var _loopID:Number;
	private var _player:Number;

	public function Struggle00() {
		super();

		this.KeyInputs = this.StrugglyKeyboard.KeyInputs;
		this.RoundInputs = this.StrugglyRound.KeyInputs;

		KeyInputs.gotoAndStop(16);
		RoundInputs.gotoAndStop(276);


		this.StrugglyKeyboard._visible = false;
		this.StrugglyRound._visible = false;
		this._visible = false;

		// in flash testing
		_loopID = setInterval(this, "Test", 1000);
	}

	/**
	 * Testing
	 */
	private function Test():Void {
		clearInterval(_loopID);

		Key.addListener(this);
		
		startgame(100, 0.3, [30]);
	}

	private function onKeyDown():Void {
		KeyInput(30);
	}

	/**
	 * SKSE Functions
	 */
	public function startgame(difficulty:Number, offset:Number, potentialkeys:Array):Void {
		this.difficulty = difficulty;
		this.potentialkeys = potentialkeys;
		this.hits = (difficulty % 7) + 1
		if (difficulty < 200 && this.hits < 3)
			this.hits += 2;
		trace("Required Hits = " + this.hits);
		trace("Potential Keys = " + potentialkeys);
		_minX = 1920 * offset;
		_minY = 1080 * offset;
		_maxX = 1920 - _minX;
		_maxY = 1080 - _minY;
		trace("minX = " + _minX + " ;; maxX = " + _maxX);
		trace("minY = " + _minY + " ;; maxY = " + _maxY);

		_loopID = setInterval(this, "NewKey", delay());
		_visible = true;
	}

	public function KeyInput(keyID:Number):Void {
		clearInterval(_player);
		if (keyID == targetkey) {
			// FlashGreen();
			trace("Remaining hits = " + (hits - 1));
			if (--hits == 0) {
				WinGame();
			} else {
				_loopID = setInterval(this, "NewKey", delay());
			}
		} else {
			FailGame();
		}
	}

	private function delay():Number {
		// next button randomly displayed between 100 and 1200 ms
		return Math.random() * 1100 + 200;
	}

	/**
	 * Main Loop
	 */
	var timing:Number;
	var _ticktock;

	private function NewKey():Void {
		clearInterval(_loopID);
		var newkey = Math.floor(Math.random() * potentialkeys.length);
		targetkey = potentialkeys[newkey];
		var qte;
		if (targetkey > 275 && targetkey <= 279)
			qte = StrugglyRound;
		else
			qte = StrugglyKeyboard;
		qte.KeyInputs.gotoAndStop(targetkey);
		// reset the qte object
		setposition();
		qte.mask.gotoAndStop(1);
		qte.gotoAndStop(1);
		qte._visible = true;
		qte._alpha = 100;
		// create new timings
		var window = createinputwindow() / 30; // divide total window into the 30 frames
		var time = window > 1 ? window : 1;

		timing = 0;
		_player = setInterval(this, "Player", time, qte);
		_ticktock = setInterval(this, "TickTime", 1);
	}

	private function TickTime():Void
	{
		timing++;
	}

	/**
	 * Player
	 */
	private function Player(qte:MovieClip):Void
	{
		qte.mask.nextFrame();
		qte.nextFrame();
		if (qte._currentFrame == 30) {
			FailGame();
			clearInterval(_player);
		}
	}

	private function createinputwindow():Number {
		var x = Math.random() * 20 - 10;
		var pentalty = (-5) * Math.pow(x, 2) + difficulty;
		// trace("inputwindow -> x = " + x);
		// trace("inputwindoe -> pentalty = " + pentalty);
		return 700 + pentalty;
	}

	private function setposition():Void {
		var rangeX = _maxX - _minX;
		var rangeY = _maxY - _minY;
		var newX = Math.random() * rangeX + _minX;
		var newY = Math.random() * rangeY + _minY;
		trace("newX = " + newX);
		trace("newY = " + newY);
		_x = newX;
		_y = newY;
	}

	private function FlashGreen():Void {
		// TODO: player feedback for correct input
		if (StrugglyKeyboard._visible) {
			StrugglyKeyboard._visible = false;
		} else {
			StrugglyRound._visible = false;
		}
	}

	private function WinGame():Void {
		// TODO: SKSE callback
	}

	private function FailGame():Void {
		// TODO: SKSE callback
		clearInterval(_ticktock);
		trace("FailGame -> Duration = " + timing);
	}

}