/*
 * Copyright (C) 2025 Michael Norris
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
	requiresScore: true
	title: "MN Check Layout and Instrumentation"
	id: mnchecklayoutandinstrumentation
	thumbnailName: "MNCheckLayoutAndInstrumentation.png"
	menuPath: "Plugins.MNCheckLayoutAndInstrumentation"
	
	// **** TEXT FILE DEFINITIONS **** //
	FileIO { id: techniquesfile; source: Qt.resolvedUrl("./assets/techniques.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: canbeabbreviatedfile; source: Qt.resolvedUrl("./assets/canbeabbreviated.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: instrumentrangesfile; source: Qt.resolvedUrl("./assets/instrumentranges.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: metronomemarkingsfile; source: Qt.resolvedUrl("./assets/metronomemarkings.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: shouldbelowercasefile; source: Qt.resolvedUrl("./assets/shouldbelowercase.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: shouldhavefullstopfile; source: Qt.resolvedUrl("./assets/shouldhavefullstop.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: spellingerrorsanywherefile; source: Qt.resolvedUrl("./assets/spellingerrorsanywhere.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: spellingerrorsatstartfile; source: Qt.resolvedUrl("./assets/spellingerrorsatstart.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: tempomarkingsfile; source: Qt.resolvedUrl("./assets/tempomarkings.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: tempochangemarkingsfile; source: Qt.resolvedUrl("./assets/tempochangemarkings.txt").toString().slice(8); onError: { console.log(msg); } }

	// ** DEBUG **
	property var debug: true
	property var errorMsg: ''
	property var currentZ: 16384
	property var numLogs: 0
	
	// **** PROPERTIES **** //
	property var spatium: 0
	property var inchesToMM: 25.4
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
	property var displayBarNum: 0
	property var hasMoreThanOneSystem: false
	property var scoreIncludesTransposingInstrument: false
	property var virtualBeatLength: 0
	property var barStartTick: 0
	property var barEndTick: 0
	property var currTick: 0
	property var numBars: 0
		
	// ** FLAGS ** //
	property var flaggedWeKnowWhosPlaying: false
	property var flaggedDivError: false
	property var flaggedRehearsalMarkError: false
	property var flaggedInstrumentRange: false
	property var flaggedFlippedStem: false
	property var flaggedPedalIssue: false
	property var flaggedNoLyrics: false
	property var flaggedWrittenStaccato: false
	property var flaggedFastMultipleStops: false
	property var flaggedOneStrokeTrem: false
	property var firstVisibleStaff: 0
	property var staffVisible: []
	property var haveHadPlayingIndication: false
	property var flaggedSlurredStaccatoBar: -10
	property var isNote: false
	property var isRest: false
	
	// ** COMMMENTS ** //
	property var prevCommentPage: null
	property var commentPosOffset: []
	
	// ** PARTS ** //
	property var isGrandStaff: []
	property var isTopOfGrandStaff: []
	property var numGrandStaves: []
	property var grandStaffTops: []
	property var numParts: 0
	property var numStaves: 0
	property var parts: null
	property var scoreHasStrings: false
	property var scoreHasWinds: false
	property var scoreHasBrass: false
	
	// ** TEXT FILES ** //
	property var techniques: []
	property var canbeabbreviated: []
	property var metronomemarkings: []
	property var shouldbelowercase: []
	property var shouldhavefullstop: []
	property var spellingerrorsanywhere: []
	property var spellingerrorsatstart: []
	property var tempomarkings: []
	property var tempochangemarkings: []
	property var instrumentranges: []
	property var lastTempoChangeMarkingBar: -1
	property var tempoChangeMarkingEnd: -1
	property var lastTempoChangeMarking: null
	property var lastTempoMarking: null
	property var lastTempoMarkingBar: -1
	property var lastArticulationTick: -1
	property var lastDynamicTick: -1
	property var lastMetronomeMarkingBar: -1
	property var numConsecutiveMusicBars: 0
	property var currentStaffNum: 0
	property var currentTimeSig: null
	property var prevTimeSig: ""
	property var prevClefId: null
	property var prevDynamic: ""
	property var prevDynamicObject: null
	property var prevDynamicBarNum: 0
	property var prevDynamicDisplayBarNum: 0
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
	property var instrumentCalcIds: []
	property var instrumentNames: []
	property var currentInstrumentName: ""
	property var currentInstrumentId: ""
	property var currentInstrumentCalcId: ""
	property var isWindInstrument: false
	property var isBrassInstrument: false
	property var isWindOrBrassInstrument: false
	property var isStringInstrument: false
	property var isStringSection: false
	property var isFlute: false
	property var isHorn: false
	property var isTrombone: false
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
	property var firstPageNum: 0
	property var lastPageNum: 0
	property var numPages: 0
	property var systemStartBars: []
	property var tempoText: []
	property var lowestPitchPossible: 0
	property var highestPitchPossible: 0
	property var quietRegisterThresholdPitch: 0
	property var highLoudRegisterThresholdPitch: 0
	property var lowLoudRegisterThresholdPitch: 0
	property var lastDynamicFlagBar: -1
	
	// ** DYNAMICS ** //
	property var dynamics: []
	property var currDynamicLevel: 0
	
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
	property var currentSlurLength: 0
	property var prevSlurLength: 0
	
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
	
	// ** consts for articulation symbols ** //
	// for the most part (except tenutos — WHY???), the ‘below’ versions of the symbols are just +1
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
	property var prevNotes: []
	property var selectionArray: []
	property var isTrem: false
	property var prevWasGraceNote: false
	property var firstDynamic: false
	property var progressShowing: false
	property var progressStartTime: 0
	
	// ** HARP ** //
	property var pedalSettings: [-1,-1,-1,-1,-1,-1,-1]
	property var pedalChangesInThisBar: 0
	property var flaggedPedalChangesInThisBar: false
	property var cmdKey: 'command'
	
	// ** VOICE ** //
	property var isMelisma: []
	property var melismaEndTick: []
	
	// ** FONTS ** //
	property var tempoFontStyle: 0
	property var metronomeFontStyle: 0
	
  onRun: {
		if (!curScore) return;
		
		setProgress (0);
		
		// **** VERSION CHECK **** //
		var versionafter450 = mscoreMajorVersion > 4 || mscoreMinorVersion > 5 || (mscoreMinorVersion == 5 && mscoreUpdateVersion > 0);

		if (!versionafter450) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin requires MuseScore v. 4.5.1 or later.</p> ";
			dialog.show();
			return;
		}
		
		//version450 = mscoreMajorVersion == 4 && mscoreMinorVersion == 5 && mscoreUpdateVersion == 0;
		
		// **** DECLARATIONS & DEFAULTS **** //
		var scoreHasTuplets = false;
		
		// **** READ IN TEXT FILES **** //
		techniques = techniquesfile.read().trim().split('\n');
		canbeabbreviated = canbeabbreviatedfile.read().trim().split('\n');
		var tempmetronomemarkings = metronomemarkingsfile.read().trim().split('\n');
		var augmentationDots = ['','.','\uECB7','metAugmentationDot']; // all the possible augmentation dots (including none)
		var spaces = [""," ","\u00A0"]; // all the possible spaces (that last one is a non-breaking space)
		for (var i = 0; i < tempmetronomemarkings.length; i++) {
			var mark = tempmetronomemarkings[i];
			for (var j = 0; j<augmentationDots.length; j++) {
				var augDot = augmentationDots[j];
				for (var k = 0; k<spaces.length; k++) {
					var space = spaces[k];
					metronomemarkings.push(mark+augDot+space+"=");
				}
			}
		}
		shouldbelowercase = shouldbelowercasefile.read().trim().split('\n');
		shouldhavefullstop = shouldhavefullstopfile.read().trim().split('\n');
		spellingerrorsanywhere = spellingerrorsanywherefile.read().trim().split('\n');
		//logError(spellingerrorsanywhere);
		spellingerrorsatstart = spellingerrorsatstartfile.read().trim().split('\n');
		tempomarkings = tempomarkingsfile.read().trim().split('\n');
		tempochangemarkings = tempochangemarkingsfile.read().trim().split('\n');
		var tempinstrumentranges = instrumentrangesfile.read().trim().split('\n');
		for (var i = 0; i < tempinstrumentranges.length; i++) instrumentranges.push(tempinstrumentranges[i].split(','));
		
		// **** INITIALISE MAIN VARIABLES **** //
		var staves = curScore.staves;
		numStaves = curScore.nstaves;
		firstBarInScore = curScore.firstMeasure;
		lastBarInScore = curScore.lastMeasure;
		var firstSystem = firstBarInScore.parent;
		var lastSystem = lastBarInScore.parent;
		var firstPage = firstSystem.parent;
		var lastPage = lastSystem.parent;
		firstPageNum = firstPage.pagenumber;
		lastPageNum = lastPage.pagenumber;
		numPages = lastPageNum - firstPageNum + 1;
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		parts = curScore.parts;
		var n = parts.length;
		// ** calculate number of parts, but ignore hidden ones
		for (var i = 0; i < n; i++) if (parts[i].show) numParts ++;
		isSoloScore = (numParts == 1);
		if (Qt.platform.os !== "osx") cmdKey = "ctrl";
		var numExcerpts = curScore.excerpts.length;
		
		if (numParts > 1 && numExcerpts < numParts) addError ("Parts have not yet been created/opened, so I wasn’t able to check the part settings.\nYou can do this by clicking ‘Parts’ then ’Open All’.\n\nOnce you have created and opened the parts, please run this again to check the parts.\nIgnore this message if you do not plan to create parts.","pagetopright");
		
		spatium = curScore.style.value("spatium")*inchesToMM/mscoreDPI; // NB spatium value is given in MuseScore's DPI setting
		pageWidth = Math.round(curScore.style.value("pageWidth")*inchesToMM);
		pageHeight = Math.round(curScore.style.value("pageHeight")*inchesToMM);
		var viewHeight = Math.round(firstPage.bbox.height*spatium);
		
		if (viewHeight != pageHeight) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin works best if the score is viewed in Page View.</p><p>Change ‘Continuous View’ to ‘Page View’ from the pop-up menu in the bottom-right of the window.</p>";
			dialog.show();
			return;
		}
				
		initialTempoExists = false;
		hasMoreThanOneSystem = !lastSystem.is(firstSystem);	
				
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

		// ************  	GO THROUGH ALL INSTRUMENTS & STAVES LOOKING FOR INFO 	************ //
		analyseInstrumentsAndStaves();
		
		// ************  				SAVE CURRENT SELECTION 						************ //
		saveSelection();
		
		// ************  		DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS 		************ //
		deleteAllCommentsAndHighlights();

		// ************  				CHECK SCORE & PAGE SETTINGS 				************ // 
		checkScoreAndPageSettings();
		
		// ************  					CHECK PART SETTINGS 					************ // 
		if (numParts > 1 && numExcerpts >= numParts) checkPartSettings();
		
		// ************					CHECK IF SCORE IS TRANSPOSED				************ //
		if (curScore.style.value("concertPitch") && scoreIncludesTransposingInstrument) addError ("It looks like you have at least one transposing instrument, but the score is currently displayed in concert pitch.\nUntick ‘Concert Pitch’ in the bottom right to display a transposed score (see ‘Behind Bars’, p. 505)","pagetop");
		
		// ************  					CHECK TITLE PAGE EXISTS 				************ // 
		if (lastPageNum > 1 && firstPageNum == 0) addError ("This score is longer than 2 pages, but doesn’t appear to have a title page.\n(Ignore this if you are planning to add a title page to the score in another app.)","pagetop");
		
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
		for (var i = 0; i <= lastPageNum; i++) commentPosOffset[i] = Array(10000).fill(0);
		
		// ************  					SELECT AND PRE-PROCESS ENTIRE SCORE 							************ //
		selectAll();
		setProgress (1);
		
		// ************  	GO THROUGH THE SCORE LOOKING FOR ANY SPANNERS (HAIRPINS, SLURS, OTTAVAS, ETC) 	************ //
		analyseSpanners();
		setProgress (2);
		
		// ************  				CHECK TITLE TEXT AND STAFF TEXT OBJECTS FOR ERRORS 					************ //
		checkScoreText();
		
		// ************ 								CHECK TIME SIGNATURES								************ //
		checkTimeSignatures();
		
		// ************ 							CHECK FOR STAFF ORDER ISSUES 							************ //
		checkStaffOrder();
		
		// ************  							CHECK STAFF NAMES ISSUES 								************ // 
		checkStaffNames();
		
		// ************  							CHECK LOCATION OF FINAL BAR								************ // 
		checkLocationOfFinalBar();
		
		// ************  					CHECK LOCATIONS OF BOTTOM SYSTEMS ON EACH PAGE 					************ // 
		if (numPages > 1) checkLocationsOfBottomSystems();
		
		// ************ 								CHECK FOR FERMATA ISSUES 							************ ///
		if (!isSoloScore && numStaves > 2) checkFermatas();
		
		setProgress (3);
		
		// ************ 			PREP FOR A FULL LOOP THROUGH THE SCORE 				************ //
		var currentBar, prevBarNum, numBarsProcessed, wasTied, isFirstNote;
		var firstBarNum, firstSegmentInScore;
		var prevDisplayDur, tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;
		var includesTransposingInstruments = false;
		var currentSlur, numSlurs, nextSlurStart, currentSlurEnd, prevSlurEnd;
		var currentPedal, currentPedalNum, numPedals, nextPedalStart, currentPedalEnd, flaggedPedalLocation;
		var currentOttavaNum, numOttavas, nextOttavaStart, currentOttavaEnd;
		var currentHairpinNum, numHairpins, nextHairpinStart, nextHairpin, expressiveSwell;
		var numSystems, currentSystem, currentSystemNum, numNoteRestsInThisSystem, numBeatsInThisSystem, noteCountInSystem, beatCountInSystem;
		var maxNoteCountPerSystem, minNoteCountPerSystem, maxBeatsPerSystem, minBeatsPerSystem, actualStaffSize;
		var isSharedStaff;
		var loop = 0;
		var prevTick = [], prevCheckedClef;
		
		firstBarInScore = curScore.firstMeasure;
		
		//logError ("Trying bracket: "+curScore.systemBracket+" "+firstBarInScore.systemBracket+" "+firstBarInScore.parent.systemBracket);
		
		currentBar = firstBarInScore;
		lastBarInScore = curScore.lastMeasure;
		numBars = curScore.nmeasures;
		cursor.rewind(Cursor.SCORE_END);
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
			prevDynamicObject = null;
			prevDynamicBarNum = 0;
			prevDynamicDisplayBarNum = 0;
			prevClefId = null;
			prevMultipleStop = null;
			prevIsMultipleStop = false;
			prevMultipleStopInterval = 0;
			prevSlurLength = 0;
			currentSlurLength = 0;
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
			tempoChangeMarkingEnd = -1;
			prevCheckedClef = null;
			lastTempoMarking = null;
			lastTempoMarkingBar = -1;
			lastMetronomeMarkingBar = -1;
			lastArticulationTick = -1;
			lastDynamicTick = -1;
			numConsecutiveMusicBars = 0;
			lastDynamicFlagBar = -1;
			
			// ** clear flags ** //
			flaggedInstrumentRange = 0;
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
			haveHadPlayingIndication = false;
			flaggedSlurredStaccatoBar = -10;
			
			// ** slurs
			currentSlur = null;
			isSlurred = false;			
			currentSlurNum = 0;
			currentSlurEnd = 0;	
			numSlurs = slurs[currentStaffNum].length;
			if (numSlurs == 0) {
				nextSlurStart = 0;
			} else {
				var theSlur = slurs[currentStaffNum][0];
				if (theSlur == undefined) {
					logError ("slur undefined!");
				} else {
					nextSlurStart = theSlur.spannerTick.ticks;
				}
			}
			
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
			nextHairpin = (numHairpins == 0) ? null : hairpins[currentStaffNum][0];
			nextHairpinStart = (numHairpins == 0) ? 0 : nextHairpin.spannerTick.ticks;
			expressiveSwell = false;
			
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
			// sometimes the instrument id is vague ('strings.group'), so we need to do a bit more detective work and calculate what the actual instrument is — the calcIds are figured out in the analyseInstrumentsAndStaves routine
			currentInstrumentCalcId = instrumentCalcIds[currentStaffNum];
			setInstrumentVariables();			
			cursor.filter = Segment.HeaderClef;
			cursor.staffIdx = currentStaffNum;
			cursor.voice = 0;
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == null) cursor.next();
			currentBar = cursor.measure;
			currentSystem = null;
			currentSystemNum = 0;
			numNoteRestsInThisSystem = 0;
			numBeatsInThisSystem = 0;
			var clef = cursor.element;
			// call checkClef AFTER the currentInstrumentName/Id setup and AFTER set InstrumentVariables
			if (clef != null) checkClef(clef);
			
			prevTimeSig = currentBar.timesigNominal.str;
			
			// **** CHECK FOR VIBRAPHONE BEING NOTATED ON A GRAND STAFF **** //
			if (currentInstrumentId.includes('vibraphone') && isTopOfGrandStaff[currentStaffNum]) addError('Vibraphones are normally notated on a single treble staff,\nrather than a grand staff.','system1 '+currentStaffNum);
						
			for (var t = 0; t < numStaves * 4; t++) prevTick[t] = -1;
			
			displayBarNum = 0;
			for (currentBarNum = 1; currentBarNum <= numBars && currentBar; currentBarNum ++) {
				if (!currentBar.irregular) displayBarNum ++;
				
				barStartTick = currentBar.firstSegment.tick;
				barEndTick = currentBar.lastSegment.tick;
				var barLength = barEndTick - barStartTick;
				var startTrack = currentStaffNum * 4;
				var goneToNextBar = false;
				var firstNoteInThisBar = null;
				var stretch = currentBar.userStretch;
				//logError("\nb. "+currentBarNum);
				currentTimeSig = currentBar.timesigNominal;
				var timeSigNum = currentTimeSig.numerator;
				var timeSigDenom = currentTimeSig.denominator;
				var beatLength = division;
				var isCompound = !(timeSigNum % 3);
				if (timeSigDenom <= 4) isCompound = isCompound && (timeSigNum > 3);
				if (isCompound && timeSigDenom >= 8) beatLength = (division * 12) / timeSigDenom;
				virtualBeatLength = beatLength;
				if (isCompound) {
					virtualBeatLength = (division * 12) / timeSigDenom;
				} else {
					virtualBeatLength = (division * 4) / timeSigDenom;
				}
				//logError ("Time sig is "+currentTimeSig.str+"; virtual beat length = "+virtualBeatLength);
				if (currentStaffNum == 0) {
					var numBeats = currentTimeSig.numerator;
					if (currentTimeSig.denominator > 8) numBeats /= 2;
					numBeatsInThisSystem += numBeats;
					
					// **** CHECK FOR NON-STANDARD STRETCH FACTOR **** //
					if (stretch != 1) addError("The stretch for this bar is set to "+stretch+";\nits spacing may not be consistent with other bars.\nYou can reset it by choosing Format→Stretch→Reset Layout Stretch.",currentBar);
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
							noteCountInSystem.push(numNoteRestsInThisSystem > numBeatsInThisSystem ? numNoteRestsInThisSystem : numBeatsInThisSystem);
							//logError("Pushed noteCountInSystem["+currentSystemNum+"] = "+noteCountInSystem[currentSystemNum]);
						} else {
							if (numNoteRestsInThisSystem > noteCountInSystem[currentSystemNum]) {
								noteCountInSystem[currentSystemNum] = numNoteRestsInThisSystem;
								//logError("Expanded noteCountInSystem["+currentSystemNum+"] = "+numNoteRestsInThisSystem);
							}
						}
						currentSystemNum ++;
					}
					numNoteRestsInThisSystem = 0;
					numBeatsInThisSystem = 0;
				}
				var numTracksWithNotes = 0;
				var numTracksWithNoteRests = 0;
				var isChord = false;
				pedalChangesInThisBar = 0;
				flaggedPedalChangesInThisBar = false;
				if (currentBarNum % 2) flaggedFastMultipleStops = false;
				
			
				// ************ CHECK HARP ISSUES ************ //
				if (isHarp && (isTopOfGrandStaff[currentStaffNum] || !isGrandStaff[currentStaffNum])) checkHarpIssues(currentBar,currentStaffNum);
				
				// ************ CHECK UNTERMINATED TEMPO CHANGE ************ //
				if (lastTempoChangeMarkingBar != -1 && currentBarNum >= lastTempoChangeMarkingBar + 8) {
					//logError("Found unterminated tempo change in b. "+currentBarNum);
					addError("You have indicated a tempo change here,\nbut I couldn’t find a new tempo marking\nor ‘a tempo’/‘tempo primo’.",lastTempoChangeMarking);
					lastTempoChangeMarkingBar = -1;
				}
				
				// ************ CHECK TEMPO MARKING WITHOUT A METRONOME ************ //
				if (lastTempoMarkingBar != -1 && currentBarNum == lastTempoMarkingBar + 1 && lastMetronomeMarkingBar < lastTempoMarkingBar) {
					//logError("lastTempoMarkingBar = "+lastTempoMarkingBar+" lastMetronomeMarkingBar = "+lastMetronomeMarkingBar);
					addError("This tempo marking doesn’t seem to have a metronome marking.\nIt can be helpful to indicate the specific metronome marking or provide a range.",lastTempoMarking);
					lastTempoChangeMarkingBar = -1;
				}
				
				for (var currentTrack = startTrack; currentTrack < startTrack + 4; currentTrack ++) {
					// **** UPDATE PROGRESS MESSAGE **** //
					var numNotesInThisTrack = 0;
					var numNoteRestsInThisTrack = 0;
					loop++;
					setProgress(5+loop*95./totalNumLoops);
					cursor.filter = Segment.All;
					cursor.track = currentTrack;
					cursor.rewindToTick(barStartTick);
					var processingThisBar = cursor.element && cursor.tick < barEndTick;
					
					prevNote = prevNotes[currentTrack];
					prevWasGraceNote = false;
					while (processingThisBar) {
						isNote = false;
						isRest = false;
						var currSeg = cursor.segment;
						//logError ("Segment type: "+currSeg.segmentType);
						currTick = currSeg.tick;
						
						// ************ CHECK TEMPO & TEMPO CHANGE TEXT FOR THIS SEGMENT *********** //
						if (tempoText.length > 0) {
							var t = tempoText[0];
							if (t.type == Element.GRADUAL_TEMPO_CHANGE) {
								if (currTick > t.spannerTick.ticks) {
									checkTextObject(t);
									tempoChangeMarkingEnd = t.spannerTick.ticks + t.spannerTicks.ticks;
									tempoText.shift();
								}
							} else {
								if (currTick > t.parent.tick) {
									checkTextObject(t);
									tempoText.shift();
								}
							}
						}
						
						if (currTick != barEndTick) {
							
							tickHasDynamic = false;
							if (isMelisma[currentTrack] && melismaEndTick[currentTrack] > 0) isMelisma[currentTrack] = currTick < melismaEndTick[currentTrack];
							var annotations = currSeg.annotations;
							var elem = cursor.element;
							var eType = elem.type;
							var eName = elem.name;
							var sType = currSeg.segmentType;
							
							// ************ CHECK IF IT'S A NOTE OR REST FIRST ************ //
							isNote = eType == Element.CHORD;
							isRest = eType == Element.REST;
						
							// ************ UNDER A SLUR? ************ //
							var readyToGoToNextSlur = false;
							if (currentSlurNum < numSlurs) {
								if (currentSlur == null) {
									readyToGoToNextSlur = true;
								} else {
									if (currTick > currentSlurEnd) {
										currentSlurNum ++;
										//logError ("Now at slur "+currentSlurNum);
										if (currentSlurNum < numSlurs) {
											var nextSlur = slurs[currentStaffNum][currentSlurNum];
											if (currentSlur != null && nextSlur != null) {
												nextSlurStart = nextSlur.spannerTick.ticks;
												var nextSlurLength = nextSlur.spannerTicks.ticks;
												//logError ("currTick "+currTick+" currentSlurEnd "+currentSlurEnd+" nextSlurStart "+nextSlurStart+" hasGraceNotes "+hasGraceNotes);
												if (nextSlurStart < currentSlurEnd && nextSlurLength > 0 && currentSlurLength > 0) {
													var nextSlurNote = getNoteRestAtTick(nextSlurStart);
													if (nextSlurNote != null) {
														if (nextSlurNote.graceNotes != null) {
															//logError ("nextSlurNote.graceNotes.length "+(nextSlurNote.graceNotes.length > 0)+"; nextSlurLength = "+nextSlurLength);
															if (nextSlurNote.graceNotes.length == 0) addError("Avoid putting slurs underneath other slurs.\nDelete one of these slurs.",nextSlur);
														}
													}
												}
											}
											readyToGoToNextSlur = true;
										}
										currentSlur = null;
										isSlurred = false;
									}
								}
							}
							if (readyToGoToNextSlur) {
								if (currTick >= nextSlurStart) {
									isSlurred = true;
									lastArticulationTick = currTick;
									//logError("Slur started: isSlurred = true");
									currentSlur = slurs[currentStaffNum][currentSlurNum];
									
									//logError ("Found a slur: pagePos = {"+Math.round(currentSlur.pagePos.x*100)/100.+","+Math.round(currentSlur.pagePos.y*100)/100.+"}\nParent system pagePos = {"+Math.round(currentSlur.parent.pagePos.x*100)/100.+","+Math.round(currentSlur.parent.pagePos.y*100)/100.+"}");
									var currentSlurStart = nextSlurStart;
									prevSlurEnd = currentSlurEnd;
									prevSlurLength = currentSlurLength;
									currentSlurLength = currentSlur.spannerTicks.ticks
									currentSlurEnd = currentSlurStart + currentSlurLength;
									//logError("currTick = "+currTick+" — Slur started at "+currentSlurStart+" & ends at "+currentSlurEnd);
									//var off1 = currentSlur.slurUoff1 == undefined ? 0 : currentSlur.slurUoff1.x;
									//var off2 = currentSlur.slurUoff2 == undefined ? 0 : currentSlur.slurUoff2.x;
									///var off3 = currentSlur.slurUoff3 == undefined ? 0 : currentSlur.slurUoff3.x;
									//var off4 = currentSlur.slurUoff4 == undefined ? 0 : currentSlur.slurUoff4.x;
									//logError("Slur offs: "+currentSlur.posX+" "+currentSlur.offsetX+" "+off1+" "+off2+" "+off3+" "+off4); // ALWAYS RETURNS 0 0 0 0 0 0 :-(
									if (currentSlurNum > 0 && currentSlurStart == prevSlurEnd && currentSlurLength > 0 && prevSlurLength > 0) addError ("Don’t start a new slur on the same note\nas you end the previous slur.",currentSlur);

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
									
									lastDynamicTick = currTick;
									if (currTick >= currentHairpinEnd) {
										//logError("Hairpin ended because currTick = "+currTick+" & currentHairpinEnd = "+currentHairpinEnd);
										// was this hairpin long enough to require ending?
										currentHairpin = null;
										isHairpin = false;
										currentHairpinNum ++;
										if (currentHairpinNum < numHairpins) {
											nextHairpin = hairpins[currentStaffNum][currentHairpinNum];
											nextHairpinStart = nextHairpin.spannerTick.ticks;
											readyToGoToNextHairpin = true;
											//logError("nextHairpin num = "+currentHairpinNum+" "+nextHairpin.hairpinType);
										}
									}
								}
							}
							if (readyToGoToNextHairpin) {
								//logError("Next hairpin start = "+nextHairpinStart+" currTick = "+currTick);
							
								if (currTick >= nextHairpinStart) {
									isHairpin = true;
									lastDynamicTick = currTick;
									//logError("currSeg.type = "+currSeg.type+" eType = "+eType+" eName = "+eName);
									
								
									currentHairpin = hairpins[currentStaffNum][currentHairpinNum];

									var hairpinStartTick = currentHairpin.spannerTick.ticks;
									var hairpinDur = currentHairpin.spannerTicks.ticks;
									//logError("found hairpin of type"+currentHairpin.hairpinType+", length "+hairpinDur);

									currentHairpinEnd = hairpinStartTick + hairpinDur;
									if (currentHairpinNum == hairpins[currentStaffNum].length - 1){
										nextHairpin = null;
										nextHairpinStart = -1;
									} else {
										nextHairpin = hairpins[currentStaffNum][currentHairpinNum+1];
										nextHairpinStart = nextHairpin.spannerTick.ticks;
									}
									if (hairpinDur <= barLength) {
										if (expressiveSwell) {
											expressiveSwell = false;
										} else {
											// even numbered hairpin types are cresc; odd-numbere are decresc
											//logError ("hairpinDur = "+hairpinDur+" hairpinType = "+currentHairpin.hairpinType);
											if (hairpinDur <= barLength && (currentHairpin.hairpinType %2 == 0)) {
												if (nextHairpin != null) {	
													//logError ("nextHairpinStart = "+nextHairpinStart+" end = "+(currentHairpinEnd + barLength)+" hairpinType = "+nextHairpin.hairpinType);
													if (nextHairpinStart < currentHairpinEnd + barLength && (nextHairpin.hairpinType %2 == 1)) {
														expressiveSwell = true;
													//logError ("expressiveSwell = true");
													}
												}
											}
											// check hairpin termination if it's not just a little expressive swell 

											if (!expressiveSwell) checkHairpinTermination(cursor);
										}
									}
									
									// **** Hairpin starting underneath a rest? **** //
									//logError ("Checking hairpin: currTick = "+currTick+" hairpinStartTick = "+hairpinStartTick+" prevTick = "+prevTick[currentTrack]+" prevNote = "+prevNote);
									var noteAtHairpinStart = getNoteRestAtTick(hairpinStartTick);
									
									var hairpinStartsOnRest = true;
									if (noteAtHairpinStart != null) hairpinStartsOnRest = noteAtHairpinStart.type == Element.REST;
									//logError ("hairpinStartsOnRest = "+hairpinStartsOnRest+" hairpinStartsAfterRest = "+hairpinStartsAfterRest);
									if (hairpinStartsOnRest) addError ("This hairpin appears to start under a rest.\nAlways start hairpins under notes.",currentHairpin);
									
									//logError("Hairpin started at "+currTick+" & ends at "+currentHairpinEnd);
									if (currentHairpinNum < numHairpins - 1) {
										nextHairpin = hairpins[currentStaffNum][currentHairpinNum+1];
										nextHairpinStart = nextHairpin.spannerTick.ticks;
										//logError("Next slur starts at "+nextHairpinStart);
									} else {
										nextHairpin = null;
										nextHairpinStart = 0;
										//logError("This is the last slur in this staff ");
									}
								}
							}
						
							// ************ FOUND A CLEF ************ //
							if (clefs[currentStaffNum][currTick] != null) {
								var clefToCheck = clefs[currentStaffNum][currTick];
								if (!clefToCheck.is(prevCheckedClef)) {
									//logError ("Check non-header clef "+clefToCheck.subtypeName());
									checkClef(clefToCheck);
									prevCheckedClef = clefToCheck;
								}
							}
							
							// ************ CHECK KEY SIGNATURE ************ //
							if (eType == Element.KEYSIG && currentStaffNum == 0) checkKeySignature(elem,cursor.keySignature);
						
							// ************ CHECK TREMOLO ************ //
							isTrem = (oneNoteTremolos[currentStaffNum][currTick] != null);
						
							
							
							/*
							for (var i = 0; i < tempoText.length; i++) {
								var t = tempoText[i];
								var m;
								if (t.type == Element.TEMPO_TEXT) {
									//logError ("Checking tempo text");
									m = t.parent.parent;
									currentBarNum = 1;
									var tempm = curScore.firstMeasure;
									while (!tempm.is(m)) {
										tempm = tempm.nextMeasure;
										currentBarNum ++;
									}
								}
								if (t.type == Element.GRADUAL_TEMPO_CHANGE) {
									//logError ("checking gradual tempo change");
									var theTicks = t.spannerTick.ticks;
									currentBarNum = 1;
									var tempm = curScore.firstMeasure;
									while (tempm.lastSegment.ticks < theTicks) {
										tempm = tempm.nextMeasure;
										currentBarNum ++;
									}
								}
								if (t.type != Element.TEMPO_TEXT && t.type != Element.GRADUAL_TEMPO_CHANGE) {
									logError ("checkScoreText() — unknown tempo type — "+t.type);
								}
								checkTextObject (t);
							} */
							
							// ************ LOOP THROUGH ANNOTATIONS IN THIS SEGMENT ************ //
							if (annotations && annotations.length) {
								for (var aIndex in annotations) {
									var theAnnotation = annotations[aIndex];
									if (theAnnotation.track == currentTrack) {
										var aType = theAnnotation.type;
										if (aType == Element.GRADUAL_TEMPO_CHANGE || aType == Element.TEMPO_TEXT || aType == Element.METRONOME) continue;
										// **** FOUND A TEXT OBJECT **** //
										if (theAnnotation.text) checkTextObject(theAnnotation);
									}
								}
							}
							
											
							// ************ FOUND A CHORD OR REST ************ //
							if (isNote || isRest) {
								numNoteRestsInThisTrack ++;
								numNoteRestsInThisSystem ++;
								var noteRest = elem;
								if (firstNoteInThisBar == null) firstNoteInThisBar = noteRest;
								var isHidden = !noteRest.visible;
								var displayDur = noteRest.duration.ticks;
								var soundingDur = noteRest.actualDuration.ticks;
								var tuplet = noteRest.tuplet;
								var barsSincePrevNote = currentBarNum - prevBarNum;
								
								if (barsSincePrevNote > 1) {
									minLedgerLines = [];
									maxLedgerLines = [];
									flaggedInstrumentRange = 0;
								}
								
								// ************ CHECK DYNAMICS ********** //

								if (lastDynamicTick < currTick - division * 32 && numConsecutiveMusicBars >= 8 && isNote) {
									lastDynamicTick = currTick + 1;
									addError("This passage has had no dynamic markings for the last while\nConsider adding more dynamic detail to this passage.",noteRest);
								}
							
								// ************ CHECK DYNAMICS UNDER RESTS ********** //

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
									
									// ************ CHECK ARTICULATION ON TIED NOTES ********** //
									if (isTied) {
										var theArticulationArray = getArticulationArray(noteRest,currentStaffNum)
										if (theArticulationArray != null) {
											var hasStaccato = false, hasHarmonic = false;
											for (var i = 0; i < theArticulationArray.length; i++) {
												if (staccatoArray.includes(theArticulationArray[i].symbol)) hasStaccato = true;
												if (theArticulationArray[i].symbol == kHarmonicCircle) hasHarmonic = true;
											}
											if (!hasStaccato && !hasHarmonic) addError("This note has articulation on it, but is tied.\nDid you mean that to be slurred instead?",noteRest);
										}
									}
															
									// ************ CHECK LYRICS ************ //
							
									if (isVoice) checkLyrics(noteRest);
								
									// ************ CHECK GRACE NOTES ************ //
									var graceNotes = noteRest.graceNotes;
									var hasGraceNotes = graceNotes.length > 0;
									if (hasGraceNotes) {
										checkGraceNotes(graceNotes, currentStaffNum);
										numNoteRestsInThisSystem += graceNotes.length / 2; // grace notes only count for half
										prevWasGraceNote = true;
									}
																
									// ************ CHECK STACCATO ISSUES ************ //
									var theArticulationArray = getArticulationArray (noteRest, currentStaffNum);
								
									if (theArticulationArray) {
										lastArticulationTick = currTick;
										for (var i = 0; i < theArticulationArray.length; i++) {
											if (staccatoArray.includes(theArticulationArray[i].symbol)) checkStaccatoIssues (noteRest);
										}
									} else {
										if (lastArticulationTick < currTick - division * 32 && numConsecutiveMusicBars >= 8) {
											if (isStringInstrument || isWindOrBrassInstrument) {
												lastArticulationTick = currTick + 1;
												addError("This passage has had no articulation for the last while\nConsider adding more detail to this passage",noteRest);
											}
										}
									}
								
									var nn = noteRest.notes.length;
									isChord = nn > 1;
									
									// ************ CHECK IF INITIAL DYNAMIC SET ************ //
									if (isChord) checkChordNotesTied(noteRest);
								
								
									// ************ CHECK OTTAVA ************ //
									if (isOttava) checkOttava(noteRest,currentOttava);
								
									// ************ CHECK STEM DIRECTION ************ //
									checkStemDirection(noteRest);
								
									// ************ CHECK LEDGER LINES ************ //
									checkInstrumentalRanges(noteRest);
								
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

									// ************ CHECK RANGE ************ //
									checkInstrumentRange(noteRest);
									
									prevBarNum = currentBarNum;
								
								} // end is rest
								
								// **** CHECK SLUR ISSUES **** //
								// We do this last so we can check if there were grace notes beforehand
								// Also note that we might call 'checkSlurIssues' multiple times for the same slur, because we check for each note under the slur
								if (isSlurred && currentSlur != null) checkSlurIssues(noteRest, currentStaffNum, currentSlur);
							
								prevSoundingDur = soundingDur;
							
							} // end if eType == Element.Chord || .Rest
							
							if (isNote) {
								if (isFirstNote) {
									isFirstNote = false;
								
									// ************ CHECK IF INITIAL DYNAMIC SET ************ //
									if (!firstDynamic && !isGrandStaff[currentStaffNum]) addError("This note should have an initial dynamic level set.",noteRest);
								
								} else {
								
									// ************ CHECK DYNAMIC RESTATEMENT ************ //
									if (barsSincePrevNote > 4 && !tickHasDynamic && !isGrandStaff[currentStaffNum] ) addError("Restate a dynamic here, after the "+(barsSincePrevNote-1)+" bars’ rest.",noteRest);
								
								}
							}
						}
						
						if (tempoChangeMarkingEnd != -1 && currTick > tempoChangeMarkingEnd + division * 2) {
							addError ("You have indicated a tempo change here,\nbut I couldn’t find a new tempo marking\nor ‘a tempo’/‘tempo primo’.",lastTempoChangeMarking);
							tempoChangeMarkingEnd = -1;
							lastTempoChangeMarkingBar = -1;
						}
						
						if (cursor.next()) {
							processingThisBar = cursor.measure.is(currentBar);
						} else {
							processingThisBar = false;
						}
						if (isNote) {
							prevNote = noteRest;
							prevNotes[currentTrack] = noteRest;
						}
						if (isRest) {
							prevNote = null;
							prevNotes[currentTrack] = null;
						}
						prevSlurNum = currentSlurNum;
						prevTick[currentTrack] = currTick;
					} // end while processingThisBar
					if (numNoteRestsInThisTrack > 0) {
						numTracksWithNoteRests ++;
					} else {
						prevNote = null;
						prevNotes[currentTrack] = null;
					}
					if (numNotesInThisTrack > 0) numTracksWithNotes ++;
				} // end track loop
				
				if (isWindOrBrassInstrument && isSharedStaff) {
					if (numTracksWithNoteRests > 1 || isChord) {
						//logError("multiple parts found");
						weKnowWhosPlaying = false;
						flaggedWeKnowWhosPlaying = false;
					} else {

						//logError("numTracksWithNotes="+numTracksWithNotes+" weKnowWhosPlaying="+weKnowWhosPlaying+" flaggedWeKnowWhosPlaying="+flaggedWeKnowWhosPlaying);
						if (numTracksWithNoteRests == 1 && !weKnowWhosPlaying && !flaggedWeKnowWhosPlaying) {
							addError("This bar has only one melodic line on a shared staff\nThis needs to be marked with, e.g., 1./2./a 2",firstNoteInThisBar);
							flaggedWeKnowWhosPlaying = true;
						}
					}
				}
				
				
				if (currentBar) currentBar = currentBar.nextMeasure;
				if (numTracksWithNotes > 0) {
					numConsecutiveMusicBars ++;
				} else {
					numConsecutiveMusicBars = 0;
				}
				numBarsProcessed ++;
			}// end currentBar num
			
			if (currentStaffNum == 0) beatCountInSystem.push(numBeatsInThisSystem);
			if (noteCountInSystem[currentSystemNum] == undefined) {
				if (numNoteRestsInThisSystem > numBeatsInThisSystem) {
					noteCountInSystem[currentSystemNum] = numNoteRestsInThisSystem;
					//logError("Pushed noteCountInSystem["+currentSystemNum+"] = "+numNoteRestsInThisSystem);
				} else {
					noteCountInSystem[currentSystemNum] = numBeatsInThisSystem;
					//logError("Pushed noteCountInSystem["+currentSystemNum+"] = "+numBeatsInThisSystem);
				}
			} else {
				if (numNoteRestsInThisSystem > noteCountInSystem[currentSystemNum]) {
					noteCountInSystem[currentSystemNum] = numNoteRestsInThisSystem;
					//logError("Expanded noteCountInSystem["+currentSystemNum+"] = "+numNoteRestsInThisSystem);
				}
			}
		} // end staffnum loop
		
		// mop up any last tests
		
		// ** CHECK FOR OMITTED INITIAL TEMPO ** //
		if (!initialTempoExists) addError("I couldn’t find an initial tempo marking","top");
		
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
				logError("Main loop — check spacing — BAR UNDEFINED");
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
		
		if (errorMsg != "") errorMsg = "<p>————————————<p><p>ERROR LOG (for developer use):</p>" + errorMsg;
		if (numErrors == 0) errorMsg = "<p>CHECK COMPLETED: Congratulations — no issues found!</p><p><font size=\"6\">🎉</font></p>"+errorMsg;
		if (numErrors == 1) errorMsg = "<p>CHECK COMPLETED: I found one issue.</p><p>Please check the score for the yellow comment box that provides more details of the issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove the comment and pink highlight.</p>" + errorMsg;
		if (numErrors > 1) errorMsg = "<p>CHECK COMPLETED: I found "+numErrors+" issues.</p><p>Please check the score for the yellow comment boxes that provide more details on each issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove all of these comments and highlights.</p>" + errorMsg;
		
		if (progressShowing) progress.close();
		
		var h = 250+numLogs*10;
		if (h > 500) h =500;
		dialog.height = h;
		dialog.contentHeight = h;
		dialog.msg = errorMsg;
		dialog.show();
	}
	
	function getNoteRestAtTick(targetTick) {
		var cursor2 = curScore.newCursor();
		cursor2.filter = Segment.ChordRest;
		cursor2.staffIdx = currentStaffNum;
		cursor2.rewind(curScore.SCORE_START);
		var prevElem = null;
		while (cursor2 && cursor2.tick < targetTick) {
			prevElem = cursor2.element;
			cursor2.next();
		}
		if (!cursor2) return null;
		if (cursor2.tick == targetTick) return cursor2.element;
		return prevElem;
	}
	
		
	function getPreviousNoteRest (noteRest) {
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = currentStaffNum;
		cursor2.track = noteRest.track;
		cursor2.rewindToTick(noteRest.parent.tick);
		if (cursor2.prev()) return cursor2.element;
		return null;
	}
	
	function getNextNoteRest (noteRest) {
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = currentStaffNum;
		cursor2.track = noteRest.track;
		cursor2.rewindToTick(noteRest.parent.tick);
		if (cursor2.next()) return cursor2.element;
		return null;
	}
	
	function getNextChordRest (cursor) {
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = cursor.staffIdx;
		cursor2.filter = Segment.ChordRest;
		cursor2.track = cursor.track;
		cursor2.rewindToTick(cursor.tick);
		if (cursor2.next()) return cursor2.element;
		return null;
	}
	
	function getPrevChordRest (cursor) {
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = cursor.staffIdx;
		cursor2.filter = Segment.ChordRest;
		cursor2.track = cursor.track;
		cursor2.rewindToTick(cursor.tick);
		if (cursor2.next()) return cursor2.element;
		return null;
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
	
	function analyseSpanners() {
		// **** LOOK FOR AND STORE ANY ELEMENTS THAT CAN ONLY BE ACCESSED FROM SELECTION: **** //
		// **** AND IS NOT PICKED UP IN A CURSOR LOOP (THAT WE WILL BE DOING LATER)       **** //
		// **** THIS INCLUDES: HAIRPINS, OTTAVAS, TREMOLOS, SLURS, ARTICULATION, FERMATAS **** //
		// **** GLISSES, PEDALS, TEMPO TEXT																								**** //
		var staves = curScore.staves;
		var elems = curScore.selection.elements;
		//logError ("Selected "+elems.length+" elems");
		var prevSlurSegment = null, prevHairpinSegment = null, prevOttavaSegment = null, prevGlissSegment = null, prevPedalSegment = null;
		
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			
			// check if elem is hidden
			if (e.parent == null) continue;
			//logError ("Found elem "+e.name);
			var etype = e.type;
			var staffIdx = 0;
			while (!staves[staffIdx].is(e.staff)) staffIdx++;
			
			// ** MuseScore versions prior to 4.5.1 had broken segment objects that would return 'undefined' for spannerTick or spannerTicks
			// ** Therefore, we'll only collect these objects if we have the right version of MuseScore
			/*if (etype == Element.REHEARSAL_MARK) {
				logError ("Checking rehearsal mark at start"); 
				checkRehearsalMark(e);
			}*/
			if (etype == Element.HAIRPIN) {
				//logError ("Pushing hairpin "+hairpins[staffIdx].length+": "+e.hairpinType);
				hairpins[staffIdx].push(e);
				if (e.subtypeName().includes(" line") && e.spannerTicks.ticks <= division * 12) addError ("It’s recommended to use hairpins instead of ‘cresc.’ or ‘dim.’\non short changes of dynamic.",e);
			}
			if (etype == Element.HAIRPIN_SEGMENT) {
				// ONLY ADD THE HAIRPIN_SEGMENT IF WE HAVEN'T ALREADY ADDED IT
				//logError ("Hairpin e.pagePos.x = "+e.pagePos.x);

				var sameLoc = false;
				var sameHairpin = false;
				if (prevHairpinSegment != null) {
					sameLoc = (e.spannerTick.ticks == prevHairpinSegment.spannerTick.ticks) && (e.spannerTicks.ticks == prevHairpinSegment.spannerTicks.ticks);
					if (sameLoc) sameHairpin = !e.parent.is(prevHairpinSegment.parent);
				}
				// only add it if it's not already added
				if (!sameHairpin) {
					
					//logError ("Pushing hairpin segment "+e.hairpinType);
					hairpins[staffIdx].push(e);
					if (e.subtypeName().includes(" line") && e.spannerTicks.ticks <= division * 12) addError ("It’s recommended to use hairpins instead of ‘cresc.’ or ‘dim.’\non short changes of dynamic.",e);
				}
				prevHairpinSegment = e;
			}
			
			if (etype == Element.OTTAVA) ottavas[staffIdx].push(e);
			if (etype == Element.OTTAVA_SEGMENT) {	// ONLY ADD THE SEGMENT IF WE HAVEN'T ALREADY ADDED IT
				var sameLoc = false;
				var sameOttava = false;
				if (prevOttavaSegment != null) {
					sameLoc = (e.spannerTick.ticks == prevOttavaSegment.spannerTick.ticks) && (e.spannerTicks.ticks == prevOttavaSegment.spannerTicks.ticks);
					if (sameLoc) sameOttava = !e.parent.is(prevOttavaSegment.parent);
				}
				// only add it if it's not already added
				if (!sameOttava) ottavas[staffIdx].push(e);
				prevOttavaSegment = e;
			}
			
			if (etype == Element.GLISSANDO) glisses[staffIdx][e.parent.parent.parent.tick] = e;
			if (etype == Element.GLISSANDO_SEGMENT) {	// ONLY ADD THE EGMENT IF WE HAVEN'T ALREADY ADDED IT
				var sameLoc = false;
				var sameGlissando = false;
				if (prevGlissandoSegment != null) {
					sameLoc = (e.spannerTick.ticks == prevGlissandoSegment.spannerTick.ticks) && (e.spannerTicks.ticks == prevGlissandoSegment.spannerTicks.ticks);
					if (sameLoc) sameGlissando = !e.parent.is(prevGlissandoSegment.parent);
				}
				// only add it if it's not already added
				if (!sameGlissando) glisses[staffIdx][e.spannerTick.ticks] = e;
				prevGlissandoSegment = e;
			}
			
			if (etype == Element.SLUR) slurs[staffIdx].push(e);
			if (etype == Element.SLUR_SEGMENT) { // ONLY ADD THE SEGMENT IF WE HAVEN'T ALREADY ADDED IT
				var sameLoc = false;
				var sameSlur = false;
				if (prevSlurSegment != null) {
					sameLoc = (e.spannerTick.ticks == prevSlurSegment.spannerTick.ticks) && (e.spannerTicks.ticks == prevSlurSegment.spannerTicks.ticks);
					if (sameLoc) sameSlur = !e.parent.is(prevSlurSegment.parent);
				}
				// only add it if it's not already added
				if (!sameSlur) slurs[staffIdx].push(e);
				prevSlurSegment = e;
			}
			
			if (etype == Element.PEDAL) pedals[staffIdx].push(e);
			if (etype == Element.PEDAL_SEGMENT) { // ONLY ADD THE SEGMENT IF WE HAVEN'T ALREADY ADDED IT
				var sameLoc = false;
				var samePedal = false;
				if (prevPedalSegment != null) {
					sameLoc = (e.spannerTick.ticks == prevPedalSegment.spannerTick.ticks) && (e.spannerTicks.ticks == prevPedalSegment.spannerTicks.ticks);
					if (sameLoc) samePedal = !e.parent.is(prevPedalSegment.parent);
				}
				// only add it if it's not already added
				if (!samePedal) pedals[staffIdx].push(e);
				prevPedalSegment = e;
			}
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
			if (etype == Element.GRADUAL_TEMPO_CHANGE || etype == Element.TEMPO_TEXT || etype == Element.METRONOME) tempoText.push(e);
			if (etype == Element.DYNAMIC) dynamics[staffIdx].push(e.parent.tick);
			if (etype == Element.CLEF) clefs[staffIdx][e.parent.tick] = e;
		}
	}
	
	function analyseInstrumentsAndStaves () {
		var transposingInstruments = ["brass.bugle.soprano","brass.bugle.mellophone-bugle","brass.bugle.baritone","brass.bugle.contrabass","brass.cornet","brass.euphonium","brass.flugelhorn","brass.french-horn","brass.trumpet.bflat","brass.trumpet.d","brass.trumpet.piccolo","keyboard.celesta","metal.crotales","pitched-percussion.glockenspiel","pitched-percussion.xylophone","pluck.guitar","strings.contrabass","wind.flutes.flute.piccolo","wind.flutes.flute.alto","wind.flutes.flute.bass","wind.reed.clarinet","wind.reed.contrabassoon","wind.reed.english-horn","wind.reed.oboe.bass","wind.reed.oboe-damore","wind.reed.saxophone"];
		numGrandStaves = 0;
		var prevPart = null;
		var prevPrevPart = null;
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
			var calcid = id;
			var staffName = staves[i].part.longName;
			var lowerStaffName = staffName.toLowerCase();
			instrumentNames.push(staffName);
			
			if (id.includes('.group')) {
				if (id.includes('strings')) {
					if (lowerStaffName.includes('violin')) calcid = 'strings.violin';
					if (lowerStaffName.includes('viola')) calcid = 'strings.viola';
					if (lowerStaffName.includes('cello')) calcid = 'strings.cello';
					if (lowerStaffName.includes('bass')) calcid = 'strings.contrabass';
				}
				if (id.includes('wind')) {
					if (lowerStaffName.includes('piccolo')) calcid = 'wind.flutes.flute.piccolo';
					if (lowerStaffName.includes('flute')) {
						if (lowerStaffName.includes('alto')) {
							calcid = 'wind.flutes.flute.alto';
						} else {
							if (lowerStaffName.includes('bass')) {
								calcid = 'wind.flutes.flute.bass';
							} else {
								calcid = 'wind.flutes.flute';
							}
						}
					}
					if (lowerStaffName.includes('oboe')) calcid = 'wind.reed.oboe';
					if (lowerStaffName.includes('anglais') || lowerStaffName.includes('english')) calcid = 'wind.reed.english-horn';
					if (lowerStaffName.includes('clarinet')) {
						if (lowerStaffName.includes('bass')) {
							calcid = 'wind.reed.clarinet.bass';
						} else {
							if (lowerStaffName.includes('a cl') || lowerStaffName.includes('in a')) {
								calcid = 'wind.reed.clarinet.a';
							} else {
								if (lowerStaffName.includes('eb cl') || lowerStaffName.includes('in eb')) {
									calcid = 'wind.reed.clarinet.eb';
								} else {
									calcid = 'wind.reed.clarinet.bb';
								}
							}
						}
					}
						
					if (staffName.includes('bassoon')) {
						if (lowerStaffName.includes('contra')) {
							calcid = 'wind.reed.contrabassoon';
						} else {
							calcid = 'wind.reed.bassoon';
						}
					}
				}
				if (id.includes('brass')) {
					if (lowerStaffName.includes('horn')) calcid = 'brass.french-horn';
					if (lowerStaffName.includes('trumpet')) calcid = 'brass.trumpet';
					if (lowerStaffName.includes('trombone')) calcid = 'brass.trombone';
					if (lowerStaffName.includes('tuba')) calcid = 'brass.tuba';
				}
			}
			instrumentCalcIds.push(calcid);
			//logError("staff "+i+" ID "+id+" name "+staffName+" vis "+staves[i].visible);
			isSharedStaffArray[i] = false;
			if (!scoreIncludesTransposingInstrument) {
				for (var j = 0; j < transposingInstruments.length; j++) {
					if (calcid.includes(transposingInstruments[j])) scoreIncludesTransposingInstrument = true;
					continue;
				}
			}
			
			// check to see whether this staff name indicates that it's a shared staff
			var firstLetterIsANumber = !isNaN(staffName.substring(0,1)); // checks to see if the staff name begins with, e.g., '2 Bassoons'
			if (firstLetterIsANumber) {
				isSharedStaffArray[i] = true;
			} else {
				// check if it includes a pattern like '1.2' or 'II &amp; III'midg
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
					addError("You appear to be composing a wind quintet\nbut the flute should be the top staff.\nReorder using the Instruments tab.","topfunction ");
				} else {
					if (obStaff != 1) {
						addError("You appear to be composing a wind quintet\nbut the oboe should be the second staff.\nReorder using the Instruments tab.","pagetop");
					} else {
						if (clStaff != 2) {
							addError("You appear to be composing a wind quintet\nbut the clarinet should be the third staff.\nReorder using the Instruments tab.","pagetop");
						} else {
							if (hnStaff != 3) {
								addError("You appear to be composing a wind quintet\nbut the horn should be the fourth staff.\nReorder using the Instruments tab.","pagetop");
							} else {
								if (bsnStaff != 4) addError("You appear to be composing a wind quintet\nbut the bassoon should be the bottom staff.\nReorder using the Instruments tab.","pagetop");
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
			
			if (fullInstNamesShowing) {
				if (full1l === 'violins 1' || full1l === 'violin 1') addError ("Change the long name of staff "+(i+1)+" to ‘Violin I’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+i);
				if (full1l === 'violas 1' || full1l === 'viola 1') addError ("Change the long name of staff "+(i+1)+" to ‘Viola I’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+i);
				if (full1l === 'cellos 1' || full1l === 'cello 1') addError ("Change the long name of staff "+(i+1)+" to ‘Cello I’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+i);
				
				if (full1l === 'violins 2' || full1l === 'violin 2') addError ("Change the long name of staff "+(i+1)+" to ‘Violin II’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+i);
				if (full1l === 'violas 2' || full1l === 'viola 2') addError ("Change the long name of staff "+(i+1)+" to ‘Viola II’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+i);
				if (full1l === 'cellos 2' || full1l === 'cello 2') addError ("Change the long name of staff "+(i+1)+" to ‘Cello II’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+i);
				
				if (full1l === 'violas') addError ("Change the long name of staff "+(i+1)+" to ‘Viola’ (see ‘Behind Bars’, p. 509)", "system1 "+i);
				if (full1l === 'violoncellos' || full1l === 'violpncello') addError ("Change the long name of staff "+(i+1)+" to ‘Cello’ (see ‘Behind Bars’, p. 509)", "system1 "+i);
				if (full1l === 'contrabasses' || full1 === 'Double basses' || full1l === 'contrabass') addError ("Change the long name of staff "+(i+1)+" to ‘Double Bass’ or ‘D. Bass’ (see ‘Behind Bars’, p. 509)", "system1 "+i);
			}
			
			if (shortInstNamesShowing) {
			
				if (short1l === 'vlns. 1' || short1l === 'vln. 1' || short1l === 'vlns 1' || short1l === 'vln 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vln. I’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vlas. 1' || short1l === 'vla. 1' || short1l === 'vlas 1' || short1l === 'vla 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vla. I’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vcs. 1' || short1l === 'vc. 1' || short1l === 'vcs 1' || short1l === 'vc 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vc. I’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				
				if (short1l === 'vlns. 2' || short1l === 'vln. 2' || short1l === 'vlns 2' || short1l === 'vln 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vln. II’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vlas. 2' || short1l === 'vla. 2' || short1l === 'vlas 2' || short1l === 'vla 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vla. II’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vcs. 2' || short1l === 'vc. 2' || short1l === 'vcs 2' || short1l === 'vc 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vc. II’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				
				if (short1l === 'vlas.') addError ("Change the short name of staff "+(i+1)+" to ‘Vla.’ (see ‘Behind Bars’, p. 509)", "system2 "+i);
				if (short1l === 'vcs.') addError ("Change the short name of staff "+(i+1)+" to ‘Vc.’ (see ‘Behind Bars’, p. 509)", "system2 "+i);
				if (short1l === 'cbs.' || short1l === 'dbs.' || short1l === 'd.bs.' || short1l === 'cb.') addError ("Change the short name of staff "+(i+1)+" to ‘D.B.’ (see ‘Behind Bars’, p. 509)", "system2 "+i);
			}
			
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
			isWindInstrument = currentInstrumentId.includes("wind.");
			isBrassInstrument = currentInstrumentId.includes("brass.");
			isWindOrBrassInstrument = isWindInstrument || isBrassInstrument;
			isHorn = currentInstrumentCalcId === "brass.french-horn";
			isTrombone = currentInstrumentCalcId === "brass.trombone.tenor";
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
				if (currentInstrumentCalcId.includes("bassoon")) {
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
				if (currentInstrumentCalcId.includes("french-horn")) {
					readsBass = true;
					checkClefs = true;
				}
				if (currentInstrumentCalcId.includes("trumpet")) checkClefs = true;
				if (currentInstrumentCalcId.includes("trombone") || currentInstrumentCalcId.includes("tuba") || currentInstrumentId.includes("sousaphone")) {
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
				if (currentInstrumentCalcId.includes("violin")) {
					checkClefs = true;
					reads8va = true;
				}
				if (currentInstrumentCalcId.includes("viola")) {
					readsAlto = true;
					checkClefs = true;
				}
				if (currentInstrumentCalcId.includes("cello") || currentInstrumentCalcId.includes("contrabass")) {
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
			
			// lowest pitch possible etc.
			lowestPitchPossible = highestPitchPossible = quietRegisterThresholdPitch = highLoudRegisterThresholdPitch = lowLoudRegisterThresholdPitch = 0;
			for (var i = 0; i < instrumentranges.length; i++) {
				var instrumentData = instrumentranges[i];
				if (currentInstrumentCalcId === instrumentData[0]) {
					/// *** BACK HERE
					lowestPitchPossible = instrumentData[1];
					if (instrumentData[2] != '') quietRegisterThresholdPitch = instrumentData[2];
					highestPitchPossible = instrumentData[3];
					if (instrumentData[4] != '') highLoudRegisterThresholdPitch = instrumentData[4];
					if (instrumentData[5] != '') lowLoudRegisterThresholdPitch = instrumentData[5];
					//logError ('Data for '+currentInstrumentCalcId+': '+lowestPitchPossible+' '+highestPitchPossible+' '+quietRegisterThresholdPitch+' '+highLoudRegisterThresholdPitch+' '+lowLoudRegisterThresholdPitch);
				}
			}
		}
	}
	
	function checkPartSettings () {
	//	logError ("checkPartSettings");
		var maxSize = 7.0;
		var minSize = 6.6;
		var excerpts = curScore.excerpts;
		if (excerpts == null) return;
		
	//	logError ("excerpts not null");
		var numExcerpts = excerpts.length;
		if (numExcerpts < 2) return;
		
	//	logError ("2 or more excerpts");
		var styleComments = [];
		var pageSettingsComments = [];
		var style;
		var flaggedStaffSize = false;
		var flaggedSystemSpacing = false;
		var flaggedMinNoteDistance = false;
		var flaggedVerticalFrameBottomMargin = false;
		var flaggedMultiRests = false;
		var flaggedMultiRestWidth = false;
		var flaggedLastSystemFillLimit = false;
		for (var i = 0; i < numExcerpts; i++) {
			var thePart = excerpts[i];
			
		//	logError ("checking part "+i);
			style = thePart.partScore.style;
			var theSpatium = style.value("spatium")*inchesToMM/mscoreDPI; // spatium value is given in 360 DPI
			// part should be 6.6-7.0mm
			if (!flaggedStaffSize) {
				var theStaffSize = theSpatium * 4.0;
				if (theStaffSize > maxSize) {
					pageSettingsComments.push("Decrease the stave space to between "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
					flaggedStaffSize = true;
				}
				if (theStaffSize < minSize) {
					pageSettingsComments.push("Increase the stave space to between "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
					flaggedStaffSize = true;
				}
			}		

			
			// check system spacing
			if (!flaggedSystemSpacing) {
				var minSystemDistance = style.value("minSystemDistance");
				var maxSystemDistance = style.value("maxSystemDistance");
				var minSystemSpread = style.value("minSystemSpread");
				var maxSystemSpread = style.value("maxSystemSpread");
				var enableVerticalSpread = style.value("enableVerticalSpread");
				if (enableVerticalSpread) {
					if (minSystemSpread < 6 || minSystemSpread > 8) {
						styleComments.push("(Page tab) Set the ‘Min. system distance’ to between 6.0–8.0sp");
						flaggedSystemSpacing = true;
					}
					if (maxSystemSpread < 10 || maxSystemSpread > 14) {
						styleComments.push("(Page tab) Set the ‘Max. system distance’ to between 10.0–14.0sp");
						flaggedSystemSpacing = true;
					}
				} else {
					if (minSystemDistance < 6 || minSystemDistance > 8) {
						styleComments.push("(Page tab) Set the ‘Min. system distance’ to between 6.0–7.0sp");
						flaggedSystemSpacing = true;
					}
					if (maxSystemDistance < 10 || maxSystemDistance > 14) {
						styleComments.push("(Page tab) Set the ‘Max. system distance’ to between 10.0–14.0sp");
						flaggedSystemSpacing = true;
					}
				}
			}
			
			// vertical frame bottom margin
			if (!flaggedVerticalFrameBottomMargin) {
				var verticalFrameBottomMargin = style.value("frameSystemDistance");
				if (verticalFrameBottomMargin != 8) {
					styleComments.push("(Page tab) Set ‘Vertical frame bottom margin’ to 8.0sp");
					flaggedVerticalFrameBottomMargin = true;
				}
			}
			
			// last system fille distance
			if (!flaggedLastSystemFillLimit) {
				var lastSystemFillLimit = style.value("lastSystemFillLimit");
				if (lastSystemFillLimit != 0) {
					styleComments.push("(Page tab) Set ‘Last system fill threshold’ to 0%");
					flaggedLastSystemFillLimit = true;
				}
			}
			
			
			// min note distance
			if (!flaggedMinNoteDistance) {
				var minNoteDistance = style.value("minNoteDistance");
				if (minNoteDistance < 1.2 || minNoteDistance > 1.4) {	
					styleComments.push("(Bars tab) Set the ‘Min. note distance’ to between 1.2-1.4sp");
					flaggedMinNoteDistance = true;
				}
			}
			
			// multirests on
			if (!flaggedMultiRests) {
				var multirestsOn = style.value("createMultiMeasureRests");
				if (!multirestsOn) {	
					styleComments.push("(Rests tab) Switch ‘Multibar rests’ on");
					flaggedMultiRests = true;
				}
			}
			
			// multirest width
			if (!flaggedMultiRestWidth) {
				var MMrestWidth = style.value("minMMRestWidth");
				if (MMrestWidth < 18.0 || MMrestWidth > 36.0) {	
					styleComments.push("(Rests tab) Set ‘Multibar rests→Minimum width’ to between 18–36sp");
					flaggedMultiRestWidth = true;
				}
			}
		}
		
		// ** POST STYLE COMMENTS
		var styleCommentsStr = "";
		var pageSettingsCommentsStr = "";

		if (styleComments.length>0) {
			if (styleComments.length == 1) {
				styleCommentsStr = "The following change to the Style settings (Format→Style…) is recommended\n(though may not be suitable for all scenarios or style guides—use your discretion.):\n"+styleComments[0];
			} else {
				var theList = styleComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				styleCommentsStr = "The following changes to the Style settings (Format→Style…) are recommended\n(though may not be suitable for all scenarios or style guides—use your discretion.):\n"+theList;
			}
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments.length > 0) {
			if (pageSettingsComments.length == 1) {	
				pageSettingsCommentsStr = "The following change to the Page Settings (Format→Page settings…) is recommended\n(though may not be suitable for all scenarios or style guides):\n"+pageSettingsComments[0];
			} else {
				var theList = pageSettingsComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				pageSettingsCommentsStr = "The following changes to the Page Settings (Format→Page settings…) are recommended\n(though may not be suitable for all scenarios or style guides)\n\n"+theList;
			}
		}
		if (styleComments.length + pageSettingsComments.length > 0) {
			var errorStr = ["PARTS SETTINGS","(These suggestions apply only to the parts, not the score. This comment box will remain\nuntil all parts have been changed; to quickly change the settings for all parts, change one part,\nthen click ‘Apply to all parts’).",styleCommentsStr,pageSettingsCommentsStr].join("\n\n").replace(/\n\n\n\n/g, '\n\n').trim();
			addError(errorStr,"pagetopright");
		}
	}
	
	function checkScoreAndPageSettings () {
		var styleComments = [];
		var pageSettingsComments = [];
		var style = curScore.style;
		var staffSpacing = style.value("staffDistance");		
		var akkoladeDistance = style.value("akkoladeDistance");
		var minSystemDistance = style.value("minSystemDistance");
		var maxSystemDistance = style.value("maxSystemDistance");
		var minSystemSpread = style.value("minSystemSpread");
		var maxSystemSpread = style.value("maxSystemSpread");
		var enableVerticalSpread = style.value("enableVerticalSpread");
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
		var pageNumberFontStyle = style.value("pageNumberFontStyle");
		var barlineWidth = style.value("barWidth");
		var minimumBarWidth = style.value("minMeasureWidth");
		var spacingRatio = style.value("measureSpacing");
		var slurEndWidth = style.value("slurEndWidth");
		var slurMidWidth = style.value("slurMidWidth");
		var showFirstBarNum = style.value("showMeasureNumberOne");
		var minNoteDistance = style.value("minNoteDistance");
		var staffLineSize = style.value("staffLineWidth");
		var minStaffSpread = style.value("minStaffSpread");
		var maxStaffSpread = style.value("maxStaffSpread");
		var staffDistance = style.value("staffDistance");
		var staffLowerBorder = style.value("staffLowerBorder");
		var lastSystemFillLimit = style.value("lastSystemFillLimit");
		var crossMeasureValues = style.value("crossMeasureValues");
		tempoFontStyle = curScore.style.value("tempoFontStyle");
		metronomeFontStyle = curScore.style.value("metronomeFontStyle");
		
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
		
		if (staffSize > maxSize) pageSettingsComments.push("Decrease the stave space to between "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
		if (staffSize < minSize) {
			if (staffSize < 3.7) {
				if (staffSize < minSize) pageSettingsComments.push("The staff size is very small.\nIncrease the stave space to at least 0.92mm");
			} else {
				pageSettingsComments.push("Increase the stave space to between "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
			}
		}
		
		// **** STYLE SETTINGS — 1. SCORE TAB **** //
		
		// **** STAFF LINE THICKNESS **** //
		if (staffLineSize != 0.1) styleComments.push("(Score tab) Set ‘Stave line thickness’ to 0.1sp");
		
		// **** CHECK FOR STAFF NAMES SHOWING OR HIDDEN INCORRECTLY **** //
		var staffNamesHiddenBecauseSoloScore = isSoloScore && style.value("hideInstrumentNameIfOneInstrument");
		if (isSoloScore) {
			if (!staffNamesHiddenBecauseSoloScore) styleComments.push("(Score tab) Tick ‘Hide if there is only one instrument’");
		} else {
			// ** FIRST STAFF NAMES SHOULD BE SHOWING — STYLE SET TO 0 **//
			// ** ALSO CHECK THEY HAVEN'T BEEN MANUALLY DELETED ** //		
			var firstStaffNamesVisibleSetting = style.value("firstSystemInstNameVisibility"); //  0 = long names, 1 = short names, 2 = hidden
			var firstStaffNamesVisible = firstStaffNamesVisibleSetting < 2;
			var blankStaffNames = [];
			if (firstStaffNamesVisible) {
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
					for (var i = 0; i < blankStaffNames.length; i++) addError ("Staff "+(blankStaffNames[i]+1)+" has no staff name.","system1 "+i);
				}
			}
			if (firstStaffNamesVisible && firstStaffNamesVisibleSetting != 0) styleComments.push("(Score tab) Set Instrument names→On first system of sections to ‘Long name’.");
			if (!firstStaffNamesVisible && firstStaffNamesVisibleSetting < 2) addError("It looks like you have manually deleted the staff names.\nThese should be showing on the first system.","pagetop");

			// ** are the subsequent staff names visible? ** //
			var subsequentStaffNamesShouldBeHidden = numParts < 6;
			var subsequentStaffNamesVisibleSetting = style.value("subsSystemInstNameVisibility");  //  0 = long names, 1 = short names, 2 = hidden
			var subsequentStaffNamesVisible = subsequentStaffNamesVisibleSetting < 2;
			if (subsequentStaffNamesVisible) {
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
					for (var i = 0; i < blankStaffNames.length; i++) addError ("Staff "+(blankStaffNames[i]+1)+" has no staff name.","system2 "+i);
				}
			}
			fullInstNamesShowing = (firstStaffNamesVisible && firstStaffNamesVisibleSetting == 0) || (subsequentStaffNamesVisible && subsequentStaffNamesVisibleSetting == 0);
			shortInstNamesShowing =  (firstStaffNamesVisible && firstStaffNamesVisibleSetting == 1) || (subsequentStaffNamesVisible && subsequentStaffNamesVisibleSetting == 1);
			
			if (subsequentStaffNamesShouldBeHidden) {
				// are they actually showing?
				if (subsequentStaffNamesVisible) styleComments.push("(Score tab) Switch Instrument names→On subsequent systems to ‘Hide’ for a small ensemble");
			} else {
				// are they actually hidden?
				if (!subsequentStaffNamesVisible) {
					if (subsequentStaffNamesVisibleSetting == 2) {
						styleComments.push("(Score tab) Switch Instrument names→On subsequent systems to ‘Short name’ for a large ensemble");
					} else {
						addError("It looks like you have manually deleted the staff names on subsequent systems.\nThese should be showing.","pagetop");
					}
				} else {
					// check they are short names
					if (subsequentStaffNamesVisibleSetting == 0) styleComments.push("(Score tab) Switch Instrument names→On subsequent systems to ‘Short name’");
				}
			}
		}
		
		if (crossMeasureValues != 0) styleComments.push("(Score tab) Uncheck ‘Display note values across bar boundaries’");
		
		// **** STYLE SETTINGS — 2. PAGE TAB **** //
		// **** 1D: CHECK SYSTEM SPACING
		if (hasMoreThanOneSystem) {
			if (enableVerticalSpread) {
				if (minSystemSpread < 12 || minSystemSpread > 14) styleComments.push("(Page tab) Set the ‘Min. system distance’ to between 12.0–14.0sp");
				if (maxSystemSpread < 24 || maxSystemSpread > 28) styleComments.push("(Page tab) Set the ‘Max. system distance’ to between 24.0–28.0sp");
			} else {
				if (minSystemDistance < 12 || minSystemDistance > 16) styleComments.push("(Page tab) Set the ‘Min. system distance’ to between 12.0–14.0sp");
				if (maxSystemDistance < 24 || maxSystemDistance > 28) styleComments.push("(Page tab) Set the ‘Max. system distance’ to between 24.0–28.0sp");
			}
		}
		
		// **** CHECK STAFF SPACING **** //
		if (!isSoloScore) {
			if (enableVerticalSpread) {
				if (minStaffSpread < 5 || minStaffSpread > 6) styleComments.push("(Page tab) Set the ‘Min. stave distance’ to between 5.0–6.0sp");
				if (maxStaffSpread < 10 || maxStaffSpread > 12) styleComments.push("(Page tab) Set the ‘Max. stave distance’ to between 10.0–12.0sp");
			} else {
				if (staffDistance < 5 || staffDistance > 6) styleComments.push("(Page tab) Set the ‘Stave distance’ to between 5.0–6.0sp");
			}
		}
		
		// **** CHECK LAST SYSTEM FILL THRESHOLD **** //
		if (lastSystemFillLimit > 0) styleComments.push("(Page tab) Set ‘Last system fill threshold’ to 0%");
		
		// ** CHECK MUSIC BOTTOM MARGIN — TO DO** //
		//if (staffLowerBorder > 0) styleComments.push("(Page tab) Set staff 5.0–6.0sp");
		
		// **** STYLE SETTINGS — 4. BAR NUMBERS TAB **** //
		if (showFirstBarNum) styleComments.push("(Bar numbers tab) Uncheck ‘Show first’");
		
		// **** STYLE SETTINGS — 9. BARS TAB **** //
		if (minimumBarWidth != 14.0) styleComments.push("(Bars tab) Set ‘Minimum bar width’ to 14.0sp");
		if (spacingRatio != 1.5) styleComments.push("(Bars tab) Set ‘Spacing Ratio’ to 1.5sp");
		if (minNoteDistance < 0.6 ) styleComments.push("(Bars tab) Increase ‘Minimum note distance’ to between 0.6–0.7sp");
		if (minNoteDistance > 0.7 ) styleComments.push("(Bars tab) Decrease ‘Minimum note distance’ to between 0.6–0.7sp");
		
		// **** STYLE SETTINGS — 10. BARLINES TAB **** //
		if (barlineWidth != 0.16) styleComments.push("(Barlines tab) Set ‘Thin barline thickness’ to 0.16sp");
		
		// **** STYLE SETTINGS — 17. SLURS & TIES **** //
		if (slurEndWidth != 0.06) styleComments.push("(Slurs &amp; Ties tab) Set ‘Slurs→Line thickness at end’ to 0.06sp");
		if (slurMidWidth != 0.16) styleComments.push("(Slurs &amp; Ties tab) Set ‘Slurs→Line thickness middle’ to 0.16sp");
		
		// **** STYLE SETTINGS — 6. TEXT STYLES TAB **** //
		//errorMsg += "tupletsFontFace = "+tupletsFontFace+" tupletsFontStyle = "+tupletsFontStyle;
		if (tupletsFontFace !== "Times New Roman" && tupletsFontStyle != 2) styleComments.push("(Text Styles→Tuplet) Use Times New Roman italic for tuplets");
		if (tupletsFontFace !== "Times New Roman" && tupletsFontStyle == 2) styleComments.push("(Text Styles→Tuplet) Use Times New Roman for tuplets");
		if (tupletsFontFace === "Times New Roman" && tupletsFontStyle != 2) styleComments.push("(Text Styles→Tuplet) Use an italic font for tuplets");
		if (pageNumberFontStyle != 0 && numPages > 1) {
			var s = 'bold';
			if (pageNumberFontStyle > 1) s = 'italics';
			styleComments.push("(Text Styles→Page Number) Set the font style to plain (not "+s+")");
		}
		if (tempoFontStyle != 1) styleComments.push("(Text Styles→Tempo) Use a bold font style for tempo markings");
		if (metronomeFontStyle != 0) styleComments.push("(Text Styles→Metronom) Use a plain font style for metronome markings");
		
		// ** OTHER STYLE ISSUES ** //
		var styleCommentsStr = "";
		var pageSettingsCommentsStr = "";

		// ** POST STYLE COMMENTS
		if (styleComments.length>0) {
			if (styleComments.length == 1) {
				styleCommentsStr = "The following change to the score’s Style settings (Format→Style…) is recommended\n(though may not be suitable for all scenarios or style guides—use your discretion):\n— "+styleComments[0];
			} else {
				var theList = styleComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				styleCommentsStr = "The following changes to the score’s Style settings (Format→Style…) are recommended\n(though may not be suitable for all scenarios or style guides—use your discretion):\n"+theList;
			}
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments.length > 0) {
			if (pageSettingsComments.length == 1) {	
				pageSettingsCommentsStr = "The following change to the score’s Page Settings (Format→Page settings…) is recommended\n(though may not be suitable for all scenarios or style guides):\n— "+pageSettingsComments[0];
			} else {
				var theList = pageSettingsComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				pageSettingsCommentsStr = "The following changes to the score’s Page Settings (Format→Page settings…) are recommended\n(though may not be suitable for all scenarios or style guides):\n"+theList;
			}
		}
		
		
		if (styleComments.length + pageSettingsComments.length > 0) {
			var errorStr = ["SCORE SETTINGS",styleCommentsStr,pageSettingsCommentsStr].join("\n\n").replace(/\n\n\n\n/g, '\n\n').trim();
			addError(errorStr,"pagetop");
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
		var thresholdb = pageHeight - maxDistance - 15;
		//logError ("Last measure rect is {"+l+" "+t+" "+r+" "+b+"}");
		//logError ("Borders: "+(thresholdr)+" "+(thresholdb));
		
		var checkBottom = true;
		// if this is a one-page composition, only check the right hand edge of the final system
		if (numPages == 1) checkBottom = false;
		
		// if there is only one staff, only check the right hand edge of the final system
		if (numStaves == 1) checkBottom = false;
		// definitely 
		
		if (checkBottom && r < thresholdr && b < thresholdb ) {
			addError("Try and arrange the layout so that the final bar is\nin the bottom right-hand corner of the last page.",lastMeasure);
			return;
		}
		if (r < thresholdr) {
			addError("Try and arrange the layout so that the final bar aligns\nwith the right-hand margin of the page.",lastMeasure);
		}
	}
	
	function checkLocationsOfBottomSystems () {
		var prevSystem = null;
		var prevPage = null;
		var prevFirstMeasure = null;
		var pageHeight = 0;
		var thresholdb = 0;
		var cursor = curScore.newCursor();
		cursor.staffIdx = 0;
		cursor.track = 0;
		cursor.rewind(Cursor.SCORE_START);
		while (cursor.next()) {
			var currMeasure = cursor.measure;
			var currSystem = currMeasure.parent;
			if (pageHeight == 0) {
				pageHeight = currSystem.parent.bbox.height;
				thresholdb = pageHeight * 0.9;
			}
			if (!currSystem.is(prevSystem)) {
				// new system
				var currPage = currSystem.parent;
				if (!currPage.is(prevPage)) {
					// prevSystem was bottom
					if (prevSystem != null) {
						//logError ("Found system at bottom of page with y "+prevSystem.pagePos.y+" height "+prevSystem.bbox.height);
						var systemBottom = prevSystem.pagePos.y + prevSystem.bbox.height;
						if (systemBottom < thresholdb) {
							addError ("This system should ideally be justified to the bottom of the page",prevFirstMeasure);
							//logError ("System Bottom = "+systemBottom+"; thresholdB = "+thresholdb);
						}
					}
					prevPage = currPage;
				}
				prevSystem = currSystem;
				prevFirstMeasure = currMeasure;
			}
		}
	}
	
	function checkHairpinTermination (cursor) {
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = cursor.staffIdx;
		cursor2.track = cursor.track;
		cursor2.rewindToTick(cursor.tick);
		cursor2.filter = Segment.ChordRest;
		
		var beatLength = (currentTimeSig.denominator == 8 && !(currentTimeSig.numerator % 3)) ? (1.5 * division) : division;
		var hairpinZoneEndTick = currentHairpinEnd + beatLength; // allow a terminating dynamic within a beat of the end of the hairpin
		//logError (currentHairpin.hairpinType+" "+currentBarNum+ " "+numBars);
		
		// allow a terminating decrescendo to a rest or on the last bar
		if (currentHairpin.hairpinType %2 == 1 && currentBarNum == numBars) return;

		for (var i=0;i<dynamics[currentStaffNum].length;i++) {
			var theTick = dynamics[currentStaffNum][i];
		//	if (theTick > (currentHairpinEnd - division * 4) && theTick < (currentHairpinEnd + division * 4)) logError ("Found a dynamic at "+theTick+"; needs to be between "+currentHairpinEnd+" and "+hairpinZoneEndTick);
			if (theTick >= currentHairpinEnd && theTick <= hairpinZoneEndTick) return;
		}
		
		// check not rests
		while (cursor2 != null && cursor2.tick < theTick) cursor2.next();
		if (cursor2 == null) return;
		if (cursor2.element == null) return;
		if (cursor2.element.notes == null) return;
		if (cursor2.element.notes.length == 0) return;
		addError ("This hairpin should have a dynamic at the end,\nor end should be closer to the next dynamic.",currentHairpin);
	}
	
	function checkInstrumentalTechniques (textObject, plainText, lowerCaseText) {
		var isBracketed = lowerCaseText.substring(0,1) === "(";
		
		if (isRest) {
			for (var i = 0; i < techniques.length; i ++) {
				if (lowerCaseText.includes(techniques[i])) {
					//logError ("textObj "+textObject.text);
					addError("Avoid putting techniques over rests if possible, though\nthis may sometimes be needed to save space.\n(See ‘Behind Bars’, p. 492).",textObject);
					break;
				}
			}
		}
		
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
			
			if (lowerCaseText === "détaché" || lowerCaseText === "detaché" || lowerCaseText === "detache") addError ("You don’t need to write ‘détaché’ here.\nA passage without slurs will be played détaché by default.",textObject);
			
			//errorMsg += "IsString: checking "+lowerCaseText;
			// **** CHECK INCORRECT 'A 2 / A 3' MARKINGS **** //
			if (lowerCaseText === "a 2" || lowerCaseText === "a 3") {
				addError("Don’t use ‘"+lowerCaseText+"’ for strings; write ‘unis.’ etc. instead",textObject);
				return;
			}
			
			if (lowerCaseText === "normal" || lowerCaseText === "normale" || lowerCaseText === "norm.") {
				if (currentPlayingTechnique === "pizz") {
					addError ("Did you mean ‘arco’?", textObject);
				} else {
					addError ("Did you mean ‘ord.’?", textObject);
				}
			}
			
			// **** CHECK ALREADY PLAYING ORD. **** .//
			if (lowerCaseText.substring(0,5) === "(ord." ) {
				if (currentContactPoint != "ord") addError ("This looks like it’s an indication to change to ord.\nIf so, you don’t need the parentheses",textObject)
			}
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
					if (isBracketed) addError ("This looks like a change to flautando.\nYou don’t need the parentheses around the technique.",textObject);
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
						if (isBracketed) addError ("This looks like a change to poco sul pont.\nYou don’t need the parentheses around the technique.",textObject);
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
							if (isBracketed) addError ("This looks like a change to molto sul pont.\nYou don’t need the parentheses around the technique.",textObject);
							currentContactPoint = "msp";
						}
					} else {
						if (currentContactPoint === "sp") {
							if (!isBracketed) {
								addError("Instrument is already playing sul pont?",textObject);
								return;
							}
						} else {
							if (isBracketed) addError ("This looks like a change to sul pont.\nYou don’t need the parentheses around the technique.",textObject);
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
						if (isBracketed) addError ("This looks like a change to poco sul tasto.\nYou don’t need the parentheses around the technique.",textObject);
						currentContactPoint = "pst";
					}
				} else {
					if (lowerCaseText.includes("molto sul tasto") || lowerCaseText.includes("m.s.t") || lowerCaseText.includes("mst")) {
						if (currentContactPoint === "mst") {
							if (!isBracketed) {
								addError("Instrument is already playing molto sul tasto?",textObject);
							}
						} else {
							if (isBracketed) addError ("This looks like a change to molto sul tasto.\nYou don’t need the parentheses around the technique.",textObject);
							currentContactPoint = "mst";
						}
					} else {
						if (currentContactPoint === "st") {
							if (!isBracketed) {
								addError("Instrument is already playing sul tasto?",textObject);
							}
						} else {
							if (isBracketed) addError ("This looks like a change to sul tasto.\nYou don’t need the parentheses around the technique.",textObject);
							currentContactPoint = "st";
						}
					}
				}
			}
		
			// **** CHECK ALREADY PLAYING ARCO **** //
			if (lowerCaseText.includes("arco") && !lowerCaseText.includes("senza arco")) {
				if (currentPlayingTechnique === "arco") {
					if (!isBracketed) {
						if (haveHadPlayingIndication) {
							addError("Instrument is already playing arco?",textObject);
						} else {
							addError("It’s not necessary to mark arco, as this is the default.",textObject);
						}
					}
				} else {
					if (isBracketed) addError ("This looks like a change to arco.\nYou don’t need the parentheses around the technique.",textObject);
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
					if (isBracketed) addError ("This looks like a change to pizz.\nYou don’t need the parentheses around the technique.",textObject);
					currentPlayingTechnique = "pizz";
					var pizzStartedInThisBar = true; // TO FIX
					haveHadPlayingIndication = true;
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
					haveHadPlayingIndication = true;
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
						if (isBracketed) addError ("This looks like a change to col legno batt.\nYou don’t need the parentheses around the technique.",textObject);
						currentPlayingTechnique = "clb";
						haveHadPlayingIndication = true;
					}
				} else {
					if (lowerCaseText.includes("tratto")) {
						if (currentPlayingTechnique === "clt") {
							if (!isBracketed) {
								addError("Instrument is already playing col legno tratto?",textObject);
							}
						} else {
							if (isBracketed) addError ("This looks like a change to col legno tratto.\nYou don’t need the parentheses around the technique.",textObject);
							currentPlayingTechnique = "clt";
							haveHadPlayingIndication = true;
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
				if (isBracketed) addError ("This looks like a change to con sord.\nYou don’t need the parentheses around the technique.",textObject);
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
				if (isBracketed) addError ("This looks like a change to senza sord.\nYou don’t need the parentheses around the technique.",textObject);
				currentMute = "senza";
			}
		}

	}
	
	function checkClef (clef) {
		if (clef == null) {
			logError("checkClef() — clef is null!");
			return;
		}
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
	
	function checkInstrumentRange(noteRest) {
		// the currentInstrumentRange array is formatted thus:
		//[instrumentId,lowestSoundingPitchPossible,quietRegisterThresholdPitch,highestSoundPitchPossible,highLoudRegisterThreshold,lowLoudRegisterThreshold] 
		var lowestPitch = getLowestPitch(noteRest);
		var highestPitch = getHighestPitch(noteRest);
		if (lowestPitch < lowestPitchPossible) {
			if (isBrassInstrument) {
				addError ('This note is very low and may not\nbe possible on this instrument.\nCheck with a player.',noteRest);
				return;
			} else {
				addError ('This note appears to be below the\nlowest note possible on this instrument.',noteRest);
				return;
			}
		}
		if (highestPitch > highestPitchPossible) {
			if (isPercussionInstrument || isHarp || isKeyboardInstrument) {
				addError ('This note appears to be above the\nhighest note possible on this instrument.',noteRest);
				return;
			} else {
				addError ('This note is very high and may not\nbe possible on this instrument.\nCheck with a player.',noteRest);
				return;
			}
		}
		if (quietRegisterThresholdPitch != 0) {
			if (lowestPitch <= quietRegisterThresholdPitch && currDynamicLevel > 3 && lastDynamicFlagBar < currentBarNum - 4) {
				//logError ("quietRegisterPitch = "+quietRegisterThresholdPitch+" currDynamicLevel = "+currDynamicLevel);
				lastDynamicFlagBar = currentBarNum;
				addError ('This note is quite low and may not\nbe able to be played at the indicated dynamic.',noteRest);
				return;
			}
		}
		if (highLoudRegisterThresholdPitch != 0) {
			if (highestPitch >= highLoudRegisterThresholdPitch && currDynamicLevel < 2 && lastDynamicFlagBar < currentBarNum - 4) {
				lastDynamicFlagBar = currentBarNum;
				addError ('This note is quite high and may not\nbe able to be played at the indicated dynamic.',noteRest);
				return;
			}
		}
		if (lowLoudRegisterThresholdPitch != 0) {
			if (lowestPitch <= lowLoudRegisterThresholdPitch && currDynamicLevel < 2 && lastDynamicFlagBar < currentBarNum - 4) {
				//logError ("lowLoudRegisterThresholdPitch = "+lowLoudRegisterThresholdPitch+" currDynamicLevel = "+currDynamicLevel);

				lastDynamicFlagBar = currentBarNum;
				addError ('This note is quite low and may not\nbe able to be played at the indicated dynamic.',noteRest);
				return;
			}
		}
	}
	
	function getLowestPitch(chord) {
		var numNotes = chord.notes.length;
		var lowestPitch = chord.notes[0].pitch;
		if (numNotes > 1) for (var i = 1; i < numNotes; i++) if (chord.notes[i].pitch < lowestPitch) lowestPitch = chord.notes[i].pitch;
		return lowestPitch;
	}
	
	function getHighestPitch(chord) {
		var numNotes = chord.notes.length;
		var highestPitch = chord.notes[0].pitch;
		if (numNotes > 1) for (var i = 1; i < numNotes; i++) if (chord.notes[i].pitch > highestPitch) highestPitch = chord.notes[i].pitch;
		return highestPitch;
	}
	
	function checkScoreText() {
		curScore.startCmd();
		cmd("title-text");
		var tempText = curScore.selection.elements[0];
		cmd("select-similar");
		var elems = curScore.selection.elements;
		currentBarNum = 0;
		var hasTitleOnFirstPageOfMusic = false;
		var hasSubtitleOnFirstPageOfMusic = false;
		var hasComposerOnFirstPageOfMusic = false;
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			if (!e.is(tempText)) {
				//logError ("Found text object "+e.text);
				checkTextObject (e);
				var eSubtype = e.subtypeName();
				if (eSubtype == "Title" && getPageNumber(e) == firstPageNum) hasTitleOnFirstPageOfMusic = true;
				if (eSubtype == "Subtitle" && getPageNumber(e) == firstPageNum) hasSubtitleOnFirstPageOfMusic = true;
				if (eSubtype == "Composer" && getPageNumber(e) == firstPageNum) hasComposerOnFirstPageOfMusic = true;

			}
		}
		curScore.endCmd(true); // undo
		if (!hasTitleOnFirstPageOfMusic) addError ("It doesn’t look like you have the title\nat the top of the first page of music.\n(See ‘Behind Bars’, p. 504)","pagetop");
		if (isSoloScore && !hasSubtitleOnFirstPageOfMusic)  addError ("It doesn’t look like you have a subtitle with the name of the solo instrument\nat the top of the first page of music. (See ‘Behind Bars’, p. 504)","pagetop");
		if (!hasComposerOnFirstPageOfMusic) addError ("It doesn’t look like you have the composer’s name\nat the top of the first page of music.\n(See ‘Behind Bars’, p. 504)","pagetop");
		selectAll();
	}
	
	function checkTextObject (textObject) {
		
		if (!textObject.visible) return;
		
		var windAndBrassMarkings = ["1.","2.","3.","4.","5.","6.","7.","8.","a 2","a 3","a 4","a 5","a 6","a 7","a 8","solo","1. solo","2. solo","3. solo","4. solo","5. solo","6. solo","7. solo","8. solo"];
		var replacements = ["accidentalNatural","n","accidentalSharp","#","accidentalFlat","b","metNoteHalfUp","h","metNoteQuarterUp","q","metNote8thUp","e","metNote16thUp","s","metAugmentationDot",".","dynamicForte","f","dynamicMezzo","m","dynamicPiano","p","dynamicRinforzando","r","dynamicSubito","s","dynamicSforzando","s","dynamicZ","z","","p","","ppp","","pp","","mp","","mf","","f","","ff","","fff","","sf","","sfz","","sffz","","z","","n","&nbsp;"," "," "," "];
		
		var eType = textObject.type;
		var nonBoldText = '';
		
		// ** subtypeName() returns a string such as "Title", "subtitle", "Tempo", etc.
		var eSubtype = textObject.subtypeName();
		if (eSubtype === "Tuplet") return;
		var eName = textObject.name;
		var styledText;
		
		if (eType == Element.GRADUAL_TEMPO_CHANGE) {
			styledText = textObject.beginText;
		} else {
			styledText = textObject.text;
		}
		//logError ("checking text: "+styledText+" subtype "+eSubtype+" name "+eName);

		if (styledText == undefined) {
			logError ("checkTextObject() — styledText is undefined");
			styledText = "";
		}
		
		if (eType == Element.REHEARSAL_MARK) {
			//logError ("Checking rehearsal mark from annotations");
			checkRehearsalMark (textObject);
			return;
		}
					
		// ** CHECK IT'S NOT A COMMENT WE'VE ADDED ** //
		var isComment = false;
		if (eType == Element.TEXT) isComment = Qt.colorEqual(textObject.frameBgColor,"yellow") && Qt.colorEqual(textObject.frameFgColor,"black");
		
		if (!isComment && styledText !== "") {	
			
			var textStyle = textObject.subStyle;
			var tn = textObject.name.toLowerCase();
			
			// remove all tags
			var styledTextWithoutTags = styledText.replace(/<[^>]+>/g, "");
			var plainText = styledTextWithoutTags;
			
			
			if (typeof plainText != 'string') logError('checkTextObject() — Typeof plainText not string: '+(typeof plainText));
			for (var i = 0; i < replacements.length; i += 2) {
				var regex1 = new RegExp(replacements[i],"g");
				plainText = plainText.replace(regex1,replacements[i+1]);
			}
			
			var lowerCaseText = plainText.toLowerCase();
			//logError("Text style is "+textStyle+"); subtype = "+eSubtype+"; styledtext = "+styledText+"; lowerCaseText = "+lowerCaseText);
			
			if (lowerCaseText != '') {
				var len = plainText.length;
				var isVisible = textObject.visible;
				
				// ** CHECK TITLE ** //
				if (eSubtype === "Title" && plainText === 'Untitled score') addError( "You have not changed the default title text",textObject);
				
				// ** CHECK SUBTITLE ** //
				if (eSubtype === "Subtitle") {
					if (plainText === 'Subtitle') addError( "You have not changed the default subtitle text",textObject);
					if (plainText.substring(0,4) === 'For ' || plainText.includes ('\nFor')) addError( "In the subtitle, make the ‘f’ in ‘for’ lower-case",textObject);
				}
				
				// ** CHECK COMPOSER ** //
				if (eSubtype === "Composer" && plainText === 'Composer / arranger') addError( "You have not changed the default composer text",textObject);
			
				// **** CHECK FOR STRAIGHT QUOTES THAT SHOULD BE CURLY **** //
				if (lowerCaseText.includes("'")) addError("This text has a straight single quote mark in it (').\nChange to curly: ‘ or ’.",textObject);	
				if (lowerCaseText.includes('\"')) addError('This text has a straight double quote mark in it (").\nChange to curly: “ or ”.',textObject);
				
				// **** CHECK FOR TEXT STARTING WITH SPACE OR NON-ALPHANUMERIC **** //
				var c = plainText.charCodeAt(0);
				if (c == 32) {
					addError("‘"+plainText+"’ begins with a space, which could be deleted.",textObject);
					return;
				}
				if (c < 32 && c != 10 && c != 13) {
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
				if (currentBarNum > 0) {
					
					// **** CHECK WHETHER INITIAL TEMPO MARKING EXISTS **** //
					if (!initialTempoExists && eType == Element.TEMPO_TEXT && currentBarNum == 1) initialTempoExists = true;
		
					// **** IS THIS A TEMPO CHANGE MARKING??? **** //
					var isTempoChangeMarking = false;
					//logError ("Checking "+lowerCaseText);
					if (!lowerCaseText.includes('trill') && !lowerCaseText.includes('trem')) {
						for (var i = 0; i < tempochangemarkings.length && !isTempoChangeMarking; i++) if (lowerCaseText.includes(tempochangemarkings[i])) isTempoChangeMarking = true;
					}
								
					// **** CHECK TEMPO CHANGE MARKING IS NOT IN TEMPO TEXT OR INCORRECTLY CAPITALISED **** //
					if (isTempoChangeMarking) {
						lastTempoChangeMarkingBar = currentBarNum;
						//logError("lastTempoChangeMarkingBar is now "+lastTempoChangeMarkingBar);
						lastTempoChangeMarking = textObject;
						if (eType != Element.TEMPO_TEXT && eType != Element.GRADUAL_TEMPO_CHANGE) {
							addError( "‘"+plainText+"’ is a tempo change marking,\nbut has not been entered as Tempo Text.\nChange in Properties→Show more→Text style→Tempo.",textObject);
							return;
						}
						if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) addError("‘"+plainText+"’ looks like it is a temporary change of tempo\nif it is, it should not have a capital first letter (see ‘Behind Bars’, p. 182)",textObject);
					}
		
					// **** IS THIS A TEMPO MARKING? **** //
					var isTempoMarking = false;
					if (!lowerCaseText.includes('trill') && !lowerCaseText.includes('trem')) {
						//logError ("Checking "+lowerCaseText);
						for (var j = 0; j < tempomarkings.length && !isTempoMarking; j++) {
							if (lowerCaseText.includes(tempomarkings[j])) {
								isTempoMarking = true;
								//logError ("Styled text = "+styledText.replace(/</g,'{'));
								if (styledText.includes("<b>")) {
									// strip anything not between <b> tags, then strip any other tags (to ensure '=' is no longer in string)
									nonBoldText = styledText.replace(/<b>.*?<\/b>/g,'').replace(/<[^>]+>/g, "");
								} else {
									//logError ("eType = "+eType+" ("+Element.TEMPO_TEXT+" "+Element.METRONOME+")");
									if ((eType == Element.TEMPO_TEXT || eSubtype === "Tempo") && tempoFontStyle != 1) nonBoldText = styledTextWithoutTags;
									if ((eType == Element.METRONOME || eSubtype === "Metronome") && metronomeFontStyle != 1) nonBoldText = styledTextWithoutTags;
								}
								//logError ("Found a tempo marking: non bold text is "+nonBoldText);
								if (nonBoldText.toLowerCase().includes(tempomarkings[j])) addError ("All tempo markings should be in bold type.\n(See ‘Behind Bars’, p. 182)",textObject);
								
								// does this require a metronome mark?
								var tempoMarkingToIgnoreArray = ["a tempo","tempo primo","tempo 1o","tempo 1°","mouv"];
								var ignoreTempoMarking = false;
								for (var k = 0; k < tempoMarkingToIgnoreArray.length && !ignoreTempoMarking; k++) if (lowerCaseText.includes(tempoMarkingToIgnoreArray[k])) ignoreTempoMarking = true;
								if (!ignoreTempoMarking) {
									lastTempoMarking = textObject;
									lastTempoMarkingBar = currentBarNum;
								}
							}
						}
					}
					
					if (isTempoMarking) {
						
						lastTempoChangeMarkingBar = -1;
						tempoChangeMarkingEnd = -1;
						//logError ("isTempoMarking — tempoChangeMarkingEnd is now "+tempoChangeMarkingEnd);
						//logError("Cancelled tempo change marking in b. "+currentBarNum);
					
						// **** CHECK TEMPO MARKING IS IN TEMPO TEXT **** //
						if (eType != Element.TEMPO_TEXT) addError("Text ‘"+plainText+"’ is a tempo marking,\nbut has not been entered as Tempo Text.\Change in Properties→Show more→Text style→Tempo.",textObject);
				
						// **** CHECK TEMPO SHOULD BE CAPITALISED **** //
						if (plainText.substring(0,1) === lowerCaseText.substring(0,1) && lowerCaseText != "a tempo" && lowerCaseText.charCodeAt(0)>32 && !lowerCaseText.substring(0,4).includes("=")) addError("‘"+plainText+"’ looks like it is establishing a new tempo;\nif it is, it should have a capital first letter. (See ‘Behind Bars’, p. 182)",textObject);
						
						// ** CHECK TEMPO DOES NOT HAVE A DOT AT THE END ** //
						if (plainText.slice(-1) === '.' && !lowerCaseText.includes("mouv")) addError ("Tempo markings do not need a full-stop at the end.",textObject);
						
					}
				
					// **** CHECK TEMPO POINT SIZE **** //
					if (isTempoMarking || isTempoChangeMarking) {
						if (textObject.fontSize > 12.0) addError("This tempo marking is larger than 12pt,\nand may appear overly large.",textObject);
						if (textObject.fontSize < 10.0) addError("This tempo marking is smaller than 10pt,\nand may appear overly small.",textObject);
					}
					
					// **** CHECK METRONOME MARKINGS **** //
					var isMetronomeMarking = false;
					if (styledTextWithoutTags.includes("=")) {
						for (var j = 0; j < metronomemarkings.length && !isMetronomeMarking; j++) {
							//logError (styledTextWithoutTags+" includes "+metronomemarkings[j]+" = "+styledTextWithoutTags.includes(metronomemarkings[j]));
							if (styledTextWithoutTags.includes(metronomemarkings[j])) {
								isMetronomeMarking = true;
								
								// **** CHECK THAT METRONOME MARKING MATCHES THE TIME SIGNATURE **** //
								var metronomeDuration = division; // crotchet
								var hasAugDot = metronomemarkings[j].includes('.') || metronomemarkings[j].includes('metAugmentationDot') || metronomemarkings[j].includes('\uECB7');
								var metroStr = "crotchet/quarter note";
								if (metronomemarkings[j].includes('metNote8thUp') || metronomemarkings[j].includes('\uECA7')) {
									metronomeDuration = division / 2; // quaver
									metroStr = "quaver/eighth note";
								}
								if (metronomemarkings[j].includes('metNoteHalfUp') || metronomemarkings[j].includes('\uECA3')) {
									metronomeDuration = division * 2; // minim
									metroStr = "minim/half note";
								}
								if (hasAugDot) {
									metronomeDuration *= 1.5;
									metroStr = "dotted "+metroStr;
								}
								if (metronomeDuration != virtualBeatLength) addError ("The metronome marking of "+metroStr+" does\nnot match the time signature of "+currentTimeSig.str+".",textObject);
								lastMetronomeMarkingBar = currentBarNum;
								if (nonBoldText === "") {
									//logError ("styledText is "+styledText.replace(/</g,'{'));
									if (styledText.includes('<b>')) {
										// see comment above on the RegExp
										nonBoldText = styledText.replace(/<b>.*?<\/b>/g,'').replace(/<[^>]+>/g, '');
									} else {
										//logError ("eType = "+eType+" ("+Element.TEMPO_TEXT+" "+Element.METRONOME+")");
										if ((eType == Element.TEMPO_TEXT || eSubtype === 'Tempo') && tempoFontStyle != 1) nonBoldText = styledTextWithoutTags;
										if ((eType == Element.METRONOME || eSubtype === 'Metronome') && metronomeFontStyle != 1) nonBoldText = styledTextWithoutTags;
									}
								}
								//logError ("Found a metronome marking: non bold text is "+nonBoldText);
							}
						}
						if (isMetronomeMarking) {
							
							// ** CHECK IF METRONOME MARKING IS IN METRONOME TEXT STYLE ** //
							var metroIsPlain = nonBoldText.includes('=');
							//logError ("isTempoMarking: "+isTempoMarking+" isTempoChangeMarking: "+isTempoChangeMarking+" isMetro: "+isMetronomeMarking+"; metroIsPlain = "+metroIsPlain);
							if (!isTempoMarking && !isTempoChangeMarking && !metroIsPlain) {
								addError ('It is recommended to have metronome markings in a plain font style, not bold.\n(See, for instance, ‘Behind Bars’ p. 183)',textObject)
							}
							if (isTempoMarking && !metroIsPlain) {
								addError ('It is recommended to have the metronome marking part of\nthis tempo marking in a plain font style, not bold.\n(See, for instance, ‘Behind Bars’ p. 183)',textObject);
							}
						}
					}
				
					// **** CHECK DIV/UNIS. **** //
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
					if (eSubtype !== "Title" && eSubtype !== "Subtitle") {
						for (var i = 0; i < dontCap.length; i++) {
							var theWord = dontCap[i];
							var l = theWord.length;
							if (plainText.includes(theWord) && plainText.substring(0,l) !== theWord) {
								addError ( "You don’t need to capitalise ‘"+theWord+"", textObject);
								return;
							}
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
					if (!isSpellingError && eSubtype !== "Title" && eSubtype !== "Subtitle" && eSubtype !== "Tempo") {
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
					var includesADynamic = styledText.includes('<sym>dynamics');
					var stringIsDynamic = isDynamic(lowerCaseText);
				
					// **** CHECK REDUNDANT DYNAMIC **** //
					if (objectIsDynamic || includesADynamic || stringIsDynamic) {
						//logError("dynamic — plainText = "+plainText);
											
						firstDynamic = true;
						tickHasDynamic = true;
						theDynamic = textObject;
						lastDynamicTick = currTick;
						setDynamicLevel (plainText);
						
						var isError = false;
						var dynamicException = plainText.includes("fp") || plainText.includes("fmp") || plainText.includes("sf") || plainText.includes("fz");
						if (prevDynamicBarNum > 0) {
							var barsSincePrevDynamic = currentBarNum - prevDynamicBarNum;
							if (plainText === prevDynamic && barsSincePrevDynamic < 5 && !dynamicException) {
								// check if visual overlapping
								
								if (textObject.pagePos == prevDynamicObject.pagePos && textObject.bbox.width == prevDynamicObject.bbox.width && textObject.bbox.height == prevDynamicObject.bbox.height) {
									//logError (textObject.pagePos+' '+prevDynamicObject.pagePos);
									//logError (textObject.text+" "+textObject.bbox+ " "+prevDynamicObject.text+" "+prevDynamicObject.bbox);
									addError ("There appear to be two dynamic markings overlapped here.\nYou can safely delete one of them.",textObject);
								} else {
									addError("This dynamic may be redundant:\nthe same dynamic was set in b. "+prevDynamicDisplayBarNum+".",textObject);
								}
								isError = true;
							}
						}
					
						if (!dynamicException) {
							prevDynamicBarNum = currentBarNum;
							prevDynamicDisplayBarNum = displayBarNum;
							prevDynamic = plainText;
							prevDynamicObject = textObject;
						} else {
							if (plainText === "fmp" || plainText === "sfmp" || plainText === "sfzmp" || plainText === "sffzmp" || plainText === "sfffzmp") {
								prevDynamicBarNum = currentBarNum;
								prevDynamic = "p";
							}
							if (plainText === "fp" || plainText === "sfp" || plainText === "sfzp" || plainText === "sffzp" || plainText === "sfffzp") {
								prevDynamicBarNum = currentBarNum;
								prevDynamic = "p";
							}
							if (plainText === "fpp" || plainText === "sfpp" || plainText === "sfzpp" || plainText === "sffzpp" || plainText === "sfffzpp") {
								prevDynamicBarNum = currentBarNum;
								prevDynamic = "pp";
							}
							if (plainText === "fppp" || plainText === "sfppp" || plainText === "sfzppp" || plainText === "sffzppp" || plainText === "sfffzppp") {
								prevDynamicBarNum = currentBarNum;
								prevDynamic = "ppp";
							}
						}
						if (isError) return;
					}
					//logError(""+lowerCaseText+" isDyn = "+isDyn);
				
					// **** CHECK FOR DYNAMIC ENTERED AS EXPRESSION (OR OTHER) TEXT **** //
					if (!objectIsDynamic && (includesADynamic || stringIsDynamic)) {
						addError("This text object looks like a dynamic,\nbut has not been entered using the Dynamics palette",textObject);
						return;
					}
			
					// **** CHECK FOR TECHNIQUES ENTERED AS EXPRESSION TEXT **** //
					if (tn === "expression") {
						for (var i = 0; i < techniques.length; i ++) {
							if (lowerCaseText.includes(techniques[i])) {
								addError("This looks like a technique, but has been\nincorrectly entered as Expression text.\nPlease check whether this should be in Technique Text instead.",textObject);
								return;
							}
						}
						var canBeAbove = plainText === "loco" || plainText.includes("ten.") || plainText.includes("tenuto") || plainText.includes("legato") || plainText.includes("flz");
						if (textObject.placement == Placement.ABOVE && !canBeAbove) {
							addError("Expression text should appear below the staff.\nCheck it is attached to the right staff, or it should be a technique.",textObject);
							return;
						}
					}
					
					checkInstrumentalTechniques (textObject, plainText, lowerCaseText);
				
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
	
	function checkChordNotesTied (noteRest) {
		var numNotes = noteRest.notes.length;
		var nextChord = getNextNoteRest(noteRest);
		if (nextChord == null) return;
		if (nextChord.notes == null) return;
		if (numNotes != nextChord.notes.length) return;
		var numTies = 0;
		for (var i = 0; i < numNotes; i++) {
			if (noteRest.notes[i].pitch != nextChord.notes[i].pitch) return;
			if (noteRest.notes[i].tieForward) numTies ++;
		}
		if (numTies > 0 && numTies < numNotes) addError ("This chord only has some notes tied to the next chord.\nShould they ALL be tied?",noteRest);
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
	
	function setDynamicLevel (str) {
		// set multiple dynamics first and return
		// dynamicLevel — 0 = ppp–p, 1 = mp, 2 = mf, 3 = f, 4 = ff+
		if (str === 'sf' || str === 'sfz' || str === 'sffz' || str === 'rf' || str === 'rfz') return;
		var strWords = str.split(' ');
		if (strWords.includes ('p') || strWords.includes ('pp') || str.includes('ppp') || str.includes('fp') || str.includes('fzp')) {
			currDynamicLevel = 0;
			return;
		}
		if (strWords.includes('mp') || str.includes('zmp') || str.includes('fmp')) {
			currDynamicLevel = 1;
			return;
		}
		if (strWords.includes('mf')) {
			currDynamicLevel = 2;
			return;
		}
		if (strWords.includes('f') && !str.includes('ff')) {
			currDynamicLevel = 3;
			return;
		}
		if (str.includes('ff')) {
			currDynamicLevel = 4;
			return;
		}
		logError ('Can’t find dynamic level for '+str);
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
		for (var s = 0; s < numStaves-1; s ++) {
			var staff = curScore.staves[s];
			if (staff.staffBarlineSpan == 0) {
				addError ("The barlines should go through all of the staves for a "+str,"system1 1");
				return;
			}
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
						var n = theTimeSig.subtypeName();
						if (n.includes("Common")) addError ("The ‘Common time’ time signature is considered old-fashioned these days;\nIt is better to write this in full, as 4/4",theTimeSig);
						if (n.includes("Cut")) addError ("The ‘Cut time’ time signature is considered old-fashioned these days;\nIt is better to write this in full, as 2/2",theTimeSig);
					}
				}
			}
			segment = segment.next;
		}
	}
	
	function checkFermatas () {
		var ticksDone = [];
		for (var i = 0; i < fermatas.length; i++) {
			var fermata = fermatas[i];
			var fermataLoc = fermataLocs[i];
			var staffIdx = fermataLoc.split(' ')[0];
			var theTick = fermataLoc.split(' ')[1];
			// check if we've already done this fermata
			if (!ticksDone.includes(theTick)) {			
				var fermataInAllParts = true;
				for (var j = 0; j<numStaves && fermataInAllParts; j++) {
					if (staffVisible[j]) {
						var searchFermata = j+' '+theTick;
						if (j!=staffIdx) fermataInAllParts = fermataLocs.includes(searchFermata);
					}
				}
				if (!fermataInAllParts) addError("In general, a fermata should be placed in ALL parts, appearing on the same beat.\nThere are some instances where placing fermatas on different beats is permitted.\nUse your judgement as to whether you may ignore this warning (see ‘Behind Bars’, p. 190)",fermata);
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
		if (isSlurred && flaggedSlurredStaccatoBar < currentBarNum - 4 && isStringInstrument) {
			var prev = getPreviousNoteRest(noteRest);
			var next = getNextNoteRest(noteRest);
			if (noteRest.notes.length > 0) {
				var pitch = noteRest.notes[0].pitch;
				var prevPitch = 0, nextPitch = 0;
				if (prev != null) {
					if (prev.notes != null) {
						if (prev.notes.length > 0) prevPitch = prev.notes[0].pitch;
					}
				}
				if (next != null) {
					if (next.notes != null) {
						if (next.notes.length > 0) nextPitch = next.notes[0].pitch;
					}
				}
				var portatoOK = (pitch == prevPitch || pitch == nextPitch);
				if (!portatoOK) {
					addError ("Slurred staccatos are not common as string articulations,\nexcept to mark portato (repeated notes under a slur).\nDid you want to consider rewriting them as legato?",noteRest);
					flaggedSlurredStaccatoBar = currentBarNum;
				}
			}
		}
	}
	
	function isDotted(noteRest) {
		var dottedDurs = [0.75,0.875,1.5,1.75,3,3.5];
		var displayDur = noteRest.duration.ticks / parseFloat(division);
		return dottedDurs.includes(displayDur);
	}
	
	function checkInstrumentalRanges (noteRest) {
		var maxNumLedgerLines = getMaxNumLedgerLines(noteRest);
		var minNumLedgerLines = (noteRest.notes.length > 1) ? getMinNumLedgerLines(noteRest) : maxNumLedgerLines;
		var absLL = Math.abs(maxNumLedgerLines);
		if (absLL > maxLLSinceLastRest) maxLLSinceLastRest = absLL;
		var numberOfRecentNotesToCheck = 3;
		if (maxLedgerLines.length >= numberOfRecentNotesToCheck) {
			maxLedgerLines = maxLedgerLines.slice(1);
			minLedgerLines = minLedgerLines.slice(1);
		}
		
		if (isHorn) {
			//logError ("Checking horn note — "+noteRest.notes[0].pitch+" b "+isBassClef+" t "+isTrebleClef);
			if (isBassClef && noteRest.notes[0].pitch > 40 && flaggedInstrumentRange != 1) {
				addError ("This horn note/passage is too high for bass clef;\nit would be better in treble clef", noteRest);
				flaggedInstrumentRange = 1;
			}
			if (isTrebleClef && noteRest.notes[0].pitch < 41 && flaggedInstrumentRange != 2) {
				addError ("This horn note/passage is too low for treble clef;\nit would be better in bass clef", noteRest);
				flaggedInstrumentRange = 2;
			}
		}
		if (maxNumLedgerLines > 3 && minNumLedgerLines > 0) {
			if (isBassClef && readsBass && (readsTenor || readsTreble) && flaggedInstrumentRange != 3) {
				addError("This passage is very high for bass clef;\nit may be better in tenor or treble clef",noteRest);
				flaggedInstrumentRange = 3;
			}
			if (isTenorClef && readsTenor && readsTreble && flaggedInstrumentRange != 4) {
				addError("This passage is very high for tenor clef;\nit may be better in treble clef",noteRest);
				flaggedInstrumentRange = 4;
			}
			if (isAltoClef && readsAlto && readsTreble && flaggedInstrumentRange != 21) {
				addError("This passage is very high for alto clef;\nit may be better in treble clef",noteRest);
				flaggedInstrumentRange = 21;
			}
		}
		if (maxNumLedgerLines > 5 && minNumLedgerLines > 2) {
			if (isTrebleClef && readsTreble && reads8va && !isOttava && flaggedInstrumentRange != 5) {
				addError("This passage is very high for treble clef;\nit may be better with an 8va symbol",noteRest);
				flaggedInstrumentRange = 5;
			}
		}
		if (maxNumLedgerLines < 0 && minNumLedgerLines <= 0) {
			if (isTrebleClef && readsTreble) {
				if (readsTenor && flaggedInstrumentRange != 6) {
					addError("This passage is very low for treble clef;\nit may be better in tenor or bass clef",noteRest);
					flaggedInstrumentRange = 6;
				} else {
					if (maxNumLedgerLines < -3 && readsBass && flaggedInstrumentRange != 7) {
						addError("This passage is very low for treble clef;\nit may be better in bass clef",noteRest);
						flaggedInstrumentRange = 7;
					} else {
						if (readsAlto && flaggedInstrumentRange != 8) {
							addError("This passage is very low for treble clef;\nit may be better in alto clef",noteRest);
							flaggedInstrumentRange = 8;
						}
					}
				}
			}
			if (isTenorClef && readsTenor && readsBass && maxNumLedgerLines < 0 && minNumLedgerLines <= 0 && flaggedInstrumentRange != 9) {
				addError("This passage is very low for tenor clef;\nit may be better in bass clef",noteRest);
				flaggedInstrumentRange = 9;
			}
			if (isBassClef && readsBass && reads8va && !isOttava && maxNumLedgerLines < -3 && minNumLedgerLines < -2 && flaggedInstrumentRange != 10) {
				addError("This passage is very low for bass clef;\nit may be better with an 8ba",noteRest);
				flaggedInstrumentRange = 10;
			}
		}
	//	if (!flaggedInstrumentRange) logError("ll length now "+ledgerLines.length);
		if (!flaggedInstrumentRange && maxLedgerLines.length >= numberOfRecentNotesToCheck) {
			var averageMaxNumLedgerLines = maxLedgerLines.reduce((a,b) => a+b) / maxLedgerLines.length;
			var averageMinNumLedgerLines = minLedgerLines.reduce((a,b) => a+b) / minLedgerLines.length;
			
			if (isOttava && currentOttava != null) {
				var ottavaArray = ["an 8va","an 8ba","a 15ma","a 15mb"];
				var ottavaStr = ottavaArray[currentOttava.ottavaType]; 
				//logError("Testing 8va Here — currentOttava.ottavaType = "+currentOttava.ottavaType+"); averageNumLedgerLines "+averageNumLedgerLines+" maxLLSinceLastRest="+maxLLSinceLastRest;
				if (currentOttava.ottavaType == 0 || currentOttava.ottavaType == 2) {
					if (averageMaxNumLedgerLines < 2 && averageMinNumLedgerLines >= 0 && maxLLSinceLastRest < 2 && flaggedInstrumentRange != 11) {
						addError("This passage is quite low for "+ottavaStr+" line:\nyou should be able to safely write this at pitch",currentOttava);
						flaggedInstrumentRange = 11;
						return;
					}
				} else {
					if (averageMaxNumLedgerLines > -2 && averageMinNumLedgerLines <= 0 && maxLLSinceLastRest < 2 && flaggedInstrumentRange != 12) {
						addError("This passage is quite high for "+ottavaStr+" line:\nyou should be able to safely write this at pitch",currentOttava);
						flaggedInstrumentRange = 12;
						return;
					}
				}
			}
			if (isBassClef) {
				//trace(averageNumLedgerLines);
				if (readsTenor && averageMaxNumLedgerLines >= 3 && averageMinNumLedgerLines > 1 && flaggedInstrumentRange != 13) {
					addError("This passage is quite high;\nit may be better in tenor or treble clef",noteRest);
					flaggedInstrumentRange = 13;
				} else {
					if (readsTreble && averageMaxNumLedgerLines >= 3 && averageMinNumLedgerLines > 2 && flaggedInstrumentRange != 14) {
						addError("This passage is very high;\nit may be better in treble clef",noteRest);
						flaggedInstrumentRange = 14;
					} else {
						if (reads8va && averageMaxNumLedgerLines < -4 && averageMinNumLedgerLines < -2 && !isOttava && flaggedInstrumentRange != 15) {
							addError("This passage is very low;\nit may be better with an 8ba",noteRest);
							flaggedInstrumentRange = 15;
						}
					}
				}
			}

			if (isTenorClef) {
				if (readsTreble && averageMaxNumLedgerLines > 2 && averageMinNumLedgerLines > 1 && flaggedInstrumentRange != 16) {
					addError("This passage is quite high;\nit may be better in treble clef",noteRest);
					flaggedInstrumentRange = 16;
				} else {
					if (readsBass && averageMaxNumLedgerLines < -1  && averageMinNumLedgerLines <= 0 && flaggedInstrumentRange != 17) {
						addError("This passage is quite low;\nit may be better in bass clef",noteRest);
						flaggedInstrumentRange = 17;
					}
				}
			}
			if (isTrebleClef) {
				if (reads8va && averageMaxNumLedgerLines > 4 && averageMinNumLedgerLines > 2 && !isOttava && flaggedInstrumentRange != 18) {
					addError("This passage is very high;\nit may be better with an 8va",noteRest);
					flaggedInstrumentRange = 18;
				} else {
					if (readsTenor && averageMaxNumLedgerLines < -1 && averageMinNumLedgerLines <= 0 && flaggedInstrumentRange != 19) {
						addError("This passage is quite low;\nit may be better in tenor clef",noteRest);
						flaggedInstrumentRange = 19;
					} else {
						if (readsBass && averageMaxNumLedgerLines < -2 && averageMinNumLedgerLines <= 0 && flaggedInstrumentRange != 20) {
							addError("This passage is quite low;\nit may be better in bass clef",noteRest);
							flaggedInstrumentRange = 20;
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
			var l = note.line; // 0 = top line, 1 = top space, 2 = second top line, etc...
			// numbers less than -1 are ledger lines ABOVE the staff
			if (l < -1) numLedgerLines = parseInt(Math.abs(l)/2);
			// numbers greater than 9 are ledger lines BELOW the staff
			if (l > 9) numLedgerLines = -parseInt((l-8)/2);
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
			if (l < -1) numLedgerLines = parseInt(Math.abs(l)/2);
			if (l > 9) numLedgerLines = -parseInt((l-8)/2);
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
		var maxStretch = 13; // 6 + 7
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
		
		if (currentInstrumentId.includes("violin") || currentInstrumentName.toLowerCase().includes("violin")) {
			iName = "violin";
			stringsArray = violinStrings;
			stringNames = violinStringNames;
		}
		if (currentInstrumentId.includes("viola") || currentInstrumentName.toLowerCase().includes("viola")) {
			iName = "viola";
			stringsArray = violaStrings;
			stringNames = violaStringNames;
			maxStretch = 12;
		}
		if (currentInstrumentId.includes("cello") || currentInstrumentName.toLowerCase().includes("cello")) {
			iName = "cello";
			stringsArray = celloStrings;
			stringNames = celloStringNames;
		}
		if (currentInstrumentId.includes("bass") || currentInstrumentName.toLowerCase().includes("bass")) {
			iName = "double bass";
			stringsArray = bassStrings;
			stringNames = bassStringNames;
			maxStretch = 9;
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
		var bottomNote = p1 < p2 ? p1: p2;
		if (!stringsArray.includes(p1) && !stringsArray.includes(p2)) interval = Math.abs(p2-p1);
		//logError("p1 = "+p1+"); p2 = "+p2+"; interval="+interval;
		
		if (numNotes == 2 && interval > maxStretch) addError ("This double-stop appears to be larger than a safe stretch on the "+iName+"\nIt may not be possible: check with a player.",chord);
		if (bottomNote > stringsArray[2] + 12) {
			if (interval < 7) {
				addError ("In general, avoid double-stops less than a fifth in a high position,\nas the bottom note is over an octave above the open string.\nThe intonation may be poor; consider increasing the interval to greater than a fifth.",chord);
			} else {
				addError ("This double-stop is quite high, with the bottom note over an octave above II.\nThe intonation may be poor — consider rewriting.",chord);
			}
		}
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
			
			// **** ARTIFICIAL HARMONICS **** //
			if (noteheadStyle1 == NoteHeadGroup.HEAD_NORMAL && noteheadStyle2 == NoteHeadGroup.HEAD_DIAMOND) {
				isStringHarmonic = true;
				// we have a false harmonic
				// are notes always in bottom-up order?
				var noteheadPitch1 = noteRest.notes[0].pitch;
				var noteheadPitch2 = noteRest.notes[1].pitch;
				var bottomNote = noteheadPitch1 < noteheadPitch2 ? noteRest.notes[0] : noteRest.notes[1];
				var topNote = noteheadPitch1 < noteheadPitch2 ? noteRest.notes[1] : noteRest.notes[0];
				//logError("FALSE HARM FOUND: np1 "+noteheadPitch1+" np2 "+noteheadPitch2);
				var interval = topNote.pitch - bottomNote.pitch;
				
				if (interval != 5) addError("This looks like an artificial harmonic, but the interval between\nthe fingered and touched pitch is not a perfect fourth.",noteRest);
				
				// check override on the top note
				if (noteRest.duration.ticks <= 2 * division) {
					var noteheadType = topNote.headType;
					if (noteheadType != NoteHeadType.HEAD_HALF) {
						addError("The diamond harmonic notehead should be hollow.\nIn Properties, set ‘Override visual duration’ to a minim.\n(See ‘Behind Bars’, p. 428)",noteRest);
					}
				}
				
				// check register
				if (bottomNote.pitch > stringsArray[3]+10) addError ("This artificial harmonic looks too high to be effective.\nConsider putting it down an octave",noteRest);
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
					var noteheadType = noteRest.notes[0].headType;
					if (noteheadType != NoteHeadType.HEAD_HALF) {
						addError("The diamond harmonic notehead should be hollow.\nIn Properties, set ‘Override visual duration’ to a minim.\n(See ‘Behind Bars’, p. 11)",noteRest);
					}
				}
			}
			if (isStringHarmonic) {
				var p = noteRest.notes[0].pitch;
				var harmonicOK = false;
				if (currentInstrumentId.includes("violin") || currentInstrumentName.toLowerCase().includes("violin")) stringsArray = violinStrings;
				if (currentInstrumentId.includes("viola") || currentInstrumentName.toLowerCase().includes("viola")) stringsArray = violaStrings;
				if (currentInstrumentId.includes("cello") || currentInstrumentName.toLowerCase().includes("cello")) stringsArray = celloStrings;
				if (currentInstrumentId.includes("bass") || currentInstrumentName.toLowerCase().includes("bass")) stringsArray = bassStrings;
				if (stringsArray.length == 0) logError ("checkStringHarmonic() — I couldn’t work out what string instrument this was — "+currentInstrumentId);
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
				addError ("Chord found in string section, but not marked as div.\n(If this is a solo work or chamber ensemble, you incorrectly chose the ‘Section’ instrument)\nYou can ignore if this has a ‘non div.’ mark, or a bracket to indicate multiple stop.",noteRest);
				flaggedDivError = true;
			}
		} else {
			if (isDiv && !flaggedDivError) {
				addError ("Single note found in string section, but no unis. marked\n(If this is a solo work or chamber ensemble, you incorrectly chose the ‘Section’ instrument)",noteRest);
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
		
		// ignore articulation issues if it's pizz
		lastArticulationTick = currTick;
		
		if (staffNum == lastPizzIssueStaff && barNum-lastPizzIssueBar < 5) return;
		// check staccato
		if (typeof staffNum !== 'number') logError("checkPizzIssues() — Articulation error");
		
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
		//logError("Slur off1 "+currentSlur.slurUoff1+" off2 "+currentSlur.slurUoff2+" off3 "+currentSlur.slurUoff3+" off4 "+currentSlur.slurUoff4);
		var currSlurTick = noteRest.parent.tick;
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
		var isStartOfSlur = currSlurTick == slurStart;
		var slurLength = currentSlur.spannerTicks.ticks;
		var slurEnd = slurStart + slurLength;
		var isEndOfSlur = currSlurTick == slurEnd;
		//logError("slurStart "+slurStart+" slurEnd "+slurEnd);

		//logError("CHECKING SLUR: isRest: "+isRest);
		if (isStartOfSlur && isStringInstrument && slurLength > division * 8) addError("Consider whether this slur is longer than one bow stroke\nand should be broken into multiple slurs.",currentSlur);

		// **** CHECK WHETHER SLUR HAS BEEN MANUALLY SHIFTED **** //
		if (isStartOfSlur) {
			if (currentSlur.offsetY != 0 && currentSlur.offsetX != 0) {
				addError ("This slur looks like it has been dragged\naway from its correct position.",currentSlur);
			} else {
				if (currentSlur.offsetY != 0) addError ("This slur looks like it has been dragged\nvertically away from its correct position.",currentSlur);
				if (currentSlur.offsetX != 0) addError ("This slur looks like it has been dragged\nhorizontally away from its correct position.",currentSlur);
			}
		//	var t = [currentSlur.offsetX,currentSlur.offsetY,currentSlur.posX,currentSlur.posY,currentSlur.pagePos.x,currentSlur.pagePos.y,currentSlur.offset.x,currentSlur.offset.y,currentSlur.slurUoff1.x,currentSlur.slurUoff1.y,currentSlur.slurUoff2.x,currentSlur.slurUoff2.y,currentSlur.slurUoff3.x,currentSlur.slurUoff3.y,currentSlur.slurUoff4.x,currentSlur.slurUoff4.y].join(' ');
			//logError (t);
			if (Math.abs(currentSlur.slurUoff1.x) > 0.5 || Math.abs(currentSlur.slurUoff4.x) > 0.5) addError ("This slur looks like it has been manually positioned by dragging an endpoint.\nIt’s usually best to use the automatic positioning of MuseScore by first\nselecting all of the notes under the slur, and then adding the slur.",currentSlur);
		}
		
		// **** CHECK SLUR GOING OVER A REST FOR STRINGS, WINDS & BRASS **** //
		if (isRest) {
			if ((isWindOrBrassInstrument || isStringInstrument) && !flaggedSlurredRest && currentSlur.spannerTicks.ticks > 0) {
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
				//logError ("isStartOfSlur "+isStartOfSlur+" prevNote "+(prevNote != null) + " prevSlurNum "+prevSlurNum+" currentSlurNum:"+currentSlurNum+" tieBack"+(noteRest.notes[0].tieBack == null));
				if (!isStartOfSlur && prevNote != null && prevSlurNum == currentSlurNum && noteRest.notes[0].tieBack == null) {
					var iterationArticulationArray = [kTenutoAbove,kTenutoBelow,
						kStaccatissimoAbove, kStaccatissimoAbove+1,
						kStaccatissimoStrokeAbove, kStaccatissimoStrokeAbove+1,
						kStaccatissimoWedgeAbove, kStaccatissimoWedgeAbove+1,
						kStaccatoAbove, kStaccatoAbove+1];
					var noteheadStyle = noteRest.notes[0].headGroup;
					var prevNoteheadStyle = prevNote.notes[0].headGroup;
					if (noteRest.notes.length == prevNote.notes.length) {
						var numNotes = noteRest.notes.length;
						var numPrevNotes = prevNote.notes.length;
						var chordMatches = numNotes == numPrevNotes;
						//logError ("numNotes matches = "+chordMatches);
						if (chordMatches) for (var i = 0; i < numNotes && chordMatches; i++) if (noteRest.notes[i].pitch != prevNote.notes[i].pitch) chordMatches = false;
						//logError ("chordMatches "+chordMatches);
						if (chordMatches && noteheadStyle != NoteHeadGroup.HEAD_DIAMOND && prevNoteheadStyle != NoteHeadGroup.HEAD_DIAMOND) {
							//logError ("here1");
							if (getArticulationArray(noteRest,staffNum) == null) {
								//logError ("here2");
								if (isEndOfSlur && prevWasStartOfSlur) {
									addError("A slur has been used between two notes of the same pitch.\nIs this supposed to be a tie, or do you need to add articulation?",currentSlur);
								} else {
									var errStr = "";
									if (numNotes == 1) {
										errStr = "Don’t repeat the same note under a slur. Either remove the slur,\nor add some articulation (e.g. tenuto/staccato).";
									} else {
										errStr = "Don’t repeat the same chord under a slur. Either remove the slur,\nor add some articulation (e.g. tenuto/staccato).";
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
				//logError("Slur started — mid = "+isMiddleOfTie+"); start = "+isStartOfTie);
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
				if (typeof staffNum !== 'number') logError("checkSlurIssues() — Articulation error");
			
				var theArticulationArray = getArticulationArray(noteRest, staffNum);
				if (theArticulationArray) {
					for (var i = 0; i < theArticulationArray.length; i++) {
						if (accentsArray.includes(theArticulationArray[i].symbol) ) {
							if (isStringInstrument) addError("In general, avoid putting accents on notes in the middle of a slur\nas strings usually articulate accents with a bow change.",noteRest);
							if (isWindOrBrassInstrument) addError("In general, avoid putting accents on notes in the middle of a slur\nas winds and brass usually articulate accents with their tongue.",noteRest);
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
		
		// ** check bow length and dynamic
		if (isStartOfSlur && isStringInstrument) {
			// dynamicLevel — 0 = ppp–p, 1 = mp, 2 = mf, 3 = f, 4 = ff+
			var maxSlurDurations = [8,6,4,3,2];
			var maxSlurDuration = maxSlurDurations[currDynamicLevel];
			var cursor = curScore.newCursor();
			cursor.staffIdx = staffNum;
			cursor.track = 0;
			cursor.rewindToTick(currSlurTick);
			var beatDurInSecs = 1./cursor.tempo;
			var tickDurInSecs = beatDurInSecs / division;
			var slurDurInSecs = currentSlur.spannerTicks.ticks*tickDurInSecs;
			if (slurDurInSecs > maxSlurDuration) addError ("This slur/bow mark may be too long at the stated dynamic.\nCheck with a performer whether a shorter one would be more appropriate.",currentSlur);
		}
		
	}
	
	function checkHarpIssues (currentBar, staffNum) {
		var cursor = curScore.newCursor();
		
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
					var theTick = currSeg.tick;
					var noteRest = cursor.element;
					if (noteRest.type == Element.CHORD) {
						var theNotes = noteRest.notes;
						var nNotes = theNotes.length;
						if (allNotes[currTick] == undefined) allNotes[currTick] = [];
						for (var  i = 0; i < nNotes; i++) allNotes[theTick].push(theNotes[i]);
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
				var theNotes = allNotes[i];
				var numNotes = theNotes.length;
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
				errorStr += "\ni.e. the first item in the Grace notes palette (see ‘Behind Bars’, p. 125)";
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
				return articulations[staffNum][theTick];
			}
		}
		return null;
	}
	
	function checkRehearsalMark (textObject) {
		//logError("Found reh mark "+textObject.text);
		if (getTick(textObject) != barStartTick) addError ("This rehearsal mark is not attached to beat 1.\nAll rehearsal marks should be above the first beat of the bar.",textObject);
		//logError ("Checking rehearsal mark");
		if (currentBarNum < 2) addError ("Don’t put a rehearsal mark at the start of the piece.\nUsually your first rehearsal mark will come about 12–20 bars in.",textObject);
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
		for (var i = 0; i<expectedRehearsalMarkLength; i++) expectedRehearsalMark += String.fromCharCode(currASCIICode);
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
		lastArticulationTick = currTick;
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
		//logError ("isStringInstrument: "+isStringInstrument+"; isSlurred: "+isSlurred);
		if (isStringInstrument && isSlurred) addError("You shouldn’t have a slur over a bowed tremolo.",noteRest);
	}
	
	function checkTwoNoteTremolo (noteRest, tremolo) {
		if (tremolo == null || tremolo == undefined) logError("checkTwoNoteTremolo() — tremolo is "+tremolo);
		lastArticulationTick = currTick;
		var tremDescription = tremolo.subtypeName();
		var tremSubdiv = parseInt(tremDescription.match(/\d+/)[0]);
		var strokesArray = [0,8,16,32,64];
		var numStrokes = strokesArray.indexOf(tremSubdiv);
		var dur = 2 * parseFloat(noteRest.duration.ticks) / division;
		//logError(" TREMOLO HAS "+numStrokes+" strokes); dur is "+dur;
		if (!isSlurred) {
			if (isStringInstrument) addError("Fingered tremolos for strings should always be slurred.",noteRest);
			if (isWindOrBrassInstrument) addError("Two-note tremolos for winds or brass should always be slurred.",noteRest);
			return;
		}
		if (isPitchedPercussionInstrument) {
			addError("It’s best to write "+currentInstrumentName.toLowerCase()+" tremolos as one-note tremolos (through stem),\nrather than two-note tremolos (between notes).",noteRest);
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
		if (gliss.glissType == Glissando.WAVY) {
			if (isStringInstrument) addError ("Strings generally don’t read wavy glissando lines.\nIn Properties→Glissando, change to ‘Straight’.",gliss);
			if (isTrombone) addError ("Trombones can’t perform wavy glissandi.\nIn Properties→Glissando, change to ‘Straight’.",gliss);
		}
		if (gliss.glissType == Glissando.STRAIGHT) {
			var nextNoteRest = getNextNoteRest(noteRest);
			if (nextNoteRest != null) {
				if (nextNoteRest.type == Element.CHORD) {
					var p1 = noteRest.notes[0].pitch;
					var p2 = nextNoteRest.notes[0].pitch;
					var interval = Math.abs (p2 - p1);
					if (isWindInstrument) {
						if (interval > 4) addError ("This gliss. may be too wide to perform smoothly\nand may be better notated as a wavy gliss.\nCheck with a performer", gliss);
					}
					if (isTrombone) {
						if (interval > 6 && interval < 12) addError ("This gliss. is too wide to be a slide gliss\nand too narrow to be a rip.\nPerhaps reconsider or check with a performer.", gliss);
						if (p1 < 54 && p2 < 54) {
							var h1 = Math.floor((p1 - 40) / 6);
							var h2 = Math.floor((p2 - 40) / 6);
							if (h1 != h2) addError ("This gliss. is not possible on the tenor trombone.\nYou might want to reconsider", gliss);
						}
					}
				}
			}
		}
		//logError("CHECKING GLISS — "+gliss.glissShowText+" | "+gliss.glissText+" | "+gliss.glissType+" | "+gliss.glissandoStyle);
		//if (gliss.glissShowText) {
			//addError("Including the word ‘gliss.’ in glissandi is  — switch it off in Properties",gliss);
			//return;
			//}
	}

	//---------------------------------------------------------
	//  addError
	//	pushes the error into an array
	//---------------------------------------------------------
	
	function addError (text,element) {
		if (element == null || element == undefined) {
			logError("addError() — element undefined for text: "+text);
		} else {
			errorStrings.push(text);
			errorObjects.push(element);
		}
	}
	
	//---------------------------------------------------------
	//	showAllErrors
	//	goes through array of errors, setting up comment boxes
	//---------------------------------------------------------
	
	function showAllErrors () {
		var objectPageNum;
		var firstStaffNum = 0;
		for (var k = 0; k < curScore.nstaves; k++) {
			if (curScore.staves[k].part.show) {
				break;
			} else {
				firstStaffNum ++;
			}
		}
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
				var checkObjectPage = false;
				element = objectArray[j];
				var eType = element.type;
				var staffNum = firstStaffNum;
				
				var elementHeight = 0;
				var commentOffset = 1.0;
				var tick = 0, desiredPosX = 0, desiredPosY = 0, commentPage = null;
			
				// the errorObjects array includes a list of the Elements to attach the text object to
				// Instead of an Element, you can use one of the following strings instead to indicate a special location unattached to an element:
				// 		top 			— top of bar 1, staff 1
				// 		pagetop			— top left of page 1
				//		pagetopright	— top right of page 1
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
								staffNum = 0;
								while (!curScore.staves[staffNum].is(elemStaff)) {
									staffNum ++; // I WISH: staffNum = element.staff.staffidx
									if (curScore.staves[staffNum] == null || curScore.staves[staffNum] == undefined) {
										logError ("showAllErrors () — got staff error "+staffNum+" — bailing");
										return;
									}
								}
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

				if (isString) {
					if (theLocation.includes("pagetop")) {
						desiredPosX = 2.5;
						desiredPosY = 10.;
					}
					if (theLocation === "system1" || theLocation === "system2") desiredPosX = 5.0;
					if (theLocation === "system2") tick = firstBarInSecondSystem.firstSegment.tick;
				} else {
					tick = getTick(element);
				}
				if (eType == Element.TEXT) {
					checkObjectPage = true;
					objectPageNum = getPageNumber(element);
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
					var commentWidth = comment.bbox.width;
					var placedX = comment.pagePos.x;				
					if (desiredPosX != 0) comment.offsetX = desiredPosX - comment.pagePos.x;
					if (desiredPosY != 0) {
						comment.offsetY = desiredPosY - comment.pagePos.y;
					} else {
						comment.offsetY -= commentHeight;
					}
					var commentTopRounded = Math.round(comment.pagePos.y);
					var commentPage = comment.parent;
					while (commentPage != null && commentPage.type != Element.PAGE && commentPage.parent != undefined) commentPage = commentPage.parent; // in theory this should get the page
					var commentPageWidth = commentPage.bbox.width; // get page width
					if (commentPage != null && commentPage != undefined) {
						if (commentPage.type == Element.PAGE) {
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
							if (checkObjectPage && commentPageNum != objectPageNum) comment.text = '[The object this comment refers to is on p. '+(objectPageNum+1)+']\n' +comment.text;
							var rhs = comment.pagePos.x + commentWidth;
							if (rhs > commentPageWidth) comment.offsetX -= (rhs - commentPageWidth);
							if (theLocation === "pagetopright") comment.offsetX = commentPageWidth - commentWidth - 2.5 - placedX;
						}
						// check comment box is not covering the element
						/* CAN'T DO JUST YET AS SLUR_SEGMENT.pagePos is returning wrong info
						if (!isString) {
							var r1x = comment.pagePos.x;
							var r1y = comment.pagePos.y;
							var r1w = commentWidth;
							var r1h = commentHeight;
							var r2x = element.pagePos.x;
							var r2y = element.pagePos.y;
							var r2w = element.bbox.width;
							var r2h = element.bbox.height;
							if (element.type == Element.SLUR_SEGMENT) {
								logError ("Found slur — {"+Math.floor(r1x)+" "+Math.floor(r1y)+" "+Math.floor(r1w)+" "+Math.floor(r1h)+"}\n{"+Math.floor(r2x)+" "+Math.floor(r2y)+" "+Math.floor(r2w)+" "+Math.floor(r2h)+"}");
							}
							
							var overlaps = (r1x <= r2x + r2w) && (r1x + r1w >= r2x) && (r1y <= r2y + r2h) && (r1y + r1h >= r2y);
							var repeats = 0;
							while (overlaps && repeats < 20) {
								logError ("Element: "+element.subtypeName()+" repeat "+repeats+": {"+Math.floor(r1x)+" "+Math.floor(r1y)+" "+Math.floor(r1w)+" "+Math.floor(r1h)+"}\n{"+Math.floor(r2x)+" "+Math.floor(r2y)+" "+Math.floor(r2w)+" "+Math.floor(r2h)+"}");
								comment.offsetY -= commentOffset;
								r1y -= 1.0;
								repeats ++;
								overlaps = (r1x <= r2x + r2w) && (r1x + r1w >= r2x) && (r1y <= r2y + r2h) && (r1y + r1h >= r2y);
							}
						}*/
					} else {
						logError ("parent parent parent parent was not a page — element = "+element.name);
					}
					///logError ("Comment is at {"+comment.pagePos.x+" "+comment.pagePos.y+"}");
				}
			}
		} // var i
		curScore.endCmd();
	}
	
	//---------------------------------------------------------
	//	getTick
	//	returns the tick of the element
	//---------------------------------------------------------
	
	function getTick (e) {
		if (e == null) {
			logError ("Tried to get tick of null");
			return 0;
		}
		var tick = 0;
		var eType = e.type;
		var spannerArray = [Element.HAIRPIN, Element.HAIRPIN_SEGMENT, Element.SLUR, Element.SLUR_SEGMENT, Element.PEDAL, Element.PEDAL_SEGMENT, Element.OTTAVA, Element.OTTAVA_SEGMENT, Element.GLISSANDO, Element.GLISSANDO_SEGMENT, Element.GRADUAL_TEMPO_CHANGE];
		if (spannerArray.includes(eType)) {
			tick = e.spannerTick.ticks;
		} else {
			if (eType == Element.MEASURE) {
				tick = e.firstSegment.tick;
			} else {
				if (e.parent == undefined || e.parent == null) {
					logError("showAllErrors() — ELEMENT PARENT IS "+e.parent+"); etype is "+e.name);
				} else {
					var p;
					if (eType == Element.TUPLET) {
						p = e.elements[0].parent;
					} else {
						p = e.parent;
					}
					if (p != null) for (var i = 0; i < 10 && p.type != Element.SEGMENT; i++) {
						if (p.parent == null) {
							logError ("Parent of "+e.name+" was null");
							return 0;
						}
						p = p.parent;
					}
					if (p.type == Element.SEGMENT) tick = p.tick;
				}
			}
		}
		return tick;
	}
	
	function getPageNumber (e) {
		var p = e.parent;
		var ptype = null;
		if (p != null) ptype = p.type;
		while (p && ptype != Element.PAGE) {
			p = p.parent;
			if (p != null) ptype = p.type;
		}
		if (p != null) {
			return p.pagenumber;
		} else {
			return 0;
		}
	}
	
	function selectTitleText () {
		curScore.startCmd();
		cmd("title-text");
		cmd("select-similar");
		curScore.endCmd();
	}
	
	function logError (str) {
		numLogs ++;
		errorMsg += "<p>Staff "+currentStaffNum+", b. "+displayBarNum+": "+str+"</p>";
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
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
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
				for (var i = 0; i < numStaves; i++) {
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
				height: parent.height
				textFormat: Text.RichText
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
