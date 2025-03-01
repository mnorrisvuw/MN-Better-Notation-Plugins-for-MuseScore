/*
 * Copyright (C) 2024 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.4 or later

import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Muse.UiComponents 1.0
import FileIO 3.0


MuseScore {
	version:  "1.0"
	description: "This plugin checks your score for common music layout, notation and instrumentation issues"
	menuPath: "Plugins.MNCheckLayoutAndInstrumentation";
	requiresScore: true
	title: "MN Check Layout and Instrumentation"
	id: mnchecklayoutandinstrumentation
	thumbnailName: "MNCheckLayoutAndInstrumentation.png"
	
	
	// **** TEXT FILE DEFINITIONS **** //
	FileIO { id: techniquesfile; source: Qt.resolvedUrl("./assets/techniques.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: canbeabbreviatedfile; source: Qt.resolvedUrl("./assets/canbeabbreviated.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: metronomemarkingsfile; source: Qt.resolvedUrl("./assets/metronomemarkings.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: shouldbelowercasefile; source: Qt.resolvedUrl("./assets/shouldbelowercase.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: shouldhavefullstopfile; source: Qt.resolvedUrl("./assets/shouldhavefullstop.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: spellingerrorsanywherefile; source: Qt.resolvedUrl("./assets/spellingerrorsanywhere.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: spellingerrorsatstartfile; source: Qt.resolvedUrl("./assets/spellingerrorsatstart.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: tempomarkingsfile; source: Qt.resolvedUrl("./assets/tempomarkings.txt").toString().slice(8); onError: { console.logError(msg); } }
	FileIO { id: tempochangemarkingsfile; source: Qt.resolvedUrl("./assets/tempochangemarkings.txt").toString().slice(8); onError: { console.logError(msg); } }

	// ** DEBUG **
	property var debug: true
	property var errorMsg: ''
	property var currentZ: 16384
	property var numLogs: 0
	
	// **** PROPERTIES **** //
	property var spatium: 0
	property var pageWidth: 0
	property var pageHeight: 0
	property var checkClefs: false
	property var reads8va: false
	property var readsTreble: false
	property var readsAlto: false
	property var readsTenor: false
	property var readsBass: false
	property var isTrebleClef: false
	property var isAltoClef: false
	property var isTenorClef: false
	property var isBassClef: false
	property var isPercClef: false
	property var clefIs8va: false
	property var clefIs8ba: false
	property var clefIs15ma: false
	property var diatonicPitchOfMiddleLine: 41
	property var initialTempoExists: false
	property var prevKeySigSharps: 0
	property var prevKeySigBarNum: 0
	property var currentBarNum: 0
	property var hasMoreThanOneSystem: false
	// ** COMMMENTS ** //
	property var prevCommentPage: null
	property var commentPosOffset: []
	// ** PARTS ** //
	property var isGrandStaff: []
	property var isTopOfGrandStaff: []
	property var numGrandStaves: []
	property var grandStaffTops: []
	property var numParts: 0
	property var parts: null
	property var scoreHasStrings: false
	property var scoreHasWinds: false
	property var scoreHasBrass: false
	// ** TEXT FILES ** //
	property var techniques: ""
	property var canbeabbreviated: ""
	property var metronomemarkings: ""
	property var shouldbelowercase: ""
	property var shouldhavefullstop: ""
	property var spellingerrorsanywhere: ""
	property var spellingerrorsatstart: ""
	property var tempomarkings: ""
	property var tempochangemarkings: ""
	property var lastTempoChangeMarkingBar: -1
	property var lastTempoChangeMarking: null
	property var currentStaffNum: 0
	property var currentTimeSig: null
	property var prevTimeSig: ""
	property var prevClefId: null
	property var prevDynamic: ""
	property var prevDynamicBarNum: 0
	property var prevIsMultipleStop: false
	property var prevSoundingDur: 0
	property var prevMultipleStopInterval: 0
	property var prevMultipleStop: null
	property var tickHasDynamic: false
	property var theDynamic: null
	property var errorStrings: []
	property var errorObjects: []
	// ** INSTRUMENTS ** //
	property var instrumentIds: []
	property var instrumentNames: []
	property var currentInstrumentName: ""
	property var currentInstrumentId: ""
	property var isWindOrBrassInstrument: false
	property var isStringInstrument: false
	property var isStringSection: false
	property var isFlute: false
	property var isHorn: false
	property var isHarp: false
	property var isCello: false
	property var isPitchedPercussionInstrument: false
	property var isUnpitchedPercussionInstrument: false
	property var isPercussionInstrument: false
	property var isKeyboardInstrument: false
	property var isPedalInstrument: false
	property var isVoice: false
	property var isSoloScore: false
	property var currentMute: ""
	property var currentPlayingTechnique: ""
	property var currentContactPoint: ""
	property var maxLedgerLines: []
	property var minLedgerLines: []
	property var maxLLSinceLastRest: 0
	property var fullInstNamesShowing: false
	property var shortInstNamesShowing: false
	property var firstBarInScore: null
	property var lastBarInScore: null
	property var firstBarInSecondSystem: null
	property var systemStartBars: []
	property var tempoText: []
	// ** DYNAMICS ** //
	property var dynamics: []
	// ** CLEFS ** //
	property var clefs: []
	// ** ARTICULATIONS ** //
	property var articulations: []
	// ** FERMATAS ** //
	property var fermatas: []
	property var fermataLocs: []
	// ** HAIRPINS ** //
	property var hairpins: []
	property var isHairpin: false
	property var currentHairpin: null
	property var currentHairpinEnd: 0
	property var prevWasStartOfSlur: false
	// ** PEDALS ** //
	property var pedals: []
	property var isPedalled: false
	// ** SLURS ** //
	property var slurs:[]
	property var isSlurred: false
	property var flaggedSlurredRest: false
	property var prevSlurNum: 0
	property var currentSlurNum: 0
	// ** OTTAVAS ** //
	property var ottavas: []
	property var isOttava: false
	property var currentOttava: null
	property var flaggedOttavaIssue: false
	// ** TREMOLOS ** //
	property var oneNoteTremolos:[]
	property var twoNoteTremolos:[]
	property var glisses:[]
	property var expectedRehearsalMark: 'A'
	property var expectedRehearsalMarkLength: 1
	property var isDiv: false
	property var isStringHarmonic: false
	property var isSharedStaffArray: []
	property var weKnowWhosPlaying: false
	property var numRehearsalMarks: 0
	property var lastPizzIssueBar: -99
	property var lastPizzIssueStaff: -1
	property var kHarmonicCircle: 2659
	// consts for articulation symbols
	// for the most part (except tenutos), the ‘below’ versions are just +1
	property var kAccentAbove: 597
	property var kAccentStaccatoAbove: 599
	property var kMarcatoAbove: 603
	property var kMarcatoStaccatoAbove: 605
	property var kMarcatoTenutoAbove: 607
	property var kSoftAccentAbove: 609
	property var kSoftAccentStaccatoAbove: 611
	property var kSoftAccentTenutoAbove: 613
	property var kSoftAccentTenutoStaccatoAbove: 615
	property var kStaccatissimoAbove: 617
	property var kStaccatissimoStrokeAbove: 619
	property var kStaccatissimoWedgeAbove: 621
	property var kStaccatoAbove: 623
	property var kStressAbove: 625
	property var kTenutoAbove: 627
	property var kAccentTenutoAbove: 628
	property var kTenutoBelow: 630
	property var prevNote: null
	property var selectionArray: []
	property var isTrem: false
	property var prevWasGraceNote: false
	property var firstDynamic: false
	property var progressShowing: false
	property var progressStartTime: 0
	// ** FLAGS ** //
	property var flaggedWeKnowWhosPlaying: false
	property var flaggedDivError: false
	property var flaggedRehearsalMarkError: false
	property var flaggedLedgerLines: false
	property var flaggedFlippedStem: false
	property var flaggedPedalIssue: false
	property var flaggedNoLyrics: false
	property var flaggedWrittenStaccato: false
	property var flaggedFastMultipleStops: false
	property var flaggedOneStrokeTrem: false
	property var firstVisibleStaff: 0
	property var staffVisible: []
	// ** HARP ** //
	property var pedalSettings: [-1,-1,-1,-1,-1,-1,-1]
	property var pedalChangesInThisBar: 0
	property var flaggedPedalChangesInThisBar: false
	property var cmdKey: 'command'
	// ** VOICE ** //
	property var isMelisma: []
	property var melismaEndTick: []
	
  onRun: {
		if (!curScore) return;
		
		setProgress (0);
		
		// **** DECLARATIONS & DEFAULTS **** //
		var scoreHasTuplets = false;
		
		// **** READ IN TEXT FILES **** //
		techniques = techniquesfile.read().trim().split('\n');
		canbeabbreviated = canbeabbreviatedfile.read().trim().split('\n');
		metronomemarkings = metronomemarkingsfile.read().trim().split('\n');
		shouldbelowercase = shouldbelowercasefile.read().trim().split('\n');
		shouldhavefullstop = shouldhavefullstopfile.read().trim().split('\n');
		spellingerrorsanywhere = spellingerrorsanywherefile.read().trim().split('\n');
		spellingerrorsatstart = spellingerrorsatstartfile.read().trim().split('\n');
		tempomarkings = tempomarkingsfile.read().trim().split('\n');
		tempochangemarkings = tempochangemarkingsfile.read().trim().split('\n');
		
		// **** GATHER VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		firstBarInScore = curScore.firstMeasure;
		lastBarInScore = curScore.lastMeasure;
		var firstSystem = firstBarInScore.parent;
		var lastSystem = lastBarInScore.parent;
		var firstPage = firstSystem.parent;
		var lastPage = lastSystem.parent;
		var firstPageNum = firstPage.pagenumber;
		var lastPageNum = lastPage.pagenumber;
		hasMoreThanOneSystem = !lastSystem.is(firstSystem);	
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		parts = curScore.parts;
		numParts = parts.length;
		if (Qt.platform.os !== "osx") cmdKey = "ctrl";
		var inchesToMM = 25.4;
		var spatiumDPI = 360.;
		spatium = curScore.style.value("spatium")*inchesToMM/spatiumDPI; // spatium value is given in 360 DPI
		pageWidth = Math.round(curScore.style.value("pageWidth")*inchesToMM);
		pageHeight = Math.round(curScore.style.value("pageHeight")*inchesToMM);
		
		//logError("1 "+curScore.selection.startSegment+" "+curScore.selection.endSegment+" "+curScore.selection.startStaff+" "+curScore.selection.endStaff);
		
		var staccatoArray = [kAccentStaccatoAbove, kAccentStaccatoAbove+1,
			kStaccatissimoAbove, kStaccatissimoAbove+1,
			kStaccatissimoStrokeAbove, kStaccatissimoStrokeAbove+1,
			kStaccatissimoWedgeAbove, kStaccatissimoWedgeAbove+1,
			kStaccatoAbove, kStaccatoAbove+1];
		
		// WORK OUT THE MEASURE THAT STARTS THE SECOND SYSTEM
		if (hasMoreThanOneSystem) {
			firstBarInSecondSystem = curScore.firstMeasure;
			while (firstBarInSecondSystem.parent.is(firstSystem)) firstBarInSecondSystem = firstBarInSecondSystem.nextMeasure;
		}
		
		// **** INITIALISE PROPERTIES AND ARRAYS **** //
		var isSpellingError = false;
		initialTempoExists = false;
		
		// ************  	GO THROUGH ALL INSTRUMENTS & STAVES LOOKING FOR INFO 	************ //
		analyseInstrumentsAndStaves();
		
		// ************  								SAVE CURRENT SELECTION 							************ //
		saveSelection();
		
		// ************  		DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS 		************ //
		deleteAllCommentsAndHighlights();

		// ************  							CHECK SCORE & PAGE SETTINGS 					************ // 
		checkScoreAndPageSettings();
		
		// ************  							CHECK TITLE PAGE 					************ // 
		if (lastPageNum > 1 && firstPageNum == 0) {
			addError ("This score is longer than 2 pages, but doesn’t appear to have a title page.\n(Ignore this if you are planning to add a title page to the score in another app.)","pagetop");
		}

		// ************  				SELECT AND PRE-PROCESS ENTIRE SCORE 				************ //
		selectAll();

		
		setProgress (1);
		
		// **** INITIALISE ALL ARRAYS **** //
		for (var i = 0; i<numStaves; i++) {
			articulations[i] = [];
			slurs[i] = [];
			pedals[i] = [];
			hairpins[i] = [];
			oneNoteTremolos[i] = [];
			twoNoteTremolos[i] = [];
			glisses[i] = [];
			ottavas[i] = [];
			dynamics[i] = [];
			clefs[i] = [];
			for (var j = 0; j < 4; j++) {
				isMelisma[i*4+j] = false;
				melismaEndTick[i*4+j] = 0;
			}
		}
		
		// **** INITIALISE THE COMMENT POSITION OFFSET **** //
		for (var i = 0; i <= lastPageNum; i++) {
			commentPosOffset[i] = Array(10000).fill(0);
		}
		
		// **** LOOK FOR AND STORE ANY ELEMENTS THAT CAN ONLY BE ACCESSED FROM SELECTION: **** //
		// **** AND IS NOT PICKED UP IN A CURSOR LOOP (THAT WE WILL BE DOING LATER)       **** //
		// **** THIS INCLUDES: HAIRPINS, OTTAVAS, TREMOLOS, SLURS, ARTICULATION, FERMATAS **** //
		// **** GLISSES, PEDALS, TEMPO TEXT																								**** //
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			var etype = e.type;
			var staffIdx = 0;
			while (!staves[staffIdx].is(e.staff)) staffIdx++;
			if (etype == Element.HAIRPIN) hairpins[staffIdx].push(e);
			if (etype == Element.OTTAVA || etype == Element.OTTAVA_SEGMENT) ottavas[staffIdx].push(e);
			if (etype == Element.GLISSANDO) glisses[staffIdx][e.parent.parent.parent.tick] = e;
			if (etype == Element.SLUR) slurs[staffIdx].push(e);
			if (etype == Element.PEDAL_SEGMENT || e.type == Element.PEDAL) pedals[staffIdx].push(e);			
			if (etype == Element.TREMOLO_SINGLECHORD) oneNoteTremolos[staffIdx][e.parent.parent.tick] = e;
			if (etype == Element.TREMOLO_TWOCHORD) twoNoteTremolos[staffIdx][e.parent.parent.tick] = e;
			if (etype == Element.ARTICULATION) {
				if (articulations[staffIdx][e.parent.parent.tick] == null || articulations[staffIdx][e.parent.parent.tick] == undefined) {
					articulations[staffIdx][e.parent.parent.tick] = new Array();
					//logError("New array "+articulations[staffIdx][e.parent.parent.tick].length);
				}
				articulations[staffIdx][e.parent.parent.tick].push(e);
				//logError("artic slot staff "+staffIdx+" tick "+(e.parent.parent.tick)+" now has "+articulations[staffIdx][e.parent.parent.tick].length+" items");
			}
			if (etype == Element.FERMATA) {
				var theTick = e.parent.tick;
				fermatas.push(e);
				var locArr = staffIdx+' '+theTick;
				fermataLocs.push(locArr);
			}
			if (etype == Element.TEMPO_TEXT) tempoText.push(e);
			if (etype == Element.DYNAMIC) dynamics[staffIdx].push(e.parent.tick);
			if (etype == Element.CLEF) clefs[staffIdx][e.parent.tick] = e;
		}
		
		setProgress (2);
		
		// ************  				CHECK TITLE TEXT AND STAFF TEXT OBJECTS FOR ERRORS 				************ //
		checkScoreText();
		
		// ************ 								CHECK TIME SIGNATURES								************ //
		checkTimeSignatures();
		
		// ************ 						CHECK FOR STAFF ORDER ISSUES 						************ //
		checkStaffOrder();
		
		// ************  							CHECK STAFF NAMES ISSUES 							************ // 
		checkStaffNames();
		
		// ************  							CHECK STAFF NAMES ISSUES 							************ // 
		checkLocationOfFinalBar();
		
		// ************ 							CHECK FOR FERMATA ISSUES 							************ ///
		if (!isSoloScore && numStaves > 2) checkFermatas();
		
		setProgress (3);
		
		// ************ 			PREP FOR A FULL LOOP THROUGH THE SCORE 				************ //
		var currentBar, prevBarNum, numBarsProcessed, wasTied, isFirstNote;
		var firstBarNum, firstSegmentInScore, numBars;
		var prevDisplayDur, tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;
		var containsTransposingInstruments = false;
		var currentSlur, numSlurs, nextSlurStart, currentSlurEnd;
		var currentPedal, currentPedalNum, numPedals, nextPedalStart, currentPedalEnd, flaggedPedalLocation;
		var currentOttavaNum, numOttavas, nextOttavaStart, currentOttavaEnd;
		var currentHairpinNum, numHairpins, nextHairpinStart;
		var numSystems, currentSystem, currentSystemNum, numNotesInThisSystem, numBeatsInThisSystem, noteCountInSystem, beatCountInSystem;
		var maxNoteCountPerSystem, minNoteCountPerSystem, maxBeatsPerSystem, minBeatsPerSystem, actualStaffSize;
		var isSharedStaff;
		var loop = 0;
		
		firstBarInScore = curScore.firstMeasure;
		
		//logError ("Trying bracket: "+curScore.systemBracket+" "+firstBarInScore.systemBracket+" "+firstBarInScore.parent.systemBracket);
		
		currentBar = firstBarInScore;
		lastBarInScore = curScore.lastMeasure;
		numBars = curScore.nmeasures;
		cursor.rewind(Cursor.SCORE_END);
		//logError("————————\n\nSTARTING LOOP\n\n");
		noteCountInSystem = [];
		beatCountInSystem = [];
		var actualStaffSize = spatium*4;
		maxNoteCountPerSystem = (10.0 - actualStaffSize) * 10.0 + 18; // 48 notes at 7mm
		minNoteCountPerSystem = (10.0 - actualStaffSize) * 3.0 + 4; // 13 notes at 7mm
		maxBeatsPerSystem = (10.0 - actualStaffSize) * 6.0 + 14; // 32
		minBeatsPerSystem = (10.0 - actualStaffSize) * 3.0; // 12
		
		setProgress (4);
		
		var totalNumLoops = numStaves * numBars * 4;
		
		// ************ 					START LOOP THROUGH WHOLE SCORE 						************ //
		for (currentStaffNum = 0; currentStaffNum < numStaves; currentStaffNum ++) {
			//logError("\n——— STAFF "+currentStaffNum+" ————");
			
			//don't process if this part is hidden
			if (!staffVisible[currentStaffNum]) {
				loop += numBars * 4;
				continue;
			}
			
			//logError("top = "+isTopOfGrandStaff[currentStaffNum]);
			
			// INITIALISE VARIABLES BACK TO DEFAULTS A PER-STAFF BASIS
			prevKeySigSharps = -99; // placeholder/dummy variable
			prevKeySigBarNum = 0;
			prevBarNum = 0;
			prevDynamic = "";
			prevDynamicBarNum = 0;
			prevClefId = null;
			prevMultipleStop = null;
			prevIsMultipleStop = false;
			prevMultipleStopInterval = 0;
			currentMute = "senza";
			currentPlayingTechnique = "arco";
			currentContactPoint = "ord";
			minLedgerLines = [];
			maxLedgerLines = [];
			isFirstNote = true;
			weKnowWhosPlaying = false;
			isSharedStaff = isSharedStaffArray[currentStaffNum];
			isDiv = false;
			firstDynamic = false;
			lastTempoChangeMarkingBar = -1;
			
			// ** clear flags ** //
			flaggedLedgerLines = false;
			flaggedDivError = false;
			flaggedWeKnowWhosPlaying = false;
			flaggedPedalLocation = false;
			flaggedSlurredRest = false;
			flaggedFlippedStem = false;
			flaggedOttavaIssue = false;
			flaggedPedalIssue = false;
			flaggedNoLyrics = false;
			flaggedWrittenStaccato = false;
			flaggedFastMultipleStops = false;
			flaggedOneStrokeTrem = false;
			
			// ** slurs
			currentSlur = null;
			isSlurred = false;			
			currentSlurNum = 0;
			currentSlurEnd = 0;	
			numSlurs = slurs[currentStaffNum].length;
			nextSlurStart = (numSlurs == 0) ? 0 : slurs[currentStaffNum][0].spannerTick.ticks;
			
			// ** pedals
			currentPedal = null;
			isPedalled = false;	
			currentPedalNum = 0;
			currentPedalEnd = 0;
			numPedals = pedals[currentStaffNum].length;
			nextPedalStart = (numPedals == 0) ? 0 : pedals[currentStaffNum][0].spannerTick.ticks;
			
			// ** hairpins
			currentHairpin = null;
			isHairpin = false;
			currentHairpinNum = 0;
			currentHairpinEnd = 0;
			numHairpins = hairpins[currentStaffNum].length;
			nextHairpinStart = (numHairpins == 0) ? 0 : hairpins[currentStaffNum][0].spannerTick.ticks;
			
			// ** ottavas
			currentOttava = null;
			isOttava = false;
			currentOttavaNum = 0;
			currentOttavaEnd = 0;
			numOttavas = ottavas[currentStaffNum].length;
			nextOttavaStart = (numOttavas == 0) ? 0 : ottavas[currentStaffNum][0].spannerTick.ticks;
			
			// **** REWIND TO START OF SELECTION **** //
			// **** GET THE STARTING CLEF OF THIS INSTRUMENT **** //
			currentInstrumentName = instrumentNames[currentStaffNum];
			currentInstrumentId = instrumentIds[currentStaffNum];
			setInstrumentVariables();			
			cursor.filter = Segment.HeaderClef;
			cursor.staffIdx = currentStaffNum;
			cursor.voice = 0;
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == null) cursor.next();
			currentBar = cursor.measure;
			currentSystem = null;
			currentSystemNum = 0;
			numNotesInThisSystem = 0;
			numBeatsInThisSystem = 0;
			var clef = cursor.element;
			// call checkClef AFTER the currentInstrumentName/Id setup and AFTER set InstrumentVariables
			if (clef != null) checkClef(clef);
			
			prevTimeSig = currentBar.timesigNominal.str;
			
			// **** CHECK FOR VIBRAPHONE BEING NOTATED ON A GRANT STAFF **** //
			if (currentInstrumentId.includes('vibraphone') && isTopOfGrandStaff[currentStaffNum]) addError('Vibraphones are normally notated on a single treble staff,\nrather than a grand staff.','system1 '+currentStaffNum);
						
			for (currentBarNum = 1; currentBarNum <= numBars && currentBar; currentBarNum ++) {
				
				var barStartTick = currentBar.firstSegment.tick;
				var barEndTick = currentBar.lastSegment.tick;
				var barLength = barEndTick - barStartTick;
				var startTrack = currentStaffNum * 4;
				var goneToNextBar = false;
				var firstNoteInThisBar = null;
				var stretch = currentBar.userStretch;
				//logError("\nb. "+currentBarNum);
				currentTimeSig = currentBar.timesigNominal;

				if (currentStaffNum == 0) {
					var numBeats = currentTimeSig.numerator;
					if (currentTimeSig.denominator > 8) numBeats /= 2;
					numBeatsInThisSystem += numBeats;
					
					// **** CHECK FOR NON-STANDARD STRETCH FACTOR **** //
					if (stretch != 1) {
						addError("The stretch for this bar is set to "+stretch+";\nits spacing may not be consistent with other bars.\nYou can reset it by choosing Format→Stretch→Reset Layout Stretch.",currentBar);
					}
				}
				if (!currentBar.parent.is(currentSystem)) {
					// start of system
					currentSystem = currentBar.parent;
					if (currentStaffNum == 0) systemStartBars.push(currentBar);
					if (currentBarNum > 1) {
						if (currentStaffNum == 0) {
							beatCountInSystem.push(numBeatsInThisSystem);
							//logError("Pushed beatCountInSystem[] = "+numBeatsInThisSystem);
						}
						if (noteCountInSystem.length <= currentSystemNum) {
							noteCountInSystem.push(numNotesInThisSystem > numBeatsInThisSystem ? numNotesInThisSystem : numBeatsInThisSystem);
							//logError("Pushed noteCountInSystem["+currentSystemNum+"] = "+noteCountInSystem[currentSystemNum]);
						} else {
							if (numNotesInThisSystem > noteCountInSystem[currentSystemNum]) {
								noteCountInSystem[currentSystemNum] = numNotesInThisSystem;
								//logError("Expanded noteCountInSystem["+currentSystemNum+"] = "+numNotesInThisSystem);
							}
						}
						currentSystemNum ++;
					}
					numNotesInThisSystem = 0;
					numBeatsInThisSystem = 0;
				}
				var numTracksWithNotes = 0;
				var numNotesInThisTrack = 0;
				var isChord = false;
				pedalChangesInThisBar = 0;
				flaggedPedalChangesInThisBar = false;
				if (currentBarNum % 2) flaggedFastMultipleStops = false;
				
			
				// ************ CHECK HARP ISSUES ************ //
				if (isHarp && (isTopOfGrandStaff[currentStaffNum] || !isGrandStaff[currentStaffNum])) checkHarpIssues(currentBar,currentStaffNum);
				
				// ************ CHECK UNTERMINATED TEMPO CHANGE ************ //
				if (lastTempoChangeMarkingBar != -1 && currentBarNum == lastTempoChangeMarkingBar + 8) {
					//logError("Found unterminated tempo change in b. "+currentBarNum);
					addError("You have indicated a tempo change here,\nbut I couldn’t find a new tempo marking\nor ‘a tempo’/‘tempo primo’.",lastTempoChangeMarking);
					lastTempoChangeMarkingBar = -1;
				}
				
				for (var currentTrack = startTrack; currentTrack < startTrack + 4; currentTrack ++) {
					// **** UPDATE PROGRESS MESSAGE **** //
					loop++;
					setProgress(5+loop*95./totalNumLoops);
					cursor.filter = Segment.All;
					cursor.track = currentTrack;
					cursor.rewindToTick(barStartTick);
					var processingThisBar = cursor.element && cursor.tick < barEndTick;
					
					prevNote = null;
					prevSlurNum = null;
					prevWasGraceNote = false;
					var prevTick = -1;
					while (processingThisBar) {
						var currSeg = cursor.segment;
						var currTick = currSeg.tick;
						if (currTick != barEndTick) {
							tickHasDynamic = false;
							
							if (isMelisma[currentTrack] && melismaEndTick[currentTrack] > 0) isMelisma[currentTrack] = currTick < melismaEndTick[currentTrack];
							
							var annotations = currSeg.annotations;
							var elem = cursor.element;
							var eType = elem.type;
							var eName = elem.name;
							var sType = currSeg.segmentType;
						
							// ************ UNDER A SLUR? ************ //
							var readyToGoToNextSlur = false;
							if (currentSlurNum < numSlurs) {
								if (currentSlur == null) {
									readyToGoToNextSlur = true;
								} else {
									if (currTick > currentSlurEnd) {
										//logError("Slur ended");
										currentSlur = null;
										isSlurred = false;
										currentSlurNum ++;
										if (currentSlurNum < numSlurs) {
											nextSlurStart = slurs[currentStaffNum][currentSlurNum].spannerTick.ticks;
											readyToGoToNextSlur = true;
										}
									}
								}
							}
							if (readyToGoToNextSlur) {
								if (currTick >= nextSlurStart) {
									isSlurred = true;
									currentSlur = slurs[currentStaffNum][currentSlurNum];
									currentSlurEnd = currentSlur.spannerTick.ticks + currentSlur.spannerTicks.ticks;
									//logError("Slur started at "+currTick+" & ends at "+currentSlurEnd);
									if (currentSlurNum < numSlurs - 1) {
										nextSlurStart = slurs[currentStaffNum][currentSlurNum+1].spannerTick.ticks;
										//logError("Next slur starts at "+nextSlurStart);
									} else {
										nextSlurStart = 0;
										//logError("This is the last slur in this staff ");
									}
								}
							}
						
							// ************ PEDAL? ************ //
							var readyToGoToNextPedal = false;
							if (currentPedalNum < numPedals) {
								if (currentPedal == null) {
									readyToGoToNextPedal = true;
								} else {
									if (currTick > currentPedalEnd) {
										//logError("Pedal ended");
										currentPedal = null;
										isPedalled = false;
										currentPedalNum ++;
										if (currentPedalNum < numPedals) {
											nextPedalStart = pedals[currentStaffNum][currentPedalNum].spannerTick.ticks;
											readyToGoToNextPedal = true;
										}
									}
								}
							}
							if (readyToGoToNextPedal) {
								if (currTick >= nextPedalStart) {
									isPedalled = true;
									currentPedal = pedals[currentStaffNum][currentPedalNum];
									currentPedalEnd = currentPedal.spannerTick.ticks + currentPedal.spannerTicks.ticks;
									//logError("Pedal started at "+currTick+" & ends at "+currentPedalEnd);
									if (isPedalInstrument) {
										if (isTopOfGrandStaff[currentStaffNum] && !flaggedPedalLocation) {
											flaggedPedalLocation = true;
											addError("Pedal markings should go below the bottom staff of a grand staff",currentPedal);
										}
									} else {
										if (!flaggedPedalIssue) {
											addError("This instrument does not have a sustain pedal",currentPedal);
											flaggedPedalIssue = true;
										}
									}
									if (currentPedalNum < numPedals - 1) {
										nextPedalStart = pedals[currentStaffNum][currentPedalNum+1].spannerTick.ticks;
										//logError("Next pedal starts at "+nextPedalStart);
									} else {
										nextPedalStart = 0;
										//logError("This is the last pedal in this staff ");
									}
								}
							}
						
							// ************ OTTAVA? ************ //
							var readyToGoToNextOttava = false;
							if (currentOttavaNum < numOttavas) {
								if (currentOttava == null) {
									readyToGoToNextOttava = true;
								} else {
									if (currTick > currentOttavaEnd) {
										//logError("Ottava ended");
										currentOttava = null;
										isOttava = false;
										currentOttavaNum ++;
										flaggedOttavaIssue = false;
										if (currentOttavaNum < numOttavas) {
											nextOttavaStart = ottavas[currentStaffNum][currentOttavaNum].spannerTick.ticks;
											readyToGoToNextOttava = true;
										}
									}
								}
							}
							if (readyToGoToNextOttava) {
								if (currTick >= nextOttavaStart) {
									isOttava = true;
									currentOttava = ottavas[currentStaffNum][currentOttavaNum];
									currentOttavaEnd = currentOttava.spannerTick.ticks + currentOttava.spannerTicks.ticks;
									//logError("Ottava started at "+currTick+" & ends at "+currentOttavaEnd);
								
									if (currentOttavaNum < numOttavas - 1) {
										nextOttavaStart = ottavas[currentStaffNum][currentOttavaNum+1].spannerTick.ticks;
										//logError("Next ottava starts at "+nextOttavaStart);
									} else {
										nextOttavaStart = 0;
										//logError("This is the last ottava in this staff ");
									}
								}
							}
						
							// ************ UNDER A HAIRPIN? ************ //
							var readyToGoToNextHairpin = false;
							if (currentHairpinNum < numHairpins) {
								if (currentHairpin == null) {
									readyToGoToNextHairpin = true;
								} else {
									if (currTick >= currentHairpinEnd) {
										//logError("Hairpin ended because currTick = "+currTick+" & currentHairpinEnd = "+currentHairpinEnd);
										// was this hairpin long enough to require ending?
										currentHairpin = null;
										isHairpin = false;
										currentHairpinNum ++;
										if (currentHairpinNum < numHairpins) {
											nextHairpinStart = hairpins[currentStaffNum][currentHairpinNum].spannerTick.ticks;
											readyToGoToNextHairpin = true;
											//logError("nextHairpinStart = "+nextHairpinStart);
										}
									}
								}
							}
							if (readyToGoToNextHairpin) {
								//logError("Next hairpin start = "+nextHairpinStart+" currTick = "+currTick);
							
								if (currTick >= nextHairpinStart) {
									isHairpin = true;
									//logError("found hairpin, currTick = "+currTick);
									//logError("currSeg.type = "+currSeg.type+" eType = "+eType+" eName = "+eName);
								
									currentHairpin = hairpins[currentStaffNum][currentHairpinNum];
									var hairpinStartTick = currentHairpin.spannerTick.ticks;
									var hairpinDur = currentHairpin.spannerTicks.ticks;
								
									currentHairpinEnd = hairpinStartTick + hairpinDur;
									if (hairpinDur > barLength * 0.8) {
										var doCheck = true;
										if (currentHairpin.hairpinType == 2) {
											var nextItem = getNextChordRest(cursor);
											doCheck = nextItem.type == Element.CHORD;
										}
										if (doCheck) checkHairpinTermination();
									}
									//logError("Hairpin started at "+currTick+" & ends at "+currentHairpinEnd);
									if (currentHairpinNum < numHairpins - 1) {
										nextHairpinStart = hairpins[currentStaffNum][currentHairpinNum+1].spannerTick.ticks;
										//logError("Next slur starts at "+nextHairpinStart);
									} else {
										nextHairpinStart = 0;
										//logError("This is the last slur in this staff ");
									}
								}
							}
						
							// ************ FOUND A CLEF ************ //
							if (clefs[currentStaffNum][currTick] != null && currTick != prevTick) checkClef(clefs[currentStaffNum][currTick]);
						
							// ************ CHECK KEY SIGNATURE ************ //
							if (eType == Element.KEYSIG && currentStaffNum == 0) checkKeySignature(elem,cursor.keySignature);
						
							// **** CHECK TREM
							isTrem = (oneNoteTremolos[currentStaffNum][currTick] != null);
						
							// ************ LOOP THROUGH ANNOTATIONS IN THIS SEGMENT ************ //
							if (annotations && annotations.length) {
								for (var aIndex in annotations) {
									var theAnnotation = annotations[aIndex];
									if (theAnnotation.track == currentTrack) {
										var aName = theAnnotation.name;
										var aType = theAnnotation.type;
										var aText = theAnnotation.text;
																		
										// **** FOUND A TEXT OBJECT **** //
										if (aText) {
											checkTextObject(theAnnotation, currentBarNum);
										} else {
											//logError(" Found non-text annotion "+aName);
										}
									}
								}
							}
						
							// ************ FOUND A CHORD OR REST ************ //
							if (eType == Element.CHORD || eType == Element.REST) {
							
								// GLISS? MAYBE DELETE
								//logError("Chord / Rest found @ tick "+currTick);
								numNotesInThisTrack ++;
								numNotesInThisSystem ++;
								var noteRest = cursor.element;
								//if (noteRest.glissType != null) logError("FOUND GLISS "+noteRest.glissType);
								if (firstNoteInThisBar == null) firstNoteInThisBar = noteRest;
								var isHidden = !noteRest.visible;
								var isRest = noteRest.type == Element.REST;
								var isNote = !isRest;
								var displayDur = noteRest.duration.ticks;
								var soundingDur = noteRest.actualDuration.ticks;
								var tuplet = noteRest.tuplet;
								var barsSincePrevNote = currentBarNum - prevBarNum;
								if (barsSincePrevNote > 1) {
									minLedgerLines = [];
									maxLedgerLines = [];
									flaggedLedgerLines = false;
								}
							
								//if (typeof currentStaffNum !== 'number') logError("Artic error in main loop");
								//if (beam) isCrossStaff = beam.cross;
								// TO FIX
								//logError("FOUND NOTE");
							
							
							
								if (isRest) {
									if (tickHasDynamic && !isGrandStaff[currentStaffNum]) addError ("In general, you shouldn’t put dynamic markings under rests.", theDynamic);
									maxLLSinceLastRest = 0;
								
								} else {
									numNotesInThisTrack ++;
									isTied = noteRest.notes[0].tieBack != null;
									if (noteRest.notes[0].tieForward != null) {
										var nextChordRest = getNextChordRest(cursor);
										if (nextChordRest != null) {
											if (nextChordRest.type == Element.REST) addError ("Don’t tie notes over a rest",noteRest);
										}
									}
															
									// ************ CHECK LYRICS ************ //
							
									if (isVoice) checkLyrics(noteRest);
								
									// ************ CHECK GRACE NOTES ************ //
									var graceNotes = noteRest.graceNotes;
									if (graceNotes.length > 0) {
										checkGraceNotes(graceNotes, currentStaffNum);
										numNotesInThisSystem += graceNotes.length / 2; // grace notes only count for half
										prevWasGraceNote = true;
									}
								
									//if (noteRest.notes[0].glissType != null) logError("FOUND GLISS 2 "+noteRest.notes[0].glissType);
								
									// ************ CHECK STACCATO ISSUES ************ //
									var theArticulationArray = getArticulationArray (noteRest, currentStaffNum);
								
									if (theArticulationArray) {
										for (var i = 0; i < theArticulationArray.length; i++) {
											if (staccatoArray.includes(theArticulationArray[i].symbol)) checkStaccatoIssues (noteRest);
										}
									}
								
									var nn = noteRest.notes.length;
									isChord = nn > 1;
								
									if (isFirstNote) {
										isFirstNote = false;
									
										// ************ CHECK IF INITIAL DYNAMIC SET ************ //
										if (!firstDynamic && !isGrandStaff[currentStaffNum]) addError("This note should have an initial dynamic level set.",noteRest);
									
										// ************ CHECK IF SCORE IS TRANSPOSED ************ //
										if (!containsTransposingInstruments) {
											var note = noteRest.notes[0];
											var containsTransposingInstruments = note.tpc1 != note.tpc2;
											if (containsTransposingInstruments && note.tpc == note.tpc1) addError("This score includes a transposing instrument, but the score is currently in Concert pitch.\nIt is generally preferred to have the score transposed.\nUntick ‘Concert pitch’ in the bottom right to view the transposed score.","pagetop");
										}
								
									} else {
									
										// ************ CHECK DYNAMIC RESTATEMENT ************ //
										if (barsSincePrevNote > 4 && !tickHasDynamic && !isGrandStaff[currentStaffNum] ) addError("Restate a dynamic here, after the "+(barsSincePrevNote-1)+" bars’ rest.",noteRest);
									
									}
								
									// ************ CHECK OTTAVA ************ //
									if (isOttava) checkOttava(noteRest,currentOttava);
								
									// ************ CHECK STEM DIRECTION ************ //
									checkStemDirection(noteRest);
								
									// ************ CHECK LEDGER LINES ************ //
									checkLedgerLines(noteRest);
								
									// ************ CHECK STRING ISSUES ************ //
									if (isStringInstrument) {
									
										// ************ CHECK STRING HARMONIC ************ //
										checkStringHarmonic(noteRest, currentStaffNum); // make sure we call this BEFORE multiple stops and divisi, as it checks for false harmonics
									
										// ************ CHECK DIVISI ************ //
										if (isStringSection) checkDivisi (noteRest, currentStaffNum);
									
										// ************ CHECK PIZZ ISSUES ************ //
										if (currentPlayingTechnique === "pizz") checkPizzIssues(noteRest, currentBarNum, currentStaffNum);
									
										// ************ CHECK MULTIPLE STOP ISSUES ************ //
										if (isChord && !isStringSection) {
											checkMultipleStop (noteRest);
										} else {
											prevIsMultipleStop = false;
										}
									
									} // end isStringInstrument
								
									// ************ CHECK FLUTE HARMONIC ************ //
									if (isFlute) checkFluteHarmonic(noteRest);
								
									// ************ CHECK PIANO STRETCH ************ //
									if (isKeyboardInstrument && isChord) checkPianoStretch(noteRest);
								
						
									// ************ CHECK TREMOLOS ************ //
									if (oneNoteTremolos[currentStaffNum][currTick] != null) checkOneNoteTremolo(noteRest,oneNoteTremolos[currentStaffNum][currTick]);
									if (twoNoteTremolos[currentStaffNum][currTick] != null) checkTwoNoteTremolo(noteRest,twoNoteTremolos[currentStaffNum][currTick]);
								
									// ************ CHECK GLISSES ************ //
									if (glisses[currentStaffNum][currTick] != null) checkGliss(noteRest,glisses[currentStaffNum][currTick]);

									prevBarNum = currentBarNum;
								
								} // end is rest
								// **** CHECK SLUR ISSUES **** //
								// We do this last so we can check if there were grace notes beforehand
								if (isSlurred && currentSlur != null) checkSlurIssues(noteRest, currentStaffNum, currentSlur);
							
								prevSoundingDur = soundingDur;
							
							} // end if eType == Element.Chord || .Rest
						}
						
						if (cursor.next()) {
							processingThisBar = cursor.measure.is(currentBar);
						} else {
							processingThisBar = false;
						}
						if (isNote) {
							prevNote = noteRest;
						} else {
							prevNote = null;
							prevSlurNum = null;
						}
						prevSlurNum = isSlurred ? currentSlurNum : null;
						prevTick = currTick;
					} // end while processingThisBar
					if (numNotesInThisTrack > 0) numTracksWithNotes ++;
				} // end track loop
				if (isWindOrBrassInstrument && isSharedStaff) {
					if (numTracksWithNotes > 1 || isChord) {
						//logError("multiple parts found");
						weKnowWhosPlaying = false;
						flaggedWeKnowWhosPlaying = false;
					} else {

						//logError("numTracksWithNotes="+numTracksWithNotes+" weKnowWhosPlaying="+weKnowWhosPlaying+" flaggedWeKnowWhosPlaying="+flaggedWeKnowWhosPlaying);
						if (numTracksWithNotes == 1 && !weKnowWhosPlaying && !flaggedWeKnowWhosPlaying) {
							addError("This bar has only one melodic line on a shared staff\nThis needs to be marked with, e.g., 1./2./a 2",firstNoteInThisBar);
							flaggedWeKnowWhosPlaying = true;
						}
					}
				}
				if (currentBar) currentBar = currentBar.nextMeasure;
				numBarsProcessed ++;
			}// end currentBar num
			
			if (currentStaffNum == 0) beatCountInSystem.push(numBeatsInThisSystem);
			if (noteCountInSystem[currentSystemNum] == undefined) {
				if (numNotesInThisSystem > numBeatsInThisSystem) {
					noteCountInSystem[currentSystemNum] = numNotesInThisSystem;
					//logError("Pushed noteCountInSystem["+currentSystemNum+"] = "+numNotesInThisSystem);
				} else {
					noteCountInSystem[currentSystemNum] = numBeatsInThisSystem;
					//logError("Pushed noteCountInSystem["+currentSystemNum+"] = "+numBeatsInThisSystem);
				}
			} else {
				if (numNotesInThisSystem > noteCountInSystem[currentSystemNum]) {
					noteCountInSystem[currentSystemNum] = numNotesInThisSystem;
					//logError("Expanded noteCountInSystem["+currentSystemNum+"] = "+numNotesInThisSystem);
				}
			}
		} // end staffnum loop
		
		// mop up any last tests
		
		// ** CHECK FOR OMITTED INITIAL TEMPO ** //
		if (!initialTempoExists) addError('I couldn’t find an initial tempo marking','top');
		
		// ** CHECK REHEARSAL MARKS ** //
		if (numBars > 30 && numStaves > 3 && !isSoloScore) checkRehearsalMarks();
		
		// ** CHECK SPACING ** //
		numSystems = systemStartBars.length;
		for (var sys = 0; sys < numSystems; sys ++) {
			var noteCountInSys = noteCountInSystem[sys];
			var numBeatsInSys = beatCountInSystem[sys];
			var bar = systemStartBars[sys];
			var mmin = maxNoteCountPerSystem * 0.4;
			var mmax = minNoteCountPerSystem * 2;
			//logError("CHECKING SYS "+sys+": nc="+noteCountInSys+" nb="+numBeatsInSys+" mmin="+mmin+" mmax="+mmax);
			if (bar == undefined) {
				logError("check spacing — BAR UNDEFINED");
			} else {
				if (noteCountInSys < minNoteCountPerSystem) {
					addError("This system doesn’t have many notes in it, and may be quite spread out.\nTry including more bars in this system.",bar);
					continue;
				}
				if (noteCountInSys > maxNoteCountPerSystem) {
					addError("This system has a lot of notes in it, and may be quite squashed.\nTry moving some of the bars out of this system.",bar);
					continue;
				}
				if (numBeatsInSys < minBeatsPerSystem && noteCountInSys < mmin) {
					addError("This system doesn’t have many bars in it and may be quite spread out.\nTry including more bars in this system.",bar);
					continue;
				}
				if (numBeatsInSys > maxBeatsPerSystem && noteCountInSys > mmax) {
					addError("This system has quite a few bars in it, and may be quite squashed.\nTry moving some of the bars out of this system.",bar);
					continue;
				}
			}
		}
		
		// ** SHOW ALL OF THE ERRORS ** //
		showAllErrors();
		
		// ************  								RESTORE PREVIOUS SELECTION 							************ //
		restoreSelection();
		
		// ** SHOW INFO DIALOG ** //
		var numErrors = errorStrings.length;
		if (errorMsg != "") errorMsg = "\n\n————————————\nERROR LOG (for developer use):" + errorMsg;
		if (numErrors == 0) errorMsg = "CHECK COMPLETED: Congratulations — no issues found!\n\n<font size=\"6\">🎉</font>" + errorMsg;
		if (numErrors == 1) errorMsg = "CHECK COMPLETED: I found one issue.\nPlease check the score for the yellow comment box that provides more details of the issue." + errorMsg;
		if (numErrors > 1) errorMsg = "CHECK COMPLETED: I found "+numErrors+" issues.\nPlease check the score for the yellow comment boxes that provide more details on each issue." + errorMsg;
		
		if (progressShowing) progress.close();
		
		var h = 200+numLogs*10;
		if (h > 500) h =500;
		dialog.height = h;
		dialog.msg = errorMsg;
		dialog.show();
	}
	
	function getNextChordRest (cursor) {
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = cursor.staffIdx;
		cursor2.filter = Segment.ChordRest;
		cursor2.track = cursor.track;
		cursor2.rewindToTick(cursor.tick);
		if (cursor2.next()) {
			return cursor2.element;
		} else {
			return null;
		}
	}
	
	function chordsAreIdentical (chord1,chord2) {
		if (chord1.notes.length != chord2.notes.length) return false;
		for (var i = 0; i < chord1.notes.length; i++) {
			if (chord1.notes[i].pitch != chord2.notes[i].pitch) return false;
		}
		return true;
	}
		
	function setProgress (percentage) {
		if (percentage == 0) {
			progressStartTime = Date.now();
		} else {
			if (!progressShowing) {
				var currentTime = Date.now();
				if (currentTime - progressStartTime > 3000) {
					progress.show();
					progressShowing = true;
				}
			} else {
				progress.progressPercent = percentage;
			}
		}
	}
	
	function analyseInstrumentsAndStaves () {
		numGrandStaves = 0;
		var prevPart = null;
		var prevPrevPart = null;
		var numStaves = curScore.nstaves;
		var staves = curScore.staves;
		var visiblePartFound = false;
		for (var i = 0; i < numStaves; i++) {
			
			// save the id and staffName
			var part = staves[i].part;
			staffVisible[i] = part.show;
			if (staffVisible[i] && !visiblePartFound) {
				visiblePartFound = true;
				firstVisibleStaff = i;
			}
			if (!staffVisible[i]) numParts--;
			var id = part.instrumentId;
			instrumentIds.push(id);
			var staffName = staves[i].part.longName;
			instrumentNames.push(staffName);
			//logError("staff "+i+" ID "+id+" name "+staffName+" vis "+staves[i].visible);
			isSharedStaffArray[i] = false;
			
			// check to see whether this staff name indicates that it's a shared staff
			var firstLetterIsANumber = !isNaN(staffName.substring(0,1)); // checks to see if the staff name begins with, e.g., '2 Bassoons'
			if (firstLetterIsANumber) {
				isSharedStaffArray[i] = true;
			} else {
				// check if it contains a pattern like '1.2' or 'II &amp; III'midg
				if (staffName.match(/([1-8]+|[MDCLXVI]+)(\.|,|, |&amp;| &amp; )([1-8]+|[MDCLXVI]+)/) != null) {
					isSharedStaffArray[i] = true;

					//logError(""+staffName+" matched.");
					continue;
				}
				//logError(""+staffName+" does not match.");
			}
			
			if (i > 0 && part.is(prevPart)) {
				isGrandStaff[i-1] = true;
				isGrandStaff[i] = true;
				isTopOfGrandStaff[i-1] = !prevPart.is(prevPrevPart);
				isTopOfGrandStaff[i] = false;
				grandStaffTops.push(i-1);
				numGrandStaves ++;
				// NOTE: THIS DOESN'T WORK IF YOUR GRAND STAFF HAS MORE THAN 2 STAVES
			} else {
				isTopOfGrandStaff[i] = false;
				isGrandStaff[i] = false;
			}
			prevPrevPart = prevPart;
			prevPart = part;
		}
	}
	
	function checkStaffOrder () {
		var numStaves = curScore.nstaves;
		// **** CHECK STANDARD CHAMBER LAYOUTS FOR CORRECT SCORE ORDER **** //
		// **** ALSO NOTE ANY GRAND STAVES														 **** //
		
		// ** FIRST CHECK THE ORDER OF STAVES IF ONE OF THE INSTRUMENTS IS A GRAND STAFF ** //
		if (numGrandStaves > 0) {
			// CHECK ALL SEXTETS, OR SEPTETS AND LARGER THAT DON"T MIX WINDS & STRINGS
			for (var i = 0; i < numStaves; i++) {
				if (staffVisible[i]) {
					var instrumentType = instrumentIds[i];
					if (instrumentType.includes("strings.")) scoreHasStrings = true;
					if (instrumentType.includes("wind.")) scoreHasWinds = true;
					if (instrumentType.includes("brass.")) scoreHasBrass = true;
				}
			}
			// do we need to check the order of grand staff instruments?
			// only if there are less than 7 parts, or all strings or all winds or only perc + piano
			var checkGrandStaffOrder = (numParts < 7) || ((scoreHasWinds || scoreHasBrass) != scoreHasStrings) || (!(scoreHasWinds || scoreHasBrass) && !scoreHasStrings);
	
			if (checkGrandStaffOrder) {
				for (var i = 0; i < numGrandStaves;i++) {
					var bottomGrandStaffNum = grandStaffTops[i]+1;
					if (bottomGrandStaffNum < numStaves-1) {
						if (!isGrandStaff[bottomGrandStaffNum+1] && staffVisible[bottomGrandStaffNum]) addError("For small ensembles, grand staff instruments should be at the bottom of the score.\nMove ‘"+curScore.staves[bottomGrandStaffNum].part.longName+"’ down using the Instruments tab.","pagetop");
					}
				}
			}
		}
		var numFl = 0;
		var numOb = 0;
		var numCl = 0;
		var numBsn = 0;
		var numHn = 0;
		var numTpt = 0;
		var numTbn = 0;
		var numTba = 0;
		var numVn = 0;
		var numVa = 0;
		var numVc = 0;
		var numDb = 0;
		var flStaff, obStaff, clStaff, bsnStaff, hnStaff;
		var tpt1Staff, tpt2Staff, tbnStaff, tbaStaff;
	
		// Check Quintets
		if (numParts > 3 && numParts < 6) {
			for (var i = 0; i < numStaves; i ++) {
				if (staffVisible[i]) {
					var id = instrumentIds[i];
					if (id.includes("wind.flutes.flute")) {
						numFl ++;
						flStaff = i;
					}
					if (id.includes("wind.reed.oboe") || id.includes("wind.reed.english-horn")) {
						numOb ++;
						obStaff = i;
					}
					if (id.includes("wind.reed.clarinet")) {
						numCl ++;
						clStaff = i;
					}
					if (id.includes("wind.reed.bassoon") || id.includes("wind.reed.contrabassoon")) {
						numBsn ++;
						bsnStaff = i;
					}
					if (id.includes( "brass.french-horn")) {
						numHn ++;
						hnStaff = i;
					}
					if (id.includes( "brass.trumpet")) {
						numTpt ++;
						if (numTpt == 1) tpt1Staff = i;
						if (numTpt == 2) tpt2Staff = i;
					}
					if (id.includes("brass.trombone")) {
						numTbn ++;
						tbnStaff = i;
					}
					if (id.includes ("brass.tuba")) {
						numTba ++;
						tbaStaff = i;
					}
					
					if (id.includes ("strings.violin")) numVn ++;
					if (id.includes ("strings.viola")) numVa ++;
					if (id.includes ("strings.cello")) numVc ++;
					if (id.includes ("strings.contrasbass")) numDb ++;
					
				}
			}
			// **** CHECK WIND QUINTET STAFF ORDER **** //
			if (numParts == 5 && numFl == 1 && numOb == 1 && numCl == 1 && numBsn == 1 && numHn == 1) {
				checkBarlinesConnected("wind quintet");
				if (flStaff != 0) {
					addError("You appear to be composing a wind quintet\nbut the flute should be the top staff.","topfunction ");
				} else {
					if (obStaff != 1) {
						addError("You appear to be composing a wind quintet\nbut the oboe should be the second staff.","pagetop");
					} else {
						if (clStaff != 2) {
							addError("You appear to be composing a wind quintet\nbut the clarinet should be the third staff.","pagetop");
						} else {
							if (hnStaff != 3) {
								addError("You appear to be composing a wind quintet\nbut the horn should be the fourth staff.","pagetop");
							} else {
								if (bsnStaff != 4) addError("You appear to be composing a wind quintet\nbut the bassoon should be the bottom staff.","pagetop");
							}
						}
					}
				}
			}
		
			// **** CHECK BRASS QUINTET STAFF ORDER **** //
			if (numParts == 5 && numTpt == 2 && numHn == 1 && numTbn == 1 && numTba == 1) {
				checkBarlinesConnected("brass quintet");
				if (tpt1Staff != 0) {
					addError("You appear to be composing a brass quintet\nbut the first trumpet should be the top staff.","pagetop");
				} else {
					if (tpt2Staff != 1) {
						addError("You appear to be composing a brass quintet\nbut the second trumpet should be the second staff.","pagetop");
					} else {
						if (hnStaff != 2) {
							addError("You appear to be composing a brass quintet\nbut the horn should be the third staff.","pagetop");
						} else {
							if (tbnStaff != 3) {
								addError("You appear to be composing a brass quintet\nbut the trombone should be the fourth staff.","pagetop");
							} else {
								if (tbaStaff != 4) addError("You appear to be composing a brass quintet\nbut the tuba should be the bottom staff.","pagetop");
							}
						}
					}
				}
			}
			if (numParts == 4 && numVn == 2 && numVa == 1 && numVc == 1) checkBarlinesConnected("string quartet");
			if (numParts == 5 && numVn == 2 && numVa > 0 && numVa < 3 && numVc > 0 && numVc < 3 && numDb < 2) checkBarlinesConnected("string quintet");
		}
	}
	
	function checkStaffNames () {
		var numStaves = curScore.nstaves;
		var staves = curScore.staves;
		var cursor = curScore.newCursor();
		cursor.rewind(Cursor.SCORE_START);

		for (var i = 0; i < numStaves ; i++) {
			var staff1 = staves[i];
			var full1 = staff1.part.longName;
			var short1 = staff1.part.shortName;
			var full1l = full1.toLowerCase();
			var short1l = short1.toLowerCase();
			
			// **** CHECK FOR NON-STANDARD DEFAULT STAFF NAMES **** //
			
			if (full1l === 'violins 1' || full1l === 'violin 1') addError ("Change the long name of staff "+(i+1)+" to ‘Violin I’\n(see Behind Bars, p. 509 & 515)", "system1 "+i);
			if (full1l === 'violas 1' || full1l === 'viola 1') addError ("Change the long name of staff "+(i+1)+" to ‘Viola I’\n(see Behind Bars, p. 509 & 515)", "system1 "+i);
			if (full1l === 'cellos 1' || full1l === 'cello 1') addError ("Change the long name of staff "+(i+1)+" to ‘Cello I’\n(see Behind Bars, p. 509 & 515)", "system1 "+i);
			
			if (full1l === 'violins 2' || full1l === 'violin 2') addError ("Change the long name of staff "+(i+1)+" to ‘Violin II’\n(see Behind Bars, p. 509 & 515)", "system1 "+i);
			if (full1l === 'violas 2' || full1l === 'viola 2') addError ("Change the long name of staff "+(i+1)+" to ‘Viola II’\n(see Behind Bars, p. 509 & 515)", "system1 "+i);
			if (full1l === 'cellos 2' || full1l === 'cello 2') addError ("Change the long name of staff "+(i+1)+" to ‘Cello II’\n(see Behind Bars, p. 509 & 515)", "system1 "+i);
			
			if (full1l === 'violas') addError ("Change the long name of staff "+(i+1)+" to ‘Viola’ (see Behind Bars, p. 509)", "system1 "+i);
			if (full1l === 'violoncellos' || full1l === 'violpncello') addError ("Change the long name of staff "+(i+1)+" to ‘Cello’ (see Behind Bars, p. 509)", "system1 "+i);
			if (full1l === 'contrabasses' || full1 === 'Double basses' || full1l === 'contrabass') addError ("Change the long name of staff "+(i+1)+" to ‘Double Bass’ or ‘D. Bass’ (see Behind Bars, p. 509)", "system1 "+i);
			if (short1l === 'vlns. 1' || short1l === 'vln. 1' || short1l === 'vlns 1' || short1l === 'vln 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vln. I’\n(see Behind Bars, p. 509 & 515)", "system2 "+i);
			if (short1l === 'vlas. 1' || short1l === 'vla. 1' || short1l === 'vlas 1' || short1l === 'vla 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vla. I’\n(see Behind Bars, p. 509 & 515)", "system2 "+i);
			if (short1l === 'vcs. 1' || short1l === 'vc. 1' || short1l === 'vcs 1' || short1l === 'vc 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vc. I’\n(see Behind Bars, p. 509 & 515)", "system2 "+i);
			
			if (short1l === 'vlns. 2' || short1l === 'vln. 2' || short1l === 'vlns 2' || short1l === 'vln 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vln. II’\n(see Behind Bars, p. 509 & 515)", "system2 "+i);
			if (short1l === 'vlas. 2' || short1l === 'vla. 2' || short1l === 'vlas 2' || short1l === 'vla 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vla. II’\n(see Behind Bars, p. 509 & 515)", "system2 "+i);
			if (short1l === 'vcs. 2' || short1l === 'vc. 2' || short1l === 'vcs 2' || short1l === 'vc 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vc. II’\n(see Behind Bars, p. 509 & 515)", "system2 "+i);
			
			if (short1l === 'vlas.') addError ("Change the short name of staff "+(i+1)+" to ‘Vla.’ (see Behind Bars, p. 509)", "system2 "+i);
			if (short1l === 'vcs.') addError ("Change the short name of staff "+(i+1)+" to ‘Vc.’ (see Behind Bars, p. 509)", "system2 "+i);
			if (short1l === 'cbs.' || short1l === 'dbs.' || short1l === 'd.bs.' || short1l === 'cb.') addError ("Change the short name of staff "+(i+1)+" to ‘D.B.’ (see Behind Bars, p. 509)", "system2 "+i);
			
			//logError("Staff "+i+" long = "+full1+" short = "+short1);
			var checkThisStaff = full1 !== "" && short1 !== "" && !isGrandStaff[i] && i < numStaves - 1;
			//logError("Staff "+full1+" check = "+checkThisStaff);
			// **** CHECK FOR REPEATED STAFF NAMES **** //
			if (checkThisStaff) {
				for (var j = i+1; j < numStaves; j++) {
					var staff2 = staves[j];
					var full2 = staff2.part.longName;
					var short2 = staff2.part.shortName;
					//inst2 = staff2.InstrumentName;
					if (fullInstNamesShowing) {
						if (full1 === full2 && full1 != "") addError("Staff name ‘"+full1+"’ appears twice.\nRename one of them, or rename as ‘"+full1+" I’ & ‘"+full1+" II’", "system1 "+i);
						if (full1 === full2 + " I") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" II’?", "system1 "+i);
						if (full2 === full1 + " I") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" II’?", "system1 "+i);
						if (full1 === full2 + " II") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" I’?", "system1 "+i);
						if (full2 === full1 + " II") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" I’?", "system1 "+i);
						if (full1 === full2 + " 1") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" 2’?", "system1 "+i);
						if (full2 === full1 + " 1") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" 2’?", "system1 "+i);
						if (full1 === full2 + " 2") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" 1’?", "system1 "+i);
						if (full2 === full1 + " 2") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" 1’?", "system1 "+i);
					}
					if (shortInstNamesShowing) {
						if (short1 === short2 && short1 != "") addError("Staff name ‘"+short1+"’ appears twice.\nRename one of them, or rename as ‘"+short1+" I’ + ‘"+short2+" II’","system2 "+i);
						if (short1 === short2 + " I") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" II’?","system2 "+i);
						if (short2 === short1 + " I") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" II’?","system2 "+i);
						if (short1 === short2 + " II") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" I’?","system2 "+i);
						if (short2 === short1 + " II") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" I’?","system2 "+i);
						if (short1 === short2 + " 1") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" 2’?","system2 "+i);
						if (short2 === short1 + " 1") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" 2’?","system2 "+i);
						if (short1 === short2 + " 2") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" 1’?","system2 "+i);
						if (short2 === short1 + " 2") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" 1’?","system2 "+i);
					}
				}
			}
		}	
	}
		
	function setInstrumentVariables () {
		
		if (currentInstrumentId != "") {
			isStringInstrument = currentInstrumentId.includes("strings.");
			isStringSection = currentInstrumentId === "strings.group";
			isFlute = currentInstrumentId.includes("wind.flutes");
			isPitchedPercussionInstrument = currentInstrumentId.includes("pitched-percussion") || currentInstrumentId.includes("crotales") || currentInstrumentId.includes("almglocken");
			isUnpitchedPercussionInstrument = false;
			if (!isPitchedPercussionInstrument) isUnpitchedPercussionInstrument = currentInstrumentId.includes("drum.") || currentInstrumentId.includes("effect.") || currentInstrumentId.includes("metal.") || currentInstrumentId.includes("wood.");
			isPercussionInstrument = isPitchedPercussionInstrument || isUnpitchedPercussionInstrument;
			isKeyboardInstrument = currentInstrumentId.includes("keyboard");
			isPedalInstrument = currentInstrumentId.includes("piano") || currentInstrumentId.includes("vibraphone");
			isWindOrBrassInstrument = currentInstrumentId.includes("wind.") || currentInstrumentId.includes("brass.");
			isHorn = currentInstrumentId === "brass.french-horn";
			isHarp = currentInstrumentId === "pluck.harp";
			isVoice = currentInstrumentId.includes("voice.");
			isCello = currentInstrumentId.includes("cello");
			checkClefs = false;
			reads8va = false;
			readsTreble = true;
			readsAlto = false;
			readsTenor = false;
			readsBass = false;
			checkClefs = false;

			//logError("Inst check id "+currentInstrumentId+" isString "+isStringInstrument+" isVoice "+isVoice);
			// WINDS
			if (currentInstrumentId.includes("wind.")) {
				// Bassoon is the only wind instrument that reads bass and tenor clef
				if (currentInstrumentId.includes("bassoon")) {
					readsTreble = false;
					readsTenor = true;
					readsBass = true;
					checkClefs = true;
				} else {
					checkClefs = true;
				}
			}
			// BRASS
			if (currentInstrumentId.includes("brass.")) {
				if (currentInstrumentId.includes("french-horn")) {
					readsBass = true;
					checkClefs = true;
				}
				if (currentInstrumentId.includes("trumpet")) checkClefs = true;
				if (currentInstrumentId.includes("trombone") || currentInstrumentId.includes("tuba") || currentInstrumentId.includes("sousaphone")) {
					if (currentInstrumentId.includes("alto") > 0) {
						readsAlto = true;
						checkClefs = true;
					} else {
						readsTenor = true;
						readsBass = true;
						checkClefs = true;
					}
				}
				if (currentInstrumentId.includes("euphonium")) {
					readsBass = true;
					checkClefs = true;
				}
			}
			
			// STRINGS, HARP, PERCUSSION
			if (currentInstrumentId.includes("keyboard") || currentInstrumentId.includes("pluck.harp") || currentInstrumentId.includes(".marimba")) {
				readsBass = true;
				reads8va = true;
				checkClefs = true;
			}
			if (currentInstrumentId.includes("timpani")) {
				readsBass = true;
				checkClefs = true;
			}
		
			// STRINGS
			if (currentInstrumentId.includes("strings.")) {
				if (currentInstrumentId.includes("violin") || currentInstrumentName.toLowerCase().includes("violin")) {
					checkClefs = true;
					reads8va = true;
				}
				if (currentInstrumentId.includes("viola") || currentInstrumentName.toLowerCase().includes("viola")) {
					readsAlto = true;
					checkClefs = true;
				}
				if (currentInstrumentId.includes("cello") || currentInstrumentId.includes("contrabass") || currentInstrumentName.toLowerCase().includes("cello") || currentInstrumentName.toLowerCase().includes("contrabass") || currentInstrumentName.toLowerCase().includes("double bass")) {
					readsTenor = true;
					readsBass = true;
					checkClefs = true;
				}
			}
			
			// VOICE
			if (isVoice) {
				if (currentInstrumentId.includes("bass") || currentInstrumentId.includes("baritone") || currentInstrumentId.includes(".male")) {
					readsBass = true;
					checkClefs = true;
				}
			}
		}
	}
	
	function checkScoreAndPageSettings () {
		var styleComments = [];
		var pageSettingsComments = [];
		var style = curScore.style;
		var numStaves = curScore.nstaves;
		var staffSpacing = style.value("staffDistance");		
		var akkoladeDistance = style.value("akkoladeDistance");
		var minSystemDistance = style.value("minSystemDistance");
		var maxSystemDistance = style.value("maxSystemDistance");
		var minSystemSpread = style.value("minSystemSpread");
		var maxSystemSpread = style.value("maxSystemSpread");
		var enableVerticalSpread = style.value("enableVerticalSpread");
				
		var inchesToMM = 25.4;
		var spatiumDPI = 360.;
		var spatium = style.value("spatium")*inchesToMM/spatiumDPI; // spatium value is given in 360 DPI
		var staffSize = spatium*4;
		//errorMsg+= "\nspatium = "+spatium+"; staffSize = "+staffSize;
		var staffLineWidth = Math.round(style.value("staffLineWidth")*inchesToMM*100)/100.;
		var pageEvenLeftMargin = Math.round(style.value("pageEvenLeftMargin")*inchesToMM*100)/100.;
		var pageOddLeftMargin = Math.round(style.value("pageOddLeftMargin")*inchesToMM*100)/100.;
		var pageEvenTopMargin = Math.round(style.value("pageEvenTopMargin")*inchesToMM*100)/100.;
		var pageOddTopMargin = Math.round(style.value("pageOddTopMargin")*inchesToMM*100)/100.;
		var pageEvenBottomMargin = Math.round(style.value("pageEvenBottomMargin")*inchesToMM*100)/100.;
		var pageOddBottomMargin = Math.round(style.value("pageOddBottomMargin")*inchesToMM*100)/100.;
		var pagePrintableWidth = Math.round(style.value("pagePrintableWidth")*inchesToMM);
		var pagePrintableHeight = Math.round(style.value("pagePrintableHeight")*inchesToMM);
		var pageEvenRightMargin = pageWidth - pagePrintableWidth - pageEvenLeftMargin;
		var pageOddRightMargin = pageWidth - pagePrintableWidth - pageOddLeftMargin;
		var tupletsFontFace = style.value("tupletFontFace");
		var tupletsFontStyle = style.value("tupletFontStyle");
		var barlineWidth = style.value("barWidth");
		var minimumBarWidth = style.value("minMeasureWidth");
		var spacingRatio = style.value("measureSpacing");
		var slurEndWidth = style.value("slurEndWidth");
		var slurMidWidth = style.value("slurMidWidth");
		var showFirstBarNum = style.value("showMeasureNumberOne");
		var minNoteDistance = style.value("minNoteDistance");
		var staffLineSize = style.value("staffLineWidth");
		
		//logError("slurEndWidth = "+slurEndWidth+"; slurMidWidth = "+slurMidWidth);
		//logError("pageWidth = "+pageWidth+"; pageHeight = "+pageHeight);
		
		// ** CHECK FOR PAGE SETTING ISSUES ** //
		
		// **** CHECK PAPER SIZE is either A4 or A3 **** //
		if ((pageWidth != 210 && pageHeight != 297) && (pageWidth != 297 && pageHeight != 210) && (pageWidth != 297 && pageHeight != 420)) {
			pageSettingsComments.push("The page size is non-standard: set it to A4, unless otherwise requested");
		}
		
		// **** TEST 1A: CHECK MARGINS ****
		var minLRMargin = 10;
		var maxLRMargin = 18;
		var minTBMargin = 10;
		var maxTBMargin = 18;
		
		//logError("pageEvenTopMargin = "+pageEvenTopMargin+"; pageOddTopMargin = "+pageOddTopMargin+"; pageEvenBottomMargin = "+pageEvenBottomMargin+"; pageOddBottomMargin = "+pageOddBottomMargin);
		if ((pageEvenLeftMargin < minLRMargin) + (pageOddLeftMargin < minLRMargin) + (pageEvenRightMargin < minLRMargin) + (pageOddRightMargin < minLRMargin)) pageSettingsComments.push("Increase your left and right margins to "+minLRMargin+"mm");
		if ((pageEvenTopMargin < minTBMargin) + (pageOddTopMargin < minTBMargin) + (pageEvenBottomMargin < minTBMargin) + (pageOddBottomMargin < minTBMargin)) pageSettingsComments.push("Increase your top and bottom margins to "+minTBMargin+"mm");
		if ((pageEvenLeftMargin > maxLRMargin) + (pageOddLeftMargin > maxLRMargin) + (pageEvenRightMargin > maxLRMargin) + (pageOddRightMargin > maxLRMargin)) pageSettingsComments.push("Decrease your left and right margins to "+maxLRMargin+"mm");
		if ((pageEvenTopMargin > maxTBMargin) + (pageOddTopMargin > maxTBMargin) + (pageEvenBottomMargin > maxTBMargin) + (pageOddBottomMargin > maxTBMargin)) pageSettingsComments.push("Decrease your top and bottom margins to "+maxTBMargin+"mm");

		
		// **** TEST 1B: CHECK STAFF SIZE ****
		var maxSize = 6.8;
		var minSize = 6.5;
		if (numStaves == 2) {
			maxSize = 6.7;
			minSize = 6.2;
		}
		if (numStaves == 3) {
			maxSize = 6.5;
			minSize = 5.4;
		}
		if (numStaves > 3 && numStaves < 8) {
			maxSize = 6.5 - ((numStaves - 3) * 0.1);
			minSize = 5.4 - ((numStaves - 3) * 0.1);
		}
		if (numStaves > 7) {
			maxSize = 5.4;
			minSize = 3.7;
		}
		
		if (staffSize > maxSize) pageSettingsComments.push("Decrease the stave space to within the range "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
		if (staffSize < minSize) {
			if (staffSize < 3.7) {
				if (staffSize < minSize) pageSettingsComments.push("The staff size is very small.\nIncrease the stave space to at least 0.92mm");
			} else {
				pageSettingsComments.push("Increase the stave space to be in the range "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
			}
		}
				
		// ** CHECK FOR STAFF NAMES ** //
		isSoloScore = (numParts == 1);
		//logError("firstStaffNameShouldBeHidden = "+firstStaffNameShouldBeHidden);
		
		var subsequentStaffNamesShouldBeHidden = numParts < 6;
		
		// **** STYLE SETTINGS — 1. SCORE TAB **** //
		
		// ** staff line thickness ** //
		if (staffLineSize != 0.1) styleComments.push("(Score tab) Set ‘Stave line thickness’ to 0.1sp");
		
		// ** are the first staff names visible? ** //
		var firstStaffNamesVisibleSetting = style.value("firstSystemInstNameVisibility"); //  0 = long names, 1 = short names, 2 = hidden
		var firstStaffNamesVisible = firstStaffNamesVisibleSetting < 2;
		
		var hideInstrumentNameForSolo = isSoloScore && style.value("hideInstrumentNameIfOneInstrument");
		var blankStaffNames = [];
		if (!hideInstrumentNameForSolo && firstStaffNamesVisible) {
			for (var i = 0; i < numParts; i++) {
				var partName;
				if (firstStaffNamesVisibleSetting == 0) {
					partName = parts[i].longName;
				} else {
					partName = parts[i].shortName;
				}
				if (partName === "") {
					for (var j = 0; j < numStaves; j++) {
						if (curScore.staves[j].part.is(parts[i])) {
							blankStaffNames.push(j);
							break;
						}
					}
				}
			}
			if (blankStaffNames.length == numParts) {
				firstStaffNamesVisible = false;
			} else {
				for (var i = 0; i < blankStaffNames.length; i++) {
					addError ("Staff "+(blankStaffNames[i]+1)+" has no staff name.","system1 "+i);
				}
			}
		}
		
		// ** are the subsequent staff names visible? ** //
		if (isSoloScore && !hideInstrumentNameForSolo) styleComments.push("(Score tab) Tick ‘Hide if there is only one instrument’");
		if (!isSoloScore && firstStaffNamesVisibleSetting != 0) styleComments.push("(Score tab) Set Instrument names→On first system of sections to ‘Long name’.");
		var subsequentStaffNamesVisibleSetting = style.value("subsSystemInstNameVisibility");  //  0 = long names, 1 = short names, 2 = hidden
		var subsequentStaffNamesVisible = subsequentStaffNamesVisibleSetting < 2;
		if (!hideInstrumentNameForSolo && subsequentStaffNamesVisible) {
			blankStaffNames = [];
			for (var i = 0; i < numParts; i++) {
				var partName;
				if (subsequentStaffNamesVisibleSetting == 0) {
					partName = parts[i].longName;
				} else {
					partName = parts[i].shortName;
				}
				if (partName === "") {
					for (var j = 0; j < numStaves; j++) {
						if (curScore.staves[j].part.is(parts[i])) {
							blankStaffNames.push(j);
							break;
						}
					}
				}
			}
			if (blankStaffNames.length == numParts) {
				subsequentStaffNamesVisible = false;
			} else {
				for (var i = 0; i < blankStaffNames.length; i++) {
					addError ("Staff "+(blankStaffNames[i]+1)+" has no staff name.","system2 "+i);
				}
			}
		}
		fullInstNamesShowing = (firstStaffNamesVisible && firstStaffNamesVisibleSetting == 0) || (subsequentStaffNamesVisible && subsequentStaffNamesVisibleSetting == 0);
		shortInstNamesShowing =  (firstStaffNamesVisible && firstStaffNamesVisibleSetting == 1) || (subsequentStaffNamesVisible && subsequentStaffNamesVisibleSetting == 1);
		
		if (subsequentStaffNamesShouldBeHidden) {
			if (subsequentStaffNamesVisible) styleComments.push("(Score tab) Switch Instrument names→On subsequent systems to ‘Hide’ for a small ensemble");
		} else {
			if (!subsequentStaffNamesVisible) styleComments.push("(Score tab) Switch Instrument names→On subsequent systems to ‘Short name’ for a large ensemble");
		}
		
		// **** STYLE SETTINGS — 2. PAGE TAB **** //
		// **** 1D: CHECK SYSTEM SPACING
		if (hasMoreThanOneSystem) {
			if (enableVerticalSpread) {
				if (minSystemSpread < 12) styleComments.push("(Page tab) Increase the ‘Min. system distance’ to at least 12");
				if (minSystemSpread > 16) styleComments.push("(Page tab) Decrease the ‘Min. system distance’ to no more than 16");
				if (maxSystemSpread < 12) styleComments.push("(Page tab) Increase the ‘Max. system distance’ to at least 12");
				if (maxSystemSpread > 16) styleComments.push("(Page tab) Decrease the ‘Max. system distance’ to no more than 16");
			} else {
				if (minSystemDistance < 12) styleComments.push("(Page tab) Increase the ‘Min. system distance’ to at least 12");
				if (minSystemDistance > 16) styleComments.push("(Page tab) Decrease the ‘Min. system distance’ to no more than 16");
				if (maxSystemDistance < 12) styleComments.push("(Page tab) Increase the ‘Max. system distance’ to at least 12");
				if (maxSystemDistance > 16) styleComments.push("(Page tab) Decrease the ‘Max. system distance’ to no more than 16");
			}

		}
		
		// **** STYLE SETTINGS — 4. BAR NUMBERS TAB **** //
		if (showFirstBarNum) styleComments.push("(Bar numbers tab) Uncheck ‘Show first’");
		
		// **** STYLE SETTINGS — 9. BARS TAB **** //
		if (minimumBarWidth < 14.0) styleComments.push("(Bars tab) Set ‘Minimum bar width’ to 14.0sp");
		if (spacingRatio != 1.5) styleComments.push("(Bars tab) Set ‘Spacing Ratio’ to 1.5sp");
		if (minNoteDistance < 0.8 ) styleComments.push("(Bars tab) Set ‘Minimum note distance’ to at least 0.8sp");
		if (minNoteDistance > 1.0 ) styleComments.push("(Bars tab) Set ‘Minimum note distance’ to no more than 1.0sp");
		
		// **** STYLE SETTINGS — 10. BARLINES TAB **** //
		if (barlineWidth != 0.16) styleComments.push("(Barlines tab) Set ‘Thin barline thickness’ to 0.16sp");
		
		// **** STYLE SETTINGS — 17. SLURS & TIES **** //
		if (slurEndWidth != 0.06) styleComments.push("(Slurs &amp; Ties tab) Set ‘Slurs→Line thickness at end’ to 0.06sp");
		if (slurMidWidth != 0.16) styleComments.push("(Slurs &amp; Ties tab) Set ‘Slurs→Line thickness middle’ to 0.16sp");
		
		// **** STYLE SETTINGS — 6. TEXT STYLES TAB **** //
		//errorMsg += "tupletsFontFace = "+tupletsFontFace+" tupletsFontStyle = "+tupletsFontStyle;
		if (tupletsFontFace !== "Times New Roman" || tupletsFontStyle != 2) styleComments.push("(Text Styles→Tuplet) Use Times New Roman italic for tuplets");
		
		// ** OTHER STYLE ISSUES ** //
		
		// ** POST STYLE COMMENTS
		if (styleComments.length>0) {
			var styleCommentsStr = "";
			if (styleComments.length == 1) {
				styleCommentsStr = "The following change to the score’s Style settings (Format→Style…) is recommended\n(though may not be suitable for all scenarios or style guides):\n— "+styleComments[0];
			} else {
				var theList = styleComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				styleCommentsStr = "The following changes to the score’s Style settings (Format→Style…) are recommended\n(though may not be suitable for all scenarios or style guides):\n"+theList;
			}
			addError(styleCommentsStr,"pagetop");
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments.length > 0) {
			var pageSettingsCommentsStr = "";
			if (pageSettingsComments.length == 1) {	
				pageSettingsCommentsStr = "The following change to the score’s Page Settings (Format→Page settings…) is recommended\n(though may not be suitable for all scenarios or style guides):\n— "+pageSettingsComments[0];
			} else {
				var theList = pageSettingsComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				pageSettingsCommentsStr = "The following changes to the score’s Page Settings (Format→Page settings…) is recommended\n(though may not be suitable for all scenarios or style guides):\n"+theList;
			}
			addError(pageSettingsCommentsStr,"pagetop");
		}
	}
	
	function checkLocationOfFinalBar () {
		var maxDistance = 25;
		var lastMeasure = curScore.lastMeasure;
		var loc = lastMeasure.pagePos;
		var rect = lastMeasure.bbox;
		var l = Math.round(loc.x*spatium);
		var t = Math.round(loc.y*spatium);
		var r = Math.round((loc.x + rect.width) * spatium);
		var b = Math.round((loc.y + rect.height) * spatium);
		var thresholdr = pageWidth - maxDistance;
		var thresholdb = pageHeight - maxDistance;
		//logError ("Last measure rect is {"+l+" "+t+" "+r+" "+b+"}");
		//logError ("Borders: "+(thresholdr)+" "+(thresholdb));
		if (r < thresholdr || b < thresholdb ) {
		//	logError("Adding comment");
			addError("Try and arrange the layout so that the final bar is\nin the bottom right-hand corner of the last page.",lastMeasure);
		}
	}
	
	function checkHairpinTermination () {
		var beatLength = (currentTimeSig.denominator == 8 && !(currentTimeSig.numerator % 3)) ? (1.5 * division) : division;
		var hairpinZoneEndTick = currentHairpinEnd + beatLength; // allow a terminating dynamic within a beat of the end of the hairpin
		for (var i=0;i<dynamics[currentStaffNum].length;i++) {
			var theTick = dynamics[currentStaffNum][i];
			if (theTick >= currentHairpinEnd && theTick <= currentHairpinEnd  + beatLength) return;
		}
		addError ("Hairpin should have a dynamic at the end, or\nend should be closer to the next dynamic.",currentHairpin);
	}
	
	function checkInstrumentalTechniques (textObject, plainText, lowerCaseText, barNum) {
		var isBracketed = false; // TO FIX
		
		if (isWindOrBrassInstrument) {
			if (lowerCaseText.includes("tutti")) {
				addError("Don’t use ‘Tutti’ for winds and brass;\nwrite ‘a 2’/‘a 3’ etc. instead",textObject);
			}
			if (lowerCaseText.includes("unis.")) {
				addError("Don’t use ‘unis.’ for winds and brass;\nwrite ‘a 2’/‘a 3’ etc. instead",textObject);
			}
			if (lowerCaseText.includes("div.")) {
				addError("Don’t use ‘div.’ for winds and brass.",textObject);
			}
			
			if (lowerCaseText.substring(0,3) === "flz") {
				// check trem
				if (!isTrem) {
					addError ("Fluttertongue notes should also have tremolo lines through the stem.",textObject)
				}
			}
		}
		if (isStringInstrument) {
			
			//errorMsg += "IsString: checking "+lowerCaseText;
			// **** CHECK INCORRECT 'A 2 / A 3' MARKINGS **** //
			if (lowerCaseText === "a 2" || lowerCaseText === "a 3") {
				addError("Don’t use ‘"+lowerCaseText+"’ for strings; write ‘unis.’ etc. instead",textObject);
				return;
			}
			
			// **** CHECK ALREADY PLAYING ORD. **** .//
			if (lowerCaseText.substring(0,4) === "ord." || lowerCaseText === "pos. nat.") {
				if (currentContactPoint === "ord" && (currentPlayingTechnique === "arco" || currentPlayingTechnique === "pizz")) {
					addError("Instrument is already playing ord?",textObject);
				} else {
					currentContactPoint = "ord";
				}
			}

			// **** CHECK ALREADY PLAYING FLAUT **** //
			if (lowerCaseText.includes("flaut")) {
				if (currentContactPoint === "flaut") {
					if (!isBracketed) {
						addError("Instrument is already playing flautando?",textObject);
					}
				} else {
					currentContactPoint = "flaut";
				}
			}
		
			// **** CHECK ALREADY MUTED **** //
			if (lowerCaseText.includes("mute") || lowerCaseText.includes("damp")) {
				if (currentContactPoint === "mute") {
					if (!isBracketed) {
						addError("Instrument is already playing muted?",textObject);
					}
				} else {
					currentContactPoint = "mute";
				}
			}
		
			// **** CHECK ALREADY PLAYING SUL PONT **** //
			if (lowerCaseText.includes("pont.") || lowerCaseText === "s.p." || lowerCaseText === "p.s.p" || lowerCaseText === "psp" || lowerCaseText.includes("msp")) {
				if (lowerCaseText === "poco sul pont." || lowerCaseText === "p.s.p" || lowerCaseText === "psp") {
					if (currentContactPoint === "psp") {
						if (!isBracketed) {
							addError("Instrument is already playing poco sul pont?",textObject);
							return;
						}
					} else {
						currentContactPoint = "psp";
					}
				} else {
					if (lowerCaseText.includes("molto sul pont") || lowerCaseText.includes("m.s.p") || lowerCaseText.includes("msp")) {
						if (currentContactPoint === "msp") {
							if (!isBracketed) {
								addError("Instrument is already playing molto sul pont?",textObject);
								return;
							}
						} else {
							currentContactPoint = "msp";
						}
					} else {
						if (currentContactPoint === "sp") {
							if (!isBracketed) {
								addError("Instrument is already playing sul pont?",textObject);
								return;
							}
						} else {
							currentContactPoint = "sp";
						}
					}
				}
			}
		
			// **** CHECK ALREADY PLAYING SUL TASTO **** //
			if (lowerCaseText.includes("tasto") || lowerCaseText === "s.t." || lowerCaseText.includes("pst") || lowerCaseText.includes("mst")) {
				if (lowerCaseText.includes("poco sul tasto") || lowerCaseText === "p.s.t" || lowerCaseText.includes("pst")) {
					if (currentContactPoint === "pst") {
						if (!isBracketed) {
							addError("Instrument is already playing poco sul tasto?",textObject);
						}
					} else {
						currentContactPoint = "pst";
					}
				} else {
					if (lowerCaseText.includes("molto sul tasto") || lowerCaseText.includes("m.s.t") || lowerCaseText.includes("mst")) {
						if (currentContactPoint === "mst") {
							if (!isBracketed) {
								addError("Instrument is already playing molto sul tasto?",textObject);
							}
						} else {
							currentContactPoint = "mst";
						}
					} else {
						if (currentContactPoint === "st") {
							if (!isBracketed) {
								addError("Instrument is already playing sul tasto?",textObject);
							}
						} else {
							currentContactPoint = "st";
						}
					}
				}
			}
		
			// **** CHECK ALREADY PLAYING ARCO **** //
			if (lowerCaseText.includes("arco") && !lowerCaseText.includes("senza arco")) {
				if (currentPlayingTechnique === "arco") {
					if (!isBracketed) {
						addError("Instrument is already playing arco?",textObject);
					}
				} else {
					currentPlayingTechnique = "arco";
				}
			}
			
			// **** CHECK ALREADY PLAYING PIZZ **** //
			if (lowerCaseText.includes("pizz")) {
				if (currentPlayingTechnique === "pizz") {
					if (!isBracketed) {
						addError("Instrument is already playing pizz?",textObject);
					}
				} else {
					currentPlayingTechnique = "pizz";
					var pizzStartedInThisBar = true; // TO FIX
				}
			}
			
			// **** CHECK HAMMER ON **** //
			if (lowerCaseText.includes("senza arco") || lowerCaseText.includes("hammer")) {
				 if (currentPlayingTechnique === "hammer") {
					if (!isBracketed) {
						addError("Instrument is already playing senza arco?",textObject);
					}
				} else {
					currentPlayingTechnique = "hammer";
				}
			}
			
			// **** CHECK COL LEGNO BATT & TRATTO **** //
			if (lowerCaseText.includes("col legno")) {
				if (lowerCaseText.includes("batt")) {
					if (currentPlayingTechnique === "clb") {
						if (!isBracketed) {
							addError("Instrument is already playing col legno battuto?",textObject);
						}
					} else {
						currentPlayingTechnique = "clb";
					}
				} else {
					if (lowerCaseText.includes("tratto")) {
						if (currentPlayingTechnique === "clt") {
							if (!isBracketed) {
								addError("Instrument is already playing col legno tratto?",textObject);
							}
						} else {
							currentPlayingTechnique = "clt";
						}
					} else {
						addError("You should specify if this is\ncol legno batt. or col legno tratto",textObject);
						currentPlayingTechnique = "cl";
						return;
					}
				}
			}
				
			// **** CHECK ALREADY PLAYING ON THE BRIDGE **** //
			if (lowerCaseText.includes("otb") || lowerCaseText.includes("o.t.b") ||
			(lowerCaseText.includes("bridge") && lowerCaseText.includes("on "))) {
				if (currentContactPoint === "on bridge") {
					if (!isBracketed) {
						addError("Instrument is already playing on the bridge?",textObject);
					}
				} else {
					currentContactPoint = "on bridge";
				}
			}
					
			// **** CHECK ALREADY PLAYING BEYOND THE BRIDGE **** //
			if (lowerCaseText.includes("btb") || lowerCaseText.includes("b.t.b") ||
			(lowerCaseText.includes("bridge") && (lowerCaseText.includes("beyond") || lowerCaseText.includes("past") || lowerCaseText.includes("wrong side")))) {
				if (currentContactPoint === "beyond bridge") {
					if (!isBracketed) {
						addError("Instrument is already playing beyond the bridge?",textObject);
					}
				} else {
					currentContactPoint = "beyond bridge";
				}
			}
		} // end isStringInstrument
		
		// **** CHECK ALREADY PLAYING MUTED **** //
		if (lowerCaseText.includes("con sord")) {
			if (currentMute === "con") {
				if (!isBracketed) {
					addError("Instrument is already muted?",textObject);
				}
			} else {
				currentMute = "con";
			}
		}
		
		// **** CHECK ALREADY PLAYING SENZA SORD **** //
		if (lowerCaseText.includes("senza sord")) {
			if (currentMute === "senza") {
				if (!isBracketed) {
					addError("Instrument is already unmuted?",textObject);
				}
			} else {
				currentMute = "senza";
			}
		}

	}
	
	function checkClef (clef) {
		var clefId = clef.subtypeName();
		//logError("Checking clef — "+clefId+" prevClefId is "+prevClefId);
		isTrebleClef = clefId.includes("Treble clef");
		isAltoClef = clefId === "Alto clef";
		isTenorClef = clefId === "Tenor clef";
		isBassClef = clefId.includes("Bass clef");
		isPercClef = clefId === "Percussion";
		clefIs8va = clefId.includes("8va alta");
		clefIs15ma = clefId.includes("15ma alta");
		clefIs8ba = clefId.includes("8va bassa");
		diatonicPitchOfMiddleLine = 41; // B4 = 41 in diatonic pitch notation (where C4 = 35)
		if (isAltoClef) diatonicPitchOfMiddleLine = 35; // C4 = 35
		if (isTenorClef) diatonicPitchOfMiddleLine = 33; // A3 = 33
		if (isBassClef) diatonicPitchOfMiddleLine = 29; // D3 = 29
		if (clefIs8va) diatonicPitchOfMiddleLine += 7;
		if (clefIs15ma) diatonicPitchOfMiddleLine += 14;
		if (clefIs8ba) diatonicPitchOfMiddleLine -= 7;
		
		// **** CHECK FOR INAPPROPRIATE CLEFS **** //
		if (checkClefs) {
			if (isTrebleClef && !readsTreble) addError(currentInstrumentName+" doesn’t read treble clef",clef);
			if (isAltoClef && !readsAlto) addError(currentInstrumentName+" doesn’t read alto clef",clef);
			if (isTenorClef && !readsTenor) addError(currentInstrumentName+" doesn’t read tenor clef",clef);
			if (isBassClef && !readsBass) addError(currentInstrumentName+" doesn’t read bass clef",clef);
		}
		
		// **** CHECK FOR REDUNDANT CLEFS **** //
		if (clefId === prevClefId) addError("This clef is redundant: already was "+clefId.toLowerCase()+"\nIt can be safely deleted",clef);
		prevClefId = clefId;
	}
	
	function checkOttava (noteRest,ottava) {
		if (flaggedOttavaIssue) return;
		if (ottava == null) {
			logError("checkOttava() — ottava is null!");
			return;
		}
		var k8va = 0, k15ma = 2;
		var ottavaArray = ["8va","8ba","15ma","15mb"];
		var ottavaStr = ottavaArray[ottava.ottavaType]; 
		//logError("Found OTTAVA: "+ottava.subtypeName()+" "+ottava.ottavaType);
		if (!reads8va) {
			addError("This instrument does not normally read "+ottavaStr+" lines.\nIt’s best to write the note(s) out at pitch.",ottava);
			flaggedOttavaIssue = true;
			
		} else {
			if (ottava.ottavaType == k8va || ottava.ottavaType == k15ma) {
				//logError("Checking 8va — "+isAltoClef);
				if (isAltoClef) {
					addError("Never use "+ottavaStr+" in alto clef.\nChange to treble clef instead.",ottava);
					flaggedOttavaIssue = true;
				}
				if (isPercClef) {
					addError("Never use "+ottavaStr+" in percussion clef.",ottava);
					flaggedOttavaIssue = true;
				}
				if (isBassClef) {
					addError("Never use "+ottavaStr+" in bass clef.\nChange to tenor or treble clef instead.",ottava);
					flaggedOttavaIssue = true;
				}
				if (isTenorClef) {
					addError("Never use "+ottavaStr+" in tenor clef.\nChange to treble clef instead.",ottava);
					flaggedOttavaIssue = true;
				}
			} else {

				//logError("Checking 8vb — "+isTrebleClef);
				if (isTrebleClef) {
					if (readsBass) {
						addError("Never use "+ottavaStr+" in treble clef.\nChange to bass clef instead.",ottava);
						flaggedOttavaIssue = true;
					} else {
						addError("Never use "+ottavaStr+" in treble clef.",ottava);
						flaggedOttavaIssue = true;
					}
				}
				if (isAltoClef) {
					addError("Never write "+ottavaStr+" in alto clef.",ottava);
					flaggedOttavaIssue = true;
				}
				if (isTenorClef) {
					addError("Never use "+ottavaStr+" in tenor clef.\nChange to bass clef instead.",ottava);
					flaggedOttavaIssue = true;
				}
				if (isPercClef) {
					addError(errors,"Never write "+ottavaStr+" in percussion clef.",ottava);
					flaggedOttavaIssue = true;
				}
			}
		}
	}
	
	function checkScoreText() {
		curScore.startCmd();
		cmd("title-text");
		var titleText = curScore.selection.elements[0];
		
		cmd("select-similar");
		
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			if (!e.is(titleText)) checkTextObject (e, null);
		}
		curScore.endCmd(true); // undo
		
		selectAll();
		
		// **** CHECK ANY STAFF-ATTACHED TEMPO TEXT **** //
		for (var i = 0; i < tempoText.length; i++) {
			var t = tempoText[i];
			var m = t.parent.parent;
			var barNum = 1;
			var tempm = curScore.firstMeasure;
			while (!tempm.is(m)) {
				tempm = tempm.nextMeasure;
				barNum ++;
			}
			checkTextObject (t, barNum);
		}
	}
	
	function checkTextObject (textObject,barNum) {
		
		if (!textObject.visible) return;
		
		var windAndBrassMarkings = ["1.","2.","3.","4.","5.","6.","7.","8.","a 2","a 3","a 4","a 5","a 6","a 7","a 8","solo","1. solo","2. solo","3. solo","4. solo","5. solo","6. solo","7. solo","8. solo"];
		var replacements = ["accidentalNatural","n","accidentalSharp","#","accidentalFlat","b","metNoteHalfUp","h","metNoteQuarterUp","q","metNote8thUp","e","metNote16thUp","s","metAugmentationDot",".","dynamicForte","f","dynamicMezzo","m","dynamicPiano","p","dynamicRinforzando","r","dynamicSubito","s","dynamicSforzando","s","dynamicZ","z"];
		var eType = textObject.type;
		var eSubtype = textObject.subtypeName();
		var eName = textObject.name;
		var styledText = textObject.text;
		if (eType == Element.REHEARSAL_MARK) checkRehearsalMark (textObject);
						
		// ** CHECK IT'S NOT A COMMENT WE'VE ADDED ** //
		if (!Qt.colorEqual(textObject.frameBgColor,"yellow") || !Qt.colorEqual(textObject.frameFgColor,"black")) {	
			var textStyle = textObject.subStyle;
			var tn = textObject.name.toLowerCase();
			//logError(;
			var plainText = styledText.replace(/<[^>]+>/g, "");
			
			if (typeof plainText != 'string') errorMsg += '\nTypeof plainText not string: '+(typeof plainText);
			for (var i = 0; i < replacements.length; i += 2) {
				plainText = plainText.replace(replacements[i],replacements[i+1]);
			}
			var lowerCaseText = plainText.toLowerCase();
			//logError("Text style is "+textStyle+"); subtype = "+eSubtype+"; styledtext = "+styledText+"; lowerCaseText = "+lowerCaseText);
			
			if (lowerCaseText != '') {
				var len = plainText.length;
				var isVisible = textObject.visible;
				
				// ** CHECK TITLE ** //
				if (eSubtype === "Title") {
					if (plainText === 'Untitled score') addError( "You have not changed the default title text",textObject);
				}
				
				// ** CHECK SUBTITLE ** //
				if (eSubtype === "Subtitle") {
					if (plainText === 'Subtitle') addError( "You have not changed the default subtitle text",textObject);
					if (plainText.substring(0,4) === 'For ') addError( "In the subtitle, make the ‘f’ in ‘for’ lower-case",textObject);
				}
				
				// ** CHECK COMPOSER ** //
				if (eSubtype === "Composer") {
					if (plainText === 'Composer / arranger') addError( "You have not changed the default composer text",textObject);
				}
			
				// **** CHECK FOR STRAIGHT QUOTES THAT SHOULD BE CURLY **** //
				if (lowerCaseText.includes("'")) {
					addError("This text has a straight single quote mark in it (').\nChange to curly: ‘ or ’.",textObject);
					return;
				}
				if (lowerCaseText.includes('\"')) {
					addError('This text has a straight double quote mark in it (").\nChange to curly: “ or ”.',textObject);
					return;
				}
				
				// **** CHECK FOR TEXT STARTING WITH SPACE OR NON-ALPHANUMERIC **** //
				if (plainText.charCodeAt(0) == 32) {
					addError("‘"+plainText+"’ begins with a space, which could be deleted.",textObject);
					return;
				}
				if (plainText.charCodeAt(0) < 32) {
					addError("‘"+plainText+"’ does not seem to begin with a letter: is that correct?",textObject);
					return;
				}
			
				// **** CHECK COMMON SPELLING ERRORS & ABBREVIATIONS **** //
				//logError("Checking spelling of "+lowerCaseText);
				var isSpellingError = false;
				for (var i = 0; i < spellingerrorsatstart.length / 2; i++) {
					var spellingError = spellingerrorsatstart[i*2];
					if (lowerCaseText.substring(0,spellingError.length) === spellingError) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsatstart[i*2+1];
						var diff = plainText.length-spellingError.length;
						var correctText = '';
						if (diff > 0) {
							correctText = correctSpelling+plainText.substring(spellingError.length);
							//logError("correctSpelling = "+correctSpelling+" splength="+spellingError.length+" plength="+plainText.length+" diff="+diff+" correct="+correctText);
						} else {
							correctText = correctSpelling;
						}
						//logError("styledText = "+styledText+" plainText = "+plainText);
						addError("‘"+plainText+"’ is misspelled;\nit should be ‘"+correctText+"’.",textObject);
						return;
					}
				}
				// **** CHECK TEXT WITH SPELLING ERRORS ANY WHERE **** //
				if (!isSpellingError) {
					var correctText = plainText;
					for (var i = 0; i < spellingerrorsanywhere.length / 2; i++) {
						var spellingError = spellingerrorsanywhere[i*2];
						if (correctText.includes(spellingError)) {
							isSpellingError = true;
							var correctSpelling = spellingerrorsanywhere[i*2+1];
							correctText = correctText.replace(spellingError,correctSpelling);
						}
					}
					if (isSpellingError) addError("‘"+plainText+"’ is misspelled;\nit should be ‘"+correctText+"’.",textObject);
				}
				
				// **** CHECK ONLY STAFF/SYSTEM TEXT (IGNORE TITLE/SUBTITLE ETC) **** //
				if (barNum != null) {
					
					// **** CHECK WHETHER INITIAL TEMPO MARKING EXISTS **** //
					if (!initialTempoExists && eType == Element.TEMPO_TEXT && barNum == 1) initialTempoExists = true;
		
					// **** IS THIS A TEMPO CHANGE MARKING??? **** //
					var isTempoChangeMarking = false;
					if (!lowerCaseText.includes('trill') && !lowerCaseText.includes('trem')) {
						for (var i = 0; i < tempochangemarkings.length; i++) {
							var theText = tempochangemarkings[i];
							if (lowerCaseText.includes(theText)) {
								isTempoChangeMarking = true;
								break;
							}
						}
					}
								
					// **** CHECK TEMPO CHANGE MARKING IS NOT IN TEMPO TEXT OR INCORRECTLY CAPITALISED **** //
					if (isTempoChangeMarking) {
						lastTempoChangeMarkingBar = currentBarNum;
						//logError("Found tempo change in b. "+currentBarNum);
						lastTempoChangeMarking = textObject;
						if (eType != Element.TEMPO_TEXT) {
							addError( "‘"+plainText+"’ is a tempo change marking\nbut has not been entered as Tempo Text.\nYou can change it in Properties→Show more→Text style→Tempo.",textObject);
							return;
						}
						if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) {
							addError("‘"+plainText+"’ looks like it is a temporary change of tempo\nif it is, it should not have a capital first letter (see Behind Bars, p. 182)",textObject);
							return;
						}
					}
		
					// **** IS THIS A TEMPO MARKING? **** //
					var isTempoMarking = false;
					if (!lowerCaseText.includes('trill') && !lowerCaseText.includes('trem')) {
						for (var j = 0; j < tempomarkings.length; j++) {
							if (lowerCaseText.includes(tempomarkings[j])) {
								isTempoMarking = true;
								break;
							}
						}
					}
					if (isTempoMarking) {
						lastTempoChangeMarkingBar = -1;
						//logError("Cancelled tempo change marking in b. "+currentBarNum);
					
						// **** CHECK TEMPO MARKING IS IN TEMPO TEXT **** //
						if (eType != Element.TEMPO_TEXT) addError("Text ‘"+plainText+"’ is a tempo marking\nbut has not been entered as Tempo Text.\nYou can change it in Properties→Show more→Text style→Tempo.",textObject);
				
						// **** CHECK TEMPO SHOULD BE CAPITALISED **** //
						if (plainText.substring(0,1) === lowerCaseText.substring(0,1) && lowerCaseText != "a tempo" && lowerCaseText.charCodeAt(0)>32 && !lowerCaseText.substring(0,4).includes("=")) addError("‘"+plainText+"’ looks like it is establishing a new tempo;\nif it is, it should have a capital first letter. (See Behind Bars, p. 182)",textObject);
					}
				
					// **** CHECK TEMPO POINT SIZE **** //
					if (isTempoMarking || isTempoChangeMarking) {
						if (textObject.fontSize > 12.0) addError("This tempo marking is larger than 12pt,\nand may appear overly large.",textObject);
						if (textObject.fontSize < 10.0) addError("This tempo marking is smaller than 10pt,\nand may appear overly small.",textObject);
					}
					
					// **** CHECK METRONOME MARKINGS **** //
					var isMetronomeMarking = false;
					for (var j = 0; j < metronomemarkings.length; j++) {
						if (lowerCaseText.includes(metronomemarkings[j])) {
							isMetronomeMarking = true;
							break;
						}
					}
					
					// ** CHECK IF METRONOME MARKING IS IN METRONOME TEXT STYLE ** //
					if (!isTempoMarking && !isTempoChangeMarking && isMetronomeMarking) {
						if (eType != Element.METRONOME) addError("This looks like a metronome marking, but is not in the Metronome text style.\n(Metronome markings should not be bold.)\nYou can change it in Properties→Show more→Text style→Metronome.",textObject);
					}
				
					// **** CHECK DIV **** //
					if (lowerCaseText.includes('div.')) {
						if (isStringSection) {
							isDiv = true;
							flaggedDivError = false;
						} else {
							addError("You’ve written a string div. marking,\nbut this doesn’t seem to be a string section\n(i.e. you haven’t used the ‘(section)’ instruments)",textObject);
							return;
						}
					}
				
					if (lowerCaseText.includes('unis.')) {
						if (isStringSection) {
							isDiv = false;
							flaggedDivError = false;
						} else {
							addError("You’ve written a string unis. marking,\nbut this doesn’t seem to be a string section\n(i.e. you haven’t used the ‘(section)’ instruments)",textObject);
							return;
						}
					}
				
					// **** CHECK WRITTEN OUT TREM **** //
					if (lowerCaseText === "trem" || lowerCaseText === "trem." || lowerCaseText === "tremolo") {
						addError("You don’t need to write ‘"&plainText&"’;\njust use a tremolo marking.",textObject);
						return;
					}
				
					// **** CHECK SUL + STRING INDICATION **** //
					var strings = ["I","II","III","IV"];
					for (var i = 0; i < 4; i++) {
						if (lowerCaseText === "sul "+strings[i]) {
							addError ( "You don’t need ‘sul’ here;\nyou can just write the string number", textObject);
							return;
						}
					}
					
					// **** CHECK Brass, Strings, Winds, Percussion **** //
					var dontCap = ["Brass","Strings","Winds","Woodwinds","Percussion"];
					for (var i = 0; i < dontCap.length; i++) {
						var theWord = dontCap[i];
						var l = theWord.length;
						if (plainText.includes(theWord) && plainText.substring(0,l) !== theWord) {
							addError ( "You don’t need to capitalise ‘"+theWord+"", textObject);
							return;
						}
					}
					
					// **** CHECK TEXT THAT IS INCORRECTLY CAPITALISED **** //
					for (var i = 0; i < shouldbelowercase.length; i++) {
						var lowercaseMarking = shouldbelowercase[i];
						if (plainText.length >= lowercaseMarking.length) {
							if (lowerCaseText.substring(0,lowercaseMarking.length) === lowercaseMarking) {
								if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) {
									addError("‘"+plainText+"’ should not have a capital first letter.",textObject);
									return;
								}
								break;
							}
						}
					}
			
					// **** CHECK TEXT THAT SHOULD HAVE A FULL-STOP AT THE END **** //
					for (var i = 0; i < shouldhavefullstop.length; i++) {
						if (lowerCaseText === shouldhavefullstop[i]) {
							addError("‘"+plainText+"’ should have a full-stop at the end.",textObject);
							return;
						}
					}
					
					// **** CHECK TEXT CAN BE ABBREVIATED **** //
					if (!isSpellingError) {
						for (var i = 0; i < canbeabbreviated.length / 2; i++) {
							var fullText = canbeabbreviated[i*2];
							if (plainText.includes(fullText)) {
								var abbreviatedText = canbeabbreviated[i*2+1];
								var correctText = plainText.replace(fullText,abbreviatedText);
								addError("‘"+plainText+"’ can be shortened to ‘"+correctText+"’.",textObject);
								break;
							}
						}
					}
					
					// **** CHECK COMMON MISSPELLINGS **** //
					if (lowerCaseText === "mute" || lowerCaseText === "with mute" || lowerCaseText === "add mute" || lowerCaseText === "put on mute" || lowerCaseText === "put mute on" || lowerCaseText === "muted") {
						addError( "This is best written as ‘con sord.’",textObject);
						return;
					}
					if (lowerCaseText === "unmuted" || lowerCaseText === "no mute" || lowerCaseText === "remove mute" || lowerCaseText === "take off mute" || lowerCaseText === "take mute off") {
						addError( "This is best written as ‘senza sord.’",textObject);
						return;
					}
					if (lowerCaseText.substring(0,5) === "arco.") {
						addError( "‘arco’ should not have a full-stop at the end.",textObject);
						return;
					}
					if (lowerCaseText.substring(0,10) === "sul tasto.") {
						addError( "‘tasto’ should not have a full-stop at the end.",textObject);
						return;
					}
					if (lowerCaseText === "norm") {
						addError( "‘norm’ should have a full-stop at the end\n(but is more commonly written as ‘ord.’).",textObject);
						return;
					}
					if (lowerCaseText.includes("sul. ")) {
						addError( "‘sul’ should not have a full-stop after it.",textObject);
						return;
					}
					if (lowerCaseText.includes("  ")) {
						addError( "This text has a double-space in it.",textObject);
						return;
					}
					if (lowerCaseText === "normale") {
						addError("Abbreviate ‘normale’ as ‘norm.’ or ‘ord.’.",textObject);
						return;
					}
			
					// **** CHECK FOR INCORRECT STYLES **** //
					if (styledText.includes("<i>arco")) {
						addError("‘arco’ should not be italicised.",textObject);
						return;
					}
					if (styledText.includes("<i>pizz")) {
						addError("‘pizz.’ should not be italicised.",textObject);
						return;
					}
					if (styledText.includes("<i>con sord")) {
						addError("‘con sord.’ should not be italicised.",textObject);
						return;
					}
					if (styledText.includes("<i>senza sord")) {
						addError("‘senza sord.’ should not be italicised.",textObject);
						return;
					}
					if (styledText.includes("<i>ord.")) {
						addError("‘ord.’ should not be italicised.",textObject);
						return;
					}
					if (styledText.includes("<i>sul ")) {
						addError("String techniques should not be italicised.",textObject);
						return;
					}
					if (styledText.slice(3) === "<b>") {
						addError("In general, you never need to manually set text to bold.\nAre you sure you want this text bold?",textObject);
						return;
					}
					
					var objectIsDynamic = tn === "dynamic";
					var containsADynamic = styledText.includes('<sym>dynamics');
					var stringIsDynamic = isDynamic(lowerCaseText);
				
					// **** CHECK REDUNDANT DYNAMIC **** //
					if (objectIsDynamic || containsADynamic || stringIsDynamic) {
						//logError("dynamic — plainText = "+plainText);
						
						firstDynamic = true;
						tickHasDynamic = true;
						theDynamic = textObject;
						var isError = false;
						var dynamicException = plainText.includes("fp") || plainText.includes("sf") || plainText.includes("fz");
						if (prevDynamicBarNum > 0) {
							var barsSincePrevDynamic = barNum - prevDynamicBarNum;
							if (plainText === prevDynamic && barsSincePrevDynamic < 5 && !dynamicException) {
								addError("This dynamic may be redundant:\nthe same dynamic was set in b. "+prevDynamicBarNum+".",textObject);
								isError = true;
							}
						}
					
						if (!dynamicException) {
							prevDynamicBarNum = barNum;
							prevDynamic = plainText;
						}
						if (isError) return;
					}
					//logError(""+lowerCaseText+" isDyn = "+isDyn);
				
					// **** CHECK FOR DYNAMIC ENTERED AS EXPRESSION (OR OTHER) TEXT **** //
					if (!objectIsDynamic && (containsADynamic || stringIsDynamic)) {
						addError("This text object looks like a dynamic,\nbut has not been entered using the Dynamics palette",textObject);
						return;
					}
			
					// **** CHECK FOR TECHNIQUES ENTERED AS EXPRESSION TEXT **** //
					if (tn === "expression") {
						for (var i = 0; i < techniques.length; i ++) {
							if (lowerCaseText.includes(techniques[i])) {
								addError("This looks like a technique, but has been incorrectly entered as Expression text.\nPlease check whether this should be in Technique Text instead.",textObject);
								return;
							}
						}
						var canBeAbove = plainText === "loco" || plainText.includes("ten.") || plainText.includes("tenuto") || plainText.includes("legato") || plainText.includes("flz");
						if (textObject.placement == Placement.ABOVE && !canBeAbove) {
							addError("Expression text should appear below the staff.\nCheck it is attached to the right staff, or it should be a technique.",textObject);
							return;
						}
					}
					
					checkInstrumentalTechniques (textObject, plainText, lowerCaseText, barNum);
				
					// **** CHECK IF THIS IS A WOODWIND OR BRASS MARKING **** //
					if (windAndBrassMarkings.includes(lowerCaseText) && isWindOrBrassInstrument) {
						weKnowWhosPlaying = true;
						flaggedWeKnowWhosPlaying = false;
						//errorMsg+="\nWW weKnowWhosPlaying is now "+weKnowWhosPlaying;
					}
				}
			} // end lowerCaseText != ''
		} // end check comments
	}
	
	function checkLyrics (noteRest) {
		if (noteRest.lyrics.length > 0) {
			// lyrics found
			var theTrack = noteRest.track;
			for (var i = 0; i < noteRest.lyrics.length; i++) {
				var l = noteRest.lyrics[i];
				var styledText = l.text;
				var plainText = styledText.replace(/<[^>]+>/g, "");
				var dur = l.lyricTicks.ticks;
				//logError(""+plainText+" LASTS "+dur+" SYLLABIC "+l.syllabic);
				isMelisma[theTrack] = (l.syllabic == 1);
				if (dur > 0) {
					melismaEndTick[theTrack] = noteRest.parent.tick + noteRest.actualDuration.ticks + dur;
					//logError("melismaEndTick["+theTrack+"] = "+melismaEndTick[theTrack]);
					isMelisma[theTrack] = true;
				} else {
					melismaEndTick[theTrack] = 0;
				}
			}
			if (isSlurred & !isMelisma[theTrack]) {
				if (currTick < currentSlur.spannerTick.ticks + currentSlur.spannerTicks.ticks) addError ("This note is slurred, but is not a melisma",noteRest);
			}
		} else {
			if (isMelisma[theTrack]) {
				// check for slur
				//logError("isSlurred = "+isSlurred+" isTied = "+isTied);
				if (!isSlurred && !isTied)	addError ("This melisma requires a slur.",noteRest);
			} else {
				if (!flaggedNoLyrics) {
					flaggedNoLyrics = true;
					addError ("This is note in a vocal part does not have any lyrics.",noteRest);
				}
			}
		}
	}
	
	function isDynamic (str) {
		var dynamics = ["pppp", "ppp","pp","p", "mp", "mf", "f", "ff", "fff", "ffff","sfz","sffz","fz"];
		var prefixes = ["poco ", "meno ", "più ", "sf","sfz","sffz","fz","sempre ","f","mf","ff"];
		var l = str.length;
		for (var i = 0; i < dynamics.length; i++) {
			var d = dynamics[i];
			if (str === d) return true;
			if (l>d.length) {
				if (str.slice(-d.length-1) === " "+d) return true;
				if (str.slice(d.length+1) === d+" ") return true;
			}
			for (var j = 0; j < dynamics.length; j++) {
				var p = prefixes[j];
				if (str === p+d) return true;
			}
		}
		return false;
	}
	
	function checkKeySignature (keySig,sharps) {
		// *********************** KEY SIGNATURE ERRORS *********************** //
		if (sharps != prevKeySigSharps) {
			var errStr = "";
			if (sharps > 6) errStr = "This key signature has "+sharps+" sharps,\nand would be easier to read if rescored as "+(12-sharps)+" flats.";
			if (sharps < -6) errStr = "This key signature has "+Math.abs(sharps)+" flats,\nand would be easier to read if rescored as "+(12+sharps)+" sharps.";
			if (currentBarNum - prevKeySigBarNum  < 16) {
				if (errStr !== "") {
					errStr += "\nAlso, this";
				} else {
					errStr = "This";
				}
				errStr += " key change comes only "+ (currentBarNum - prevKeySigBarNum) +" bars after the previous one.\nPerhaps one of them could be avoided by using accidentals instead?";
			}
			if (errStr !== "") addError(errStr,keySig);
			prevKeySigSharps = sharps;
			prevKeySigBarNum = currentBarNum;
		} else {
			addError("This key signature is the same as the one in bar "+prevKeySigBarNum+".\nPerhaps delete it?",keySig);
		}
	}
	
	function checkBarlinesConnected (str) {
		for (var s = 0; s < curScore.nstaves-1; s ++) {
			var staff = curScore.staves[s];
			//logError("Checking "+staff.systemBracket);
			if (staff.staffBarlineSpan == 0) {
				addError ("The barlines should go through all of the staves for a "+str,"system1 1");
				return;
			}
//			logError ("s.bar "+staff.staffBarlineSpan+" "+staff.staffBarlineSpanFrom+" "+staff.staffBarlineSpanTo);
		}
	}
	
	function checkTimeSignatures () {
		var segment = curScore.firstSegment();
		prevTimeSig = "";
		while (segment) {
			if (segment.segmentType == Segment.TimeSig) {
				var theTimeSig = segment.elementAt(0);
				if (theTimeSig.type == Element.TIMESIG) {
					if (theTimeSig.visible) {
						var theTimeSigStr = theTimeSig.timesig.str;
						if (theTimeSigStr === prevTimeSig) addError("This time signature appears to be redundant (was already "+prevTimeSig+")\nIt can be safely deleted.",theTimeSig);
						prevTimeSig = theTimeSigStr;
					}
				}
			}
			segment = segment.next;
		}
	}
	
	function checkFermatas () {
		var numStaves = curScore.nstaves;
		var ticksDone = [];
		for (var i = 0; i < fermatas.length; i++) {
			var fermata = fermatas[i];
			var fermataLoc = fermataLocs[i];
			var staffIdx = fermataLoc.split(' ')[0];
			var theTick = fermataLoc.split(' ')[1];
			// check if we've already done this fermata
			if (!ticksDone.includes(theTick)) {
				//errorMsg+="\nChecking fermata "+fermataLoc[0]+" "+fermataLoc[1];
				
				var fermataInAllParts = true;
				for (var j = 0; j<numStaves && fermataInAllParts; j++) {
					if (staffVisible[j]) {
						var searchFermata = j+' '+theTick;
						if (j!=staffIdx) fermataInAllParts = fermataLocs.includes(searchFermata);
					}
				}
				if (!fermataInAllParts) addError("If you have a fermata in one staff, all staves\nshould also have a fermata at the same place",fermata);
				ticksDone.push(theTick);
			}
		}
	}
	
	function checkStaccatoIssues (noteRest) {
		if (noteRest.duration.ticks >= division * 2) {
			addError ("Don’t put staccato dots on long notes",noteRest);
			return;
		}		
		if (isDotted(noteRest) && noteRest.duration.ticks >= (division * 0.5)) {
			addError ("Don’t put staccato dots on dotted notes",noteRest);
			return;
		}
		if (noteRest.notes[0].tieForward != null) {
			addError ("Don’t put staccato dots on tied notes",noteRest);
			return;
		}
	}
	
	function isDotted(noteRest) {
		var dottedDurs = [0.75,0.875,1.5,1.75,3,3.5];
		var displayDur = noteRest.duration.ticks / parseFloat(division);
		return dottedDurs.includes(displayDur);
	}
	
	function checkLedgerLines (noteRest) {
		var maxNumLedgerLines = getMaxNumLedgerLines(noteRest);
		var minNumLedgerLines = maxNumLedgerLines;
		if (noteRest.notes.length > 1) minNumLedgerLines = getMinNumLedgerLines(noteRest);
		var absLL = Math.abs(maxNumLedgerLines);
		if (absLL > maxLLSinceLastRest) maxLLSinceLastRest = absLL;
		//errorMsg += "maxNumLL = "+maxNumLedgerLines;
		var numberOfLedgerLinesToCheck = 3;
		if (maxLedgerLines.length >= numberOfLedgerLinesToCheck) {
			maxLedgerLines = maxLedgerLines.slice(1);
			minLedgerLines = minLedgerLines.slice(1);
		}
		maxLedgerLines.push(maxNumLedgerLines);
		minLedgerLines.push(minNumLedgerLines);
		
		if (!flaggedLedgerLines) {
			if (maxNumLedgerLines > 3) {
				if (isBassClef && (readsTenor || readsTreble)) {
					addError("This passage is very high for bass clef;\nit may be better in tenor or treble clef",noteRest);
					flaggedLedgerLines = true;
				}
				if (isTenorClef && readsTreble) {
					addError("This passage is very high for tenor clef;\nit may be better in treble clef",noteRest);
					flaggedLedgerLines = true;
				}
			}
			if (maxNumLedgerLines > 5 && minNumLedgerLines > 2) {
				if (isTrebleClef && reads8va && !isOttava) {
					addError("This passage is very high for treble clef;\nit may be better with an 8va symbol",noteRest);
					flaggedLedgerLines = true;
				}
			}
			if (maxNumLedgerLines < 0 && minNumLedgerLines <= 0) {
				if (isTrebleClef) {
					if (readsTenor) {
						addError("This passage is very low for treble clef;\nit may be better in tenor or bass clef",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (maxNumLedgerLines < -3 && readsBass) {
							addError("This passage is very low for treble clef;\nit may be better in bass clef",noteRest);
							flaggedLedgerLines = true;
						} else {
							if (readsAlto) {
								addError("This passage is very low for treble clef;\nit may be better in alto clef",noteRest);
								flaggedLedgerLines = true;
							}
						}
					}
				}
				if (isTenorClef && readsBass && maxNumLedgerLines < -1 && minNumLedgerLines <= 0) {
					addError("This passage is very low for tenor clef;\nit may be better in bass clef",noteRest);
					flaggedLedgerLines = true;
				}
				if (isBassClef && reads8va && !isOttava && maxNumLedgerLines < -3 && minNumLedgerLines < -2) {
					addError("This passage is very low for bass clef;\nit may be better with an 8ba",noteRest);
					flaggedLedgerLines = true;
				}
			}
		//	if (!flaggedLedgerLines) logError("ll length now "+ledgerLines.length);
			if (!flaggedLedgerLines && maxLedgerLines.length >= numberOfLedgerLinesToCheck) {
				var averageMaxNumLedgerLines = maxLedgerLines.reduce((a,b) => a+b) / maxLedgerLines.length;
				var averageMinNumLedgerLines = minLedgerLines.reduce((a,b) => a+b) / minLedgerLines.length;
				
				if (isOttava && currentOttava != null) {
					var ottavaArray = ["an 8va","an 8ba","a 15ma","a 15mb"];
					var ottavaStr = ottavaArray[currentOttava.ottavaType]; 
					//logError("Testing 8va Here — currentOttava.ottavaType = "+currentOttava.ottavaType+"); averageNumLedgerLines "+averageNumLedgerLines+" maxLLSinceLastRest="+maxLLSinceLastRest;
					if (currentOttava.ottavaType == 0 || currentOttava.ottavaType == 2) {
						if (averageMaxNumLedgerLines < 2 && averageMinNumLedgerLines >= 0 && maxLLSinceLastRest < 2) {
							addError("This passage is quite low for "+ottavaStr+" line:\nyou should be able to safely write this at pitch",currentOttava);
							flaggedLedgerLines = true;
							return;
						}
					} else {
						if (averageMaxNumLedgerLines > -2 && averageMinNumLedgerLines <= 0 && maxLLSinceLastRest < 2) {
							addError("This passage is quite high for "+ottavaStr+" line:\nyou should be able to safely write this at pitch",currentOttava);
							flaggedLedgerLines = true;
							return;
						}
					}
				}
				if (isBassClef) {
					//trace(averageNumLedgerLines);
					if (readsTenor && averageMaxNumLedgerLines >= 3 && averageMinNumLedgerLines > 1) {
						addError("This passage is quite high;\nit may be better in tenor or treble clef",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsTreble && averageMaxNumLedgerLines >= 3 && averageMinNumLedgerLines > 2) {
							addError("This passage is very high;\nit may be better in treble clef",noteRest);
							flaggedLedgerLines = true;
						} else {
							if (reads8va && averageMaxNumLedgerLines < -4 && averageMinNumLedgerLines < -2 && !isOttava) {
								addError("This passage is very low;\nit may be better with an 8ba",noteRest);
								flaggedLedgerLines = true;
							}
						}
					}
				}

				if (isTenorClef) {
					if (readsTreble && averageMaxNumLedgerLines > 2 && averageMinNumLedgerLines > 1) {
						addError("This passage is quite high;\nit may be better in treble clef",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsBass && averageMaxNumLedgerLines < -1  && averageMinNumLedgerLines <= 0) {
							addError("This passage is quite low;\nit may be better in bass clef",noteRest);
							flaggedLedgerLines = true;
						}
					}
				}
				if (isTrebleClef) {
					if (reads8va && averageMaxNumLedgerLines > 4 && averageMinNumLedgerLines > 2 && !isOttava) {
						addError("This passage is very high;\nit may be better with an 8va",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsTenor && averageMaxNumLedgerLines < -1 && averageMinNumLedgerLines <= 0) {
							addError("This passage is quite low;\nit may be better in tenor clef",noteRest);
							flaggedLedgerLines = true;
						} else {
							if (readsBass && averageMaxNumLedgerLines < -2 && averageMinNumLedgerLines <= 0) {
								addError("This passage is quite low;\nit may be better in bass clef",noteRest);
								flaggedLedgerLines = true;
							}
						}
					}
				}
			}
		}
	}
	
	function getMaxNumLedgerLines (noteRest) {
		var n = noteRest.notes.length;
		var maxNumLedgerLines = 0;
		for (var i = 0; i < n; i++ ) {
			var note = noteRest.notes[i];
			var numLedgerLines = 0;
			var l = note.line;
			if (l <= -2) numLedgerLines = parseInt(Math.abs(l)/2);
			if (l >= 10) numLedgerLines = -parseInt((l-8)/2);
			if (Math.abs(numLedgerLines) > Math.abs(maxNumLedgerLines)) maxNumLedgerLines = numLedgerLines;
		}
		return maxNumLedgerLines;
	}
	
	function getMinNumLedgerLines (noteRest) {
		var n = noteRest.notes.length;
		var minNumLedgerLines = 999;
		for (var i = 0; i < n; i++ ) {
			var note = noteRest.notes[i];
			var numLedgerLines = 0;
			var l = note.line;
			if (l <= -2) numLedgerLines = parseInt(Math.abs(l)/2);
			if (l >= 10) numLedgerLines = -parseInt((l-8)/2);
			if (Math.abs(numLedgerLines) < Math.abs(minNumLedgerLines)) minNumLedgerLines = numLedgerLines;
			if (minNumLedgerLines == 0) break;
		}
		return minNumLedgerLines;
	}
	
	function checkMultipleStop (chord) {
		if (isStringHarmonic) return;
		var violinStrings = [55,62,69,76];
		var violinStringNames = ["G","D","A","E"];
		var violaStrings = [48,55,62,69];
		var violaStringNames = ["C","G","D","A"];
		var celloStrings = [36,43,50,57];
		var celloStringNames = ["C","G","D","A"];
		var bassStrings = [28,33,38,43];
		var bassStringNames = ["E","A","D","G"];
		var noteOnString = [-1,-1,-1,-1];
		var stringsArray = [];
		var stringNames = [];
		var iName = "";
		var maxStretch = 11;
		var numNotes = chord.notes.length;
		
		if (numNotes > 4) {
			addError ("This multiple stop has more than 4 notes in it",chord);
			return;
		}
		
		if (numNotes > 2 && chord.duration.ticks > division * 1.5) {
			var str = numNotes == 3 ? "This triple stop" : "This quadruple stop";
			addError (str+" is too long to hear all strings playing at the same time\nYou should rewrite it with 1 or 2 of the notes as grace notes\nso that no more than 2 notes are sustained.",chord);
			return;
		}
		
		if (currentInstrumentId.includes("violin")) {
			iName = "violin";
			stringsArray = violinStrings;
			stringNames = violinStringNames;
		}
		if (currentInstrumentId.includes("viola")) {
			iName = "viola";
			stringsArray = violaStrings;
			stringNames = violaStringNames;
			maxStretch = 10;
		}
		if (currentInstrumentId.includes("cello")) {
			iName = "cello";
			stringsArray = celloStrings;
			stringNames = celloStringNames;
		}
		if (currentInstrumentId.includes("bass")) {
			iName = "double bass";
			stringsArray = bassStrings;
			stringNames = bassStringNames;
			maxStretch = 8;
		}
		if (iName === "") return; // unknown string instrument
		var tempPitchArray = [];
		for (var i = 0; i < numNotes; i++) tempPitchArray.push(chord.notes[i].pitch);
		//logError("stringsArray[0] ="+stringsArray[0]+" stringNames[1]="+stringNames[1]);
		for (var stringNum = 0; stringNum < 4 && tempPitchArray.length > 0; stringNum++) {
			var lowestPitchIndex = 0, lowestPitch = tempPitchArray[0];
			var removedPitch = false;
			for (var i = 0; i < tempPitchArray.length; i++) {
				var p = tempPitchArray[i];
				if (p < lowestPitch) {
					lowestPitch = p;
					lowestPitchIndex = i;
				}
				//logError("stringNum is "+stringNum+" i = "+i+" p = "+p);
				if (p < stringsArray[stringNum]) {
					//logError("Found a pitch below the string tuning");
					if (stringNum == 0) {
						addError ("This chord has a note below the "+iName+"’s bottom string\nand is therefore impossible to play.",chord);
						return;
					} else {
						//logError("stringNames[stringNum - 1] = "+(stringNames[stringNum - 1])+" stringNum - 1 = "+(stringNum-1));
						addError ("This chord is impossible to play, because there are\ntwo notes that can only be played on the "+(stringNames[stringNum - 1])+" string.",chord);
						return;
					}
				}
				if (stringNum < 3) {
					//logError("Found a pitch that has to be on this string");
					if (p < stringsArray[stringNum+1]) {
						// has to be on this string
						tempPitchArray.splice(i,1);
						removedPitch = true;
					}
				}
			}
			if (!removedPitch) tempPitchArray.splice(lowestPitchIndex,1);
		}
		// check dyads
		//logError("Checking dyad");
		var interval = 0;
		var p1 = chord.notes[0].pitch;
		var p2 = chord.notes[1].pitch;
		if (!stringsArray.includes(p1) && !stringsArray.includes(p2)) interval = Math.abs(p2-p1);
		//logError("p1 = "+p1+"); p2 = "+p2+"; interval="+interval;
		
		if (numNotes == 2 && interval > maxStretch) addError ("This double-stop appears to be larger than a safe stretch on the "+iName+"\nIt may not be possible: check with a player.",chord);
		if (prevIsMultipleStop && chord.actualDuration.ticks <= division && prevSoundingDur <= division && interval > 0 && prevMultipleStopInterval > 0 && !flaggedFastMultipleStops) {
			//logError("Checking sequence");
			
			var pi1 = interval > 7;
			var pi2 = prevMultipleStopInterval > 7;
			if (pi1 != pi2) {
				addError ("This sequence of double-stops looks very difficult,\nas the hand has to change its position and orientation.",chord);
				flaggedFastMultipleStops = true;
				
			} else {
				//logError("Checking identical chords");
				
				if (!chordsAreIdentical (chord,prevMultipleStop)) {
					addError ("This looks like a sequence of relatively quick double-stops,\nwhich might be challenging to play accurately.",chord);
					flaggedFastMultipleStops = true;
				} else {
					if (interval == 7 && !isCello) {
						addError ("This looks like a sequence of relatively quick perfect fifths,\nwhich is challenging to play accurately.",chord);
						flaggedFastMultipleStops = true;
					}
				}
			}
		}
		prevMultipleStop = chord;
		prevIsMultipleStop = true;
		prevMultipleStopInterval = interval;
	}
	
	function checkStringHarmonic (noteRest, staffNum) {

		var harmonicCircleIntervals = [12,19,24,28,31,34,36,38,40,42,43,45,46,47,48];
		var diamondHarmonicIntervals = [3,4,5,7,12,19,24,28,31,34,36];
		var violinStrings = [55,62,69,76];
		var violaStrings = [48,55,62,69];
		var celloStrings = [36,43,50,57];
		var bassStrings = [28,33,38,43];
		
		isStringHarmonic = false;
		
		if (noteRest.notes[0].tieBack) return;
		var nn = noteRest.notes.length;
		//logError("CHECKING STRING HARMONIC — nn = "+nn);
		if (nn == 2) {
			//check for possible artificial harmonic
			var noteheadStyle1 = noteRest.notes[0].headGroup;
			var noteheadStyle2 = noteRest.notes[1].headGroup;
			//logError("ns1 = "+noteheadStyle1+" vs "+NoteHeadGroup.HEAD_NORMAL+"); ns2 = "+noteheadStyle2+" vs "+NoteHeadGroup.HEAD_DIAMOND;
			if (noteheadStyle1 == NoteHeadGroup.HEAD_NORMAL && noteheadStyle2 == NoteHeadGroup.HEAD_DIAMOND) {
				isStringHarmonic = true;
				// we have a false harmonic
				var noteheadPitch1 = noteRest.notes[0].pitch;
				var noteheadPitch2 = noteRest.notes[1].pitch;
				//logError("FALSE HARM FOUND: np1 "+noteheadPitch1+" np2 "+noteheadPitch2);
				var interval = noteheadPitch2 - noteheadPitch1;
				
				if (interval != 5) {
					addError("This looks like an artificial harmonic, but the interval between\nthe fingered and touched pitch is not a perfect fourth.",noteRest);
				}
				
				// check override on the top note
				if (noteRest.duration.ticks <= 2 * division) {
					var noteheadType = noteRest.notes[1].headType;
					if (noteheadType != NoteHeadType.HEAD_HALF) {
						addError("The diamond harmonic notehead should be hollow.\nIn Properties, set ‘Override visual duration’ to a minim.\n(See ‘Behind Bars’, p. 428)",noteRest);
					}
				}
			}
		}
		
		if (nn == 1) {
			var harmonicArray = [];
			var stringsArray = [];
			var noteheadStyle = noteRest.notes[0].headGroup;

			if (typeof staffNum !== 'number') logError("Artic error in checkStringHarmonic nn1");
			var theArticulationArray = getArticulationArray(noteRest, staffNum);
			//logError("The artic sym = "+theArticulation.symbol.toString());
			// CHECK FOR HARMONIC CIRCLE ARTICULATION ATTACHED TO THIS NOTE
			if (theArticulationArray) {
				for (var i = 0; i < theArticulationArray.length; i++) {
					if (theArticulationArray[i].symbol == kHarmonicCircle) {
						isStringHarmonic = true;
						harmonicArray = harmonicCircleIntervals;
						break;
					}
				}
			}
			if (noteheadStyle == NoteHeadGroup.HEAD_DIAMOND) {
				isStringHarmonic = true;
				harmonicArray = diamondHarmonicIntervals;
				// check override on the top note
				if (noteRest.duration.ticks <= 2 * division) {
					var noteheadType = noteRest.notes[1].headType;
					if (noteheadType != NoteHeadType.HEAD_HALF) {
						addError("The diamond harmonic notehead should be hollow.\nIn Properties, set ‘Override visual duration’ to a minim.\n(See ‘Behind Bars’, p. 11)",noteRest);
					}
				}
			}
			if (isStringHarmonic) {
				var p = noteRest.notes[0].pitch;
				var harmonicOK = false;
				if (currentInstrumentId.includes("violin")) stringsArray = violinStrings;
				if (currentInstrumentId.includes("viola")) stringsArray = violaStrings;
				if (currentInstrumentId.includes("cello")) stringsArray = celloStrings;
				if (currentInstrumentId.includes("bass")) stringsArray = bassStrings;
				for (var i = 0; i < stringsArray.length && !harmonicOK; i++) {
					for (var j = 0; j < harmonicArray.length && !harmonicOK; j++) {
						harmonicOK = (p == stringsArray[i]+harmonicArray[j]);
					}
				}
				if (!harmonicOK) addError("This looks like a natural harmonic, but there is no\nnatural harmonic available at the given pitch on this instrument.",noteRest);
			}
		}
	}
	
	function checkDivisi (noteRest, staffNum) {
		if (noteRest.notes.length > 1) {
			// we have a chord
			if (!isDiv && !flaggedDivError && !isStringHarmonic) {
				addError ("Chord found in string section, but not marked as div.\n(If this is a chamber ensemble, you incorrectly chose the ‘Section’ instruments)\nYou can ignore if this has a ‘non div.’ mark, or a bracket to indicate multiple stop.",noteRest);
				flaggedDivError = true;
			}
		} else {
			if (isDiv && !flaggedDivError) {
				addError ("Single note found in string section, but no unis. marked\n(If this is a chamber ensemble, you incorrectly chose the ‘Section’ instruments)",noteRest);
				flaggedDivError = true;
			}
		}
	}
	
	function checkPizzIssues (noteRest, barNum, staffNum) {
		var noPizzArticArray = [kAccentStaccatoAbove,kAccentStaccatoAbove+1,
			kStaccatissimoAbove,kStaccatissimoAbove+1,
			kStaccatissimoStrokeAbove,kStaccatissimoStrokeAbove+1,
			kStaccatissimoWedgeAbove,kStaccatissimoWedgeAbove+1,
			kStaccatoAbove,kStaccatoAbove+1];
			
		var Minim = 2 * division;
		
		if (staffNum == lastPizzIssueStaff && barNum-lastPizzIssueBar < 5) return;
		// check staccato
		if (typeof staffNum !== 'number') logError("Articulation error in check pizz");
		
		var theArticulationArray = getArticulationArray (noteRest, staffNum);
		if (theArticulationArray) {
			for (var i = 0; i < theArticulationArray.length; i++) {
				if (noPizzArticArray.includes(theArticulationArray[i].symbol)) {
					addError("It’s not recommended to have a staccato articulation on a pizzicato note.",noteRest);
					lastPizzIssueBar = barNum;
					lastPizzIssueStaff = staffNum;
					return;
				}
			}
		}
		
		// check dur >= minim
		if (noteRest.duration.ticks > Minim) {
			addError("It’s not recommended to have a pizzicato longer\nthan a minim unless the tempo is very fast.\nPerhaps this is supposed to be arco?",noteRest);
			lastPizzIssueBar = barNum;
			lastPizzIssueStaff = staffNum;
			return;
		}
		
		// check tied pizz
		if (noteRest.notes[0].tieForward) {
			addError("In general, you shouldn’t need to tie pizzicato notes.\nPerhaps this is supposed to be arco?",noteRest);
			lastPizzIssueBar = barNum;
			lastPizzIssueStaff = staffNum;
			return;
		}
		
		// check slurred pizz
		if (isSlurred) {
			addError("In general, you shouldn’t slur pizzicato notes unless you\nspecifically want the slurred notes not to be replucked", noteRest);
			lastPizzIssueBar = barNum;
			lastPizzIssueStaff = staffNum;
			return;
		}
		
	}
	
	function checkFluteHarmonic (noteRest) {
		var allowedIntervals = [12,19,24,28,31,34,36];
		var nn = noteRest.notes.length;
		
		if (nn == 2) {
			var noteheadStyle1 = noteRest.notes[0].headGroup;
			var noteheadStyle2 = noteRest.notes[1].headGroup;
			if (noteheadStyle1 == NoteHeadGroup.HEAD_DIAMOND && noteheadStyle2 == NoteHeadGroup.HEAD_NORMAL) {
				// we have a flute harmonic
				var np1 = noteRest.notes[0].pitch;
				var np2 = noteRest.notes[1].pitch;
				var interval = np2 - np1;
				if (np1 > 72) addError("The bottom note on this flute harmonic is too high.\nFlute harmonics should always come from fingerings in the bottom octave.",noteRest);
				if (interval == 12) addError("Second harmonics on the flute are indistinguishable from normal notes\nit’s recommended to only use third, fourth or fifth harmonics.",noteRest);
				if (!allowedIntervals.includes(interval)) addError("This looks like a flute harmonic, but you can’t get the\ntop note as a harmonic of the bottom note.",noteRest);		
			}
		}
	}
	
	function checkSlurIssues (noteRest, staffNum, currentSlur) {
		//logError("Slur "+currentSlur);
		//logError("Slur posX = "+currentSlur.posX+" posY = "+currentSlur.posY+" off1 "+noteRest.slurUoff1+" off2 "+noteRest.slurUoff2+" dir "+currentSlur.slurDirection+" pa "+currentSlur.posAbove+" pos "+currentSlur.position);
		var currTick = noteRest.parent.tick;
		var isRest = noteRest.type == Element.REST;
		var accentsArray = [ kAccentAbove,	kAccentAbove+1,
			kAccentStaccatoAbove,	kAccentStaccatoAbove+1,
			kMarcatoAbove,	kMarcatoAbove+1,
			kMarcatoStaccatoAbove,	kMarcatoStaccatoAbove+1,
			kMarcatoTenutoAbove,	kMarcatoTenutoAbove+1,
			kSoftAccentAbove,	kSoftAccentAbove+1,
			kSoftAccentStaccatoAbove,	kSoftAccentStaccatoAbove+1,
			kSoftAccentTenutoAbove,	kSoftAccentTenutoAbove+1,
			kSoftAccentTenutoStaccatoAbove, kSoftAccentTenutoStaccatoAbove+1];
		var slurStart = currentSlur.spannerTick.ticks;
		var isStartOfSlur = currTick == slurStart;
		var slurLength = currentSlur.spannerTicks.ticks;
		var slurEnd = slurStart + slurLength;
		var isEndOfSlur = currTick == slurEnd;

		//logError("CHECKING SLUR: isRest: "+isRest);
		if (isStartOfSlur) {
			if (isStringInstrument) {
				if (slurLength > division * 8) {
					addError("Consider whether this slur is longer than one bow stroke\nand should be broken into multiple slurs.",currentSlur);
				}
			}
		}
		// **** CHECK SLUR GOING OVER A REST FOR STRINGS, WINDS & BRASS **** //
		if (isRest) {
			if ((isWindOrBrassInstrument || isStringInstrument) && !flaggedSlurredRest) {
				addError("In general, avoid putting slurs over rests.",currentSlur);
				flaggedSlurredRest = true;
				return;
			}
		} else {
			// Check accent
			var n = noteRest.notes[0];
			var isMiddleOfTie = n.tieBack != null && n.tieForward != null;
			var isEndOfTie = n.tieBack != null && n.tieForward == null;
			var isStartOfTie = n.tieForward != null && n.tieBack == null;
			// *** CHECK REPEATED NOTE UNDER A SLUR — ONLY STRINGS, WINDS OR BRASS *** //
			if (isStringInstrument || isWindOrBrassInstrument) {
				if (!isStartOfSlur && prevNote != null && prevSlurNum == currentSlurNum && noteRest.notes[0].tieBack == null) {
					var iterationArticulationArray = [kTenutoAbove,kTenutoBelow,
						kStaccatissimoAbove, kStaccatissimoAbove+1,
						kStaccatissimoStrokeAbove, kStaccatissimoStrokeAbove+1,
						kStaccatissimoWedgeAbove, kStaccatissimoWedgeAbove+1,
						kStaccatoAbove, kStaccatoAbove+1];
					var noteheadStyle = noteRest.notes[0].headGroup;
					var prevNoteheadStyle = prevNote.notes[0].headGroup;
					if (noteRest.notes.length == prevNote.notes.length) {
						var chordMatches = true;
						var numNotes = noteRest.notes.length;
						for (var i = 0; i < numNotes && chordMatches; i++) {
							if (noteRest.notes[i].pitch != prevNote.notes[i].pitch) chordMatches = false;
						}
						if (chordMatches && noteheadStyle != NoteHeadGroup.HEAD_DIAMOND && prevNoteheadStyle != NoteHeadGroup.HEAD_DIAMOND) {
							if (getArticulationArray(noteRest,staffNum) == null) {
								if (isEndOfSlur && prevWasStartOfSlur) {
									addError("A slur has been used between two notes of the same pitch.\nIs this supposed to be a tie, or do you need to add articulation?",currentSlur);
								} else {
									var errStr = "";
									if (numNotes == 1) {
										errStr = "Don’t repeat the same note under a slur. Either remove the slur, or\nadd some articulation (e.g. tenuto/staccato).";
									} else {
										errStr = "Don’t repeat the same chord under a slur. Either remove the slur, or\nadd some articulation (e.g. tenuto/staccato).";
									}
									addError(errStr,noteRest);
								}
							}
						}
					}
				}
			}
			
			prevWasStartOfSlur = isStartOfSlur;
			
			// Check ties to middle of slurs
			if (isEndOfSlur) {
				//logError("Slur started — mid = "+isMiddleOfTie+"); start = "+isStartOfTie;
				if (isMiddleOfTie) {
					addError("Don’t end a slur in the middle of a tied note.\nExtend the slur to the end of the tie",currentSlur);
					return;
				}
				if (isStartOfTie && !prevWasGraceNote) {
					addError("Don’t end a slur at the beginning of a tied note.\nInclude the full duration of tied note in the slur",currentSlur);
					return;
				}
			}
			
			if (!isStartOfSlur && !isEndOfSlur) {
				if (typeof staffNum !== 'number') logError("Articulation error in check slur issues");
			
				var theArticulationArray = getArticulationArray(noteRest, staffNum);
				if (theArticulationArray) {
					for (var i = 0; i < theArticulationArray.length; i++) {
						if (accentsArray.includes(theArticulationArray[i].symbol) ) {
							addError("Don’t put accents on notes in the middle of a slur.",noteRest);
							return;
						}
					}
				}
			}
		
			// Check ties to middle of slurs
			if (isStartOfSlur) {
				//logError("Slur started — mid = "+isMiddleOfTie+"); end = "+isEndOfTie;
				if (isMiddleOfTie) {
					addError("Don’t begin a slur in the middle of a tied note.\nExtend the slur back to the start of the tie",currentSlur);
					return;
				}
				if (isEndOfTie) {
					addError("Don’t begin a slur at the end of a tied note.\nStart the slur at the beginning of the next note",currentSlur);
					return;
				}
			}
		}
		
	}
	
	function checkHarpIssues (currentBar, staffNum) {
		var cursor = curScore.newCursor();
		var barStartTick = currentBar.firstSegment.tick;
		var barEndTick = currentBar.lastSegment.tick;
		
		// collate all the notes in this bar
		var allNotes = [];
		
		var endStaffNum = staffNum;
		if (isTopOfGrandStaff[staffNum]) endStaffNum ++;
		for (var currStaffNum = staffNum; currStaffNum <= endStaffNum; currStaffNum ++) {
			// set cursor staff
			for (var currentTrack = currStaffNum * 4; currentTrack < currStaffNum * 4 + 4; currentTrack ++) {
				cursor.filter = Segment.ChordRest;
				cursor.track = currentTrack;
				cursor.rewindToTick(barStartTick);
				var processingThisBar = cursor.element && cursor.tick < barEndTick;
			
				while (processingThisBar) {
					var currSeg = cursor.segment;
					var currTick = currSeg.tick;
					var noteRest = cursor.element;
					if (noteRest.type == Element.CHORD) {
						var theNotes = noteRest.notes;
						var nNotes = theNotes.length;
						if (allNotes[currTick] == undefined) allNotes[currTick] = [];
						for (var  i = 0; i < nNotes; i++) {
							allNotes[currTick].push(theNotes[i]);
						}
						//logError("Pushed "+nNotes+" notes at "+currTick);
					}
					if (cursor.next()) {
						processingThisBar = cursor.measure.is(currentBar);
					} else {
						processingThisBar = false;
					}
				}
			}
		}
		
		for (var i = 0; i < barEndTick; i++) {
			var errorAdded = false;
			if (allNotes[i] != undefined) {
			
				// getNote rest

				var theNotes = allNotes[i];
				var numNotes = theNotes.length;
				//logError("Found "+numNotes+" notes at "+i);
				
				//logError("Here: numNotes="+numNotes);

				var pedalLabels = ['C','G','D','A','E','B','F'];
				var pedalAccs = ['b','♮','#'];
				var pedalSettingInThisChord = [-1,-1,-1,-1,-1,-1,-1];
				for (var j = 0; j < numNotes; j++) {		
					var tpc = theNotes[j].tpc;
					if (tpc < 6) {
						addError ("You can’t use double flats in harp parts", nn[i]);
						continue;
					}
					if (tpc > 26) {
						addError ("You can’t use double sharps in harp parts", nn[i]);
						continue;
					}
					var pedalSetting = parseInt((tpc - 6) / 7);
					var pedalNumber = tpc % 7;
					//logError("tpc "+tpc+" pedalSetting "+pedalSetting+" pedalNum "+pedalNumber+" pedalSetting "+pedalSettings[pedalNumber]);
					if (pedalSettings[pedalNumber] == -1) {
						//logError(pedalLabels[pedalNumber]+pedalAccs[pedalSetting]);
						pedalSettings[pedalNumber] = pedalSetting;
						pedalSettingInThisChord[pedalNumber] = pedalSetting;
					} else {
						if (pedalSettings[pedalNumber] != pedalSetting) {
							//change
							//logError(""+pedalLabels[pedalNumber]+pedalAccs[pedalSettings[pedalNumber]]+"→"+pedalLabels[pedalNumber]+pedalAccs[pedalSetting]);
		
							pedalSettings[pedalNumber] = pedalSetting;
							pedalChangesInThisBar ++;
							//logError("pedalChangesInThisBar now "+pedalChangesInThisBar);
		
							if (pedalChangesInThisBar > 2 && !flaggedPedalChangesInThisBar) {
								addError ("There are a number of pedal changes in this bar.\nIt might be challenging for the harpist to play.",noteRest);
								flaggedPedalChangesInThisBar = true;
							}
		
						}
						// check this chord first
	
						if (pedalSettingInThisChord[pedalNumber] == -1) {
							pedalSettingInThisChord[pedalNumber] = pedalSetting
						} else {
							if (pedalSettingInThisChord[pedalNumber] != pedalSetting && !errorAdded ) {
								//logError("Pedal "+pedalLabels[pedalNumber]+" in this chord was changed to "+pedalAccs[pedalSetting]);
			
								var s = pedalLabels[pedalNumber];
								var ped1 = s+pedalAccs[pedalSettingInThisChord[pedalNumber]];
								var ped2 = s+pedalAccs[pedalSetting];
								var notesToHighlight = [];
								for (var k = 0; k < numNotes; k++) {		
									var temptpc = theNotes[k].tpc;
									var tempPedalNumber = tpc % 7;
									if (tempPedalNumber == pedalNumber) notesToHighlight.push(theNotes[k]);
								}
								addError ("This chord is impossible to play,\nas you have both a "+ped1+" and a "+ped2+".",notesToHighlight);
								errorAdded = true;
							}
						}
					}
				}
			}
		}
	}
	
	function checkStemDirection (noteRest) {
		if (noteRest.stem) {
			var stemDir = noteRest.stem.stemDirection;
			if (stemDir > 0) {
				if (noteRest.beam == null) {
					//calc dir
					var calcDir = 0;
					var nNotes = noteRest.notes.length;
					if (nNotes == 1) {
						if (noteRest.notes[0].line < 4) calcDir = 2;
						if (noteRest.notes[0].line > 4) calcDir = 1;
					} else {
						var minL = noteRest.notes[0].line - 4;
						var maxL = minL;
					
						for (var i=1; i<nNotes; i++) {
							var l = noteRest.notes[i].line - 4;
							if (l < minL) minL = l;
							if (l > maxL) maxL = l;
						}
						if (Math.abs(minL) > Math.abs(maxL)) calcDir = 2;
						if (Math.abs(minL) < Math.abs(maxL)) calcDir = 1;
					}
					if (calcDir > 0 && stemDir != calcDir) {
						addError("Note has had stem direction flipped. If this is not deliberate,\nreset it by clicking ‘Format→Reset Shapes and Positions’",noteRest);
					}
				}
			}
		}
	}
	
	function checkGraceNotes (graceNotes,staffNum) {
		var n = graceNotes.length;
		if (n == 0) return;
		if (n == 1) {
			var hasSlash = graceNotes[0].stemSlash != null;
			if (graceNotes[0].duration.ticks != division * 0.5 || !hasSlash) {
				var errorStr = "A single grace-note should ";
				if (graceNotes[0].duration.ticks != division * 0.5) {
					errorStr += "be a quaver ";
					if (!hasSlash) errorStr += "with a slash";
				} else {
					errorStr += "have a slash through the stem";
				}
				errorStr += "\ni.e. the first item in the Grace notes palette (see Behind Bars, p. 125)";
				addError (errorStr,graceNotes[0]);
			}
		}
		if (n > 1 && graceNotes[0].duration.ticks < division * 0.25) addError ("It is recommended that grace notes use only\n1 or 2 beams (see ‘Behind Bars’, p. 125).",graceNotes[0]);

		if (!isSlurred) {
			//logError("Grace note parent "+graceNotes[0].parent.name+" p p "+graceNotes[0].parent.parent.name);
			if (getArticulationArray(graceNotes[0],staffNum) == null) addError("In general, grace-notes should always be slurred to the main note,\nunless you add staccatos or accents to them",graceNotes[0]);
		}
	}
	
	function getArticulationArray (noteRest, staffNum) {
		// I WISH: you could just get the articulations of a note instead of having to do this hack
		// I WISH: you could get the staffidx of a note/staff
		if (typeof staffNum !== 'number') logError("getArticulationArray() — articulation error staffNum wrong");
		var theTick;
		if (noteRest.parent.type == Element.CHORD) {
			theTick = noteRest.parent.parent.tick;
		} else {
		 theTick = noteRest.parent.tick;
	 }
		//logError("Getting artic at tick = "+theTick);
		
		if (theTick == undefined || theTick == null) {
			logError("getArticulationArray() — couldn’t get articulation tick for this item = "+theTick);
		} else {
			if (articulations[staffNum] == null || articulations[staffNum] == undefined) {
				logError("getArticulationArray() — articulations["+staffNum+"] is undefined "+staffNum.length);
			} else {
				if (articulations[staffNum][theTick] == null || articulations[staffNum][theTick] == undefined) return null;
				
				//logError("articArray[theTick] has "+articulations[staffNum][theTick].length+" items");
				
				return articulations[staffNum][theTick];
			}
		}
		return null;
	}
	
	function checkRehearsalMark (textObject) {
		//logError("Found reh mark "+textObject.text);
		
		if (textObject.text !== expectedRehearsalMark && !flaggedRehearsalMarkError) {
			flaggedRehearsalMarkError = true;
			addError ("This is not the rehearsal mark I would expect.\nDid you miss rehearsal mark ‘"+expectedRehearsalMark+"’?", textObject);
		}
		
		numRehearsalMarks ++;
		var currASCIICode = expectedRehearsalMark.charCodeAt(0);
		if (currASCIICode == 90) {
			expectedRehearsalMarkLength ++;
			currASCIICode = 65;
		} else {
			currASCIICode ++;
		}
		expectedRehearsalMark = '';
		for (var i = 0; i<expectedRehearsalMarkLength; i++) {
			expectedRehearsalMark += String.fromCharCode(currASCIICode);
		}
	}
	
	function checkRehearsalMarks () {
		//logError("Found "+numRehearsalMarks+" rehearsal marks");
		if (numRehearsalMarks == 0) {
			addError("No rehearsal marks have been added.\nIf this piece will be conducted, you should add rehearsal marks every 8–16 bars.","pagetop");
		} else {
			if (numRehearsalMarks < curScore.nmeasures / 30) {
				if (numRehearsalMarks == 1) {
					addError("There is only one rehearsal mark.\nWe recommend adding rehearsal marks every 8–16 bars, approximately.","pagetop");
				} else {
					addError("There are only "&numRehearsalMarks&" rehearsal marks.\nWe recommend adding rehearsal marks every 8–16 bars, approximately.","pagetop");
				}
			}
		}
	}
	
	function checkPianoStretch (noteRest) {
		// CHECK PIANO STRETCH
		var lowestPitch = noteRest.notes[0].pitch;
		var highestPitch = lowestPitch;
		var numNotes = noteRest.notes.length;
		// may not need to do this — TO FIX
		for (var i = 1; i < numNotes; i++) {
			var pitch = noteRest.notes[i].pitch;
			if (pitch > highestPitch) highestPitch = pitch;
			if (pitch < lowestPitch) lowestPitch = pitch;
		}
		var stretch = highestPitch - lowestPitch;
		if (stretch > 14 && stretch < 16) addError("This chord may be too wide to stretch for some pianists.\nConsider splitting it between the hands.",noteRest);
		if (stretch > 16) addError("This chord is too wide to stretch.\nConsider splitting it between the hands.",noteRest);
		if (stretch < 14 && numNotes > 5) addError("It looks like there are too many notes in this chord to play in one hand.\nConsider splitting it between the hands.",noteRest);
	}
	
	function checkOneNoteTremolo (noteRest, tremolo) {
		if (tremolo == null || tremolo == undefined) logError("checkOneNoteTremolo() — tremolo is "+tremolo);
		var tremDescription = tremolo.subtypeName();
		var tremSubdiv;
		if (tremDescription.includes("eighth")) {
			tremSubdiv = 8;
		} else {
			var tremSubdiv = parseInt(tremDescription.match(/\d+/)[0]);
		}
		var strokesArray = [0,8,16,32,64];
		var numStrokes = strokesArray.indexOf(tremSubdiv);
		//logError("TREMOLO: parent parent tick is "+tremolo.parent.parent.tick);
		//logError("TREMOLO: bbox height is "+tremolo.bbox.height+" elements is "+tremolo.elements);
		var dur = parseFloat(noteRest.duration.ticks) / division;
		//logError(" TREMOLO HAS "+numStrokes+" strokes); dur is "+dur;
		switch (numStrokes) {
			case 0:
				logError("checkOneNoteTremolo — Couldn't calculate number of strokes");
				break;
			case 1:
				if (!flaggedOneStrokeTrem) addError("Are you sure you want a one-stroke measured tremolo here?\nThese are almost always better written as quavers.",noteRest);
				flaggedOneStrokeTrem = true;
				break;
			case 2:
				if (dur >= 0.25 && dur < 0.5) addError("You don’t need more than 1 stroke for an unmeasured tremolo on semiquavers.",noteRest);
					break;
			case 3:
				if (dur >= 0.25 && dur < 0.5) addError("You don’t need more than 1 stroke for an unmeasured tremolo on semiquavers.",noteRest);
				if (dur >= 0.5 && dur < 1) addError("You don’t need more than 2 strokes for an unmeasured tremolo on quavers.",noteRest);
				break;
			default:
				addError("You don’t need more than 3 strokes for an unmeasured tremolo.",noteRest);
				break;
		}
	}
	
	function checkTwoNoteTremolo (noteRest, tremolo) {
		if (tremolo == null || tremolo == undefined) logError("checkTwoNoteTremolo() — tremolo is "+tremolo);
		var tremDescription = tremolo.subtypeName();
		var tremSubdiv = parseInt(tremDescription.match(/\d+/)[0]);
		var strokesArray = [0,8,16,32,64];
		var numStrokes = strokesArray.indexOf(tremSubdiv);
		var dur = 2 * parseFloat(noteRest.duration.ticks) / division;
		//logError(" TREMOLO HAS "+numStrokes+" strokes); dur is "+dur;
		if (isStringInstrument && !isSlurred) {
			addError("Fingered tremolos for strings should always be slurred.",noteRest);
			return;
		}
		if (isPitchedPercussionInstrument) {
			addError(errors,"It’s best to write "+currentInstrumentName.toLowerCase()+" tremolos as one-note tremolos (through stem),\nrather than two-note tremolos (between notes).",noteRest);
			return;
		}
		switch (numStrokes) {
			case 0:
				logError("checkTwoNoteTremolo() — Couldn't calculate number of strokes");
				break;
			case 1:
				addError("Are you sure you want a one-stroke measured tremolo here?\nThese are almost always better written as quavers.",noteRest);
				break;
			case 2:
				if (dur >= 0.25 && dur < 0.5) addError("You don’t need more than 1 stroke for an unmeasured tremolo on semiquavers.",noteRest);
					break;
			case 3:
				if (dur >= 0.25 && dur < 0.5) addError("You don’t need more than 1 stroke for an unmeasured tremolo on semiquavers.",noteRest);
				if (dur >= 0.5 && dur < 1) addError("You don’t need more than 2 strokes for an unmeasured tremolo on quavers.",noteRest);
				break;
			default:
				addError("You don’t need more than 3 strokes for an unmeasured tremolo.",noteRest);
				break;
		}
	}
	
	function checkGliss (noteRest, gliss) {
		if (gliss == null || gliss == undefined) logError("checkGliss() — gliss is "+gliss);
		//logError("CHECKING GLISS — "+gliss.glissShowText+" | "+gliss.glissText+" | "+gliss.glissType+" | "+gliss.glissandoStyle);
		//if (gliss.glissShowText) {
			//addError("Including the word ‘gliss.’ in glissandi is  — switch it off in Properties",gliss);
			//return;
			//}
	}
	
	function addError (text,element) {
		if (element == null || element == undefined) {
			logError("addError() — element undefined for text: "+text);
		} else {
			errorStrings.push(text);
			errorObjects.push(element);
		}
	}
	
	function showAllErrors () {
		curScore.startCmd()
		for (var i in errorStrings) {
			var text = errorStrings[i];
			var element = errorObjects[i];
			var isArray = Array.isArray(element);
			var objectArray;
			if (isArray) {
				objectArray = element;
			} else {
				objectArray = [element];
			}
			for (var j in objectArray) {
				element = objectArray[j];
				var eType = element.type;
				var staffNum = 0;
				var elementHeight = 0;
				var commentOffset = 1.0;
				var tick = 0, desiredPosX = 0, desiredPosY = 0, commentPage = null;
			
				// the errorObjects array contains a list of the Elements to attach the text object to
				// There are 4 special strings you can use instead of an Element: these are special locations that don't necessarily have an element there
				// Here are the strings, and where the text object will be attached
				// 		top 				— top of bar 1, staff 1
				// 		pagetop			— top left of page 1
				//		system1 n		— top of bar 1, staff n
				//		system2 n		— first bar in second system, staff n
			
				var isString = typeof element === 'string';
				var theLocation = element;
				if (isString) {
					if (element.includes(' ')) {
						staffNum = parseInt(element.split(' ')[1]); // put the staff number as an 'argument' in the string
						theLocation = element.split(' ')[0];
						if (theLocation === "system2" && !hasMoreThanOneSystem) continue; // don't show if only one system
					}
				} else {
					// calculate the staff number that this element is on
					if (element.bbox == undefined) {
						logError("showAllErrors() — bbox undefined — elem type is "+element.name);
					} else {
						elementHeight = element.bbox.height;
						if (eType != Element.MEASURE) {
							var elemStaff = element.staff;
							if (elemStaff == undefined) {
								isString = true;
								theLocation = "";
								desiredPosX = element.bbox.x;
								desiredPosY = element.bbox.y;
								//logError(" x = "+desiredPosX+"); y = "+desiredPosY;
							} else {
								while (!curScore.staves[staffNum].is(elemStaff)) staffNum ++; // I WISH: staffNum = element.staff.staffidx
							}
						}
					}
				}
				// add a text object at the location where the element is
				var comment = newElement(Element.STAFF_TEXT);
				comment.text = text;
		
				// style the text object
				comment.frameType = 1;
				comment.framePadding = 0.6;
				comment.frameWidth = 0.2;
				comment.frameBgColor = "yellow";
				comment.frameFgColor = "black";
				comment.fontSize = 7.0;
				comment.fontFace = "Helvetica";
				comment.autoplace = false;
				var spannerArray = [Element.HAIRPIN, Element.SLUR, Element.PEDAL, Element.PEDAL_SEGMENT, Element.OTTAVA, Element.OTTAVA_SEGMENT];
				if (isString) {
					if (theLocation === "pagetop") {
						desiredPosX = 2.5;
						desiredPosY = 10.;
					}
					if (theLocation === "system1" || theLocation === "system2") desiredPosX = 5.0;
					if (theLocation === "system2") tick = firstBarInSecondSystem.firstSegment.tick;
				} else {
					if (spannerArray.includes(eType)) {
						tick = element.spannerTick.ticks;
					} else {
						if (eType == Element.MEASURE) {
							tick = element.firstSegment.tick;
						} else {
							if (element.parent == undefined || element.parent == null) {
								logError("showAllErrors() — ELEMENT PARENT IS "+element.parent+"); etype is "+element.name);
							} else {
								if (element.parent.type == Element.CHORD) {
									// it's either a notehead or a gracenote
									if (element.parent.parent.type == Element.CHORD) {
										// it's a grace note, so need to get parent of parent
										tick = element.parent.parent.parent.tick;
									} else {
										tick = element.parent.parent.tick;
									}
								} else {
									tick = element.parent.tick;
								}
							}
						}
					}
				}
		
				// style the element
				if (element !== "pagetop" && element !== "top") {
					if (element.type == Element.CHORD) {
						element.color = "hotpink";
						for (var i=0; i<element.notes.length; i++) element.notes[i].color = "hotpink";
					} else {
						element.color = "hotpink";
					}
				}
				
				// add text object to score
				if (j == 0) {
					var cursor = curScore.newCursor();
					cursor.staffIdx = staffNum;
					cursor.rewindToTick(tick);
					cursor.add(comment);
					comment.z = currentZ;
					currentZ ++;
					var commentHeight = comment.bbox.height;					
					if (desiredPosX != 0) comment.offsetX = desiredPosX - comment.pagePos.x;
					if (desiredPosY != 0) {
						comment.offsetY = desiredPosY - comment.pagePos.y;
					} else {
						comment.offsetY -= commentHeight;
					}
					var commentTopRounded = Math.round(comment.pagePos.y);
					var commentPage = comment.parent.parent.parent.parent; // in theory this should get the page
					if (commentPage != null && commentPage != undefined) {
						var commentPageNum = commentPage.pagenumber;
						var theOffset = commentPosOffset[commentPageNum][commentTopRounded+1000];
						if (theOffset > 4 * commentOffset) {
							theOffset = 0;
							commentPosOffset[commentPageNum][commentTopRounded+1000] = 0;
						} else {
							commentPosOffset[commentPageNum][commentTopRounded+1000] += commentOffset;
						}
						comment.offsetY -= theOffset;
						comment.offsetX += theOffset;
					}
				}
			}
		} // var i
		curScore.endCmd();
	}
	
	function selectTitleText () {
		curScore.startCmd();
		cmd("title-text");
		cmd("select-similar");
		curScore.endCmd();
	}
	
	function logError (str) {
		numLogs ++;
		errorMsg += "\nStaff "+currentStaffNum+", b. "+currentBarNum+": "+str;
	}
	
	function saveSelection () {
		selectionArray = [];
		if (curScore.selection.isRange) {
			selectionArray[0] = curScore.selection.startSegment.tick;
			selectionArray[1] = curScore.selection.endSegment.tick;
			selectionArray[2] = curScore.selection.startStaff;
			selectionArray[3] = curScore.selection.endStaff;
		}
	}
	
	function selectAll () {
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,curScore.nstaves);
		curScore.endCmd();
	}
	
	function restoreSelection () {
		curScore.startCmd();
		if (selectionArray.length == 0) {
			curScore.selection.clear();
		} else {
			var st = selectionArray[0];
			var et = selectionArray[1];
			var ss = selectionArray[2];
			var es = selectionArray[3];
			curScore.selection.selectRange(st,et+1,ss,es + 1);
		}
		curScore.endCmd();
	}
	
	function deleteAllCommentsAndHighlights () {

		//errorMsg = "Num elemns: "+elems.length;
		var elementsToRemove = [];
		var elementsToRecolor = [];
		
		// ** SAVE CURRENT SELECTION ** //
		saveSelection();
		
		// ** CHECK TITLE TEXT FOR HIGHLIGHTS ** //
		selectTitleText();
		
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			var c = e.color;	
			// style the element pink
			if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
		}
		
		// **** SELECT ALL **** //
		selectAll();
		
		// **** GET ALL OTHER ITEMS **** //
		var elems = curScore.selection.elements;
		
		// **** LOOP THROUGH ALL ITEMS AND ADD THEM TO AN ARRAY IF THEY MATCH **** //
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			var t = e.type;
			var c = e.color;	
			// style the element
			if (Qt.colorEqual(c,"hotpink")) {
				elementsToRecolor.push(e);
			} else {
				if (t == Element.STAFF_TEXT) {
					if (Qt.colorEqual(e.frameBgColor,"yellow") && Qt.colorEqual(e.frameFgColor,"black")) elementsToRemove.push(e);
				}
			}
		}
		
		var segment = curScore.firstSegment();
		while (segment) {
			if (segment.segmentType == Segment.TimeSig) {
				for (var i = 0; i < curScore.nstaves; i++) {
					var theTimeSig = segment.elementAt(i*4);
					if (theTimeSig.type == Element.TIMESIG) {
						var c = theTimeSig.color;
						if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(theTimeSig);
					}
				}
			}
			segment = segment.next;
		}
		
		// **** DELETE EVERYTHING IN THE ARRAY **** //
		curScore.startCmd();
		for (var i = 0; i < elementsToRecolor.length; i++) elementsToRecolor[i].color = "black";
		for (var i = 0; i < elementsToRemove.length; i++) removeElement(elementsToRemove[i]);
		curScore.endCmd();
		
		restoreSelection();
	}
	
	StyledDialogView {
		id: dialog
		title: "CHECK COMPLETED"
		contentHeight: 232
		contentWidth: 456
		property var msg: ""

		Text {
			id: theText
			width: parent.width-40
			x: 20
			y: 20

			text: "MN CHECK LAYOUT AND INSTRUMENTATION"
			font.bold: true
			font.pointSize: 18
		}
		
		Rectangle {
			x:20
			width: parent.width-40
			y:45
			height: 1
			color: "black"
		}

		ScrollView {
			id: view
			x: 20
			y: 60
			height: parent.height-100
			width: parent.width-40
			leftInset: 0
			leftPadding: 0
			ScrollBar.vertical.policy: ScrollBar.AsNeeded
			TextArea {
				text: dialog.msg
				wrapMode: TextEdit.Wrap
				leftInset: 0
				leftPadding: 0
				readOnly: true
			}
		}

		ButtonBox {
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				margins: 10
			}
			buttons: [ ButtonBoxModel.Ok ]
			navigationPanel.section: dialog.navigationSection
			onStandardButtonClicked: function(buttonId) {
				if (buttonId === ButtonBoxModel.Ok) {
					dialog.close()
				}
			}
		}
	}
	
	ApplicationWindow {
		id: progress
		title: "PROGRESS"
		property var progressPercent: 0
		visible: false
		flags: Qt.Dialog | Qt.WindowStaysOnTopHint
		width: 500
		height: 200        

		ProgressBar {
			id: progressBar
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.verticalCenter
				margins: 10
			}
			value: progress.progressPercent
			to: 100
		}
		
		FlatButton {            
			accentButton: true
			text: "Ok"
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				margins: 10
			}
			onClicked: progress.close()
		}
	}

}
