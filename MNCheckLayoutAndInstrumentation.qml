/*
 * Copyright (C) 2025 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.5.1 or later

import MuseScore 3.0
import QtQuick 2.15
import QtQml.Models 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Muse.UiComponents 1.0
import FileIO 3.0

MuseScore {
	version:  "1.0"
	description: "This plugin checks your score for common music layout, notation and instrumentation issues"
    categoryCode: "MN Better Notation Plugins"
	requiresScore: true
	title: "MN Check Layout and Instrumentation"
	id: mnchecklayoutandinstrumentation
	thumbnailName: "MNCheckLayoutAndInstrumentation.png"
	menuPath: "Plugins.MNCheckLayoutAndInstrumentation"
	
	// **** TEXT FILE DEFINITIONS **** //
    // on Linux, slice(8) does not work
    function getAssetPath(filename) {
        if (Qt.platform.os === "linux") {
            return Qt.resolvedUrl("./assets/" + filename).toString();
        } else {
            return Qt.resolvedUrl("./assets/" + filename).toString().slice(8);
        }
    }

    FileIO { id: techniquesfile; source: getAssetPath("techniques.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: canbeabbreviatedfile; source: getAssetPath("canbeabbreviated.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: instrumentrangesfile; source: getAssetPath("instrumentranges.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: metronomemarkingsfile; source: getAssetPath("metronomemarkings.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: shouldbelowercasefile; source: getAssetPath("shouldbelowercase.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: shouldhavefullstopfile; source: getAssetPath("shouldhavefullstop.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: spellingerrorsanywherefile; source: getAssetPath("spellingerrorsanywhere.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: spellingerrorsatstartfile; source: getAssetPath("spellingerrorsatstart.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: tempomarkingsfile; source: getAssetPath("tempomarkings.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: tempochangemarkingsfile; source: getAssetPath("tempochangemarkings.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: versionnumberfile; source: getAssetPath("versionnumber.txt"); onError: function(msg) { console.log("Error:", msg); } }
    FileIO { id: hyphenationfile; source: getAssetPath("EnglishHyphDict.txt"); onError: function(msg) { console.log("Error:", msg); } }
    

	// ** DEBUG **
	property var debug: true
	property var errorMsg: ''
	property var currentZ: 16384
	property var numLogs: 0
	property var versionNumber: ''
	
	// ** OPTIONS **
 	property var doCheckScoreStyle: true
	property var doCheckPartStyle: true
	property var doCheckPageSettings: true
	property var doCheckMusicSpacing: true
	property var doCheckStaffNamesAndOrder: true
	property var doCheckFonts: true
	property var doCheckClefs: true
	property var doCheckTimeSignatures: true
	property var doCheckKeySignatures: true
	property var doCheckOttavas: true
	property var doCheckSlursAndTies: true
	property var doCheckArticulation: true
	property var doCheckArpeggios: true
	property var doCheckExpressiveDetail: true
	property var doCheckTremolosAndFermatas: true
	property var doCheckGraceNotes: true
	property var doCheckStemsAndBeams: true
	property var doCheckDynamics: true
	property var doCheckTempoMarkings: true
	property var doCheckTitleAndSubtitle: true
	property var doCheckSpellingAndFormat: true
	property var doCheckRehearsalMarks: true
	property var doCheckTextPositions: true
	property var doCheckRangeRegister: true
	property var doCheckOrchestralSharedStaves: true
	property var doCheckVoice: true
	property var doCheckWindsAndBrass: true
	property var doCheckPianoHarpAndPercussion: true
	property var doCheckStrings: true
	property var doCheckBarStretches: true
	
	// **** PROPERTIES **** //
 	property var spatium: 0
	property var inchesToMM: 25.4
	property var pageWidth: 0
	property var pageHeight: 0
	property var checkInstrumentClefs: false
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
	property var diatonicPitchOfMiddleLine: 41
	property var initialTempoExists: false
	property var prevKeySigSharps: 0
	property var prevKeySigBarNum: 0
	property var currentBarNum: 0
	property var currentBar: null
	property var displayOffset: 0
	property var hasMoreThanOneSystem: false
	property var scoreIncludesTransposingInstrument: false
	property var beatLength: 0
	property var virtualBeatLength: 0
	property var barStartTick: 0
	property var barEndTick: 0
	property var barLength: 0
	property var currTick: 0
	property var numBars: 0
	property var firstPageHeight: 0
	property var hasFooter: false
	property var hasTitlePage: true
	property var averageOttavaLedgerLines: 0
	property var maxOttavaLedgerLines: 0
	property var numNotesUnderOttava: 0
	property var measureTicks: []
	property var cursor: null
	property var unhyphenatedWords: []
	property var unhyphenatedWordsLower: []
	property var hyphenatedWords: []
	property var isVocalScore: false
	property var isChoirScore: false
	property var frames: []
	property var voicesArray: []
	//property var lyrics: []
		
	// ** FLAGS ** //
 	property var flaggedWeKnowWhosPlaying: false
	property var flaggedDivError: false
	property var flaggedRehearsalMarkError: false
	property var flaggedClefTooLow: false
	property var flaggedClefTooHigh: false
	property var flaggedOttavaTooLow: false
	property var flaggedOttavaTooHigh: false
	property var flaggedStaccatoOnShortDecayInstrumentBarNum: 0
	property var flaggedClefTooLowBarNum: 0
	property var flaggedClefTooHighBarNum: 0
	property var flaggedOttavaTooLowBarNum: 0
	property var flaggedOttavaTooHighBarNum: 0
	property var flaggedFlippedStem: false
	property var flaggedPedalIssue: false
	property var flaggedNoLyrics: false
	property var flaggedWrittenStaccato: false
	property var flaggedFastMultipleStops: false
	property var flaggedOneStrokeTrem: false
	property var flaggedManualSlurBarNum: -1
	property var flaggedBravuraHarmonics: false

 	property var firstVisibleStaff: 0
	property var staffVisible: []
	property var haveHadPlayingIndication: false
	property var flaggedSlurredStaccatoBar: -10
	property var isNote: false
	property var isRest: false
	property var flaggedFlz: false
	property var flaggedPolyphony: false
	property var lastStemDirectionFlagBarNum: -1;
	
	// ** PARTS ** //
 	property var isGrandStaff: []
	property var isTopOfGrandStaff: []
	property var numGrandStaves: []
	property var grandStaffTops: []
	property var numParts: 0
	property var visibleParts: []
	property var numStaves: 0
	property var numTracks: 0
	property var numVoicesInThisBar: 0
	property var numExcerpts: 0
	property var parts: null
	property var scoreHasStrings: false
	property var scoreHasWinds: false
	property var scoreHasBrass: false
	property var mmrNumber: 0
	property var mmrs: []
	property var hasMMRs: false;
	property var firstMMRSystem: null
	property var lastMMRSystem: null
	
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
	
	// ** VARIOUS FLAGS AND NOTES ** //
 	property var lastTempoChangeMarkingBar: -1
	property var tempoChangeMarkingEnd: -1
	property var lastTempoChangeMarking: null
	property var lastTempoChangeMarkingText: ''
	property var lastTempoMarking: null
	property var lastTempoMarkingBar: -1
	property var barContainsTempo: false
	property var barContainsMetronome: false
	property var lastArticulationTick: -1
	property var lastDynamicTick: -1
	property var lastMetronomeMarking: null
	property var lastMetronomeMarkingBar: -1
	property var lastMetronomeMarkingDisplayBar: -1
	property var lastMetronomeComponent: ''
	property var numConsecutiveMusicBars: 0
	property var currentStaffNum: 0
	property var currentStaff: null;
	property var currentTrack: 0
	property var currentTimeSig: null
	property var firstRehearsalMarkStaffNum: 0
	property var isFirstNote: false
	property var isCompound: false
	property var currentClef: null
	property var currentClefNum: 0
	property var currentClefBarNum: 0
	property var currentClefTick: 0
	property var isMidBarClef: false
	property var isEndOfBarClef: false
	property var firstNoteSinceClefChange: false
	property var numClefs: 0
	property var prevClefType: -1
	property var prevDynamic: ""
	property var prevDynamicObject: null
	property var prevDynamicBarNum: 0
	property var prevDynamicDisplayBarNum: 0
	property var prevIsMultipleStop: false
	property var prevSoundingDur: 0
	property var prevMultipleStopInterval: 0
	property var prevMultipleStop: null
	property var theDynamic: null
	property var errorStrings: []
	property var errorObjects: []
	property var prevBeam: null
	property var wasHarmonic: false
	property var isArco: false
	property var trillStartTick: 0
	
	// ** INSTRUMENTS ** //
	property var currentInstrumentName: ""
	property var currentInstrumentId: ""
	property var currentInstrumentNum: 0
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
	property var isShortDecayInstrument: false
	property var isLongDecayInstrument: false
	property var isDecayInstrument: false
	property var isKeyboardInstrument: false
	property var isPedalInstrument: false
	property var isPiano: false
	property var isVibraphone: false
	property var isMarimba: false
	property var isVoice: false
	property var isGuitar: false
	property var isSoloScore: false
	property var currentMute: ""
	property var currentPlayingTechnique: ""
	property var currentContactPoint: ""
	property var currentVibrato: ""
	property var maxLedgerLines: []
	property var minLedgerLines: []
	property var maxLLSinceLastRest: 0
	property var fullInstNamesShowing: false
	property var shortInstNamesShowing: false
	property var firstBarInScore: null
	property var lastBarInScore: null
	property var firstBarInSecondSystem: null
	property var endOfScoreTick: 0
	property var firstPageOfMusic: null
	property var firstPageOfMusicNum: 0
	property var lastPageOfMusicNum: 0
	property var numPagesOfMusic: 0
	property var systemStartBars: []
	property var tempoText: []
	property var lowestPitchPossible: 0
	property var highestPitchPossible: 0
	property var quietRegisterThresholdPitch: 0
	property var highLoudRegisterThresholdPitch: 0
	property var lowLoudRegisterThresholdPitch: 0
	property var lastDynamicFlagBar: -1
	property var stringsArray: []
	property var stringNames: []
	property var flzFound: false
	
	// ** DYNAMICS ** //
	property var dynamics: []
	property var dynamicTicks: []
	property var currDynamicLevel: 0
	property var expressiveSwell: 0
	property var currentDynamic: null
	property var currentDynamicNum: -1
	property var nextDynamic: null
	property var nextDynamicTick: 0
	property var numDynamics: 0
	property var isSforzando: false
	
	// ** CLEFS ** //
	property var clefs: []
	property var nextClefTick: 0
	property var prevClefNumInBar: 0
		
	// ** FERMATAS ** //
	property var fermatas: []
	property var isFermata: false
	
	// ** HAIRPINS ** //
	property var hairpins: []
	property var isHairpin: false
	property var currentHairpin: null
	property var currentHairpinEnd: 0
	property var currentHairpinNum: 0
	property var numHairpins: 0
	property var nextHairpinStart: -1
	property var nextHairpin: null
	
	// ** TRILLS ** //
	property var trills: []
	property var isTrill: false
	property var currentTrill: null
	property var currentTrillEnd: 0
	property var currentTrillNum: 0
	property var numTrills: 0
	property var nextTrillStart: -1
	property var nextTrill: null
	property var nextTrillDur: 0

	// ** PEDALS ** //
	property var pedals: []
	property var isPedalled: false
	property var currentPedal: null
	property var prevPedal: null
	property var prevPedalEnd: -1
	property var currentPedalNum: 0
	property var numPedals: 0
	property var nextPedalStart: -1
	property var currentPedalEnd: -1
	property var flaggedPedalLocation: false
	property var isFirstPedal: false
	property var pedalStaffNum: 0
	
	// ** LV ** //
	property var isLv: false
	
	// ** SLURS ** //
	property var slurs:[]
	property var isSlurred: false
	property var isStartOfSlur: false
	property var isEndOfSlur: false
	property var flaggedSlurredRest: false
	property var prevSlurNum: 0
	property var prevSlurNumOnTrack: []
	property var prevWasStartOfSlur: false
	property var currentSlurNumOnTrack: []
	property var nextSlurStartOnTrack: []
	property var currentSlur: null
	property var currentSlurLength: -1
	property var currentSlurStart: -1
	property var currentSlurEnd: -1
	property var numSlurs: 0
	property var prevSlurEnd: -1	
	
	// ** OTTAVAS ** //
	property var ottavas: []
	property var isOttava: false
	property var currentOttava: null
	property var flaggedOttavaIssue: false
	property var currentOttavaNum: 0
	property var numOttavas: 0
	property var nextOttavaStart: -1
	property var currentOttavaEnd: -1
	
	// ** TREMOLOS ** //
	property var instrumentChanges: []
	property var hasInstrumentChanges: false
	property var numInstrumentChanges: 0
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
	
	// ** ARTICULATIONS ** //
	// for the most part (except tenutos — WHY???), the ‘below’ versions of the symbols are just +1
	// these ids come from WHERE?
	
	property var prevNote: null
	property var prevNotes: []
	property var selectionArray: []
	property var isTremolo: false
	property var prevWasGraceNote: false
	property var firstDynamic: false
	property var progressShowing: false
	property var progressStartTime: 0
	property var articulations: []
	property var staccatoArray: []
	property var stringArticulationsArray: []
	property var accentsArray: []
	property var iterationArticulationArray: []
		
	// ** HARP ** //
 	property var pedalSettings: [-1,-1,-1,-1,-1,-1,-1]
	property var pedalSettingLastNeededTick: [-1,-1,-1,-1,-1,-1,-1]
	property var pedalChangesInThisBar: 0
	property var flaggedPedalChangesInThisBar: false
	property var cmdKey: 'command'
	
	// ** VOICE ** //
	property var isMelisma: []
	property var melismaEndTick: []
	
	// ** FONTS ** //
	property var tempoFontStyle: 0
	property var metronomeFontStyle: 0
	
	// ** LYRICS ** //
	property var currentWord: ''
	property var currentWordArray: []
	
	
  onRun: {
		if (!curScore) return;
		
		//setProgress (0);
			
		// **** READ IN TEXT FILES **** //
		loadTextFiles();
		
		// ** SET DIALOG HEADER ** //
		dialog.titleText = 'MN CHECK LAYOUT AND INSTRUMENTATION '+versionNumber;
		
		// **** VERSION CHECK **** //
		var version461 = mscoreMajorVersion > 4 || (mscoreMajorVersion == 4 && mscoreMinorVersion > 6) || (mscoreMajorVersion == 4 && mscoreMinorVersion == 6 && mscoreUpdateVersion >= 1);
		if (!version461) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin requires MuseScore v. 4.6.1 or later.</p> ";
			dialog.show();
			return;
		}
		
		// **** INITIALISE MAIN VARIABLES **** //
		var staves = curScore.staves;
		numStaves = curScore.nstaves;
		numTracks = numStaves * 4;
		firstBarInScore = curScore.firstMeasure;
		//logError ('bar name = '+firstBarInScore.userName());
		lastBarInScore = curScore.lastMeasure;
		endOfScoreTick = curScore.lastSegment.tick+1;
		
		spatium = curScore.style.value("spatium")*inchesToMM/mscoreDPI; // NB spatium value is given in MuseScore's DPI setting
		pageWidth = Math.round(curScore.style.value("pageWidth")*inchesToMM);
		pageHeight = Math.round(curScore.style.value("pageHeight")*inchesToMM);

		if (curScore.lastSegment.pagePos.x > pageWidth + 100) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin works best if the score is viewed in Page View.</p><p>Change ‘Continuous View’ to ‘Page View’ from the pop-up menu in the bottom-right of the window.</p>";
			dialog.show();
			return;
		}
		
		// ***********		SET UP THE ARTICULATION SYMBOLS ARRAYS		********** //
		setupArticulationSymbolsArrays();
		
		// ************  	SHOW THE OPTIONS WINDOW 	************ //
		options.open();
		
		
	}
	
	function setupArticulationSymbolsArrays () {	
	
		staccatoArray = [SymId.articAccentStaccatoAbove, SymId.articAccentStaccatoBelow,
			SymId.articSoftAccentStaccatoAbove, SymId.articSoftAccentStaccatoBelow,
			SymId.articStaccatissimoAbove, SymId.articStaccatissimoBelow,
			SymId.articStaccatissimoStrokeAbove, SymId.articStaccatissimoStrokeBelow,
			SymId.articStaccatissimoWedgeAbove, SymId.articStaccatissimoWedgeBelow,
			SymId.articStaccatoAbove, SymId.articStaccatoBelow,
			SymId.articTenutoStaccatoAbove, SymId.articTenutoStaccatoBelow,
			SymId.articMarcatoStaccatoAbove, SymId.articMarcatoStaccatoBelow,
			SymId.articSoftAccentTenutoStaccatoAbove, SymId.articSoftAccentTenutoStaccatoBelow];
				
		stringArticulationsArray = [SymId.stringsDownBow, SymId.stringsDownBowAwayFromBody, SymId.stringsDownBowBeyondBridge,
			SymId.stringsDownBowTowardsBody, SymId.stringsDownBowTurned,
			SymId.stringsUpBow, SymId.stringsUpBowAwayFromBody, SymId.stringsUpBowBeyondBridge,
			SymId.stringsUpBowTowardsBody, SymId.stringsUpBowTurned ];
					
		accentsArray = [SymId.articAccentAbove, SymId.articAccentBelow,
			SymId.articAccentStaccatoAbove,	SymId.articAccentStaccatoBelow,
			SymId.articMarcatoAbove, SymId.articMarcatoBelow,
			SymId.articMarcatoStaccatoAbove, SymId.articMarcatoStaccatoBelow,
			SymId.articMarcatoTenutoAbove, SymId.articMarcatoTenutoBelow,
			SymId.articSoftAccentAbove,	SymId.articSoftAccentBelow,
			SymId.articSoftAccentStaccatoAbove,	SymId.articSoftAccentStaccatoBelow,
			SymId.articSoftAccentTenutoAbove, SymId.articSoftAccentTenutoBelow,
			SymId.articSoftAccentTenutoStaccatoAbove, SymId.articSoftAccentTenutoStaccatoBelow];
					
		iterationArticulationArray = [SymId.articTenutoAbove, SymId.articTenutoBelow,
			SymId.articTenutoAccentAbove, SymId.articTenutoAccentBelow,
			SymId.articMarcatoTenutoAbove, SymId.articMarcatoTenutoBelow,
			SymId.articTenutoStaccatoAbove, SymId.articTenutoStaccatoBelow,
			SymId.articStaccatissimoAbove, SymId.articStaccatissimoBelow,
			SymId.articStaccatissimoStrokeAbove, SymId.articStaccatissimoStrokeBelow,
			SymId.articStaccatissimoWedgeAbove, SymId.articStaccatissimoWedgeBelow,
			SymId.articStaccatoAbove, SymId.articStaccatoBelow];
		
	}
	
	function checkScore() {
		
		if (options.numOptionsChecked == 0) {
			options.close();
			dialog.msg = "<p><font size=\"6\">🛑</font> No options were selected.</p> ";
			dialog.show();
			return;
		}
				
		// ************  	INITIALISE LOCAL VARIABLES 	************ //
		var prevBarNum = 0, numBarsProcessed = 0;
		var isTied = false;
		cursor = curScore.newCursor();
		var prevTick = [];
		
		// ************  	GET USER-SELECT OPTIONS 	************ //
		doCheckScoreStyle = options.scoreStyle;
		doCheckPartStyle = options.partStyle;
		doCheckPageSettings = options.pageSettings;
		doCheckMusicSpacing = options.musicSpacing;
		doCheckStaffNamesAndOrder = options.staffNamesAndOrder;
		doCheckFonts = options.fonts;
		doCheckClefs = options.clefs;
		doCheckTimeSignatures = options.timeSignatures;
		doCheckKeySignatures = options.keySignatures;
		doCheckOttavas = options.ottavas;
		doCheckSlursAndTies = options.slursAndTies;
		doCheckStemsAndBeams = options.stemsAndBeams;
		doCheckArticulation = options.articulation;
		doCheckArpeggios = options.arpeggios;
		doCheckTremolosAndFermatas = options.tremolosAndFermatas;
		doCheckExpressiveDetail = options.expressiveDetail;
		doCheckDynamics = options.dynamics;
		doCheckTempoMarkings = options.tempoMarkings;
		doCheckTitleAndSubtitle = options.titleAndSubtitle;
		doCheckSpellingAndFormat = options.spellingAndFormat;
		doCheckRehearsalMarks = options.rehearsalMarks;
		doCheckTextPositions = options.textPositions;
		doCheckRangeRegister = options.rangeRegister;
		doCheckOrchestralSharedStaves = options.orchestralSharedStaves;
		doCheckVoice = options.voice;
		doCheckWindsAndBrass = options.windsAndBrass;
		doCheckPianoHarpAndPercussion = options.pianoHarpAndPercussion;
		doCheckStrings = options.strings;
		doCheckBarStretches = options.barStretches;
		
		// ************  	CLOSE THE OPTIONS WINDOW 	************ //	
		options.close();
				
		// ************  	CALCULATE NUMBER OF PARTS 	************ //	
		parts = curScore.parts;
		numParts = 0;
		for (var i = 0; i < parts.length; i++) if (parts[i].show) visibleParts.push(parts[i]);
		numParts = visibleParts.length;
		isSoloScore = (numParts == 1);
		if (Qt.platform.os !== "osx") {
			cmdKey = "ctrl";
			dialog.fontSize = 12;
		}
		numExcerpts = curScore.excerpts.length;
		if (doCheckPartStyle && numParts > 1 && numExcerpts < numParts && !isChoirScore) addError ("Parts have not yet been created/opened, so I wasn’t able to check the part settings.\nYou can do this by clicking ‘Parts’ then ’Open All’.\n\nOnce you have created and opened the parts, please run this again to check the parts.\nIgnore this message if you do not plan to create parts.","pagetopright");
		
		// **** INITIALISE ALL ARRAYS **** //
		
		// THESE ITEMS ARE NOT ATTACHED TO SPECIFIC NOTEHEADS OR TRACKS
		for (var i = 0; i<numStaves; i++) {
			pedals[i] = [];
			hairpins[i] = [];
			trills[i] = [];
			instrumentChanges[i] = [];
			ottavas[i] = [];
			dynamics[i] = [];
			dynamicTicks[i] = [];
			clefs[i] = [];
			fermatas[i] = [];
		}
		
		// initialise voicesArray
		for (var i = 0; i <= curScore.nmeasures; i++) {
			voicesArray[i] = [];
			for (var j = 0; j < numStaves; j++) {
				voicesArray[i][j] = [];
				for (var k = 0; k < 4; k++) {
					voicesArray[i][j][k] = 0;
				}
			}
		}
		
		// THESE ITEMS CAN APPLY TO SPECIFIC TRACKS OR NOTEHEADS
		for (var i = 0; i < numTracks; i++) {
			slurs[i] = [];
			currentSlurNumOnTrack[i] = -1;
			prevSlurNumOnTrack[i] = -1;
			nextSlurStartOnTrack[i] = -1;
			isMelisma[i] = false;
			glisses[i] = [];
			melismaEndTick[i] = 0;
			prevTick[i] = -1;
		}
				
		// ************  		DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS 		************ //
		getFrames();
		deleteAllCommentsAndHighlights();
				
		// ************  				SELECT AND PRE-PROCESS ENTIRE SCORE			************ //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();

		setProgress (1);
		
		// ************  	GO THROUGH ALL INSTRUMENTS & STAVES LOOKING FOR INFO 	************ //
		// ************		WE DO THIS FIRST, BECAUSE IT MARKS WHICH STAVES ARE VISIBLE ********* //
		analyseInstrumentsAndStaves();
		
		// ************  	GO THROUGH THE SCORE LOOKING FOR ANY SPANNERS (HAIRPINS, TRILLS, SLURS, OTTAVAS, ETC) 	************ //
		analyseSystemsAndSpanners();
		setProgress (2);
		
		// ************  	CHECK SPACING BETWEEN SYSTEMS 	************ //
		checkSystemSpacing();
		
		// ************  	SET UP VARIABLES THAT DEAL WITH PAGES AND SYSTEMS 	************ //
		var firstSystem = firstBarInScore.parent;
		var lastSystem = lastBarInScore.parent;
		if (firstSystem == null) {
			firstSystem = firstMMRSystem;
			if (firstSystem == null) logError ('first system is null!');
		}
		if (lastSystem == null) {
			lastSystem = lastMMRSystem;
			if (lastSystem == null) logError ('last system is null!');
		}
		hasMoreThanOneSystem = !lastSystem.is(firstSystem);
		firstPageOfMusic = firstSystem.parent;
		var lastPageOfMusic = lastSystem.parent;
		firstPageOfMusicNum = firstPageOfMusic.pagenumber;
		lastPageOfMusicNum = lastPageOfMusic.pagenumber;
		numPagesOfMusic = lastPageOfMusicNum - firstPageOfMusicNum + 1;
		hasTitlePage = lastPageOfMusicNum > 1 && firstPageOfMusicNum > 0;
		firstPageHeight = firstPageOfMusic.bbox.height;
		currentBar = firstBarInScore;
		while (currentBar) {
			measureTicks.push(currentBar.firstSegment.tick);
			currentBar = currentBar.nextMeasure;
		}
		
		// ************					CHECK REHEARSAL MARKS						************ //
		// NB: do this before checking the score settings
		if (doCheckRehearsalMarks && numBars > 30 && numStaves > 3 && !isSoloScore) checkRehearsalMarks();

		// ************  				CHECK SCORE & PAGE SETTINGS 				************ // 
		checkScoreAndPageSettings();
				
		// ************					CHECK IF SCORE IS TRANSPOSED				************ //
		if (curScore.style.value("concertPitch") && scoreIncludesTransposingInstrument) addError ("It looks like you have at least one transposing instrument, but the score is currently displayed in concert pitch.\nUntick ‘Concert Pitch’ in the bottom right to display a transposed score (see ‘Behind Bars’, p. 505)","pagetop");
		
		// ************  					CHECK TITLE PAGE EXISTS 				************ // 
		if (doCheckTitleAndSubtitle && !hasTitlePage && numPagesOfMusic > 1) addError ("This score is longer than 2 pages, but doesn’t appear to have a title page.\n(Ignore this if you are planning to add a title page to the score in another app.)","pagetop");
		
		// ************  				CHECK TITLE TEXT AND STAFF TEXT OBJECTS FOR ERRORS 					************ //
		if (doCheckTitleAndSubtitle) checkScoreText();
		
		// ************ 								CHECK TIME SIGNATURES								************ //
		if (doCheckTimeSignatures) checkTimeSignatures();
		
		// ************ 							CHECK FOR STAFF ORDER ISSUES 							************ //
		if (doCheckStaffNamesAndOrder) checkStaffOrderAndBrackets();
		
		// ************  					CHECK PART SETTINGS 					************ // 
		// NB do AFTER checkStaffOrderAndBrackets
		if (doCheckPartStyle && numParts > 1 && numExcerpts >= numParts) checkPartSettings();
		
		// ************  							CHECK STAFF NAMES ISSUES 								************ // 
		if (doCheckStaffNamesAndOrder) checkStaffNames();
		
		// ************  							CHECK LOCATION OF FINAL BAR								************ // 
		checkLocationOfFinalBar();
		
		// ************  					CHECK LOCATIONS OF BOTTOM SYSTEMS ON EACH PAGE 					************ // 
		if (numPagesOfMusic > 1) checkLocationsOfBottomSystems();
		
		// ************ 								CHECK FOR FERMATA ISSUES 							************ ///
		if (!isSoloScore && numStaves > 2) checkFermatas();
		
		setProgress (3);
		
		// ************ 			PREP FOR A FULL LOOP THROUGH THE SCORE 				************ //
		
		var firstClefNumInBar;
		var numSystems, currentSystem, currentSystemNum, numNoteRestsInThisSystem, numBeatsInThisSystem, noteCountInSystem, beatCountInSystem;
		var maxNoteCountPerSystem, minNoteCountPerSystem, maxBeatsPerSystem, minBeatsPerSystem, actualStaffSize;
		var isSharedStaff;
		var loop = 0;
		
		firstBarInScore = curScore.firstMeasure;		
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
		minBeatsPerSystem = (15.0 - actualStaffSize); // Be a little more lenient here — 8 beats at 7mm
		
		setProgress (4);
		
		var totalNumLoops = numStaves * numBars * 4;
		
		//MARK: currentStaffNum loop
		// ************ 					START LOOP THROUGH WHOLE SCORE 						************ //
		for (currentStaffNum = 0; currentStaffNum < numStaves; currentStaffNum ++) {
			
			currentStaff = curScore.staves[currentStaffNum];
			currentBar = firstBarInScore;
			currentBarNum = 1;
			currentSystemNum = 0;
			displayOffset = 0;

			//don't process if this part is hidden
			if (!staffVisible[currentStaffNum]) {
				loop += numBars * 4;
				continue;
			}
			
			// INITIALISE VARIABLES BACK TO DEFAULTS A PER-STAFF BASIS
			prevKeySigSharps = -99; // placeholder/dummy variable
			prevKeySigBarNum = 0;
			prevBarNum = 0;
			prevDynamic = "";
			prevDynamicObject = null;
			prevDynamicBarNum = 0;
			prevDynamicDisplayBarNum = 0;
			prevClefType = -1;
			prevMultipleStop = null;
			prevIsMultipleStop = false;
			prevMultipleStopInterval = 0;
			prevBeam = null;
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
			wasHarmonic = false;
			isArco = false;
			currentWord = '';
			currentWordArray = [];
			
			lastMetronomeComponent = '';
			lastMetronomeMarking = null;
			lastMetronomeMarkingBar = -1;
			lastMetronomeMarkingDisplayBar = -1;

			lastTempoChangeMarkingBar = -1;
			lastTempoChangeMarking = null;
			lastTempoChangeMarkingText = '';
			tempoChangeMarkingEnd = -1;
			
			lastTempoMarking = null;
			lastTempoMarkingBar = -1;
			
			lastArticulationTick = -1;
			lastDynamicTick = -1;
			numConsecutiveMusicBars = 0;
			lastDynamicFlagBar = -1;
			currentDynamicNum = -1;
			currentDynamic = null;
			nextDynamicTick = -1;
			numDynamics = dynamics[currentStaffNum].length;
			if (numDynamics == 0) {
				// no dynamics marked!
				nextDynamic = null;
				nextDynamicTick = endOfScoreTick;
			} else {
				getNextDynamic();				
				if (nextDynamicTick == 0) {
					currentDynamic = nextDynamic;
					currentDynamicNum ++;
					checkTextObject(currentDynamic);
					getNextDynamic();
				}
			}
					
			pedalSettings = [-1,-1,-1,-1,-1,-1,-1];
			pedalSettingLastNeededTick = [-1,-1,-1,-1,-1,-1,-1];
			numInstrumentChanges = instrumentChanges[currentStaffNum].length;
			currentInstrumentNum = 0;
			numNotesUnderOttava = 0;
			averageOttavaLedgerLines = 0;
			maxOttavaLedgerLines = 0;
			
			// ** clear flags ** //
			flaggedClefTooLow = false;
			flaggedClefTooHigh = false;
			flaggedOttavaTooLow = false;
			flaggedOttavaTooHigh = false;
			flaggedClefTooLowBarNum = 0;
			flaggedClefTooHighBarNum = 0;
			flaggedOttavaTooLowBarNum = 0;
			flaggedOttavaTooHighBarNum = 0;
			flaggedStaccatoOnShortDecayInstrumentBarNum = 0;
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
			flaggedManualSlurBarNum = -1;
			haveHadPlayingIndication = false;
			flaggedSlurredStaccatoBar = -10;
			flzFound = false;
			flaggedFlz = false;
			flaggedPolyphony = false;
			lastStemDirectionFlagBarNum = -1;
			
			// ** pedals
			currentPedal = null;
			prevPedal = null;
			isPedalled = false;	
			currentPedalNum = 0;
			currentPedalEnd = -1;
			prevPedalEnd = -1;
			pedalStaffNum = currentStaffNum;
			// for grand staff instruments, pedals are attached to the top staff
			// if this is a grand staff stave, but not the top one, then go upwards until we find the top one
			while (isGrandStaff[pedalStaffNum] && !isTopOfGrandStaff[pedalStaffNum] && pedalStaffNum >= 0) pedalStaffNum --;
			numPedals = pedals[pedalStaffNum].length;
			nextPedalStart = (numPedals == 0) ? 0 : pedals[pedalStaffNum][0].spanner.spannerTick.ticks;
			
			// ** hairpins
			currentHairpin = null;
			isHairpin = false;
			currentHairpinNum = 0;
			currentHairpinEnd = 0;
			numHairpins = hairpins[currentStaffNum].length;
			nextHairpin = (numHairpins == 0) ? null : hairpins[currentStaffNum][0];
			nextHairpinStart = (numHairpins == 0) ? 0 : nextHairpin.spanner.spannerTick.ticks;
			expressiveSwell = 0;
			
			// ** trills
			currentTrill = null;
			isTrill = false;
			currentTrillNum = 0;
			currentTrillEnd = 0;
			numTrills = trills[currentStaffNum].length;
			nextTrill = (numTrills == 0) ? null : trills[currentStaffNum][0];
			nextTrillStart = (numTrills == 0) ? 0 : nextTrill.spanner.spannerTick.ticks;
			
			// ** ottavas
			currentOttava = null;
			isOttava = false;
			currentOttavaNum = 0;
			currentOttavaEnd = 0;
			numOttavas = ottavas[currentStaffNum].length;
			nextOttavaStart = (numOttavas == 0) ? 0 : ottavas[currentStaffNum][0].spanner.spannerTick.ticks;
			
			// **** GET INSTRUMENT ID & NAME OF THIS STAFF **** //
			currentInstrumentId = currentStaff.part.musicXmlId;
			currentInstrumentName = currentStaff.part.longName;
			// sometimes the instrument id is vague ('strings.group'), so we need to do a bit more detective work and calculate what the actual instrument is — this routine does that
			calculateCalcId();
			// set any specific variables for the current instrument
			setInstrumentVariables();
			
			// ** clefs
			numClefs = clefs[currentStaffNum].length;
			currentClefNum = 0;
			prevClefType = -1;
			currentClef = clefs[currentStaffNum][0];
			currentClefTick = 0;
			currentClefBarNum = 1;
			firstNoteSinceClefChange = false;
			
			// **** GET THE STARTING CLEF OF THIS INSTRUMENT **** //
			// NB: call checkClef AFTER the currentInstrumentName/Id setup and AFTER set InstrumentVariables
			if (currentClef != null) {
				checkClef(currentClef);
				prevClefNumInBar = 0;
				nextClefTick = (numClefs > 1) ? clefs[currentStaffNum][1].parent.tick : endOfScoreTick;
			} else {
				logError ('checkScore() — couldn’t find currentClef');
			}
						
			// **** CHECK FOR VIBRAPHONE BEING NOTATED ON A GRAND STAFF **** //
			if (doCheckPianoHarpAndPercussion && isVibraphone && isTopOfGrandStaff[currentStaffNum]) addError('Vibraphones are normally notated on a single treble staff,\nrather than a grand staff.','system1 '+currentStaffNum);
			
			// **** MAIN MEASURE LOOP HERE **** //
			for (currentBarNum = 1; currentBarNum <= numBars && currentBar; currentBarNum ++) {
				if (currentStaffNum == 0) {
					if (currentBarNum > 1 && currentBarNum < 4) {
						if (barContainsMetronome && !barContainsTempo && lastTempoMarking != null) {
							addError ("For original compositions, it’s good to add a tempo phrase or mood descriptor\nin addition to the metronome marking at the start of a work.",lastTempoMarking);
						}
					} 
				}
				
				//logError ('barloop '+currentBarNum);
				if (currentBar.irregular) displayOffset ++;
				barStartTick = currentBar.firstSegment.tick;
				barEndTick = currentBar.lastSegment.tick;
				barLength = barEndTick - barStartTick;
				
				// reset clef from the previous bar
				firstClefNumInBar = prevClefNumInBar; // we need to do this to keep track of clefs; in future we can replace this with clefAtTick()
				currentClefNum = firstClefNumInBar;
				if (currentClefNum >= clefs[currentStaffNum].length) {
					logError ('currentClefNum >= numClefs');
				} else {
					currentClef = clefs[currentStaffNum][currentClefNum];
				}
				var firstClefTypeInBar = currentClef.transposingClefType;
				prevClefType = firstClefTypeInBar;
				var startTrack = currentStaffNum * 4;
				var firstNoteInThisBar = null;
				var stretch = currentBar.userStretch;
				
				// **** GET CURRENT TIME SIGNATURE OF THIS BAR	**** //
				// **** AND CALCULATE THE BEAT LENGTH			**** //
				currentTimeSig = currentBar.timesigNominal;
				var timeSigNum = currentTimeSig.numerator;
				var timeSigDenom = currentTimeSig.denominator;
				beatLength = division;
				isCompound = !(timeSigNum % 3);
				if (timeSigDenom <= 4) isCompound = isCompound && (timeSigNum > 3);
				// if 6/8, 12/8, etc., beatLength = dotted whatever
				if (isCompound && timeSigDenom >= 8) beatLength = (division * 1.5) * (8 / timeSigDenom);
				if (timeSigDenom == 4) {
					virtualBeatLength = division;
				} else {
					virtualBeatLength = division * (isCompound ? 12 : 4) / timeSigDenom;
				}
				if (currentStaffNum == 0) {
					var numTicks = currentBar.lastSegment.tick - currentBar.firstSegment.tick;
					var numBeats = numTicks / beatLength;
					//logError ('This bar is '+numBeats+' long, because numTicks = '+numTicks+' and beatLength = '+beatLength);
					numBeatsInThisSystem += numBeats;
					
					// **** CHECK FOR NON-STANDARD STRETCH FACTOR **** //
					var isMMR = mmrs[currentBarNum] != null;
					if (stretch != 1 && doCheckBarStretches && !isMMR) {
						addError("The stretch for this bar is set to "+stretch+";\nits spacing may not be consistent with other bars.\nYou can reset it by choosing Format→Stretch→Reset Layout Stretch.",currentBar);
					}
				}
				
				// ********* COUNT HOW MANY VOICES THERE ARE IN THIS BAR ********* //
				numVoicesInThisBar = voicesArray[currentBarNum-1][currentStaffNum][0] + voicesArray[currentBarNum-1][currentStaffNum][1] + voicesArray[currentBarNum-1][currentStaffNum][2] + voicesArray[currentBarNum-1][currentStaffNum][3];
				
				// ********** TO DO — MAYBE DON'T NEED TO DO THIS? ******** //				
				var tempSystem = currentBar.parent;
				if (tempSystem == null) {
					currentSystem = null;
				} else {
					if (!tempSystem.is(currentSystem)) {
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
				}
				var numTracksWithNotes = 0;
				var numTracksWithNoteRests = 0;
				var isChord = false;
				pedalChangesInThisBar = 0;
				flaggedPedalChangesInThisBar = false;
				if (currentBarNum % 2) flaggedFastMultipleStops = false;	
			
				// ************ CHECK HARP ISSUES ************ //
				if (isHarp && (isTopOfGrandStaff[currentStaffNum] || !isGrandStaff[currentStaffNum])) checkHarpIssues();
				
				// ************ CHECK UNTERMINATED TEMPO CHANGE (e.g. rit/accel without a final tempo marking) ************ //
				if (doCheckTempoMarkings) {
					
					// ************ CHECK TEMPO MARKING WITHOUT A METRONOME ************ //
					if (lastTempoMarkingBar != -1 && currentBarNum == lastTempoMarkingBar + 2 && lastMetronomeMarkingBar < lastTempoMarkingBar) {
						//logError("lastTempoMarkingBar = "+lastTempoMarkingBar+" lastMetronomeMarkingBar = "+lastMetronomeMarkingBar);
						addError("This tempo marking doesn’t seem to have a metronome marking.\nIt can be helpful to indicate the specific metronome marking or provide a range.",lastTempoMarking);
					}
				}
				
				// ** clef
				if (firstClefNumInBar != currentClefNum) {
					currentClefNum = firstClefNumInBar;
					currentClef = clefs[currentStaffNum][currentClefNum];
					setClef(currentClef);
					nextClefTick = (currentClefNum < numClefs - 1) ? clefs[currentStaffNum][currentClefNum+1].parent.tick : endOfScoreTick;
					prevClefType = firstClefTypeInBar;
				}
				
				// ****  MAIN TRACK LOOP HERE  **** //
				for (currentTrack = startTrack; currentTrack < startTrack + 4; currentTrack ++) {
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
					
					// ** slurs
					currentSlur = null;
					currentSlurLength = -1;
					currentSlurStart = -1;
					currentSlurEnd = -1;
					isSlurred = false;	
					isStartOfSlur = false;	
					isEndOfSlur = false;	
					
					// ** load in the current slur settings from this track
					numSlurs = slurs[currentTrack].length;
					if (currentSlurNumOnTrack[currentTrack] > -1 && currentSlurNumOnTrack[currentTrack] < numSlurs) {
						currentSlur = slurs[currentTrack][currentSlurNumOnTrack[currentTrack]];
						currentSlurStart = currentSlur.spanner.spannerTick.ticks;
						currentSlurLength = currentSlur.spanner.spannerTicks.ticks;
						currentSlurEnd = currentSlurStart + currentSlurLength;
						isSlurred = (barStartTick >= currentSlurStart && barStartTick <= currentSlurEnd);
						isStartOfSlur = (barStartTick == currentSlurStart);
						isEndOfSlur = (barStartTick == currentSlurEnd);
					}
															
					while (processingThisBar) {
						isNote = false;
						isRest = false;
						isSforzando = false;
						var currSeg = cursor.segment;
						currTick = currSeg.tick;

						// ************ CHECK TEMPO & TEMPO CHANGE TEXT FOR THIS SEGMENT *********** //
						if (tempoText.length > 0) {
							var t = tempoText[0];
							while (checkTempoObjectNow(t) && tempoText.length > 0) {
								//logError ('Checking tempo marking '+t.text);
								checkTextObject(t);
								tempoText.shift();
								if (tempoText.length > 0) t = tempoText[0];
							}
						}

						if (currTick != barEndTick) {
							
							// ** CHECK IF MELISMA IS STILL GOING ** //
							if (isMelisma[currentTrack] && melismaEndTick[currentTrack] > 0) isMelisma[currentTrack] = currTick <= melismaEndTick[currentTrack];
							var annotations = currSeg.annotations;
							var elem = cursor.element;
							var eType = elem.type;
													
							// ************ CHECK IF IT'S A NOTE OR REST FIRST ************ //
							isNote = eType == Element.CHORD;
							isRest = eType == Element.REST;
							
							// ************ CHECK IF THERE’S A FERMATA ************ //
							if (isNote || isRest) checkFermata (elem);
							
							// ************ IS LV? ************ //
							isLv = false;
							if (isNote) {
								var theTie = elem.notes[0].tieForward;
								if (theTie != null) isLv = theTie.type == Element.LAISSEZ_VIB;
							}
							
							// ************ CHECK KEY SIGNATURE ************ //
							if (eType == Element.KEYSIG && currentStaffNum == 0) checkKeySignature(elem,cursor.keySignature);
							
							// ************ CHECK SPANNERS & DYNAMICS ETC. ************ //
							checkScoreElements(elem);
							
							// ************ LOOP THROUGH ANNOTATIONS IN THIS SEGMENT ************ //
							if (annotations && annotations.length) {
								for (var aIndex in annotations) {
									var theAnnotation = annotations[aIndex];
									if (theAnnotation.track == currentTrack) {
										var aType = theAnnotation.type;
										// ** THESE ELEMENTS HAVE ALREADY BEEN CHECKED ELSEWHERE ** //
										if (aType == Element.GRADUAL_TEMPO_CHANGE || aType == Element.GRADUAL_TEMPO_CHANGE_SEGMENT || aType == Element.TEMPO_TEXT || aType == Element.METRONOME || aType == Element.DYNAMIC) continue;
										// **** FOUND A TEXT OBJECT **** //
										if (theAnnotation.text) checkTextObject(theAnnotation);
									}
								}
							}
							
							// ************************************************ //
							// **											 **	//
							// **            FOUND A CHORD OR REST           ** //
							// **											 ** //
							// ************************************************ //
							var isHidden = !elem.visible;
							if (isNote && !isHidden) {
								var numHiddenNoteheads = 0;
								var numNoteheads = elem.notes.length;
								for (var ni = 0; ni < numNoteheads; ni++) if (!elem.notes[ni].visible) numHiddenNoteheads ++
								if (numHiddenNoteheads == numNoteheads) isHidden = true;
							}
							//if (isHidden) logError ('Found hidden note');

							if ((isNote || isRest) && !isHidden) {
								
								numNoteRestsInThisTrack ++;
								numNoteRestsInThisSystem ++;
								var noteRest = elem;
								if (firstNoteInThisBar == null) firstNoteInThisBar = noteRest;
								var displayDur = noteRest.duration.ticks;
								var soundingDur = noteRest.actualDuration.ticks;
								var tuplet = noteRest.tuplet;
								var barsSincePrevNote = currentBarNum - prevBarNum;
								
								if (barsSincePrevNote > 1) {
									minLedgerLines = [];
									maxLedgerLines = [];
									flaggedClefTooLow = false;
									flaggedClefTooHigh = false;
									flaggedOttavaTooLow = false;
									flaggedOttavaTooHigh = false;
								}
								
								if (flaggedClefTooLow) if (flaggedClefTooLowBarNum < currentBarNum - 4) flaggedClefTooLow = false;
								if (flaggedClefTooHigh) if (flaggedClefTooHighBarNum < currentBarNum - 4) flaggedClefTooHigh = false;
								if (flaggedOttavaTooLow) if (flaggedOttavaTooLowBarNum < currentBarNum - 4) flaggedOttavaTooLow = false;
								if (flaggedOttavaTooHigh) if (flaggedOttavaTooHighBarNum < currentBarNum - 4) flaggedOttavaTooHigh = false;
								
								// ************ CHECK EXPRESSIVE DETAIL (DYNAMICS) ********** //
								if (doCheckExpressiveDetail && !isGrandStaff[currentStaffNum]) {
									if (lastDynamicTick < currTick - division * 32 && numConsecutiveMusicBars >= 8 && isNote) {
										lastDynamicTick = currTick + 1;
										addError("This passage has had no dynamic markings for the last 8 or more bars.\nConsider adding more dynamic detail to this passage.",noteRest);
									}
								}
								
								if (isRest) {
									
									// ************ CHECK DYNAMICS WITH SIGNIFICANT HORIZONTAL OFFSETS 	********** //
									// ************ AND DYNAMICS UNDER RESTS							********** //
									if (doCheckDynamics && tickHasDynamic() && !isGrandStaff[currentStaffNum]) {
										if (theDynamic.offsetX < -1.5) {
											addError ("This dynamic has a significant negative x offset.\nThis may cause problems in parts and playback.\nDrag the dynamic horizontally until its attachment line is more vertical.",theDynamic);
										} else {
											if (theDynamic.offsetX > 1.5) {
												addError ("This dynamic has a significant positive x offset.\nThis may cause problems in parts and playback.\nDrag the dynamic horizontally until its attachment line is more vertical.",theDynamic);
											} else {
												if (allTracksHaveRestsAtCurrTick()) addError ("In general, don’t put dynamic markings under rests.", theDynamic);
											}
										}
									}
									maxLLSinceLastRest = 0;
								
								} else {
									
									// ************************************************ //
									// **											 **	//
									// ************** FOUND A NOTE/CHORD ************** //
									// **											 ** //
									// ************************************************ //
									
									numNotesInThisTrack ++;
									var isTiedBack = noteRest.notes[0].tieBack != null;
									var isTiedForward = noteRest.notes[0].tieForward != null;
									isTied = isTiedBack || isTiedForward;

									if (isNote && !isTremolo) flzFound = false;
									if (isTiedForward && !isLv && numVoicesInThisBar == 1) {
										var nextChordRest = getNextNoteRest(elem);
										if (nextChordRest != null) {
											if (doCheckSlursAndTies && nextChordRest.type == Element.REST) addError ("Don’t tie notes over a rest.",noteRest);
										}
									}
									
									// ************ CHECK CLEF ********** //
									if (!firstNoteSinceClefChange && currentClefTick > 0) {
										firstNoteSinceClefChange = true;
										var ticksSinceLastClef = currTick - currentClefTick;
										//logError ('firstNote: ticksSinceLastClef = '+ticksSinceLastClef+'; isEndOfBarClef = '+isEndOfBarClef+'; currentBarNum = '+currentBarNum+'; currentClefBarNum = '+currentClefBarNum);
										if (isMidBarClef && ticksSinceLastClef >= division) addError ('Try moving this mid-bar clef closer to the next note.',currentClef);
										if (isEndOfBarClef && currentBarNum != currentClefBarNum) addError ('Don’t put a clef before an empty bar.\nTry moving it closer to the next note.',currentClef);
									}
									
									// ************ CHECK ARTICULATION ON TIED NOTES ********** //
									var theArticulationArray = getArticulations(noteRest);
									if (flaggedStaccatoOnShortDecayInstrumentBarNum > 0 && flaggedStaccatoOnShortDecayInstrumentBarNum < currentBarNum - 4) flaggedStaccatoOnShortDecayInstrumentBarNum = 0;
									if (theArticulationArray.length > 0) {
										lastArticulationTick = currTick;
										if (doCheckArticulation) {
											checkArticulation (noteRest, theArticulationArray);
											var numStaccatos = 0;
											for (var i = 0; i < theArticulationArray.length; i++) {
												if (theArticulationArray[i].visible) {
													if (staccatoArray.includes(theArticulationArray[i].symbol)) numStaccatos++;
												}
											}
											if (numStaccatos > 0) checkStaccatoIssues (noteRest);
											if (numStaccatos > 1) addError ("It looks like you have multiple staccato dots on this note.\nYou should delete one of them.", noteRest);
											if (isSforzando){
												var isAccented = false;
												for (var i = 0; i < theArticulationArray.length && !isAccented; i++) {
													if (theArticulationArray[i].visible) {
														isAccented = accentsArray.includes(theArticulationArray[i].symbol);
													}
												}
												if (!isAccented) addError("This note is marked as some kind of sforzando,\nbut has no accent articulation. Consider\nadding an accent to aid the performer.",noteRest);
											}
										}
									} else {
										if (doCheckExpressiveDetail) {
											if (lastArticulationTick < currTick - division * 32 && numConsecutiveMusicBars >= 8) {
												if (isStringInstrument || isWindOrBrassInstrument) {
													lastArticulationTick = currTick + 1;
													addError("This passage has had no articulation for the 8 or more bars.\nConsider adding more detail to this passage.",noteRest);
												}
											}
											if (isSforzando) addError("This note is marked as some kind of sforzando,\nbut has no accent articulation. Consider\nadding an accent to aid the performer.",noteRest);
										}
									}
									// ************ CHECK ARTICULATION & STACCATO ISSUES ************ //
									if (isTied && !isLv) {
										var hasStaccato = false, hasHarmonic = false;
										if (theArticulationArray.length > 0) {
											for (var i = 0; i < theArticulationArray.length; i++) {
												if (theArticulationArray[i].visible) {
													if (staccatoArray.includes(theArticulationArray[i].symbol)) hasStaccato = true;
													if (theArticulationArray[i].symbol == SymId.stringsHarmonic) hasHarmonic = true;
												}
											}
											if (isTiedBack && doCheckSlursAndTies && !hasStaccato && !hasHarmonic) addError("This note has articulation in the middle of a tie.\nDid you mean that to be slurred instead?",noteRest);
										}
										if (!hasHarmonic && wasHarmonic && !isHorn) {
											hasHarmonic = true;
											addError ("Put harmonic circles on all notes in a tied harmonic.",noteRest);
										}
										wasHarmonic = isTiedForward ? hasHarmonic : false;
									} else {
										wasHarmonic = false;
									}
									
									// ************ CHECK TRILL ************ //
									//if (isTrill && currTick == trillStartTick) checkTrill(noteRest);
															
									// ************ CHECK LYRICS ************ //
									if (doCheckVoice && isVoice) checkLyrics(noteRest);
								
									// ************ CHECK GRACE NOTES ************ //
									var graceNotes = noteRest.graceNotes;
									var hasGraceNotes = graceNotes.length > 0;
									if (hasGraceNotes) {
										checkGraceNotes(graceNotes, noteRest);
										numNoteRestsInThisSystem += graceNotes.length / 2; // grace notes only count for half
										prevWasGraceNote = true;
									}
									
									var nn = noteRest.notes.length;
									isChord = nn > 1;
									
									if (doCheckWindsAndBrass && isChord && isWindOrBrassInstrument && !isSharedStaff && !flaggedPolyphony) {
										addError ('This is a chord in a monophonic instrument.\nIf this is not a multiphonic, is this an error?',noteRest);
										flaggedPolyphony = true;
									}
									
									// ************ CHECK WHETHER CHORD NOTES ARE TIED ************ //
									if (doCheckSlursAndTies && isChord) checkChordNotesTied(noteRest);
									
									// ************ CHECK TREMOLOS ************ //
									isTremolo = false;
									if (doCheckTremolosAndFermatas) {
										if (noteRest.tremoloSingleChord != undefined && noteRest.tremoloSingleChord != null) {
											isTremolo = true;
											checkOneNoteTremolo(noteRest);
										}
										if (noteRest.tremoloTwoChord != undefined && noteRest.tremoloTwoChord != null) {
											isTremolo = true;
											checkTwoNoteTremolo(noteRest);
										}
									}
								
									// ************ CHECK OTTAVA ************ //
									if (doCheckOttavas && isOttava) checkOttava(noteRest,currentOttava);
								
									// ************ CHECK STEM DIRECTION && BEAM TWEAKS ************ //
									if (doCheckStemsAndBeams) checkStemsAndBeams(noteRest);
								
									// ************ CHECK LEDGER LINES ************ //
									if (doCheckRangeRegister) checkInstrumentalRanges(noteRest);
								
									// ************ CHECK STRING ISSUES ************ //
									if (doCheckStrings && isStringInstrument) {
									
										// ************ CHECK STRING HARMONIC ************ //
										checkStringHarmonic(noteRest); // make sure we call this BEFORE multiple stops and divisi, as it checks for false harmonics
									
										// ************ CHECK DIVISI ************ //
										if (isStringSection) checkDivisi (noteRest);
									
										// ************ CHECK PIZZ ISSUES ************ //
										if (currentPlayingTechnique === "pizz") checkPizzIssues(noteRest);
									
										// ************ CHECK MULTIPLE STOP ISSUES ************ //
										if (isChord && !isStringSection) {
											checkMultipleStop (noteRest);
										} else {
											prevIsMultipleStop = false;
										}
									
									} // end isStringInstrument
									
									// ************ CHECK SHORT DECAY INSTRUMENT ISSUES ************ //
									if (doCheckPianoHarpAndPercussion && (isShortDecayInstrument || isLongDecayInstrument)) checkDecayInstrumentIssues(noteRest);
																
									// ************ CHECK FLUTE HARMONIC ************ //
									if (doCheckWindsAndBrass && isFlute) checkFluteHarmonic(noteRest);
								
									// ************ CHECK PIANO STRETCH ************ //
									if (doCheckPianoHarpAndPercussion && isKeyboardInstrument && isChord) checkPianoStretch(noteRest);
									
									// ************ CHECK SPANNERS ATTACHED TO THIS NOTE ************ //
									// ************ THIS INCLUDES CHECKING GLISSES ************ //
									checkSpanners(noteRest)
									
									// ************ CHECK RANGE ************ //
									if (doCheckRangeRegister) checkInstrumentRange(noteRest);
									
									prevBarNum = currentBarNum;
								
								} // end is rest
								
								// **** CHECK SLUR ISSUES **** //
								// We do this last so we can check if there were grace notes beforehand
								// Also note that we might call 'checkSlurIssues' multiple times for the same slur, because we check for each note under the slur
								if (doCheckSlursAndTies && isSlurred && currentSlur != null) checkSlurIssues(noteRest, currentSlur);
							
								prevSoundingDur = soundingDur;
							
							} // end if eType == Element.Chord || .Rest
							
							if (isNote) {
								if (isFirstNote) {
									isFirstNote = false;
									// ************ CHECK IF INITIAL DYNAMIC SET ************ //
									if (doCheckDynamics && !firstDynamic && !isGrandStaff[currentStaffNum]) addError("This note should have an initial dynamic level set.\n(If there is a dynamic underneath, it may be too far to the right.)",noteRest);
								
								} else {
								
									// ************ CHECK DYNAMIC RESTATEMENT ************ //
									if (doCheckDynamics && barsSincePrevNote > 4 && !tickHasDynamic() && !isGrandStaff[currentStaffNum] ) addError("Restate a dynamic here, after the "+(barsSincePrevNote-1)+" bars’ rest.",noteRest);
								}
							}
						}
						
						// CHECK FOR UNTERMINATED GRADUAL TEMPO CHANGES
						if (doCheckTempoMarkings && tempoChangeMarkingEnd != -1 && currTick > tempoChangeMarkingEnd + division * 2) {
							//logError ('checking unterminated gradual tempo change; currTick = '+currTick+' tempoChangeMarkingEnd = '+tempoChangeMarkingEnd);
							var endsInFermata = false;
							if (fermatas[currentStaffNum].length > 0) endsInFermata = fermatas[currentStaffNum].filter (e => e.parent.tick > tempoChangeMarkingEnd && e.parent.tick < tempoChangeMarkingEnd + division *4).length > 0;
							if (!endsInFermata) addError ("You have indicated a tempo change here,\nbut I couldn’t find a new tempo marking, nor\nan ‘a tempo’ or ‘tempo primo’ marking.",lastTempoChangeMarking);
							tempoChangeMarkingEnd = -1;
						}
						
						processingThisBar = cursor.next() ? (cursor.measure.is(currentBar) && cursor.tick < barEndTick) : false;
						
						if (isNote) {
							prevNote = noteRest;
							prevNotes[currentTrack] = noteRest;
						} else {
							prevNote = null;
							prevNotes[currentTrack] = null;
						}
						prevSlurNumOnTrack[currentTrack] = currentSlurNumOnTrack[currentTrack];
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
				
				if (doCheckOrchestralSharedStaves && isWindOrBrassInstrument && isSharedStaff) {
					if (numTracksWithNoteRests > 1 || isChord) {
						//logError("multiple parts found");
						weKnowWhosPlaying = false;
						flaggedWeKnowWhosPlaying = false;
					} else {

						//logError("numTracksWithNotes="+numTracksWithNotes+" weKnowWhosPlaying="+weKnowWhosPlaying+" flaggedWeKnowWhosPlaying="+flaggedWeKnowWhosPlaying);
						// We might have a situation for shared staves if all of the following are true:
						// 1. There was only one voice with notes in it
						// 2. There was not a second voice with only rests in it
						// 3. It has not been clarified if this is 1./2./a 2
						// 4. We haven't already flagged this as an issue
						if (numTracksWithNotes == 1 && numTracksWithNoteRests == 1 && !weKnowWhosPlaying && !flaggedWeKnowWhosPlaying) {
							addError("This bar has only one melodic line on a shared staff\nThis needs to be marked with, e.g., 1./2./a 2",firstNoteInThisBar);
							flaggedWeKnowWhosPlaying = true;
						}
					}
				}
				
				if (currentBar) currentBar = currentBar.nextMeasure;
				numConsecutiveMusicBars = (numTracksWithNotes > 0) ? numConsecutiveMusicBars + 1 : 0;
				numBarsProcessed ++;
			}// end currentBar num
			
			if (currentStaffNum == 0) beatCountInSystem.push(numBeatsInThisSystem);
			if (noteCountInSystem[currentSystemNum] == undefined) {
				noteCountInSystem[currentSystemNum] = (numNoteRestsInThisSystem > numBeatsInThisSystem) ? numNoteRestsInThisSystem : numBeatsInThisSystem;
			} else {
				if (numNoteRestsInThisSystem > noteCountInSystem[currentSystemNum]) noteCountInSystem[currentSystemNum] = numNoteRestsInThisSystem;
			}
		} // end staffnum loop
	
		// mop up any last tests
		
		// ** CHECK FOR OMITTED INITIAL TEMPO ** //
		if (doCheckTempoMarkings && !initialTempoExists) addError("I couldn’t find an initial tempo marking.","top");
		
		// ** CHECK SPACING ** //
		numSystems = systemStartBars.length;
		if (doCheckMusicSpacing && currentSystem != null) {
			for (var sys = 0; sys < numSystems; sys ++) {
				var noteCountInSys = noteCountInSystem[sys];
				var numBeatsInSys = beatCountInSystem[sys];
				var bar = systemStartBars[sys];
				var mmin = maxNoteCountPerSystem * 0.4;
				var mmax = minNoteCountPerSystem * 2;
				//logError("CHECKING SYS "+sys+": nc="+noteCountInSys+" nb="+numBeatsInSys+" mmin="+mmin+" mmax="+mmax);
				if (bar == undefined) {
					logError("checkScore() — bar is underfined");
				} else {
					if (noteCountInSys > maxNoteCountPerSystem) {
						addError("This system has a lot of notes in it,\nand may be quite squashed.\nTry moving some of the bars out of this system.",bar);
						continue;
					}
					if (numBeatsInSys < minBeatsPerSystem && noteCountInSys < mmin) {
						if (hasMMRs) {
							addError("This system doesn’t have many bars in it,\nand may be quite spread out.\nTry including more bars in this system.\n(Ignore if this system includes a multimeasure rest.)",bar);
						} else {
							//logError ('numBeatsInSys = '+numBeatsInSys+'; minBeatsPerSystem = '+minBeatsPerSystem+'; noteCountInSys = '+noteCountInSys+'; mmin = '+mmin);
							addError("This system doesn’t have many bars in it,\nand may be quite spread out.\nConsider including more bars in this system.",bar);
						}
						continue;
					}
					
					if (noteCountInSys < minNoteCountPerSystem) {
						if (hasMMRs) {
							addError("This system doesn’t have many notes in it,\nand may be quite spread out.\nTry including more bars in this system.\n(Ignore if this system includes a multimeasure rest.)",bar);
						} else {
							addError("This system doesn’t have many notes in it,\nand may be quite spread out.\nConsider including more bars in this system.",bar);
						}
						continue;
					}
					if (numBeatsInSys > maxBeatsPerSystem && noteCountInSys > mmax) {
						//logError ('numBeatsInSys = '+numBeatsInSys+'; maxBeatsPerSys = '+maxBeatsPerSystem+'; noteCountInSys = '+noteCountInSys+'; mmax = '+mmax);
						addError("This system has quite a few bars in it,\nand may be quite squashed.\nTry moving some of the bars out of this system.",bar);
						continue;
					}
				}
			}
		}
		
		
		// ** SHOW ALL OF THE ERRORS ** //
		showAllErrors();
		
		// ** SELECT NONE ** //
		selectNone();

		// ** SHOW INFO DIALOG ** //
		showFinalDialog();
	}
	
	function checkScoreElements (noteRest) {

		// ** CHECK SLURS ** //
		// ** HAS CURRENT SLUR ENDED? **
		if (isSlurred && currTick > currentSlurEnd) {
			currentSlur = null;
			isSlurred = false;
			currentSlurLength = 0;
			//logError ('slur ended; currentSlur is now false');
		}
		
		// ** HAS A NEW ONE STARTED? ** //
		if (!isSlurred && currentSlurNumOnTrack[currentTrack] < numSlurs) {
			if (currTick >= nextSlurStartOnTrack[currentTrack] && nextSlurStartOnTrack[currentTrack] > -1) {
				prevSlurEnd = currentSlurEnd;
				lastArticulationTick = currTick;
				
				//logError ('not slurred and currTick >= nextSlurTick, so going through remaining slurs');
				// GO THROUGH REMAINING SLURS
				// PUT THIS IN A WHILE LOOP, BECAUSE WE MAY HAVE NESTED SLURS TO DEAL WITH
				while (currentSlurNumOnTrack[currentTrack] < numSlurs && currTick >= nextSlurStartOnTrack[currentTrack] && nextSlurStartOnTrack[currentTrack] != -1) {
					currentSlurNumOnTrack[currentTrack] ++;
					currentSlur = slurs[currentTrack][currentSlurNumOnTrack[currentTrack]];
					currentSlurStart = currentSlur.spanner.spannerTick.ticks;
					currentSlurLength = currentSlur.spanner.spannerTicks.ticks;
					currentSlurEnd = currentSlurStart + currentSlurLength;
					//logError("Slur started; ends at "+currentSlurEnd);
					var prevSlurLength = 0;
					if (currentSlurNumOnTrack[currentTrack] > 0) prevSlurLength = slurs[currentTrack][currentSlurNumOnTrack[currentTrack] - 1].spanner.spannerTicks.ticks;
					//logError ("Slur check: "+currentSlurNumOnTrack[currentTrack]+" "+currentSlurStart+" "+prevSlurEnd+" "+currentSlurLength+" "+prevSlurLength);
					if (doCheckSlursAndTies && currentSlurNumOnTrack[currentTrack] > 0 && currentSlurStart == prevSlurEnd && currentSlurLength > 0 && prevSlurLength > 0 && !prevWasGraceNote) addError ("Don’t start a new slur on the same note\nas you end the previous slur.",currentSlur);
					if (currentSlurNumOnTrack[currentTrack] < numSlurs - 1) {
						nextSlurStartOnTrack[currentTrack] = slurs[currentTrack][currentSlurNumOnTrack[currentTrack]+1].spanner.spannerTick.ticks;
						//logError("currTick = "+currTick+"; Next slur starts at "+nextSlurStartOnTrack[currentTrack]);
					} else {
						nextSlurStartOnTrack[currentTrack] = -1;
						//logError("currTick = "+currTick+"; This is the last slur in this staff ");
					}
				}
				//logError ('currentSlurNum now '+currentSlurNumOnTrack[currentTrack]+' out of '+numSlurs);
				//logError ('CHECK: currTick = '+currTick+'; currentSlurEnd = '+currentSlurEnd);
				// did this slur end already?
				isSlurred = currentSlurEnd >= currTick;
				if (!isSlurred) {
					currentSlur = null;
					currentSlurLength = 0;
				}
				if (currentSlurNumOnTrack[currentTrack] < numSlurs - 1) {
					// LOAD UP THE NEXT SLUR
					//logError ('Loading up next slur');
					var nextSlur = slurs[currentTrack][currentSlurNumOnTrack[currentTrack]+1];
					if (nextSlur != null) {
						var nextSlurStart = nextSlur.spanner.spannerTick.ticks;
						var nextSlurLength = nextSlur.spanner.spannerTicks.ticks;
						nextSlurStartOnTrack[currentTrack] = nextSlurStart;
						if (nextSlurStart < currentSlurEnd && nextSlurLength > 0 && currentSlurLength > 0) {
							var hasGraceNotes = false;
							var nextSlurNote = getNoteRestAtTick(nextSlurStart);
							if (nextSlurNote != null) {
								if (nextSlurNote.graceNotes != null) {
									if (nextSlurNote.graceNotes.length > 0) hasGraceNotes = true;
								}
							}
							if (!hasGraceNotes && doCheckSlursAndTies) addError("Avoid putting slurs underneath other slurs.\nDelete one of these slurs.",nextSlur);
						}
					}
				}
			}
		}
		
		isStartOfSlur = isSlurred ? currTick == currentSlurStart : false;
		isEndOfSlur = isSlurred ? currTick == currentSlurEnd : false;
		
		// ************ PEDAL? ************ //
		
		if (currentPedalNum < numPedals) {
			if (isPedalled) {
				if (currTick > currentPedalEnd) {
					//logError("Pedal ended");
					prevPedal = currentPedal;
					prevPedalEnd = currentPedalEnd;
					currentPedal = null;
					isPedalled = false;
					currentPedalNum ++;
					if (currentPedalNum < numPedals) nextPedalStart = pedals[pedalStaffNum][currentPedalNum].spanner.spannerTick.ticks;
				}
			}
			if (!isPedalled && currTick >= nextPedalStart && currentPedalNum < numPedals) {
				isPedalled = true;
				currentPedal = pedals[pedalStaffNum][currentPedalNum];
				if (!isFirstPedal) {
					isFirstPedal = true;
					// check first pedal has the 'ped' text in it
					var pedText = currentPedal.beginText;
					var containsPedSymbol = false;
					if (pedText) containsPedSymbol = pedText.includes('<sym>keyboardPedalPed</sym>');
					if (!containsPedSymbol) {
						addError ("Your first pedal marking should begin with the Ped. symbol,\navailable from the Keyboard palette.",currentPedal);
					}
				}
				if (currentPedal == null || currentPedal == undefined) {
					currentPedalNum = numPedals;
				} else {
					if (prevPedal != null && prevPedalEnd != -1 && prevPedalEnd >= currTick - beatLength) {
						if (prevPedal.endHookType != 2 && currentPedal.beginHookType != 2) {
							if (currentPedal.beginText !== "") {
								addError ("The previous pedal ended just before this one. It is therefore\nbest to use a pedal ‘retake’ instead of a new Ped. marking.\nIn Properties, set the previous pedal to an angled end hook,\nset this pedal to an angled start hook, delete the ‘Ped.’ text,\nand align the end and beginning to form the retake.", currentPedal); 
							} else {
								addError ("The previous pedal ended just before this one. It is therefore\nbest to use a pedal ‘retake’ instead of a new Ped. marking.\nIn Properties, set the previous pedal to an angled end hook,\nset this pedal to an angled start hook, and\nalign the end and beginning to form the retake.", currentPedal);
							}
						}
					}
					currentPedalEnd = currentPedal.spanner.spannerTick.ticks + currentPedal.spanner.spannerTicks.ticks;
				}
				//logError("Pedal started at "+currTick+" & ends at "+currentPedalEnd);
				if (isPedalInstrument) {
					if (isTopOfGrandStaff[currentStaffNum] && !flaggedPedalLocation && currentPedal.staffIdx == currentStaffNum && doCheckPianoHarpAndPercussion) {
						flaggedPedalLocation = true;
						addError("Pedal markings should go below the bottom staff of a grand staff.",currentPedal);
					}
				} else {
					if (!flaggedPedalIssue && doCheckPianoHarpAndPercussion) {
						addError("This instrument does not have a sustain pedal.",currentPedal);
						flaggedPedalIssue = true;
					}
				}
				nextPedalStart = (currentPedalNum < numPedals - 1) ? pedals[pedalStaffNum][currentPedalNum+1].spanner.spannerTick.ticks : 0;
			}
		}
		
		// ************ OTTAVA? ************ //
		if (currentOttavaNum < numOttavas) {
			if (isOttava && currTick > currentOttavaEnd) {
				currentOttava = null;
				isOttava = false;
				currentOttavaNum ++;
				flaggedOttavaIssue = false;
				if (currentOttavaNum < numOttavas) nextOttavaStart = ottavas[currentStaffNum][currentOttavaNum].spanner.spannerTick.ticks;
			}
			if (!isOttava && currTick >= nextOttavaStart && currentOttavaNum < numOttavas) {
				isOttava = true;
				currentOttava = ottavas[currentStaffNum][currentOttavaNum];
				currentOttavaEnd = currentOttava.spanner.spannerTick.ticks + currentOttava.spanner.spannerTicks.ticks;			
				// ** Flag 22ma and 22mb markings
				if (currentOttava.ottavaType == OttavaType.OTTAVA_22MA) addError ("Never use a 22ma marking.\nThey are almost never seen.", currentOttava);
				if (currentOttava.ottavaType == OttavaType.OTTAVA_22MB) addError ("Never use a 22mb marking.\nThey are almost never seen.", currentOttava);
				if (currentOttavaNum < numOttavas - 1) {
					nextOttavaStart = ottavas[currentStaffNum][currentOttavaNum+1].spanner.spannerTick.ticks;
					//logError("Next ottava starts at "+nextOttavaStart);
				} else {
					nextOttavaStart = 0;
					//logError("This is the last ottava in this staff ");
				}
			}
		}
		
		if (doCheckDynamics) {
			// ************ UNDER A HAIRPIN? ************ //
			
			//if (currentHairpinNum >= numHairpins) logError ('Not checking hairpin because '+currentHairpinNum+' >= '+numHairpins);
			if (currentHairpinNum < numHairpins) {
				if (isHairpin) {
					lastDynamicTick = currTick;
					if (currTick >= currentHairpinEnd) {
						//logError("Hairpin ended because currTick = "+currTick+" & currentHairpinEnd = "+currentHairpinEnd);
						// was this hairpin long enough to require ending?
						currentHairpin = null;
						isHairpin = false;
						currentHairpinNum ++;
						if (currentHairpinNum < numHairpins) {
							nextHairpin = hairpins[currentStaffNum][currentHairpinNum];
							nextHairpinStart = nextHairpin.spanner.spannerTick.ticks;
							//logError("nextHairpin num = "+currentHairpinNum+" "+nextHairpin.hairpinType);
						} else {
							nextHairpinStart = endOfScoreTick;
						}
					}
				}
				if (!isHairpin && currentHairpinNum < numHairpins) {
					if (currTick >= nextHairpinStart) {
						isHairpin = true;
						lastDynamicTick = currTick;
						currentHairpin = hairpins[currentStaffNum][currentHairpinNum];
						if (currentHairpin == null || currentHairpin == undefined) {
							nextHairpinStart = endOfScoreTick;
						} else {
							var hairpinStartTick = currentHairpin.spanner.spannerTick.ticks;
							var hairpinDur = currentHairpin.spanner.spannerTicks.ticks;				
							currentHairpinEnd = hairpinStartTick + hairpinDur;
							if (currentHairpinNum == hairpins[currentStaffNum].length - 1){
								nextHairpin = null;
								nextHairpinStart = -1;
							} else {
								nextHairpin = hairpins[currentStaffNum][currentHairpinNum+1];
								nextHairpinStart = nextHairpin.spanner.spannerTick.ticks;
							}
							checkExpressiveSwell (nextHairpin);
							checkHairpins();
							if (expressiveSwell) expressiveSwell = (expressiveSwell + 1) % 3;
						}
					}
				}
			}
			// ************ DYNAMIC? ************ //		
			if (currentDynamicNum < numDynamics && nextDynamicTick < endOfScoreTick) {
				if (currTick >= nextDynamicTick) {
					currentDynamic = nextDynamic;
					currentDynamicNum ++;
					checkTextObject(currentDynamic);
					//logError ('checking dynamic at '+nextDynamicTick+' (currtick = '+currTick+') tickHasDynamic is now '+tickHasDynamic()+'; firstDynamic = '+firstDynamic);
					if (currTick == nextDynamicTick && isNote) {
						if (noteRest.actualDuration.ticks < division) {
							var loudArray = ['dynamicForte','dynamicSforzando','dynamicZ','sf'];
							var isLoud = false, isSoft = false;
							for (var i = 0; i < loudArray.length && !isLoud; i++) isLoud = nextDynamic.text.includes(loudArray[i]);
							var softArray = ['dynamicPiano'];
							
							for (var i = 0; i < softArray.length && !isSoft; i++) isSoft = nextDynamic.text.includes(softArray[i]);
							//logError (nextDynamic.text+' isLoud:'+isLoud+' isSoft:'+isSoft);
							if (isLoud && isSoft) {
								addError ("This is a compound dynamic with loud and soft elements,\nwhich doesn’t make sense for a short note.\nConsider lengthening the note or changing the dynamic.",nextDynamic);
							}
						}
					}
					getNextDynamic();
				}
			}
		}
		
		// ************ UNDER A TRILL? ************ //
		if (doCheckTremolosAndFermatas && currentTrillNum < numTrills) {
			if (isTrill) {
				if (currTick >= currentTrillEnd) {
					currentTrill = null;
					isTrill = false;
					currentTrillNum ++;
					if (currentTrillNum < numTrills) {
						nextTrill = trills[currentStaffNum][currentTrillNum];
						nextTrillStart = nextTrill.spanner.spannerTick.ticks;
					}
				}
			}
			if (!isTrill && currentTrillNum < numTrills) {
				//logError("Next trill start = "+nextTrillStart+" currTick = "+currTick);
			
				if (currTick >= nextTrillStart) {
					isTrill = true;					
					currentTrill = trills[currentStaffNum][currentTrillNum];
					trillStartTick = currentTrill.spanner.spannerTick.ticks;
					var trillDur = currentTrill.spanner.spannerTicks.ticks;
					checkTrill();
			
					currentTrillEnd = trillStartTick + trillDur;
					if (currentTrillNum == trills[currentStaffNum].length - 1){
						nextTrill = null;
						nextTrillStart = -1;
						nextTrillDur = 0;
					} else {
						nextTrill = trills[currentStaffNum][currentTrillNum+1];
						nextTrillStart = nextTrill.spanner.spannerTick.ticks;
						nextTrillDur = nextTrill.spanner.spannerTicks.ticks;
					}
				}
			}
		}
		
		// ************ CLEF ************ //
		if (numClefs > 0) {
			if (currTick >= nextClefTick && currTick != currentBar.lastSegment.tick) {
				//logError ('currTick = '+currTick+' nextClefTick was '+nextClefTick+'; lastSeg = '+currentBar.lastSegment.tick);
				//logError ('currentClefNum = '+currentClefNum+'; numClefs = '+numClefs+'; about to increment');
				if (currentClefNum < numClefs - 1) currentClefNum ++;
				while (currentClefNum < numClefs - 1) {
					if (clefs[currentStaffNum][currentClefNum+1].parent.tick <= currTick) {
						currentClefNum ++;
					} else {
						break;
					}
				}
				currentClefTick = clefs[currentStaffNum][currentClefNum].parent.tick;
				//logError ('currentClefNum is now '+currentClefNum+'; currentClefTick is now '+currentClefTick);

				if (currentClefTick <= currTick) {
					currentClef = clefs[currentStaffNum][currentClefNum];
					currentClefBarNum = currentClef.parent.parent.no + 1;
					if (currentClef.parent.tick == currentClef.parent.parent.lastSegment.tick) currentClefBarNum ++;
					//logError ('currentClefNum = '+currentClefNum+' in bar '+currentClefBarNum+'; isHeader = '+currentClef.isHeader+'; tick = '+currentClef.parent.tick);
					if (currentTrack % 4 == 0 && currentClefTick == currTick) {
						//logError ('*** FOUND clef on track 0');
						checkClef(currentClef);
						firstNoteSinceClefChange = false;
						nextClefTick = (currentClefNum < numClefs - 1) ? clefs[currentStaffNum][currentClefNum+1].parent.tick : endOfScoreTick;
						prevClefNumInBar = currentClefNum;
						//logError ('nextClefTick = '+nextClefTick);
					} else {
						//logError ('*** FOUND clef on other track or previously noted:');
						setClef (currentClef);
						nextClefTick = (currentClefNum < numClefs - 1) ? clefs[currentStaffNum][currentClefNum+1].parent.tick : endOfScoreTick;
					}
				}
			}
		}
				
		// ************ CHECK INSTRUMENT CHANGE ************ //
		if (numInstrumentChanges > 0 && currentInstrumentNum < numInstrumentChanges) {
			var nextInstrumentChangeTick = instrumentChanges[currentStaffNum][currentInstrumentNum].parent.tick;
			if (currTick >= nextInstrumentChangeTick) {
				var newInstrument = curScore.staves[currentStaffNum].part.instrumentAtTick(currTick);
				currentInstrumentId = newInstrument.musicXmlId;
				calculateCalcId();
				currentInstrumentName = newInstrument.longName;
				currentInstrumentNum ++;
				if (currentInstrumentId == undefined) logError ('currentInstrumentId undefined');
				//logError ('Changing instrument to '+currentInstrumentId+' '+currentInstrumentId.length+' '+currentInstrumentId.replace(/</g,"≤"));
				setInstrumentVariables();
			}
		}
	}
	
	function showFinalDialog () {

		var numErrors = errorStrings.length;
		
		if (errorMsg != "") errorMsg = "<p>————————————<p><p>ERROR LOG (for developer use):</p>" + errorMsg;
		if (numErrors == 0) errorMsg = "<p>CHECK COMPLETED: Congratulations — no issues found!</p><p><font size=\"6\">🎉</font></p>"+errorMsg;
		if (numErrors == 1) errorMsg = "<p>CHECK COMPLETED: I found one issue.</p><p>Please check the score for the yellow comment box that provides more details of the issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove the comment and pink highlight.</p>" + errorMsg;
		if (numErrors > 1 && numErrors <= 100) errorMsg = "<p>CHECK COMPLETED: I found "+numErrors+" issues.</p><p>Please check the score for the yellow comment boxes that provide more details on each issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove all of these comments and highlights.</p>" + errorMsg;
		if (numErrors > 100) errorMsg = "<p>CHECK COMPLETED: I found over 100 issues — I have only flagged the first 100.<p>Please check the score for the yellow comment boxes that provide more details on each issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove all of these comments and highlights.</p>" + errorMsg;
		
		if (progressShowing) progress.close();
		
		var h = 250+numLogs*10;
		if (h > 500) h =500;
		dialog.height = h;
		dialog.contentHeight = h;
		dialog.msg = errorMsg;
		dialog.show();
	}
	
	function loadTextFiles() {
		techniques = techniquesfile.read().trim().split('\n');
		canbeabbreviated = canbeabbreviatedfile.read().trim().split('\n');
		shouldbelowercase = shouldbelowercasefile.read().trim().split('\n');
		shouldhavefullstop = shouldhavefullstopfile.read().trim().split('\n');
		spellingerrorsanywhere = spellingerrorsanywherefile.read().trim().split('\n');
		spellingerrorsatstart = spellingerrorsatstartfile.read().trim().split('\n');
		tempomarkings = tempomarkingsfile.read().trim().split('\n');
		tempochangemarkings = tempochangemarkingsfile.read().trim().split('\n');
		versionNumber = versionnumberfile.read().trim();
		var hyphenationArray = hyphenationfile.read().trim().split('\n');
		hyphenationArray.forEach (item => { const parts = item.split(' ');
			unhyphenatedWords.push(parts[0]);
			unhyphenatedWordsLower.push(parts[0].toLowerCase());
			hyphenatedWords.push(parts[1]);
		});
		
		// **** WORK OUT INSTRUMENT RANGES **** //
		var tempinstrumentranges = instrumentrangesfile.read().trim().split('\n');
		for (var i = 0; i < tempinstrumentranges.length; i++) instrumentranges.push(tempinstrumentranges[i].split(','));
		
		// **** WORK OUT METRONOME MARKINGS **** //
		var tempmetronomemarkings = metronomemarkingsfile.read().trim().split('\n');
		var augmentationDots = ['','.','\uECB7','metAugmentationDot']; // all the possible augmentation dots (including none)
		var spaces = [""," ","\u00A0","\u2009"]; // all the possible spaces: 1) no space, 2) normal space, 3) non-breaking space, 4) thin space
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
	}
	
	function getNoteRestAtTick(targetTick) {
		// get the measure
		var theMeasure = curScore.tick2measure(fractionFromTicks(targetTick));
		var theSeg = theMeasure.firstSegment;
		//logError ('getNoteRestAtTick '+targetTick);
		while (theSeg) {
			//logError ('segType = '+theSeg.segmentType);
			if (theSeg.segmentType == Segment.ChordRest) {
				for (var i = 0; i < 4; i++) {
					var theTrack = currentStaffNum * 4 + i;
					var theElem = theSeg.elementAt(theTrack);
					if (theElem != null) {
						var theElemStart = theSeg.tick;
						var theElemEnd = theElemStart + theElem.actualDuration.ticks;
						//logError ('here1 start = '+theElemStart+' end = '+theElemEnd+' target = '+targetTick);
						if (targetTick >= theElemStart && targetTick < theElemEnd) {
							//logError ('returning element on track '+i+': isRest = '+(theElem.type == Element.REST));
							return theElem;
						}
					}
				}
			}
			theSeg = theSeg.nextInMeasure;
		}
		return null;
			
	}
		
	function getPreviousNoteRest (noteRest) {
		var theTick = getTick(noteRest);
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = currentStaffNum;
		cursor2.track = noteRest.track;
		cursor2.filter = Segment.ChordRest;
		cursor2.rewindToTick(theTick);
		if (cursor2.prev()) return cursor2.element;
		return null;
	}
	
	function getNextNoteRest (noteRest) {
		var theTick = getTick(noteRest);
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = currentStaffNum;
		cursor2.track = noteRest.track;
		cursor2.filter = Segment.ChordRest;
		cursor2.rewindToTick(theTick);
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
	
	function getFrames() {
		var systems = curScore.systems;
		var numSystems = systems.length;
		for (var i = 0; i < numSystems; i++ ) {
			var system = systems[i];
			var measures = system.measures;
			for (var j = 0; j < measures.length; j++ ) {
				var e = measures[j];
				if (e.type == Element.VBOX) frames.push(e);
			}
		}
	}
	
	function getNextDynamic () {
		if (currentDynamicNum < numDynamics-1) {
			nextDynamic = dynamics[currentStaffNum][currentDynamicNum+1];
			if (nextDynamic == null || nextDynamic == undefined) {
				logError ('nextDynamic was '+nextDyanmic);
			} else {
				var p = nextDynamic.parent;
				while (p.type != Element.SEGMENT) p = p.parent;
				nextDynamicTick = p.tick;
				//logError ('next Dynamic is '+nextDynamic.text+' at '+nextDynamicTick);
			}
		} else {
			nextDynamic = null;
			nextDynamicTick = endOfScoreTick;
		}
	}
	
	function checkSystemSpacing() {
		// max spacing to flag
		var maxSpacingToFlag = 40;
		// go through all pages
		var pages = curScore.pages;
		var actualSystemNum = 0, visibleSystemNum = 0;
		for (var i = 0; i < pages.length; i++) {
			var page = pages[i];
			var systems = page.systems;
			var lastSystemBottom = - 1;
			for (var j = 0; j < systems.length; j++) {
				actualSystemNum ++;
				var system = systems[j];
				// get first visible staff
				var firstVisibleStaffIdx = -1, lastVisibleStaffIdx = -1;
				for (var k = 0; k < curScore.nstaves; k++) {
					if (system.show(k)) {
						if (firstVisibleStaffIdx == -1) firstVisibleStaffIdx = k;
						lastVisibleStaffIdx = k;
					}
				}
				if (system.firstMeasure != null) { // ignore frames
					var systemTop = system.canvasPos.y;
					var systemHeight = system.firstMeasure.bbox.height; // to get the height of a system, get the height of its first measure
					var systemBottom = systemTop + systemHeight;
					//logError ('page '+i+' system '+j+'; systemTop = '+systemTop+' systemBottom = '+systemBottom);
					visibleSystemNum ++;
					if (visibleSystemNum == 2) firstBarInSecondSystem = system.firstMeasure;
					if (lastSystemBottom != -1) {
						var systemSpacing = systemTop - lastSystemBottom;
						//logError ('systemSpacing = '+systemSpacing);
						if (systemSpacing > maxSpacingToFlag) {
							var e = 'system'+actualSystemNum+' 0';
							var sysNum = parseInt(e.substring(6,e.indexOf(' ')));
							//logError ('e is '+e);
							addError ("The spacing before this system looks too wide.\nYou can narrow the spacing by choosing Format→Style…\nand setting Spacing→Max. System Distance to 25sp.",e);
						}
					}
					lastSystemBottom = systemBottom;
				}
			}
		}
	}
	
	function analyseSystemsAndSpanners() {
		// **** LOOK FOR AND STORE ANY ELEMENTS THAT CAN ONLY BE ACCESSED FROM SELECTION: **** //
		// **** AND IS NOT PICKED UP IN A CURSOR LOOP (THAT WE WILL BE DOING LATER)       **** //
		// **** THIS INCLUDES: HAIRPINS, OTTAVAS, TREMOLOS, SLURS, ARTICULATION, FERMATAS **** //
		// **** GLISSES, PEDALS, TEMPO TEXT																								**** //
		
		var elems = curScore.selection.elements;
		var prevSlurSegment = null, prevHairpinSegment = null, prevTrillSegment = null, prevOttavaSegment = null, prevPedalSegment = null;
		var firstChord = null;
		if (elems.length == 0) {
			addError ('analyseSystemsAndSpanners() — elems.length was 0');
			return;
		}
		var mmrBar = curScore.firstMeasure;
		var mmrBarNum = 1;
		
		// ** PUSH ALL HEADER CLEFS
		cursor.filter = Segment.HeaderClef;
		for (var staffIdx = 0; staffIdx < curScore.nstaves; staffIdx ++) {
			cursor.staffIdx = staffIdx;
			cursor.voice = 0;
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == undefined || cursor.element == null) {
				logError ('no header clef found for staff '+staffIdex);
			} else {
				clefs[staffIdx].push(cursor.element);
			}
		}
		
		for (var i = 0; i<elems.length; i++) {
			
			var e = elems[i];
			
			// don't log if the element is not visible
			if (!e.visible) continue;
			var etype = e.type;
			var etrack = e.track;
			var staffIdx = e.staff.idx;
			
			if (etype == Element.CHORD || etype == Element.NOTE) {
				var theMeasureNumber = (etype == Element.CHORD) ? e.measure.no : e.parent.measure.no;
				var theVoice = e.voice;
				voicesArray[theMeasureNumber][staffIdx][theVoice] = 1;
			}
			
		/*	if (etype == Element.LYRICS) {
				lyrics.push(e);
				logError ('Found lyric: '+e.text);
			}*/
			var isTempoText = etype == Element.GRADUAL_TEMPO_CHANGE || etype == Element.GRADUAL_TEMPO_CHANGE_SEGMENT || etype == Element.TEMPO_TEXT;
			if (!isTempoText && etype == Element.STAFF_TEXT) isTempoText = e.subStyle == Tid.TEMPO || e.subStyle == Tid.TEMPO_CHANGE || e.subStyle == Tid.METRONOME;
			//logError ('isTempoText = '+isTempoText+' etype = '+etype+'; e.subStyle = '+e.subStyle);
			// etype = 28 (TimeSig) 51 = Tempo_Text; 52 = Staff_Text, 41 = Dynamic 
			if (isTempoText) {
				var theText = '';
				var theTick = 0;
				if (etype == Element.GRADUAL_TEMPO_CHANGE || etype == Element.GRADUAL_TEMPO_CHANGE_SEGMENT) {
					theText = e.beginText;
					theTick = e.spanner.spannerTick.ticks;
				} else {
					theText = e.text;
					theTick = e.parent.tick;
				}
				//logError ('Pushing Tempo Text: '+theText);
				var foundObj = false;
				for (var j = 0; j < tempoText.length && !foundObj; j ++) {
					var compe = tempoText[j];
					if (compe.type == etype) {
						var compareText = '';
						var compareTick = 0;
						if (compe.type == Element.GRADUAL_TEMPO_CHANGE || compe.type == Element.GRADUAL_TEMPO_CHANGE_SEGMENT) {
							compareText = compe.beginText;
							compareTick = compe.spanner.spannerTick.ticks;
						} else {
							compareText = compe.text;
							compareTick = compe.parent.tick;
						}
						foundObj = compareText === theText && compareTick == theTick;
					}
				}
				if (!foundObj) tempoText.push(e);
			}
			
			// ignore if staff is not visible
			if (!staffVisible[staffIdx]) continue;

			if (etype == Element.MMREST) {
				//logError ('Found mmrest '+e+' on staff '+e.staff);
				var startTick = e.parent.parent.firstSegment.tick;
				var endTick = e.parent.parent.lastSegment.tick;
				hasMMRs = true;
				if (mmrBar != null) {
					while (mmrBar.firstSegment.tick < startTick) {
						mmrBar = mmrBar.nextMeasure;
						mmrBarNum ++;
						if (mmrBar == null) break;
					}
					if (mmrBar) {
						if (e.staff.is(curScore.staves[firstVisibleStaff])) {
							while (mmrBar.firstSegment.tick >= startTick && mmrBar.lastSegment.tick <= endTick) {
								mmrs[mmrBarNum] = e;
								//logError ('Pushed mmrBar at '+mmrBarNum);

								var theSys = e.parent.parent.parent;
								if (mmrBarNum == 0) firstMMRSystem = theSys;
								lastMMRSystem = theSys;
								mmrBar = mmrBar.nextMeasure;
								mmrBarNum ++;
								if (mmrBar == null) break;

							}
						}
					}
				}
			}
			
			// *** CHORD
			if (firstChord == null && etype == Element.CHORD) firstChord = e;
			
			// *** HAIRPINS
			if (etype == Element.HAIRPIN_SEGMENT) {
				var sameHairpin = false;
				if (prevHairpinSegment != null) {
					var sameLoc = (e.spanner.spannerTick.ticks == prevHairpinSegment.spanner.spannerTick.ticks) && (e.spanner.spannerTicks.ticks == prevHairpinSegment.spanner.spannerTicks.ticks) && (e.staffIdx == prevHairpinSegment.staffIdx);
					if (sameLoc) sameHairpin = e.spanner.is(prevHairpinSegment.spanner);
				}
				// only add it if it's not already added
				if (!sameHairpin) {
					hairpins[staffIdx].push(e);
					if (e.subtypeName().includes(" line") && e.spanner.spannerTicks.ticks <= division * 12 && doCheckDynamics) addError ("It’s recommended to use hairpins instead of ‘cresc.’ or ‘dim.’\nfor short dynamic changes.",e);
				}
				prevHairpinSegment = e;
			}
			
			// *** TRILLS *** //
			if (etype == Element.TRILL_SEGMENT) {
				var sameTrill = false;
				if (prevTrillSegment != null) {
					var sameLoc = (e.spanner.spannerTick.ticks == prevTrillSegment.spanner.spannerTick.ticks) && (e.spanner.spannerTicks.ticks == prevTrillSegment.spanner.spannerTicks.ticks) && (e.staffIdx == prevTrillSegment.staffIdx);
					if (sameLoc) sameTrill = e.spanner.is(prevTrillSegment.spanner);
				}
				// only add it if it's not already added
				if (!sameTrill) trills[staffIdx].push(e);
				prevTrillSegment = e;
			}
			
			// *** OTTAVAS
			if (etype == Element.OTTAVA_SEGMENT) {
				var sameOttava = false;
				if (prevOttavaSegment != null) {
					var sameLoc = (e.spanner.spannerTick.ticks == prevOttavaSegment.spanner.spannerTick.ticks) && (e.spanner.spannerTicks.ticks == prevOttavaSegment.spanner.spannerTicks.ticks) && (e.staffIdx == prevOttavaSegment.staffIdx);
					if (sameLoc) sameOttava = e.spanner.is(prevOttavaSegment.spanner);
				}
				if (!sameOttava) ottavas[staffIdx].push(e);
				prevOttavaSegment = e;
			}
			
			// *** SLURS *** //
			if (etype == Element.SLUR_SEGMENT) {
				var sameSlur = false;
				if (prevSlurSegment != null && e.parent != null) {
					var sameLoc = (e.spanner.spannerTick.ticks == prevSlurSegment.spanner.spannerTick.ticks) && (e.spanner.spannerTicks.ticks == prevSlurSegment.spanner.spannerTicks.ticks) && (e.staffIdx == prevSlurSegment.staffIdx);
					if (sameLoc) sameSlur = e.spanner.is(prevSlurSegment.spanner);
				}
				if (!sameSlur){
					slurs[etrack].push(e);
					if (slurs[etrack].length == 1) nextSlurStartOnTrack[etrack] = e.spanner.spannerTick.ticks;
				}
				prevSlurSegment = e;
			}
			
			// *** PEDAL MARKINGS *** //
			if (etype == Element.PEDAL_SEGMENT) {
				var samePedal = false;
				if (prevPedalSegment != null) {
					var sameLoc = (e.spanner.spannerTick.ticks == prevPedalSegment.spanner.spannerTick.ticks) && (e.spanner.spannerTicks.ticks == prevPedalSegment.spanner.spannerTicks.ticks);
					if (sameLoc) samePedal = e.spanner.is(prevPedalSegment.spanner);
				}
				// only add it if it's not already added
				if (!samePedal) {
					var staffNum = staffIdx;
					if (isGrandStaff[staffIdx]) {
						// push into the top staff only of grand staves, so we can pick it up
						while (staffNum > 0 && !isTopOfGrandStaff[staffNum]) staffNum --;
					}
					pedals[staffNum].push(e);
					prevPedalSegment = e;
				}
			}
			
			// *** INSTRUMENT CHANGES *** //
			if (etype == Element.INSTRUMENT_CHANGE) {
				instrumentChanges[staffIdx].push(e);
				hasInstrumentChanges = true;
				//logError ('Found instrument change '+e.text);
			}
			
			// *** ARPEGGIOS *** //
			if (etype == Element.ARPEGGIO && doCheckArpeggios) {
				//logError ("Arpeggio found, type "+e.subtype);
				// Versions prior to MuseScore 4.6 reported the subtype as 'undefined', so we had to use the subtypeName instead
				if (e.subtype == 1 || e.subtypeName() === "Up arpeggio") addError ("Arpeggios are played upwards by default.\nOnly use an up arrow to contrast with downwards ones,\notherwise, replace with a standard arpeggio symbol.",e);
			}
			
			// *** FERMATAS, DYNAMICS & CLEFS *** //
			if (etype == Element.FERMATA) fermatas[staffIdx].push(e);
			if (etype == Element.DYNAMIC) {
				dynamics[staffIdx].push(e);
				var theTick = e.parent.tick;
				//logError ('dynamic theTick = '+theTick);
				dynamicTicks[staffIdx][theTick] = e;
			}
			if (etype == Element.CLEF) clefs[staffIdx].push(e);
			
		}
		
		// sort the tempo text array
		tempoText.sort( orderTempoText );
	}
	
	function orderTempoText (a, b) {
		var aType = a.type;
		var bType = b.type;
		var aTick = (aType == Element.GRADUAL_TEMPO_CHANGE || aType == Element.GRADUAL_TEMPO_CHANGE_SEGMENT) ? a.spanner.spannerTick.ticks : a.parent.tick;
		var bTick = (bType == Element.GRADUAL_TEMPO_CHANGE || bType == Element.GRADUAL_TEMPO_CHANGE_SEGMENT) ? b.spanner.spannerTick.ticks : b.parent.tick;
		return aTick - bTick;
	}
	
	function analyseInstrumentsAndStaves () {
		numGrandStaves = 0;
		var prevPart = null;
		var prevPrevPart = null;
		var staves = curScore.staves;
		var visibleStaffFound = false;
		
		for (var i = 0; i < numStaves; i++) {
			var staff = staves[i];
			var part = staff.part;
			staffVisible[i] = staff.show;
			//logError ('staff '+i+'; visible = '+staffVisible[i]);
			// don't process if the part is hidden
			if (!staffVisible[i]) continue;
			
			if (!visibleStaffFound) {
				visibleStaffFound = true;
				firstVisibleStaff = i;
			}
			currentInstrumentId = part.musicXmlId;
			calculateCalcId();
			currentInstrumentName = part.longName;
			
			// is this instrument transposing? If so, flag that the score includes a transposing instrument
			if (!scoreIncludesTransposingInstrument) {
				var tran = staff.transpose(fractionFromTicks(0)).chromatic;
				if (tran != 0) {
					scoreIncludesTransposingInstrument = true;
				} else {
					for (var j = 0; j < instrumentChanges[i].length && !scoreIncludesTransposingInstrument; j++) {
						var t = instrumentChanges[j].parent.tick;
						if (staff.transpose(fractionFromTicks(t)).chromatic != 0) scoreIncludesTransposingInstrument = true;
					}
				}
			}
			
			//logError("staff "+i+" ID "+id+" name "+staffName+" vis "+staves[i].visible);
			isSharedStaffArray[i] = false;
			
			var firstStaffName = staves[i].part.longName;
			// check to see whether this staff name indicates that it's a shared staff
			var firstWordIsANumber = firstStaffName.match(/^([0-9])+\s/) != null; // checks to see if the staff name begins with, e.g., '2 Bassoons'
			if (firstWordIsANumber) {
				isSharedStaffArray[i] = true;
			} else {
				// check if it includes a pattern like '1.2' or 'II &amp; III'
				if (firstStaffName.match(/([1-8]+|[VI]+)(\.|,|, |&amp;| &amp; )([1-8]+|[VI]+)/) != null) {
					isSharedStaffArray[i] = true;
					continue;
				}
			}
			
			//logError ('i = '+i+'; matchPart = '+part.is(prevPart)+'; primaryStaff = '+staves[i].primaryStaff);
			
			if (i > 0 && part.is(prevPart) && isNormallyMultiStaveInstrument(currentInstrumentId)) {
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
		//logError ('scoreIncludesTransposingInstrument = '+scoreIncludesTransposingInstrument);
	}
	
	function isNormallyMultiStaveInstrument (id) {
		return id.includes("keyboard.") || id.includes("marimba") || id.includes("pluck.harp");
	}
	
	function calculateCalcId () {
		var id = currentInstrumentId;
		currentInstrumentCalcId = id;
		var lowerStaffName = currentInstrumentName.toLowerCase();
		
		if (id.includes ('voice')) isVocalScore = true;
		// It's a group id, so try and work out what it might be given the name
		if (id.includes('.group')) {
			if (id.includes('strings')) {
				if (lowerStaffName.includes('violin')) currentInstrumentCalcId = 'strings.violin';
				if (lowerStaffName.includes('viola')) currentInstrumentCalcId = 'strings.viola';
				if (lowerStaffName.includes('cello')) currentInstrumentCalcId = 'strings.cello';
				if (lowerStaffName.includes('bass')) currentInstrumentCalcId = 'strings.contrabass';
			}
			if (id.includes('wind')) {
				if (lowerStaffName.includes('piccolo')) currentInstrumentCalcId = 'wind.flutes.flute.piccolo';
				if (lowerStaffName.includes('flute')) {
					if (lowerStaffName.includes('alto')) {
						currentInstrumentCalcId = 'wind.flutes.flute.alto';
					} else {
						if (lowerStaffName.includes('bass')) {
							currentInstrumentCalcId = 'wind.flutes.flute.bass';
						} else {
							currentInstrumentCalcId = 'wind.flutes.flute';
						}
					}
				}
				if (lowerStaffName.includes('oboe')) currentInstrumentCalcId = 'wind.reed.oboe';
				if (lowerStaffName.includes('anglais') || lowerStaffName.includes('english')) currentInstrumentCalcId = 'wind.reed.english-horn';
				if (lowerStaffName.includes('clarinet')) {
					if (lowerStaffName.includes('bass')) {
						currentInstrumentCalcId = 'wind.reed.clarinet.bass';
					} else {
						if (lowerStaffName.includes('a cl') || lowerStaffName.includes('in a')) {
							currentInstrumentCalcId = 'wind.reed.clarinet.a';
						} else {
							if (lowerStaffName.includes('eb cl') || lowerStaffName.includes('in eb')) {
								currentInstrumentCalcId = 'wind.reed.clarinet.eb';
							} else {
								currentInstrumentCalcId = 'wind.reed.clarinet.bb';
							}
						}
					}
				}
					
				if (staffName.includes('bassoon')) {
					if (lowerStaffName.includes('contra')) {
						currentInstrumentCalcId = 'wind.reed.contrabassoon';
					} else {
						currentInstrumentCalcId = 'wind.reed.bassoon';
					}
				}
			}
			if (id.includes('brass')) {
				if (lowerStaffName.includes('horn')) currentInstrumentCalcId = 'brass.french-horn';
				if (lowerStaffName.includes('trumpet')) currentInstrumentCalcId = 'brass.trumpet';
				if (lowerStaffName.includes('trombone')) currentInstrumentCalcId = 'brass.trombone';
				if (lowerStaffName.includes('tuba')) currentInstrumentCalcId = 'brass.tuba';
			}
		}
	}
	
	// ***************************************************************** //
	// **** CHECK STANDARD CHAMBER LAYOUTS FOR CORRECT SCORE ORDER 	**** //
	// **** 					AND CORRECT BRACKETING				**** //
	// **** 				ALSO NOTE ANY GRAND STAVES				**** //
	// ***************************************************************** //
	
	function checkStaffOrderAndBrackets () {
		
		var numVocalParts = 0;
		var numVisibleStaves = 0;
		for (var i = 0; i < numStaves; i++) {
			if (staffVisible[i]) {
				numVisibleStaves ++;
				var instrumentType = curScore.staves[i].part.musicXmlId;
				if (instrumentType.includes("strings.")) scoreHasStrings = true;
				if (instrumentType.includes("wind.")) scoreHasWinds = true;
				if (instrumentType.includes("brass.")) scoreHasBrass = true;
				if (instrumentType.includes("voice.")) numVocalParts ++;
			}
		}
		isChoirScore = numVocalParts > 0 && numVocalParts == numVisibleStaves;
		
		// ** FIRST CHECK THE ORDER OF STAVES IF ONE OF THE INSTRUMENTS IS A GRAND STAFF ** //
		if (numGrandStaves > 0) {
			// CHECK ALL SEXTETS, OR SEPTETS AND LARGER THAT DON"T MIX WINDS & STRINGS
			
			// do we need to check the order of grand staff instruments?
			// only if there are less than 7 parts, or all strings or all winds or only perc + piano
			var checkGrandStaffOrder = (numParts < 7) || ((scoreHasWinds || scoreHasBrass) != scoreHasStrings) || (!(scoreHasWinds || scoreHasBrass) && !scoreHasStrings);
	
			if (checkGrandStaffOrder) {
				for (var i = 0; i < numGrandStaves;i++) {
					var bottomGrandStaffNum = grandStaffTops[i]+1;
					if (bottomGrandStaffNum < numStaves-1) {
						if (!isGrandStaff[bottomGrandStaffNum+1] && staffVisible[bottomGrandStaffNum]) addError("For small ensembles, grand staff instruments should be at the bottom of the score.\nMove ‘"+curScore.staves[bottomGrandStaffNum].part.longName+"’ down using the Layout tab.","pagetop");
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
		var numPf = 0;
		var flStaff, obStaff, clStaff, bsnStaff, hnStaff;
		var tpt1Staff, tpt2Staff, tbnStaff, tbaStaff;
				
		
		for (var i = 0; i < numStaves; i ++) {
			if (staffVisible[i]) {
				var id = curScore.staves[i].part.musicXmlId;
				//logError (id);
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
				if (id.includes ("strings.contrabass")) numDb ++;
				if (id.includes ("keyboard.piano")) numPf ++;
			}
		}
		var checked = false;
		//logError ('numParts = '+numParts+'; numPf = '+numPf);
		if (numParts == 2) {
			checkBracketsAndBraces("duo");
			checked = true;
		}

		// ** CHECK PIANO TRIO ** //
		if (numParts == 3 && numPf > 0) {
			checkBracketsAndBraces ("piano trio");
			checked = true}
		
		// ** CHECK PIANO QUARTET ** //
		if (numParts == 4 && numPf > 0) {
			checkBracketsAndBraces ("piano quartet");
			checked = true;
		}
		
		// ** CHECK STRING QUARTET ** //

		if (numParts == 4 && numVn == 2 && numVa == 1 && numVc == 1) {
			checkBarlinesConnected("string quartet");
			checkBracketsAndBraces("string quartet");
			checked = true;
		}
			
		// **** CHECK WIND QUINTET **** //
		if (numParts == 5 && numFl == 1 && numOb == 1 && numCl == 1 && numBsn == 1 && numHn == 1) {
			checkBarlinesConnected("wind quintet");
			checkBracketsAndBraces("wind quintet");
			checked = true;
			if (flStaff != 0) {
				addError("You appear to be composing a wind quintet\nbut the flute should be the top staff.\nReorder using the Layout tab.","topfunction ");
			} else {
				if (obStaff != 1) {
					addError("You appear to be composing a wind quintet\nbut the oboe should be the second staff.\nReorder using the Layout tab.","pagetop");
				} else {
					if (clStaff != 2) {
						addError("You appear to be composing a wind quintet\nbut the clarinet should be the third staff.\nReorder using the Layout tab.","pagetop");
					} else {
						if (hnStaff != 3) {
							addError("You appear to be composing a wind quintet\nbut the horn should be the fourth staff.\nReorder using the Layout tab.","pagetop");
						} else {
							if (bsnStaff != 4) addError("You appear to be composing a wind quintet\nbut the bassoon should be the bottom staff.\nReorder using the Layout tab.","pagetop");
						}
					}
				}
			}
		}
	
		// **** CHECK BRASS QUINTET **** //
		if (numParts == 5 && numTpt == 2 && numHn == 1 && numTbn == 1 && numTba == 1) {
			checkBarlinesConnected("brass quintet");
			checkBracketsAndBraces("brass quintet");
			checked = true;
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
		
		// **** CHECK STRING QUINTET **** //
		if (numParts == 5 && numVn == 2 && numVa + numVc + numDb == 3) {
			checkBarlinesConnected("string quintet");
			checkBracketsAndBraces("string quintet");
			checked = true;
		}
		
		if (!checked) {
			checkBarlinesConnected(null);
			checkBracketsAndBraces(null);	
		}
	}
	
	// ***************************************************************** //
	// **** 	CHECK NAMES OF STAVES FOR VARIOUS AMBIGUITIES OR 	**** //
	// **** 			ERRORS; ALSO PREFERRED STRING NAMING		**** //
	// **** 														**** //
	// ***************************************************************** //
	
	function checkStaffNames () {
		var staves = curScore.staves;
		var parts = curScore.parts;
		var numParts = parts.length;
		var pluralWindsAndBrassFull = ["flutes","oboes","saxes","saxophones","clarinets","bassoons","horns","trumpets","trombones","tubas"];
		var pluralWindsAndBrassShort = ["fls","flts","obs","saxes","cls","clts","bsns","bns","hrns","hns","tpts","trps","trpts","troms","tbns","tmbns","tbas"];
		var numberRegex = /\b(?:[0-9]|IX|IV|V?I{1,3}|V)\b/;
		

		for (var i = 0; i < numParts ; i++) {
			var part1 = parts[i];
			var staff1 = part1.staves[0];
			var staffnum = staff1.idx;
			//logError ('staffnum = '+staffnum);
			var displaystaffnum = staffnum+1;
			var full1 = part1.longName.trim();
			var short1 = part1.shortName.trim();
			var full1l = full1.toLowerCase();
			var short1l = short1.toLowerCase();
						
			// **** CHECK FOR NON-STANDARD DEFAULT STAFF NAMES **** //
			
			if (fullInstNamesShowing) {
				if (full1l === 'violins 1' || full1l === 'violin 1') addError ("Change the long name of staff "+displaystaffnum+" to ‘Violin I’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+staffnum);
				if (full1l === 'violas 1' || full1l === 'viola 1') addError ("Change the long name of staff "+displaystaffnum+" to ‘Viola I’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+staffnum);
				if (full1l === 'cellos 1' || full1l === 'cello 1') addError ("Change the long name of staff "+displaystaffnum+" to ‘Cello I’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+staffnum);
				
				if (full1l === 'violins 2' || full1l === 'violin 2') addError ("Change the long name of staff "+displaystaffnum+" to ‘Violin II’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+staffnum);
				if (full1l === 'violas 2' || full1l === 'viola 2') addError ("Change the long name of staff "+displaystaffnum+" to ‘Viola II’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+staffnum);
				if (full1l === 'cellos 2' || full1l === 'cello 2') addError ("Change the long name of staff "+displaystaffnum+" to ‘Cello II’\n(see ‘Behind Bars’, p. 509 &amp; 515)", "system1 "+staffnum);
				
				if (full1l === 'violas') addError ("Change the long name of staff "+displaystaffnum+" to ‘Viola’\n(see ‘Behind Bars’, p. 509)", "system1 "+staffnum);
				if (full1l === 'violoncellos' || full1l === 'violoncello') addError ("Change the long name of staff "+displaystaffnum+" to ‘Cello’\n(see ‘Behind Bars’, p. 509)", "system1 "+staffnum);
				if (full1l === 'contrabasses' || full1 === 'Double basses' || full1l === 'contrabass') addError ("Change the long name of staff "+displaystaffnum+" to ‘Double Bass’ or ‘D. Bass’\n(see ‘Behind Bars’, p. 509)", "system1 "+staffnum);
				if (full1l === 'classical guitar') addError ("Change the long name of staff "+displaystaffnum+" to just ‘Guitar’", "system1 "+staffnum);
				
				// search for numbers for Roman Numerals
				if (!numberRegex.test(full1l)) {
					for (var x = 0; x < pluralWindsAndBrassFull.length; x++) {
						if (full1l.includes(pluralWindsAndBrassFull[x])) addError ("You need to indicate how many\n"+full1+" there are","system1 "+staffnum);
					}
				}
			}
			
			if (shortInstNamesShowing) {
			
				if (short1l === 'vlns. 1' || short1l === 'vln. 1' || short1l === 'vlns 1' || short1l === 'vln 1' || short1l === "vn 1" || short1l === "vn. 1") addError ("Change the short name of staff "+(i+1)+" to ‘Vln. I’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vlas. 1' || short1l === 'vla. 1' || short1l === 'vlas 1' || short1l === 'vla 1' || short1l === 'va 1' || short1l === 'va. 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vla. I’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vcs. 1' || short1l === 'vc. 1' || short1l === 'vcs 1' || short1l === 'vc 1') addError ("Change the short name of staff "+(i+1)+" to ‘Vc. I’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				
				if (short1l === 'vlns. 2' || short1l === 'vln. 2' || short1l === 'vlns 2' || short1l === 'vln 2' || short1l === "vn 2" || short1l === "vn. 2") addError ("Change the short name of staff "+(i+1)+" to ‘Vln. II’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vlas. 2' || short1l === 'vla. 2' || short1l === 'vlas 2' || short1l === 'vla 2' || short1l === 'va 2' || short1l === 'va. 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vla. II’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				if (short1l === 'vcs. 2' || short1l === 'vc. 2' || short1l === 'vcs 2' || short1l === 'vc 2') addError ("Change the short name of staff "+(i+1)+" to ‘Vc. II’\n(see ‘Behind Bars’, p. 509 & 515)", "system2 "+i);
				
				if (short1l === 'vlas.') addError ("Change the short name of staff "+(i+1)+" to ‘Vla.’\n(see ‘Behind Bars’, p. 509)", "system2 "+i);
				if (short1l === 'vcs.') addError ("Change the short name of staff "+(i+1)+" to ‘Vc.’\n(see ‘Behind Bars’, p. 509)", "system2 "+i);
				if (short1l === 'cbs.' || short1l === 'dbs.' || short1l === 'd.bs.' || short1l === 'cb.') addError ("Change the short name of staff "+(i+1)+" to ‘D.B.’\n(see ‘Behind Bars’, p. 509)", "system2 "+i);
				// search for numbers for Roman Numerals
				if (!numberRegex.test(short1l)) {
					for (var x = 0; x < pluralWindsAndBrassShort.length; x++) {
						if (short1l.includes(pluralWindsAndBrassShort[x])) addError ("You need to indicate how many\ninstruments there are in ‘"+short1+"’","system2 "+i);
					}
				}
			}
			
			var checkThisPart = full1 !== "" && short1 !== "" && !isGrandStaff[i] && i < numParts - 1 && part1.show;

			// **** CHECK FOR REPEATED STAFF NAMES **** //
			if (checkThisPart) {
				for (var j = i+1; j < numParts; j++) {
					var part2 = parts[j];
					var full2 = part2.longName.trim();
					var short2 = part2.shortName.trim();
					
					if (part2.show) {
						if (fullInstNamesShowing) {
							//logError ('full1 = '+full1+'; full2 = '+full2);
							if (full1 === full2 && full1 != "") addError("Staff name ‘"+full1+"’ appears twice.\nRename one of them, or rename as ‘"+full1+" I’ & ‘"+full1+" II’", "system1 "+i);
							if (full1 === full2 + " I") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" II’?", "system1 "+staffnum);
							if (full2 === full1 + " I") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" II’?", "system1 "+staffnum);
							if (full1 === full2 + " II") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" I’?", "system1 "+staffnum);
							if (full2 === full1 + " II") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" I’?", "system1 "+staffnum);
							if (full1 === full2 + " 1") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" 2’?", "system1 "+staffnum);
							if (full2 === full1 + " 1") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" 2’?", "system1 "+staffnum);
							if (full1 === full2 + " 2") addError("You have a staff ‘"+full2+"’ and a staff ‘"+full1+"’.\nDo you want to rename as ‘"+full2+" 1’?", "system1 "+staffnum);
							if (full2 === full1 + " 2") addError("You have a staff ‘"+full1+"’ and a staff ‘"+full2+"’.\nDo you want to rename as ‘"+full1+" 1’?", "system1 "+staffnum);
						}
						if (shortInstNamesShowing) {
							if (short1 === short2 && short1 != "") addError("Staff name ‘"+short1+"’ appears twice.\nRename one of them, or rename as ‘"+short1+" I’ + ‘"+short2+" II’","system2 "+staffnum);
							if (short1 === short2 + " I") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" II’?","system2 "+staffnum);
							if (short2 === short1 + " I") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" II’?","system2 "+staffnum);
							if (short1 === short2 + " II") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" I’?","system2 "+staffnum);
							if (short2 === short1 + " II") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" I’?","system2 "+staffnum);
							if (short1 === short2 + " 1") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" 2’?","system2 "+staffnum);
							if (short2 === short1 + " 1") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" 2’?","system2 "+staffnum);
							if (short1 === short2 + " 2") addError("You have a staff ‘"+short2+"’ and a staff ‘"+short1+"’.\nDo you want to rename as ‘"+short2+" 1’?","system2 "+staffnum);
							if (short2 === short1 + " 2") addError("You have a staff ‘"+short1+"’ and a staff ‘"+short2+"’.\nDo you want to rename as ‘"+short1+" 1’?","system2 "+staffnum);
						}
					}
				}
			}
		}	
	}
		
	// ***************************************************************** //
	// **** WORK OUT WHAT THE CURRENT INSTRUMENT IS AND SET ANY 	**** //
	// **** 	USEFUL VARIABLES THAT WE'LL USE IN LATER CHECKS		**** //
	// **** 		 (E.G. STRING TUNING, RANGE, CLEFS, ETC.)		**** //
	// ***************************************************************** //
	
	function setInstrumentVariables () {
		var violinStrings = [55,62,69,76];
		var violinStringNames = ["G","D","A","E"];
		var violaStrings = [48,55,62,69];
		var violaStringNames = ["C","G","D","A"];
		var celloStrings = [36,43,50,57];
		var celloStringNames = ["C","G","D","A"];
		var bassStrings = [28,33,38,43];
		var bassStringNames = ["E","A","D","G"];
		var shortDecayInstruments = ["xylophone","drum.","brake-drum"];
		var longDecayInstruments = ["keyboard.piano","vibraphone","pluck.harp","metal.cymbal","metal.bells","metal.gong"];
		
		if (currentInstrumentId != "") {
			isStringInstrument = currentInstrumentId.includes("strings.");
			isStringSection = currentInstrumentId === "strings.group";
			isFlute = currentInstrumentId.includes("wind.flutes");
			isPitchedPercussionInstrument = currentInstrumentId.includes("pitched-percussion") || currentInstrumentId.includes("crotales") || currentInstrumentId.includes("almglocken");
			isUnpitchedPercussionInstrument = false;
			if (!isPitchedPercussionInstrument) isUnpitchedPercussionInstrument = currentInstrumentId.includes("drum.") || currentInstrumentId.includes("effect.") || currentInstrumentId.includes("metal.") || currentInstrumentId.includes("wood.");
			isPercussionInstrument = isPitchedPercussionInstrument || isUnpitchedPercussionInstrument;
			isShortDecayInstrument = false;
			for (var i = 0; i < shortDecayInstruments.length && !isShortDecayInstrument; i++) if (currentInstrumentId.includes(shortDecayInstruments[i])) isShortDecayInstrument = true;
			isLongDecayInstrument = false;
			for (var i = 0; i < longDecayInstruments.length && !isLongDecayInstrument; i++) if (currentInstrumentId.includes(longDecayInstruments[i])) isLongDecayInstrument = true;
			isKeyboardInstrument = currentInstrumentId.includes("keyboard");
			isPiano = currentInstrumentId.includes("piano");
			isVibraphone = currentInstrumentId.includes("vibraphone");
			isPedalInstrument = isPiano || isVibraphone;
			isMarimba = currentInstrumentId.includes("marimba");
			isWindInstrument = currentInstrumentId.includes("wind.");
			isBrassInstrument = currentInstrumentId.includes("brass.");
			isWindOrBrassInstrument = isWindInstrument || isBrassInstrument;
			isHorn = currentInstrumentCalcId === "brass.french-horn";
			isTrombone = currentInstrumentCalcId === "brass.trombone.tenor";
			isHarp = currentInstrumentId === "pluck.harp";
			isVoice = currentInstrumentId.includes("voice.");
			isGuitar = currentInstrumentId.includes("guitar");
			isCello = currentInstrumentId.includes("cello");
			checkInstrumentClefs = false;
			
			reads8va = false;
			readsTreble = true;
			readsAlto = false;
			readsTenor = false;
			readsBass = false;

			//logError("Inst check id "+currentInstrumentId+" isString "+isStringInstrument+" isVoice "+isVoice);
			
			// WINDS
			if (currentInstrumentId.includes("wind.")) {
				currentVibrato = currentInstrumentId.includes('clarinet') ? 'senza' : 'con';
				// Bassoon is the only wind instrument that reads bass and tenor clef
				if (currentInstrumentCalcId.includes("bassoon")) {
					readsTreble = false;
					readsTenor = true;
					readsBass = true;
					checkInstrumentClefs = true;
				} else {
					checkInstrumentClefs = true;
				}
			}
			// BRASS
			if (currentInstrumentId.includes("brass.")) {
				currentVibrato = 'senza';
				if (currentInstrumentCalcId.includes("french-horn")) {
					readsBass = true;
					checkInstrumentClefs = true;
				}
				if (currentInstrumentCalcId.includes("trumpet")) checkInstrumentClefs = true;
				if (currentInstrumentCalcId.includes("trombone") || currentInstrumentCalcId.includes("tuba") || currentInstrumentId.includes("sousaphone")) {
					if (currentInstrumentId.includes("alto") > 0) {
						readsAlto = true;
						checkInstrumentClefs = true;
					} else {
						readsTenor = true;
						readsBass = true;
						checkInstrumentClefs = true;
					}
				}
				if (currentInstrumentId.includes("euphonium")) {
					readsBass = true;
					checkInstrumentClefs = true;
				}
			}
			
			// STRINGS, HARP, PERCUSSION
			if (currentInstrumentId.includes("keyboard") || currentInstrumentId.includes("pluck.harp") || currentInstrumentId.includes(".marimba")) {
				readsBass = true;
				reads8va = true;
				checkInstrumentClefs = true;
			}
			if (currentInstrumentId.includes("timpani")) {
				readsBass = true;
				checkInstrumentClefs = true;
			}
		
			// STRINGS
			stringsArray = [];
			stringNames = [];
			if (currentInstrumentId.includes("strings.")) {
				currentVibrato = 'con';
				if (currentInstrumentCalcId.includes("violin")) {
					checkInstrumentClefs = true;
					reads8va = true;
					stringsArray = violinStrings;
					stringNames = violinStringNames;
				}
				if (currentInstrumentCalcId.includes("viola")) {
					readsAlto = true;
					checkInstrumentClefs = true;
					stringsArray = violaStrings;
					stringNames = violaStringNames;
				}
				if (currentInstrumentCalcId.includes("cello")) {
					readsTenor = true;
					readsBass = true;
					checkInstrumentClefs = true;
					stringsArray = celloStrings;
					stringNames = celloStringNames;
				}
				if (currentInstrumentCalcId.includes("contrabass")) {
					readsTenor = true;
					readsBass = true;
					checkInstrumentClefs = true;
					stringsArray = bassStrings;
					stringNames = bassStringNames;
				}
				
				if (stringsArray.length == 0) logError ("setInstrumentVariables() — I couldn’t work out what string instrument this was — "+currentInstrumentId);
			}
			
			// VOICE
			if (isVoice) {
				if (currentInstrumentId.includes("bass") || currentInstrumentId.includes("baritone") || currentInstrumentId.includes(".male")) {
					readsBass = true;
					checkInstrumentClefs = true;
				}
			}
			
			// ranges and dynamics
			lowestPitchPossible = highestPitchPossible = quietRegisterThresholdPitch = highLoudRegisterThresholdPitch = lowLoudRegisterThresholdPitch = 0;
			for (var i = 0; i < instrumentranges.length; i++) {
				var instrumentData = instrumentranges[i];
				if (currentInstrumentCalcId === instrumentData[0]) {
					lowestPitchPossible = instrumentData[1];
					if (instrumentData[2] != '') quietRegisterThresholdPitch = instrumentData[2];
					highestPitchPossible = instrumentData[3];
					if (instrumentData[4] != '') highLoudRegisterThresholdPitch = instrumentData[4];
					if (instrumentData[5] != '') lowLoudRegisterThresholdPitch = instrumentData[5];
				}
			}
		}
	}
	
	
	function checkPartSettings () {
		//logError ("checkPartSettings");
		var maxSize = 7.0;
		var minSize = 6.6;
		var excerpts = curScore.excerpts;		
		if (numExcerpts < 2) return;
		
		//logError ("2 or more excerpts");
		var styleComments = [];
		var pageSettingsComments = [];
		var partStyle;
		var flaggedStaffSize = false;
		var flaggedSystemSpacing = false;
		var flaggedMinNoteDistance = false;
		var flaggedVerticalFrameBottomMargin = false;
		var flaggedMultiRests = false;
		var flaggedMultiRestsMinBars = false;
		var flaggedMultiRestWidth = false;
		var flaggedLastSystemFillLimit = false;
		var flaggedPartNameStyle = false;
		var flaggedIndentation = false;
		
		for (var i = 0; i < numExcerpts; i++) {
			var thePart = excerpts[i];
			
		//logError ("checking part "+i);
			partStyle = thePart.partScore.style;
			var thePartSpatium = partStyle.value("spatium")*inchesToMM/mscoreDPI;
			// part should be 6.6-7.0mm
			if (!flaggedStaffSize) {
				var theStaffSize = thePartSpatium * 4.0;
				if (theStaffSize > maxSize) {
					pageSettingsComments.push("Decrease the stave space to between "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
					flaggedStaffSize = true;
				}
				if (theStaffSize < minSize) {
					pageSettingsComments.push("Increase the stave space to between "+Math.round(minSize*250)/1000.+"–"+Math.round(maxSize*250)/1000.+"mm");
					flaggedStaffSize = true;
				}
			}
			
			if (!flaggedIndentation) {
				var indent = partStyle.value("enableIndentationOnFirstSystem");
				if (indent) {
					styleComments.push("(Score tab) Uncheck ‘Enable indentation on first system'");
					flaggedIndentation = true;
				}
			}
			
			// check system spacing
			if (!flaggedSystemSpacing) {
				var minSystemDistance = partStyle.value("minSystemDistance");
				var maxSystemDistance = partStyle.value("maxSystemDistance");
				var minSystemSpread = partStyle.value("minSystemSpread");
				var maxSystemSpread = partStyle.value("maxSystemSpread");
				var enableVerticalSpread = partStyle.value("enableVerticalSpread");
				if (enableVerticalSpread) {
					if (minSystemSpread < 6 || minSystemSpread > 8) {
						styleComments.push("(Spacing tab) Set the ‘Min. system distance’ to between 6.0–8.0sp");
						flaggedSystemSpacing = true;
					}
					if (maxSystemSpread < 10 || maxSystemSpread > 14) {
						styleComments.push("(PSpacingage tab) Set the ‘Max. system distance’ to between 10.0–14.0sp");
						flaggedSystemSpacing = true;
					}
				} else {
					if (minSystemDistance < 6 || minSystemDistance > 8) {
						styleComments.push("(Spacing tab) Set the ‘Min. system distance’ to between 6.0–7.0sp");
						flaggedSystemSpacing = true;
					}
					if (maxSystemDistance < 10 || maxSystemDistance > 14) {
						styleComments.push("(Spacing tab) Set the ‘Max. system distance’ to between 10.0–14.0sp");
						flaggedSystemSpacing = true;
					}
				}
			}
			
			// vertical frame bottom margin
			if (!flaggedVerticalFrameBottomMargin) {
				var verticalFrameBottomMargin = partStyle.value("frameSystemDistance");
				if (verticalFrameBottomMargin != 8) {
					styleComments.push("(Spacing tab) Set ‘Vertical frame bottom margin’ to 8.0sp");
					flaggedVerticalFrameBottomMargin = true;
				}
			}
			
			// last system fille distance
			if (!flaggedLastSystemFillLimit) {
				var lastSystemFillLimit = partStyle.value("lastSystemFillLimit");
				if (lastSystemFillLimit != 0) {
					styleComments.push("(Spacing tab) Set ‘Last system fill threshold’ to 0%");
					flaggedLastSystemFillLimit = true;
				}
			}
			
			// min note distance
			if (!flaggedMinNoteDistance) {
				var minNoteDistance = partStyle.value("minNoteDistance");
				if (minNoteDistance < 1.2 || minNoteDistance > 1.4) {	
					styleComments.push("(Spacing tab) Set ‘Padding→Note to Note’ to between 1.2-1.4sp");
					flaggedMinNoteDistance = true;
				}
			}
			
			// multirests on
			if (!flaggedMultiRests) {
				var multirestsOn = partStyle.value("createMultiMeasureRests");
				if (!multirestsOn) {	
					styleComments.push("(Rests tab) Switch ‘Multibar rests’ on");
					flaggedMultiRests = true;
				}
			}
			
			// set multirests to min 2 bars
			if (!flaggedMultiRestsMinBars) {
				var multirestsMinNumBars = partStyle.value("minEmptyMeasures");
				if (multirestsMinNumBars != 2) {	
					styleComments.push("(Rests tab) Set ‘Minimum number of empty bars’ to 2");
					flaggedMultiRestsMinBars = true;
				}
			}
			
			// multirest width
			if (!flaggedMultiRestWidth) {
				var MMrestWidth = partStyle.value("minMMRestWidth");
				if (MMrestWidth < 18.0 || MMrestWidth > 36.0) {	
					styleComments.push("(Rests tab) Set ‘Multibar rests→Minimum width’ to between 18–36sp");
					flaggedMultiRestWidth = true;
				}
			}
			
			// part title setup
			if (!flaggedPartNameStyle) {
				var type = partStyle.value ("partInstrumentFrameType");
				var padding = partStyle.value ("partInstrumentFramePadding");
				if (type != 1) {
					styleComments.push("(Text Styles→Instrument name (Part)) Set Frame type to Rectangle");
					flaggedPartNameStyle = true;
				}
				if (padding != 0.8) {
					styleComments.push("(Text Styles→Instrument name (Part)) Set Frame Padding to 0.80");
					flaggedPartNameStyle = true;
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
		var staffSize = spatium*4;
		var style = curScore.style;
		tempoFontStyle = style.value("tempoFontStyle");
		metronomeFontStyle = style.value("metronomeFontStyle");
		if (!doCheckPageSettings && !doCheckScoreStyle) return;
		
		// ** CHECK FOR PAGE SETTING ISSUES ** //
		if (doCheckPageSettings) {
			
			var pageEvenLeftMargin = Math.round(style.value("pageEvenLeftMargin")*inchesToMM*100)/100.;
			var pageOddLeftMargin = Math.round(style.value("pageOddLeftMargin")*inchesToMM*100)/100.;
			var pageEvenTopMargin = Math.round(style.value("pageEvenTopMargin")*inchesToMM*100)/100.;
			var pageOddTopMargin = Math.round(style.value("pageOddTopMargin")*inchesToMM*100)/100.;
			var pageEvenBottomMargin = Math.round(style.value("pageEvenBottomMargin")*inchesToMM*100)/100.;
			var pageOddBottomMargin = Math.round(style.value("pageOddBottomMargin")*inchesToMM*100)/100.;
			var pagePrintableWidth = Math.round(style.value("pagePrintableWidth")*inchesToMM);
			var pageEvenRightMargin = pageWidth - pagePrintableWidth - pageEvenLeftMargin;
			var pageOddRightMargin = pageWidth - pagePrintableWidth - pageOddLeftMargin;
			
			// **** CHECK PAPER SIZE is either A4 or A3 **** //
			if ((pageWidth != 210 && pageHeight != 297) && (pageWidth != 297 && pageHeight != 210) && (pageWidth != 297 && pageHeight != 420)) pageSettingsComments.push("The page size is non-standard: set it to A4, unless otherwise requested");
			
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
		}
		
		if (doCheckScoreStyle) {
			var minSystemDistance = style.value("minSystemDistance");
			var maxSystemDistance = style.value("maxSystemDistance");
			var minSystemSpread = style.value("minSystemSpread");
			var maxSystemSpread = style.value("maxSystemSpread");
			var enableVerticalSpread = style.value("enableVerticalSpread");
			var tupletsFontFace = style.value("tupletFontFace");
			var tupletsFontStyle = style.value("tupletFontStyle");
			var tupletsFontSize = style.value("tupletFontSize");
			var barNumberFontSize = style.value("measureNumberFontSize");
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
			//var staffLowerBorder = style.value("staffLowerBorder");
			var lastSystemFillLimit = style.value("lastSystemFillLimit");
			var crossMeasureValues = style.value("crossMeasureValues");
			var instrumentChangeFontStyle = style.value("instrumentChangeFontStyle");
			var instrumentChangeFrameType = style.value("instrumentChangeFrameType");
			var instrumentChangeFramePadding = style.value("instrumentChangeFramePadding");
			var rehearsalMarkFontSize = style.value("rehearsalMarkFontSize");
			var lyricsMinDistance = style.value("lyricsMinDistance");
			var mergeMatchingRests = style.value("mergeMatchingRests");
			var measureNumberPlacementMode = style.value("measureNumberPlacementMode");
			
			// *************************************** //
			// **** STYLE SETTINGS — 1. SCORE TAB **** //
			// *************************************** //
			
			// **** STAFF LINE THICKNESS **** //
			if (staffLineSize != 0.1) styleComments.push("(Score tab) Set ‘Stave line thickness’ to 0.1sp");
			
			// **** CHECK FOR STAFF NAMES SHOWING OR HIDDEN INCORRECTLY **** //
			var staffNamesHiddenBecauseSoloScore = isSoloScore && style.value("hideInstrumentNameIfOneInstrument");
			if (isSoloScore) {
				if (!staffNamesHiddenBecauseSoloScore) styleComments.push("(Score tab) Tick ‘Hide if there is only one instrument’");
			} else {
				// ** FIRST STAFF NAMES SHOULD BE SHOWING — i.e. STYLE SET TO 0 **//
				// ** ALSO CHECK THEY HAVEN'T BEEN MANUALLY DELETED ** //		
				var firstStaffNamesVisibleSetting = style.value("firstSystemInstNameVisibility"); //  0 = long names, 1 = short names, 2 = hidden
				var firstStaffNamesVisible = firstStaffNamesVisibleSetting < 2;
				var blankStaffNames = [];
				if (firstStaffNamesVisible) {
					for (var i = 0; i < numParts; i++) {
						var partName;
						if (firstStaffNamesVisibleSetting == 0) {
							partName = visibleParts[i].longName;
						} else {
							partName = visibleParts[i].shortName;
						}
						if (partName === "") {
							for (var j = 0; j < numStaves; j++) {
								if (curScore.staves[j].part.is(visibleParts[i])) {
									blankStaffNames.push(j);
									break;
								}
							}
						}
					}
					if (blankStaffNames.length == numParts) {
						firstStaffNamesVisible = false;
					} else {
						for (var i = 0; i < blankStaffNames.length; i++) addError ("Staff "+(blankStaffNames[i]+1)+" has no staff name.","system1 "+blankStaffNames[i]);
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
							partName = visibleParts[i].longName;
						} else {
							partName = visibleParts[i].shortName;
						}
						var isBlank = partName == '';
						if (isBlank) {
							for (var j = 0; j < numStaves; j++) {
								if (curScore.staves[j].part.is(visibleParts[i])) {
									blankStaffNames.push(j);
									break;
								}
							}
						}
					}
					if (blankStaffNames.length == numParts) {
						subsequentStaffNamesVisible = false;
					} else {
						for (var i = 0; i < blankStaffNames.length; i++) addError ("Staff "+(blankStaffNames[i]+1)+" has no staff name.","system2 "+blankStaffNames[i]);
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
			
			
			// *************************************** //
			// ****      2. SPACING TAB          ***** //
			// *************************************** //
			
			// *** CHECK SYSTEM SPACING *** //
			if (hasMoreThanOneSystem) {
				if (enableVerticalSpread) {
					if (isSoloScore) {
						if (minSystemSpread < 6 || minSystemSpread > 8) styleComments.push("(Spacing tab) Set the ‘Min. system distance’ to between 6.0–8.0sp");
						if (maxSystemSpread < 12 || maxSystemSpread > 16) styleComments.push("(Spacing tab) Set the ‘Max. system distance’ to between 12.0–16.0sp");				
					} else {
						if (minSystemSpread < 12 || minSystemSpread > 14) styleComments.push("(Spacing tab) Set the ‘Min. system distance’ to between 12.0–14.0sp");
						if (maxSystemSpread < 24 || maxSystemSpread > 36) styleComments.push("(Spacing tab) Set the ‘Max. system distance’ to between 24.0–36.0sp");
					}
				} else {
					if (minSystemDistance < 12 || minSystemDistance > 16) styleComments.push("(Spacing tab) Set the ‘Min. system distance’ to between 12.0–14.0sp");
					if (maxSystemDistance < 24 || maxSystemDistance > 36) styleComments.push("(Spacing tab) Set the ‘Max. system distance’ to between 24.0–36.0sp");
				}
			}
			
			// *** CHECK STAFF SPACING *** //
			if (!isSoloScore) {
				if (enableVerticalSpread) {
					if (minStaffSpread < 5 || minStaffSpread > 6) styleComments.push("(Spacing tab) Set the ‘Min. staff distance’ to between 5.0–6.0sp");
					if (maxStaffSpread < 8 || maxStaffSpread > 10) styleComments.push("(Spacing tab) Set the ‘Max. staff distance’ to between 8.0–10.0sp");
				} else {
					if (staffDistance < 5 || staffDistance > 6) styleComments.push("(Spacing tab) Set the ‘Staff distance’ to between 5.0–6.0sp");
				}
			}
			
			if (minimumBarWidth < 14.0 || minimumBarWidth > 16.0) styleComments.push("(Spacing tab) Set ‘Horizontal Spacing→Minimum bar width’ to between 14.0-16.0sp");
			if (spacingRatio != 1.5) styleComments.push("(Spacing tab) Set ‘Horizontal Spacing→Spacing Ratio’ to 1.5sp");
			if (isSoloScore) {
				if (minNoteDistance < 1.0 ) styleComments.push("(Spacing tab) Increase ‘Padding→Note to Note’ to between 1.0–1.2sp");
				if (minNoteDistance > 1.2 ) styleComments.push("(Spacing tab) Decrease ‘Padding→Note to Note’ to between 1.0–1.2sp");
				
			} else {
				if (minNoteDistance < 0.6 ) styleComments.push("(Spacing tab) Increase ‘Padding→Note to Note’ to between 0.6–0.7sp");
				if (minNoteDistance > 0.7 ) styleComments.push("(Spacing tab) Decrease ‘Padding→Note to Note’ to between 0.6–0.7sp");
			}
			
			// *** CHECK LAST SYSTEM FILL THRESHOLD *** //
			if (lastSystemFillLimit > 0) styleComments.push("(Spacing tab) Set ‘Last system fill threshold’ to 0%");
			
			// ** CHECK MUSIC BOTTOM MARGIN — TO DO** //
			//if (staffLowerBorder > 0) styleComments.push("(Page tab) Set staff 5.0–6.0sp");
			
			// *************************************** //
			// ****        4. BAR NUMBERS TAB     **** //
			// *************************************** //
			if (showFirstBarNum) styleComments.push("(Bar numbers tab) Uncheck ‘Show first’");
			if (measureNumberPlacementMode != 0) styleComments.push("(Bar numbers tab) Set 'Position→Show' to 'Above system'");
			
			// *************************************** //
			// ****       5. BARLINES TAB        **** //
			// *************************************** //
			if (barlineWidth != 0.16) styleComments.push("(Barlines tab) Set ‘Thin barline thickness’ to 0.16sp");
			
			// *************************************** //
			// ****       6. RESTS TAB        **** //
			// *************************************** //
			if (mergeMatchingRests != 1) styleComments.push("(Rests tab) Check ‘Merge matching rests’");
			
			// *************************************** //
			// ****       17. SLURS & TIES        **** //
			// *************************************** //
			if (slurEndWidth != 0.06) styleComments.push("(Slurs &amp; Ties tab) Set ‘Slurs→Line thickness at end’ to 0.06sp");
			if (slurMidWidth != 0.16) styleComments.push("(Slurs &amp; Ties tab) Set ‘Slurs→Line thickness middle’ to 0.16sp");
			
			// *************************************** //
			// ****       18. LYRICS        	  **** //
			// *************************************** //
			if (lyricsMinDistance != 0.7 && isVocalScore) styleComments.push("(Lyrics tab) Set ‘Min. space between lyrics’ to 0.7sp");
			
			// *************************************** //
			// ****      20. TEXT STYLES TAB      **** //
			// *************************************** //
			if (tupletsFontFace !== "Times New Roman" && tupletsFontStyle != 2) styleComments.push("(Text Styles→Tuplet) Use Times New Roman italic for tuplets");
			if (tupletsFontFace !== "Times New Roman" && tupletsFontStyle == 2) styleComments.push("(Text Styles→Tuplet) Use Times New Roman for tuplets");
			if (tupletsFontFace === "Times New Roman" && tupletsFontStyle != 2) styleComments.push("(Text Styles→Tuplet) Use an italic font for tuplets");
			if (tupletsFontSize < 9 || tupletsFontSize > 11) styleComments.push("(Text Styles→Tuplet) Set tuplet font size to between 9–11pt");
			if (barNumberFontSize < 8.5 || barNumberFontSize > 11) styleComments.push("(Text Styles→Bar number) Set bar number font size to between 8.5–11pt");
			if (pageNumberFontStyle != 0 && numPagesOfMusic > 1) {
				var s = 'bold';
				if (pageNumberFontStyle > 1) s = 'italics';
				styleComments.push("(Text Styles→Page Number) Set the font style to plain (not "+s+")");
			}
			if (tempoFontStyle != 1) styleComments.push("(Text Styles→Tempo) Use a bold font style for tempo markings");
			if (metronomeFontStyle != 0) styleComments.push("(Text Styles→Metronome) Use a plain font style for metronome markings");
			if (rehearsalMarkFontSize != 14 && numRehearsalMarks > 0) styleComments.push("(Text Styles→Rehearsal Marks) Set rehearsal mark font size to 14pt");
			if (hasInstrumentChanges) {
				if (instrumentChangeFontStyle != 0) styleComments.push("(Text Styles→Instrument Change) Use a plain font style for instrument changes");
				if (instrumentChangeFrameType != 1) styleComments.push("(Text Styles→Instrument Change) Set Frame to ‘Rectangle’");
				if (instrumentChangeFramePadding != 0.4) styleComments.push("(Text Styles→Instrument Change) Set Frame Padding to 0.4");
			}
		}
		
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
			errorStr += "\n\nNOTE: the MN Make Recommended Layout Changes plugin can automatically change these settings for you."
			addError(errorStr,"pagetop");
		}
	}
	
	function checkLocationOfFinalBar () {
		var maxDistance = 25;
		var lastMeasure = curScore.lastMeasure;
		var loc = lastMeasure.pagePos;
		var rect = lastMeasure.bbox;
		var r = Math.round((loc.x + rect.width) * spatium);
		var b = Math.round((loc.y + rect.height) * spatium);
		var thresholdr = pageWidth - maxDistance;
		var thresholdb = pageHeight - maxDistance - 15;
		var checkBottom = true;
		
		// if this is a one-page composition, only check the right hand edge of the final system
		if (numPagesOfMusic == 1) checkBottom = false;
		
		// if there is only one staff, only check the right hand edge of the final system
		if (numStaves == 1) checkBottom = false;
		
		if (checkBottom && r < thresholdr && b < thresholdb ) {
			addError("Try and arrange the layout so that the final bar is\nin the bottom right-hand corner of the last page.",lastMeasure);
			return;
		}
		if (r < thresholdr) {
			addError("Try and arrange the layout so that the final bar aligns\nwith the right-hand margin of the page.",lastMeasure);
		}
	}
	
	function checkLocationsOfBottomSystems () {
		// get the pages of this score
		var pages = curScore.pages;
		var pageHeight = pages[0].bbox.height;
		var thresholdb = hasFooter? pageHeight * 0.6 : pageHeight * 0.8;
		for (var i = 0; i < pages.length; i++) {
			var thePage = pages[i];
			var systems = thePage.systems;
			if (systems != null) {
				var lastSystem = systems[systems.length-1];
				if (lastSystem.pagePos.y + lastSystem.bbox.height < thresholdb) addError ("This system should ideally be justified to the bottom of the page.",lastSystem.measures[0]);
			}
		}
	}
	
	// ***************************************************************** //
	// **** CHECK WHETHER THESE HAIRPINS ARE JUST SHORT EXPRESSIVE	**** //
	// **** 	SWELLS, AND THEREFORE DON’T REQUIRE TERMINATING		**** //
	// **** 		 DYNAMIC MARKINGS								**** //
	// ***************************************************************** //
	
	function checkExpressiveSwell (nextHairpin) {
		// *** checks if this hairpin is the start of an expressive swell *** //
		// There are 8 conditions to be met:
		
		// 1) we're not already in the middle of one
		if (expressiveSwell != 0) return;
		
		// 2) there is a hairpin coming up
		if (nextHairpin == null) return;
		
		// 3) the current hairpin is a crescendo
		if (currentHairpin.hairpinType % 2 != 0) return;
		
		// 4) the next hairpin is a decrescendo 
		if (nextHairpin.hairpinType %2 != 1) return;
		
		// 5) the current hairpin is short (bar length or less)		
		var hairpinDur = currentHairpin.spanner.spannerTicks.ticks;
		if (hairpinDur > barLength) return;
		
		// 6) the next hairpin is short (bar length or less)
		var nextHairpinDur = nextHairpin.spanner.spannerTicks.ticks;
		if (nextHairpinDur > barLength) return;
		
		// 7) the next hairpin starts within a bar length of the current hairpin's end
		var nextHairpinStart = nextHairpin.spanner.spannerTick.ticks;
		if (nextHairpinStart > currentHairpinEnd + barLength) return;
			
		// 8) there are no rests between the end of this hairpin and the start of the next
		var cursor2 = curScore.newCursor();

		cursor2.staffIdx = cursor.staffIdx;
		cursor2.track = cursor.track;
		cursor2.rewindToTick(currentHairpinEnd);
		cursor2.filter = Segment.ChordRest;
		
		while (cursor2 != null) {
			cursor2.next();
			if (cursor2.tick >= nextHairpinStart) break;
			if (cursor2 == null) return;
			if (cursor2.element == null) return;
			if (cursor2.element.type == Element.REST) return;
			if (cursor2.element.notes == null) return;
			if (cursor2.element.notes.length == 0) return;
		}
		
		// OK, so it's an expressive swell
		//logError ("expressive swell");
		expressiveSwell = 1;
	}
	
	// ***************************************************************** //
	// **** CHECK HAIRPINS FOR ANY GENERAL ISSUES, SUCH AS STARTING	**** //
	// **** 	UNDER A REST, MANUAL POSITIONING, AND TERMINATING	**** //
	// **** 							 DYNAMICS					**** //
	// ***************************************************************** //
	
	function checkHairpins () {
		
		// **** Hairpins cancel out previous dynamic for checking **** //
		prevDynamic = '';
		prevDynamicBarNum = currentBarNum;
		var hairpinStartTick = currentHairpin.spanner.spannerTick.ticks;		
		
		// **** Does the hairpin start under a rest? **** //
		var noteAtHairpinStart = getNoteRestAtTick(hairpinStartTick);
		var hairpinStartsOnRest = (noteAtHairpinStart == null) ? true : noteAtHairpinStart.type == Element.REST;
		//logError ('hairpinStartsOnRest = '+hairpinStartsOnRest+'; noteAtHairpinStart = '+noteAtHairpinStart);
		if (hairpinStartsOnRest && !isGrandStaff[cursor.staffIdx]) addError ("This hairpin appears to start under a rest.\nAlways start hairpins under notes.",currentHairpin);		
		var startOffset = Math.abs(currentHairpin.offset.x);
		var endOffset = currentHairpin.userOff2.x;
		//logError ("off: "+startOffset+" "+endOffset);
		var m = 1.0;
		if (startOffset >= m && endOffset < m) addError ("This hairpin’s start has been moved from the default.\nThis may result in poor positioning if bars are resized.\nSelect the hairpin and press "+cmdKey+"-R.",currentHairpin);
		if (startOffset < m && endOffset >= m) addError ("This hairpin’s end has been moved from the default.\nThis may result in poor positioning if bars are resized.\nSelect the hairpin and press "+cmdKey+"-R.",currentHairpin);
		if (startOffset >= m && endOffset >= m) addError ("This hairpin’s start &amp; end have been moved from the default.\nThis may result in poor positioning if bars are resized.\nSelect the hairpin and press "+cmdKey+"-R.",currentHairpin);
		
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = cursor.staffIdx;
		cursor2.track = cursor.track;
		cursor2.rewindToTick(cursor.tick);
		cursor2.filter = Segment.ChordRest;
		var isDecresc = currentHairpin.hairpinType %2 == 1;
		var hairpinZoneEndTick = currentHairpinEnd + beatLength; // allow a terminating dynamic within a beat of the end of the hairpin
		var hairpinZoneStartTick = currentHairpinEnd - beatLength;
		//logError ("Checking hairpin termination");
		
		// allow an expressive swell
		if (expressiveSwell > 0) return;
		
		// allow a terminating decrescendo on the last bar
		if (isDecresc && currentBarNum == numBars) return;
		
		// cycle through the dynamics in the staff, looking to see whether there is one near the end of the hairpin
		for (var i = 0;i < dynamics[currentStaffNum].length; i++) {
			var dynamicTick = dynamics[currentStaffNum][i].parent.tick;
			if (dynamicTick >= hairpinZoneStartTick && dynamicTick <= hairpinZoneEndTick) return;
		}
				
		// allow a decrescendo going to a rest without needing a terminating dynamic
		if (isDecresc) {
			while (cursor2 != null) {
				cursor2.next();
				if (cursor2 == null) return;
				if (cursor2.element == null) return;
				if (cursor2.tick >= currentHairpinEnd) break;
			}
			if (cursor2.element.notes == null) return;
			if (cursor2.element.notes.length == 0) return;
		}
		addError ("This hairpin should have a dynamic at the end,\nor end should be closer to the next dynamic.", currentHairpin);
	}
	
	// ***************************************************************** //
	// **** 														**** //
	// **** 			CHECK FERMATAS FOR VARIOUS ISSUES		 	**** //
	// **** 														**** //
	// ***************************************************************** //
	
	function checkFermata (noteRest) {
		isFermata = false;
		if (isNote || isRest) {
			var theSeg = noteRest.parent;
			while (theSeg.type != Element.SEGMENT) {
				theSeg = theSeg.parent;
				if (theSeg == undefined || theSeg == null) return;
			}
			var theAnnotations = theSeg.annotations;
			if (theAnnotations != null) {
				var n = theAnnotations.length;
				for (var i = 0; i < n; i++) {
					var theElem = theAnnotations[i];
					if (theElem.type == Element.FERMATA) {
						isFermata = true;
						return;
					}
				}
			}
		}
	}
	
	// ********************************************************************* //
	// **** 															**** //
	// **** 	CHECK (NON-STACCATO) ARTICULATION FOR VARIOUS ISSUES	**** //
	// **** 															**** //
	// ********************************************************************* //
	
	function checkArticulation (noteRest, theArticulationArray) {
		
		var numArtic = theArticulationArray.length;
		
		for (var i = 0; i < numArtic; i++) {
			var theArticulation = theArticulationArray[i];
			if (theArticulation.visible) {
				var theSymbol = theArticulation.symbol;
				
				// CHECK USE OF WIGGLE VIBRATO
				if (theSymbol >= SymId.wiggleVibrato && theSymbol <= SymId.wiggleWavyWide) {
					addError ("These vibrato articulations are non-standard.\nIt’s usually better to just write (e.g.)\n‘molto vib.’ or ‘slow, wide vibrato’.", theArticulation);
					continue;
				}
				
				// CHECK FOR UPBOW/DOWNBOW MARKINGS IN NON-STRING INSTRUMENTS
				var hasBowMarking = stringArticulationsArray.includes(theSymbol);
				if (hasBowMarking) {
					if (!isStringInstrument) {
						addError ('This is a string articulation, but this is not a string instrument.', theArticulation);
					} else {
						var prevNoteHasBowMarking = false;
						var nextNoteHasBowMarking = false;
						var prevNote = getPreviousNoteRest(noteRest);
						var nextNote = getNextNoteRest(noteRest);
						if (prevNote) {
							var prevNoteArticulationArray = getArticulations(prevNote);
							if (prevNoteArticulationArray.length > 0) {
								for (var j = 0; j < prevNoteArticulationArray.length && !prevNoteHasBowMarking ; j++) {
									prevNoteHasBowMarking = stringArticulationsArray.includes (prevNoteArticulationArray[j].symbol);
								}
							}
						}
						if (nextNote) {	
							var nextNoteArticulationArray = getArticulations(nextNote);
							if (nextNoteArticulationArray.length > 0) {	
								for (var j = 0; j < nextNoteArticulationArray.length && !nextNoteHasBowMarking ; j++) {
									nextNoteHasBowMarking = stringArticulationsArray.includes (nextNoteArticulationArray[j].symbol);
								}
							}
						}
						if (!prevNoteHasBowMarking && !nextNoteHasBowMarking) {
							addError ('Are you sure this isolated bow marking is necessary?\n(Only write bow markings that are required for a specific effect.)', theArticulation);
							return;
						}
					}	
				}
			}
		}	
	}

	
	function checkInstrumentalTechniques (textObject, plainText, lowerCaseText) {
		var isBracketed = lowerCaseText.substr(0,1) === "(";
		
		if (isRest) {
			for (var i = 0; i < techniques.length; i ++) {
				if (lowerCaseText.includes(techniques[i]) && !(lowerCaseText.includes('senza sord') || lowerCaseText.includes('via sord'))) {
					//logError ("textObj "+textObject.text);
					addError("Avoid putting techniques over rests if possible, though\nthis may sometimes be needed to save space.\n(See ‘Behind Bars’, p. 492).",textObject);
					break;
				}
			}
		}
		
		if (lowerCaseText.includes('vib.') || lowerCaseText.includes('vibr.')) {
			if (isWindOrBrassInstrument || isStringInstrument) {
				if ((isWindOrBrassInstrument && doCheckWindsAndBrass) || (isStringInstrument && doCheckStrings)) {
					if (lowerCaseText.includes ('con vib') || lowerCaseText.includes ('norm')) {
						if (currentVibrato === 'con') {
							addError ('This instrument already appears to be con vib?',textObject);
						} else {
							currentVibrato = 'con';
						}
					}
					if (lowerCaseText.includes ('senza vib')) {
						if (currentVibrato === 'senza') {
							addError ('This instrument already appears to be senza vib?',textObject);
						} else {
							currentVibrato = 'senza';
						}
					}
					if (lowerCaseText.includes ('molto vib')) {
						if (currentVibrato === 'molto') {
							addError ('This instrument already appears to be molto vib?',textObject);
						} else {
							currentVibrato = 'molto';
						}
					}
					if (lowerCaseText.includes ('slow vib') || lowerCaseText.includes ('wide vib')) {
						if (currentVibrato === 'wide') {
							addError ('This instrument already appears to be '+lowerCaseText+'?',textObject);
						} else {
							currentVibrato = 'wide';
						}
					}
				}
				
			} else {
				if (!isVibraphone) addError ("I’m not sure if this instrument can do vibrato.", textObject);
			}
		}
		
		if (isWindOrBrassInstrument && doCheckWindsAndBrass) {
			if (lowerCaseText.includes("tutti")) addError("Don’t use ‘Tutti’ for winds and brass;\nwrite ‘a 2’/‘a 3’ etc. instead.",textObject);
			if (lowerCaseText.includes("unis.")) addError("Don’t use ‘unis.’ for winds and brass;\nwrite ‘a 2’/‘a 3’ etc. instead.",textObject);
			if (lowerCaseText.includes("div.")) addError("Don’t use ‘div.’ for winds and brass.",textObject);
			
			if (lowerCaseText.substr(0,3) === "flz") {
				// check trem
				flzFound = true;
				if (!isTremolo) addError ("Fluttertongue notes should also have tremolo lines through the stem.",textObject);
			}
		}
		if (lowerCaseText === "arco") isArco = true;
		if (lowerCaseText === "ord." || lowerCaseText.includes("sticks") || lowerCaseText.includes("mallet")) isArco = false;
		
		if (isStringInstrument && doCheckStrings) {
			
			if (lowerCaseText === "détaché" || lowerCaseText === "detaché" || lowerCaseText === "detache") addError ("You don’t need to write ‘détaché’ here.\nA passage without slurs will be played détaché by default.",textObject);
			
			//errorMsg += "IsString: checking "+lowerCaseText;
			// **** CHECK INCORRECT 'A 2 / A 3' MARKINGS **** //
			if (lowerCaseText === "a 2" || lowerCaseText === "a 3") {
				addError("Don’t use ‘"+lowerCaseText+"’ for strings; write ‘unis.’ etc. instead.",textObject);
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
			if (lowerCaseText.substr(0,5) === "(ord." ) {
				if (currentContactPoint != "ord") addError ("This looks like it’s an indication to change to ord.\nIf so, you don’t need the parentheses.",textObject)
			}
			if (lowerCaseText.substr(0,4) === "ord." || lowerCaseText === "pos. nat.") {
				if (currentContactPoint === "ord" && (currentPlayingTechnique === "arco" || currentPlayingTechnique === "pizz")) {
					if (currentVibrato != 'con') {
						addError("Instrument is already playing ord?\nIs that meant to refer to the vibrato (i.e. vib. norm.?)",textObject);
					} else {
						addError("Instrument is already playing ord?",textObject);
					}
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
			//logError ('checking lowerCaseText: '+lowerCaseText);
			if (lowerCaseText.includes("tasto") || lowerCaseText.includes("s.t") || lowerCaseText.includes("pst") || lowerCaseText.includes("mst")) {
				if (lowerCaseText.includes("poco sul tasto") || lowerCaseText.includes("p.s.t") || lowerCaseText.includes("pst")) {
					
					if (currentContactPoint === "pst") {
						if (!isBracketed) addError("Instrument is already playing poco sul tasto?",textObject);
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
						if (haveHadPlayingIndication || !isFirstNote) {
							addError("Instrument is already playing arco?",textObject);
						} else {
							addError("It’s not necessary to mark ‘arco’, as this is the default.",textObject);
						}
					}
				} else {
					if (isBracketed) addError ("This looks like a change to arco.\nYou don’t need the parentheses around the technique.",textObject);
					if (currentPlayingTechnique === "lhpizz") addError ("It’s not necessary to indicate ‘arco’\nafter a left-hand pizz.", textObject);	

					currentPlayingTechnique = "arco";
				}
			}
			
			// **** CHECK ALREADY PLAYING PIZZ **** //
			if (lowerCaseText.includes("pizz")) {
				if (lowerCaseText.includes ('l.h.') || lowerCaseText.includes ('left hand') || lowerCaseText.includes ('l. h.')) {
					addError ('You can indicate a left-hand pizz. using\njust a ‘+’ articulation above the notehead',textObject);
					currentPlayingTechnique = "lhpizz";	
				}  else {
					if (currentPlayingTechnique === "pizz") {
						if (!isBracketed) {
							addError("Instrument is already playing pizz?",textObject);
						}
					} else {
						if (isBracketed) addError ("This looks like a change to pizz.\nYou don’t need the parentheses around the technique.",textObject);
						currentPlayingTechnique = "pizz";
						haveHadPlayingIndication = true;
					}
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
			if (lowerCaseText.includes("col legno") || lowerCaseText.includes("c.l.") || lowerCaseText.includes("clb") || lowerCaseText.includes("clt") || lowerCaseText.includes("c. l.")) {
				if (lowerCaseText.includes("batt") || lowerCaseText.includes("c.l.b") || lowerCaseText.includes("clb") || lowerCaseText.includes("c. l. b")) {
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
					if (lowerCaseText.includes("tratto") || lowerCaseText.includes("c.l.t") || lowerCaseText.includes("clt") || lowerCaseText.includes("c. l. t")) {
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
						addError("You should specify if this is\ncol legno batt. or col legno tratto.",textObject);
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
		if ((isWindOrBrassInstrument && doCheckWindsAndBrass) || (isStringInstrument && doCheckStrings)) {
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
	}
	
	function checkClef (clef) {
		if (clef == null) {
			logError("checkClef() — clef is null!");
			return;
		}
		var clefType = clef.transposingClefType;
		var clefSegment = clef.parent;
		var clefTick = clefSegment.tick;
		var clefMeasure = clefSegment.parent;
		var clefMeasureStart = clefMeasure.firstSegment.tick;
		isEndOfBarClef = false;
		isMidBarClef = false;
		if (clefTick == clefMeasure.lastSegment.tick) {
			clefMeasure = clefMeasure.nextMeasure;
			isEndOfBarClef = true;
		} else {
			if (clefTick > clefMeasureStart) {
				isMidBarClef = true;
				if ((clefTick - clefMeasureStart) % beatLength != 0) {
					addError ('If possible, move this clef to the start of the beat.',clef);
				}
			}
		}
			
		//logError ('clefType = '+clefType+'; prevClefType = '+clefType);
		if (clefType == prevClefType && !clef.isHeader) {
			var clefId = clef.subtypeName();
			addError("This clef is redundant: already was "+clefId.toLowerCase()+".\nIt can be safely deleted.",clef);
		}

		setClef (clef);
		
		// *** CHECK LOCATION OF CLEFS *** //
	}
	
	function setClef (clef) {
		var trebleClefs = [ClefType.G, ClefType.G15_MB, ClefType.G8_VB, ClefType.G8_VA, ClefType.G15_MA, ClefType.G8_VB_O, ClefType.G8_VB_P,ClefType.G_1];
		var bassClefs = [ClefType.F,ClefType.F15_MB,ClefType.F8_VB,ClefType.F_8VA,ClefType.F_15MA,ClefType.F_B,ClefType.F_C,ClefType.F_F18C,ClefType.F_19C];
		var ottavaClefs = [ClefType.G8_VA,ClefType.F_8VA];
		var quintissimaClefs = [ClefType.G15_MA, ClefType.F_15MA];
		var ottavaBassaClefs = [ClefType.G8_VB_P,ClefType.F8_VB,ClefType.C4_8VB];
		var quintissimaBassaClefs = [ClefType.G15_MB, ClefType.F15_MB];
		
		var clefType = clef.transposingClefType;
		isTrebleClef = trebleClefs.includes(clefType);
		isAltoClef = clefType == ClefType.C3;
		isTenorClef = clefType == ClefType.C4;
		isBassClef = bassClefs.includes(clefType);
		isPercClef = clefType == ClefType.PERC || clefType == ClefType.PERC2;
		
		// CHECK FOR 8va etc.
		var clefIs8va = ottavaClefs.includes(clefType);
		var clefIs15ma = quintissimaClefs.includes(clefType);
		var clefIs8ba = ottavaBassaClefs.includes(clefType);
		var clefIs15mb = quintissimaBassaClefs.includes(clefType);

		diatonicPitchOfMiddleLine = 41; // B4 = 41 in diatonic pitch notation (where C4 = 35)
		if (isAltoClef) diatonicPitchOfMiddleLine = 35; // C4 = 35
		if (isTenorClef) diatonicPitchOfMiddleLine = 33; // A3 = 33
		if (isBassClef) diatonicPitchOfMiddleLine = 29; // D3 = 29
		if (clefIs8va) diatonicPitchOfMiddleLine += 7;
		if (clefIs15ma) diatonicPitchOfMiddleLine += 14;
		if (clefIs8ba) diatonicPitchOfMiddleLine -= 7;
		if (clefIs15mb) diatonicPitchOfMiddleLine -= 14;
		prevClefType = clefType;
		
		// **** CHECK FOR INAPPROPRIATE CLEFS **** //
		if (checkInstrumentClefs) {
			if (clefIs8va && !isPiano) 	addError ('This 8va clef is rarely used.\nAre you sure that’s right?', clef);
			if (clefIs15ma) addError ('Don’t use a 15ma clef.\nUse a 15ma symbol instead.', clef);
			if (clefIs8ba) {
				if (isTrebleClef && !isGuitar && !isVoice) addError ('This 8ba clef is rarely used.\nAre you sure that’s right?', clef);
				if (isBassClef) addError ('Don’t use an octave-transposing bass clef.\nUse an 8ba symbol instead.',clef);
			}
			if (clefIs15mb) addError ('Don’t use a 15mb clef.\nUse a 15mb symbol instead.', clef);
			if (isTrombone && isTrebleClef) {
				addError (currentInstrumentName + " almost never reads treble clef unless\nthis is British brass band music, where treble clef is transposing.\nConsider changing to tenor clef, unless this is intended to be super-high.",clef);
			} else {
				if (isTrebleClef && !readsTreble) addError(currentInstrumentName+" doesn’t read treble clef.",clef);
				if (isAltoClef && !readsAlto) addError(currentInstrumentName+" doesn’t read alto clef.",clef);
				if (isTenorClef && !readsTenor) addError(currentInstrumentName+" doesn’t read tenor clef.",clef);
				if (isBassClef && !readsBass) addError(currentInstrumentName+" doesn’t read bass clef.",clef);
			}
			if (!clef.isHeader && (isMarimba || isHarp || isVibraphone)) addError (currentInstrumentName+" prefers not to have clef changes, if possible.\nConsider moving this material to the other staff to avoid clef changes,\nunless this clef change makes the music easier to read.",clef);
		}
	}
	
	function checkTrill () {
		// wait until MS 4.6.?
		//logError ('Found trill: '+currentTrill+'; type = '+currentTrill.type);
		/*if (noteRest.articulations.length > 0) {
			logError ('Artic = '+noteRest.articulations[0].type);
		}*/
		//logError ('Found trill: psanner = '+currentTrill.spanner+'; orn = '+currentTrill.spanner.ornament);	

		//logError ('Found trill: show acc = '+currentTrill.spanner.ornamentShowAccidental+'; show cue = '+currentTrill.spanner.showCueNote);	
	}
	
	function checkOttava (noteRest,ottava) {
		if (flaggedOttavaIssue) return;
		if (ottava == null) {
			logError("checkOttava() — ottava is null!");
			return;
		}
		// don't flag 22ma and 22mb here, as they will already have been flagged previously
		if (ottava.ottavaType == OttavaType.OTTAVA_22MA || ottava.ottavaType == OttavaType.OTTAVA_22MB) return;
		numNotesUnderOttava++;
		var numll = getMaxNumLedgerLines(noteRest);
		if (numll > maxOttavaLedgerLines) maxOttavaLedgerLines == numll;
		averageOttavaLedgerLines = (averageOttavaLedgerLines * (numNotesUnderOttava - 1) + numll) / numNotesUnderOttava;
		var ottavaArray = ["8va","8ba","15ma","15mb"];
		var ottavaStr = ottavaArray[ottava.ottavaType]; 
		//logError("Found OTTAVA: "+ottava.subtypeName()+" "+ottava.ottavaType);
		if (!reads8va) {
			addError("This instrument does not normally read "+ottavaStr+" lines.\nIt’s best to write the note(s) out at pitch.",ottava);
			flaggedOttavaIssue = true;
			
		} else {
			if (ottava.ottavaType == OttavaType.OTTAVA_8VA || ottava.ottavaType == OttavaType.OTTAVA_15MA) {
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
		if (!flaggedOttavaIssue) {
			var endNote = noteRest.notes[0].lastTiedNote;
			var endTick = endNote.parent.fraction.ticks + endNote.parent.duration.ticks;
			
			//logError ('lastTIedNote = '+endNote+' endTick='+endTick);
			if (endTick >= currentOttavaEnd) {
				if (numNotesUnderOttava > 0 && currentOttava != null && isTrebleClef) {
					if (currentOttava.ottavaType == OttavaType.OTTAVA_8VA || currentOttava.ottavaType == OttavaType.OTTAVA_15MA) {
						if (averageOttavaLedgerLines < 3 && maxOttavaLedgerLines < 4) addError ('The passage under this ottava doesn’t seem high enough to warrant an ottava.\nPerhaps it could be written at pitch?', currentOttava);
						flaggedOttavaIssue = true;
					} else {
						if ( averageOttavaLedgerLines > -3  && maxOttavaLedgerLines > -4) {
							addError ('The passage under this ottava doesn’t seem low enough to warrant an ottava.\nPerhaps it could be written at pitch?', currentOttava);
							flaggedOttavaIssue = true;
						}
					}
				}
				numNotesUnderOttava = 0;
				averageOttavaLedgerLines = 0;
				maxOttavaLedgerLines = 0;
			}
		}
	}
	
	function checkInstrumentRange(noteRest) {
		if (lowestPitchPossible == 0 && highestPitchPossible == 0) return;
		// the currentInstrumentRange array is formatted thus:
		//[instrumentId,lowestSoundingPitchPossible,quietRegisterThresholdPitch,highestSoundPitchPossible,highLoudRegisterThreshold,lowLoudRegisterThreshold] 
		var lowestPitch = getLowestConcertPitch(noteRest);
		var highestPitch = getHighestConcertPitch(noteRest);
		if (lowestPitchPossible > 0 && lowestPitch < lowestPitchPossible) {
			if (isBrassInstrument) {
				addError ('This note is very low and may not\nbe possible on this instrument.\nCheck with a player.',noteRest);
				return;
			} else {
				addError ('This note appears to be below the\nlowest note possible on this instrument.',noteRest);
				return;
			}
		}
		if (highestPitchPossible > 0 && highestPitch > highestPitchPossible) {
			if (isPercussionInstrument || isHarp || isKeyboardInstrument) {
				addError ('This note appears to be above the\nhighest note possible on this instrument.',noteRest);
				return;
			} else {
				addError ('This note is very high and may not\nbe possible on this instrument.\nCheck with a player.',noteRest);
				return;
			}
		}
		if (quietRegisterThresholdPitch > 0) {
			if (lowestPitch <= quietRegisterThresholdPitch && currDynamicLevel > 3 && lastDynamicFlagBar < currentBarNum - 4) {
				//logError ("quietRegisterPitch = "+quietRegisterThresholdPitch+" currDynamicLevel = "+currDynamicLevel);
				lastDynamicFlagBar = currentBarNum;
				addError ('This note is quite low and may not\nbe able to be played at the indicated dynamic.',noteRest);
				return;
			}
		}
		if (highLoudRegisterThresholdPitch > 0) {
			if (highestPitch >= highLoudRegisterThresholdPitch && currDynamicLevel < 2 && lastDynamicFlagBar < currentBarNum - 4) {
				lastDynamicFlagBar = currentBarNum;
				addError ('This note is quite high and may not\nbe able to be played at the indicated dynamic.',noteRest);
				return;
			}
		}
		if (lowLoudRegisterThresholdPitch > 0) {
			if (lowestPitch <= lowLoudRegisterThresholdPitch && currDynamicLevel < 2 && lastDynamicFlagBar < currentBarNum - 4) {
				//logError ("lowLoudRegisterThresholdPitch = "+lowLoudRegisterThresholdPitch+" currDynamicLevel = "+currDynamicLevel);
				lastDynamicFlagBar = currentBarNum;
				addError ('This note is quite low and may not\nbe able to be played at the indicated dynamic.',noteRest);
				return;
			}
		}
	}
	
	function getLowestConcertPitch(chord) {
		return Math.min(chord.notes.map (e => e.pitch ));
	}
	
	function getHighestConcertPitch(chord) {
		return Math.max(chord.notes.map (e => e.pitch ));
	}
	
	function checkScoreText() {
		currentBarNum = 0;
		var hasTitleOnFirstPageOfMusic = false;
		var hasSubtitleOnFirstPageOfMusic = false;
		var hasComposerOnFirstPageOfMusic = false;
		hasFooter = false;
		var threshold = firstPageHeight*0.7;

		for (var i = 0; i < frames.length; i++) {
			var frame = frames[i];
			var elems = frame.elements;
			for (var j = 0; j < elems.length; j++) {
				var e = elems[j];
				if (e.type == Element.TEXT) {
					//logError ("Found text object in frame: "+e.text);
					var textStyle = e.subStyle;
					if (textStyle != Tid.TUPLET) {
						if (frame.pagePos.y > threshold) hasFooter = true;
						checkTextObject (e);
					}
					if (textStyle == Tid.TITLE) {
						if (getPageNumber(e) == firstPageOfMusicNum) hasTitleOnFirstPageOfMusic = true;
					}
					if (textStyle == Tid.SUBTITLE) {
						if (getPageNumber(e) == firstPageOfMusicNum) hasSubtitleOnFirstPageOfMusic = true;
					}
					if (textStyle == Tid.COMPOSER) {
						if (getPageNumber(e) == firstPageOfMusicNum) hasComposerOnFirstPageOfMusic = true;
					}
				}
			}
		}

		if (!hasTitleOnFirstPageOfMusic) addError ("It doesn’t look like you have the title\nat the top of the first page of music.\n(See ‘Behind Bars’, p. 504)","pagetop");
		if (isSoloScore && !hasSubtitleOnFirstPageOfMusic)  addError ("It doesn’t look like you have a subtitle with the name of the solo instrument\nat the top of the first page of music. (See ‘Behind Bars’, p. 504)","pagetop");
		if (!hasComposerOnFirstPageOfMusic) addError ("It doesn’t look like you have the composer’s name\nat the top of the first page of music.\n(See ‘Behind Bars’, p. 504)","pagetop");
	}
	
	function checkTextObject (textObject) {

		if (!textObject.visible) return;
		
		var windAndBrassMarkings = ["1.","2.","3.","4.","5.","6.","7.","8.","a2", "a 2","a3", "a 3","a4", "a 4","a5", "a 5","a6", "a 6","a7","a 7","a8","a 8","solo","1. solo","2. solo","3. solo","4. solo","5. solo","6. solo","7. solo","8. solo"];
		var replacements = ["accidentalNatural","n","accidentalSharp","#","accidentalFlat","b","metNoteHalfUp","h","metNoteQuarterUp","q","metNote8thUp","e","metNote16thUp","s","metAugmentationDot",".","dynamicForte","f","dynamicMezzo","m","dynamicPiano","p","dynamicRinforzando","r","dynamicSubito","s","dynamicSforzando","s","dynamicZ","z","dynamicNiente", "n", "","p","","ppp","","pp","","mp","","mf","","f","","ff","","fff","","sf","","sfz","","sffz","","z","","n","&nbsp;"," "," "," "];
		
		var elementType = textObject.type;
		var isTempoChangeElement = elementType == Element.GRADUAL_TEMPO_CHANGE || elementType == Element.GRADUAL_TEMPO_CHANGE_SEGMENT;
		//if (isTempoChangeElement) logError ('isTempoChangeElement');
		var textStyle = textObject.subStyle;
		
		// don't bother looking for certain textstyles
		if (textStyle == Tid.TUPLET || textStyle == Tid.ARTICULATION || textStyle == Tid.STICKING || textStyle == Tid.FINGERING) return;
		var isTitleTextStyle = textStyle == Tid.TITLE;
		var isSubtitleTextStyle = textStyle == Tid.SUBTITLE;
		var isComposerTextStyle = textStyle == Tid.COMPOSER;
		var isTempoTextStyle = textStyle == Tid.TEMPO;
		var isMetronomeTextStyle = textStyle == Tid.METRONOME;
		var nonBoldText = '', boldText = '';
		var elemPage = getPage(textObject);
		
		// if there's no text available, then bail
		var styledText = isTempoChangeElement ? textObject.beginText : textObject.text;
		if (styledText == undefined || styledText == null) {
			logError ("checkTextObject() — styledText is "+styledText);
			return;
		}
		//logError ('styledText = "'+styledText.replace(/</g,'≤')+'"');
		
		// if it's a rehearsal mark, we can just check it, then bail
		if (textStyle == Tid.REHEARSAL_MARK) {
			checkRehearsalMark (textObject);
			return;
		}
		
		// ** CHECK IT'S NOT A COMMENT WE'VE ADDED ** //
		if (elementType == Element.TEXT) {
			if (Qt.colorEqual(textObject.frameBgColor,"yellow") && Qt.colorEqual(textObject.frameFgColor,"black")) return;
		}
		
		var tn = textObject.name.toLowerCase();
		
		// remove all tags
		var plainTextWithSymbols = styledText.replace(/<[^>]+>/g, "");
		var plainText = plainTextWithSymbols;
		if (typeof plainText != 'string') logError('checkTextObject() — Typeof plainText not string: '+(typeof plainText));
		for (var i = 0; i < replacements.length; i += 2) {
			var regex1 = new RegExp(replacements[i],"g");
			plainText = plainText.replace(regex1,replacements[i+1]);
		}
		
		var lowerCaseText = plainText.toLowerCase();
		
		if (lowerCaseText != '') {

			// ** CHECK TITLE ** //
			if (isTitleTextStyle && plainText === "Untitled score") addError("You have not changed the default title text.", textObject);
			
			// ** CHECK SUBTITLE ** //
			if (isSubtitleTextStyle) {
				if (plainText === "Subtitle") addError( "You have not changed the default subtitle text.", textObject);
				
				// check if the subtitle is lower-case
				// the only exception is SATB-like choral descriptions (SSA, TTBB, etc.)
				if (plainText != lowerCaseText && lowerCaseText.substr(0,4) === "for " && lowerCaseText.length < 20) {
					var isSATB = plainText.match(/\b(S*A*T*B*)\b/) != null;
					if (!isSATB) addError( "The subtitle can be all lower-case, unless it includes people’s names.", textObject);
				}
				if (elemPage !== null) {
					if (hasTitlePage && lowerCaseText.substr(0,3) === 'for' && elemPage.pagenumber == firstPageOfMusicNum) addError ( "If you have a title page that lists the forces/instrumentation,\nyou don’t need to repeat them on the first page of music.", textObject);
				}
			}
			
			// ** CHECK COMPOSER ** //
			if (isComposerTextStyle) {
				if (plainText === "Composer / arranger") addError( "You have not changed the default composer text.", textObject);
				if (plainText.substring(0,3).toLocaleLowerCase() === "by ") addError ("You don’t need ‘by’ at the start", textObject);
				if (plainText.substring(0,11).toLocaleLowerCase() === "composed by") addError ("You don’t need ‘Composed by’ at the start of this text", textObject);
				if (elemPage != null) {
					if (elemPage.pagenumber == firstPageOfMusicNum) { 
						// check to see whether the composer text is upper or lower case
						var upperCaseText = plainText.toLocaleUpperCase();
						var keepLowerCase = ["arr. ", "by ", "arranged ", "orch. ", "orchestrated "];
						for (var i=0; i<keepLowerCase.length; i++) {
							if (plainText.includes(keepLowerCase[i])) {
								upperCaseText = upperCaseText.replace(keepLowerCase[i].toLocaleUpperCase(),keepLowerCase[i]);
							}
						}
						if (plainText !== upperCaseText) addError ("(Optional) A common house style is to have composer names in all caps.\n(See ‘Behind Bars’, p. 504)", textObject);
					}
				}
			}
			
			// **** CHECK IF THIS IS A WOODWIND OR BRASS MARKING **** //
			// **** WE CHECK THIS FIRST BECAUSE WE ALLOW A FEW COMMON MISSPELLINGS **** //
			if (windAndBrassMarkings.includes(lowerCaseText) && isWindOrBrassInstrument) {
				weKnowWhosPlaying = true;
				flaggedWeKnowWhosPlaying = false;
			}
			
			// ***************************************************** //
			// ****		ANALYSE METRONOME & TEMPO MARKINGS		**** //
			// ***************************************************** //
			var containsMetronomeComponent = false;
			var containsTempoComponent = false;
			var containsTempoChangeComponent = isTempoChangeElement;
			var resetTempo = false;
			var metronomeComponent = '', nonMetronomeComponent = '', augDotComponent = '';
			
			// ** THIS REGEX ATTEMPTS TO MATCH ALL POSSIBLE PERMUTATIONS OF A METRONOME MARKING **//
			// ** NB — DON'T CHANGE THIS WITHOUT CHECKING THAT THE AUGMENTATION DOT CAPTURE GROUP IS CORRECT **
			// ** THIS IS THE INDEX OF THE CAPTURE GROUP (\.|<sym>metAugmentationDot<\/sym>|\uECB7) ** //
			var metronomeComponentRegex = new RegExp( /(<b>)?\(?(<\/?b>|c|approx|circa|\.|\s)*(<sym>metNote.*?<\/sym>|\uECA5|\uECA7|\uECA3)(\.|<sym>metAugmentationDot<\/sym>|\uECB7)?(<font.*?>.*?<\/font>|<font.*\/>|<b>|<\/b>)*(\s|\u00A0|\u2009)*=(\s|\u00A0|\u2009|<b>|<\/b>)*(c|approx|circa)?\.?(\s|<b>|<\/b>)*[0-9–\-—]*(<b>|<\/b>)*\)?/);
			var augDotCaptureGroup = 4;
			
			if (currentBarNum > 0) {
				// **** CHECK TO SEE IF THIS CONTAINS A METRONOME MARKING **** //
				if (plainText.includes("=")) {
					var theMatch = styledText.match(metronomeComponentRegex);
					containsMetronomeComponent = theMatch != null;
					if (containsMetronomeComponent) {
						metronomeComponent = theMatch[0].replace(/<\/*b>/g,'');
						//logError ('metroComponent = '+metronomeComponent.replace(/</g,'≤'));
						if (theMatch[augDotCaptureGroup] != undefined) {
							augDotComponent = theMatch[augDotCaptureGroup];
							//logError ('augDotComponent = '+augDotComponent+' '+augDotComponent.length);
						}
					}
					//logError ('styledText = '+styledText.replace(/</g,'≤')+'; containsMetronomeComponent = '+containsMetronomeComponent+'; metronomeComponent = '+metronomeComponent.replace(/</g,'≤'));
				}
				
				// **** CHECK TO SEE IF THIS CONTAINS A TEMPO MARKING COMPONENT **** //
				if (!lowerCaseText.includes('trill') && !lowerCaseText.includes('trem')) {
					for (var j = 0; j < tempomarkings.length && !containsTempoComponent; j++) {
						if (lowerCaseText.includes(tempomarkings[j])) containsTempoComponent = true;
					}
				}
				// if it doesn't contain a standard tempo marking, we then check to see whether there's any
				// non-metronome component (only if it's in a tempo text style)
				if (!containsTempoComponent && isTempoTextStyle) {
					nonMetronomeComponent = textObject.text.replace(metronomeComponentRegex,'');
					// delete any basic HTML tags — <b> <font> <i>
					//logError ('nonMetroComp before replace = '+nonMetronomeComponent.trim().replace(/</g,'≤'));
					nonMetronomeComponent = nonMetronomeComponent.replace(/<\/*(b|font|i)+[^>]*>/g,'');
					if (nonMetronomeComponent.trim() !== '') {
						containsTempoComponent = true;
						//logError ('Found residual text after replacing metronome: '+nonMetronomeComponent.trim().replace(/</g,'≤'));
					}
				}
							
				// **** CHECK TO SEE IF THIS CONTAINS A TEMPO CHANGE ELEMENT **** //
				if (!isTempoChangeElement && !lowerCaseText.includes('trill') && !lowerCaseText.includes('trem')) {
					for (var i = 0; i < tempochangemarkings.length && !containsTempoChangeComponent; i++) if (lowerCaseText.includes(tempochangemarkings[i])) containsTempoChangeComponent = true;
				}
			}
			
			// ***************************************************** //
			// ****		CHECK SPELLING AND FORMAT ERRORS		**** //
			// ***************************************************** //

			// **** CHECK FOR STRAIGHT QUOTES THAT SHOULD BE CURLY **** //
			if (doCheckSpellingAndFormat) {
				if (lowerCaseText.includes("'")) addError("This text has a straight single quote mark in it (').\nChange to curly: ‘ or ’.", textObject);	
				if (lowerCaseText.includes('"')) addError('This text has a straight double quote mark in it (").\nChange to curly: “ or ”.', textObject);

				// **** CHECK FOR TEXT STARTING WITH SPACE OR NON-ALPHANUMERIC **** //
				var c = plainText.charCodeAt(0);
				if (c == 32) addError("‘"+plainText+"’ begins with a space, which could be deleted.", textObject);
				if (c < 32 && c != 10 && c != 13) addError("‘"+plainText+"’ does not seem to begin with a letter: is that correct?" ,textObject);

				// **** CHECK COMMON SPELLING ERRORS & ABBREVIATIONS **** //
				var isSpellingError = false;
				for (var i = 0; i < spellingerrorsatstart.length / 2; i++) {
					var spellingError = spellingerrorsatstart[i*2];
					if (lowerCaseText.substr(0,spellingError.length) === spellingError) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsatstart[i*2+1];
						var diff = plainText.length-spellingError.length;
						var correctText = (diff > 0) ? correctSpelling+plainText.substr(spellingError.length) : correctSpelling;
						if (plainText.length > 50) {
							addError("This text includes the following misspelling: "+spellingError+";\nit should be ‘"+correctSpelling+"’.",textObject);
						} else {
							addError("‘"+plainText+"’ contains a misspelling;\nit should be ‘"+correctText+"’.",textObject);
						}
						return;
					}
				}

				// **** CHECK TEXT WITH SPELLING ERRORS ANYWHERE **** //
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
					if (isSpellingError) {
						if (plainText.length > 50) {
							addError("This text includes the following misspelling: "+spellingError+";\nit should be ‘"+correctSpelling+"’.", textObject);
						} else {
							addError("‘"+plainText+"’ contains a misspelling;\nit should be ‘"+correctText+"’.", textObject);
						}
					}
				}
				
				// **** CHECK Brass, Strings, Winds, Percussion **** //
				var dontCap = ["Brass","Strings","Winds","Woodwinds","Percussion"];
				if (!isTitleTextStyle && !isSubtitleTextStyle) {
					for (var i = 0; i < dontCap.length; i++) {
						var theWord = dontCap[i];
						var l = theWord.length;
						if (lowerCaseText.substr(0,l) === theWord && plainText.substr(0,l) !== theWord) {
							addError ( "‘"+theWord+"’ can be lower-case.", textObject);
							return;
						}
					}
				}
				
				// **** CHECK A 1 **** //
				if (lowerCaseText === 'a 1' || lowerCaseText === 'a. 1' || lowerCaseText === 'a.1') addError ("Never write ‘"+lowerCaseText+"’ to indicate the first player.\nYou should just write ‘1.’.", textObject);
				
				// **** CHECK VIB **** //
				if (!isTitleTextStyle && !isSubtitleTextStyle && isStringInstrument) {
					if (lowerCaseText === 'vib' || lowerCaseText === 'vib.' || lowerCaseText === 'vibr.' || lowerCaseText === 'vibrato') addError ("This indication is a little ambiguous.\nDo you mean ‘vib. norm.’?", textObject);
				}
				
				// **** CHECK SUL CAPITALISATION **** //
				if (lowerCaseText.includes('sul ') && lowerCaseText.length == 5) {
					if (lowerCaseText === plainText) addError ("Capitalise the string name (i.e. ‘sul "+lowerCaseText.substring(4).toUpperCase()+"’)", textObject);
				}
				
				// **** CHECK TEXT THAT IS INCORRECTLY CAPITALISED **** //
				// but don't check title/composer etc
				if (!isTitleTextStyle && !isSubtitleTextStyle && !isComposerTextStyle && !containsTempoComponent) {
					//logError ('checking lower case text: '+plainText);
					for (var i = 0; i < shouldbelowercase.length; i++) {
						var lowercaseMarking = shouldbelowercase[i];
						var r = new RegExp ('\\b'+lowercaseMarking+'\\b');
						var theMatch = lowerCaseText.match(r);
						if (theMatch != null) {
							var theIndex = theMatch.index;
							if (plainText.substr(theIndex,1) !== lowerCaseText.substr(theIndex,1)) {
								//logError ('lowercaseMarking = '+lowercaseMarking+' theIndex = '+theIndex+' ps = '+plainText.substr(theIndex,1)+' lcs = '+lowerCaseText.substr(theIndex,1));
								addError("‘"+lowercaseMarking+"’ should not have a capital first letter.",textObject);
								return;
							}
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
				if (!isSpellingError && !isTitleTextStyle && !isSubtitleTextStyle && !containsTempoComponent) {
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
				if (lowerCaseText === "mute" || lowerCaseText === "with mute" || lowerCaseText === "add mute" || lowerCaseText === "put on mute" || lowerCaseText === "put mute on" || lowerCaseText === "muted") addError( "This is best written as ‘con sord.’",textObject);
				if (lowerCaseText === "unmuted" || lowerCaseText === "no mute" || lowerCaseText === "remove mute" || lowerCaseText === "take off mute" || lowerCaseText === "take mute off") addError( "This is best written as ‘senza sord.’",textObject);
				if (lowerCaseText === "with vibrato") addError( "This can be abbreviated to ‘con vib.’",textObject);
				if (lowerCaseText === "no vibrato") addError( "This can be abbreviated to ‘senza vib.’",textObject);
				if (lowerCaseText === "much vibrato" || lowerCaseText === "a lot of vibrato") addError( "This can be abbreviated to ‘molto vib.’",textObject);
				if (lowerCaseText.substr(0,5) === "arco.") addError( "‘arco’ should not have a full-stop at the end.",textObject);
				if (lowerCaseText.substr(0,10) === "sul tasto.") addError( "‘tasto’ should not have a full-stop at the end.",textObject);
				if (lowerCaseText === "norm") addError( "‘norm’ should have a full-stop at the end\n(but is more commonly written as ‘ord.’).",textObject);
				if (lowerCaseText.includes("sul. ")) addError( "‘sul’ should not have a full-stop after it.",textObject);
				if (lowerCaseText.includes("  ")) addError( "This text has a double-space in it.",textObject);
				if (lowerCaseText === "normale") addError("Abbreviate ‘normale’ as ‘norm.’ or ‘ord.’.",textObject);
				
				// **** CHECK FOR INCORRECT STYLES **** //
				if (styledText.includes("<i>arco")) addError("‘arco’ should not be italicised.",textObject);
				if (styledText.includes("<i>pizz")) addError("‘pizz.’ should not be italicised.",textObject);
				if (styledText.includes("<i>con sord")) addError("‘con sord.’ should not be italicised.",textObject);
				if (styledText.includes("<i>senza sord")) addError("‘senza sord.’ should not be italicised.",textObject);
				if (styledText.includes("<i>ord.")) addError("‘ord.’ should not be italicised.",textObject);
				if (styledText.includes("<i>sul ")) addError("String techniques should not be italicised.",textObject);
				if (styledText.slice(3) === "<b>") addError("In general, you never need to manually set text to bold.\nAre you sure you want this text bold?",textObject);					
			}
			
			

			// **** CHECK ONLY STAFF/SYSTEM TEXT (IGNORE TITLE/SUBTITLE ETC) **** //
			if (doCheckTempoMarkings) {
				
				// **** 	CHECK TEMPO MARKINGS, METRONOME MARKINGS & TEMPO CHANGE MARKINGS 	**** //
				if (containsTempoComponent || containsMetronomeComponent || containsTempoChangeComponent) {

					// **** CHECK WHETHER INITIAL TEMPO MARKING EXISTS **** //
					if (!initialTempoExists && (isTempoTextStyle || isMetronomeTextStyle) && currentBarNum == 1) initialTempoExists = true;
								
					// **** CHECK TEMPO MARKING IS IN TEMPO TEXT **** //
					if (containsTempoComponent) {
						if (!isTempoTextStyle) addError("‘"+plainText+"’ looks like a tempo marking,\nbut has not been entered as Tempo Text.\nChange in Properties→Show more→Text style→Tempo.",textObject);
					
						// does this require a metronome mark?
						var resetTempoArray = ["a tempo","tempo primo","tempo i","tempo 1","tempo secondo","tempo 2","mouv"];
					
						for (var k = 0; k < resetTempoArray.length && !resetTempo; k++) if (lowerCaseText.includes(resetTempoArray[k])) resetTempo = true;
						
						if (resetTempo) {
							lastTempoMarking = null;
							lastTempoMarkingBar = -1;
							lastTempoChangeMarkingBar = -1;
							lastTempoChangeMarking = null;
							lastTempoChangeMarkingText = '';
							tempoChangeMarkingEnd = -1;
							//logError ('resetTempo');
						} else {
							if (!containsTempoChangeComponent) {
								lastTempoMarking = textObject;
								lastTempoMarkingBar = currentBarNum;
							}
						}
						
						// *** CHECK IF IT IS ATTACHED TO BEAT 1 *** //
						if (!resetTempo) {
							if (!isOnFirstBeatOfBar(textObject)) addError ("This tempo marking is not attached to\nthe first beat of the bar. Is it misplaced?",textObject);
						}
						
					}
					var metroIsBold = false, tempoMarkingIsBold = false;
					if (containsTempoComponent) barContainsTempo = true;
					if (containsMetronomeComponent) barContainsMetronome = true;
					
					// *** CHECK STYLING OF TEMPO MARKING AND METRONOME MARKING					*** //
					// *** ANALYSE THE TEXT OBJECT AND ITS STYLING TO SEE WHICH COMPONENTS 		*** //
					// *** ARE BOLD, AND WHICH ARE PLAIN. WE PREFER THAT THE TEMPO DESCRIPTOR 	*** //
					// *** IS BOLD, AND THE METRONOME MARKING IS PLAIN — SEE EXAMPLES IN 		*** //
					// *** BEHIND BARS, P. 183													*** //
					
					// *** IF THERE IS MANUAL STYLING, THERE WILL BE SOME <B> TAGS				*** //
					// *** IF NO <B> TAGS, THEN THE STYLE OF THE WHOLE TEXT OBJECT APPLIES		*** //
					if (styledText.includes("<b>")) {
						// strip all <b> tags and their contents, to leave only the plain text
						nonBoldText = styledText.replace(/<b>.+?<\/b>/g,'').replace(/<[^>]+>/g, "");
						// strip out anything NOT in between <b> tags
						boldText = styledText.replace(/^.*?<b>|<\/b>.*?(<b>|$)+/g,'');
					} else {
						var textStyleIsBold = textObject.fontStyle == 1;					
						if (textStyleIsBold) {
							boldText = plainText;
							nonBoldText = '';
						} else {
							boldText = '';
							nonBoldText = plainText;
						}
					}
					//logError ('nonBoldText = '+nonBoldText.replace(/</g,'≤')+'; boldText = '+boldText.replace(/</g,'≤'));
					var boldTextStripped = boldText.replace(/<\/?[^>]*?>/g,'');
					var nonMetronomeComponentStripped = nonMetronomeComponent.replace(/<\/?[^>]*?>/g,'').trim();
					if (containsMetronomeComponent) metroIsBold = boldTextStripped.includes('=');
					if (containsTempoComponent) tempoMarkingIsBold = boldTextStripped.includes(nonMetronomeComponentStripped);
					//logError ('metroIsBold = '+metroIsBold+'; tempoMarkingIsBold = '+tempoMarkingIsBold);
					
					if (containsMetronomeComponent || containsTempoComponent) {
						//logError ('Found metronome component');
						if (textObject.offsetX < -4.5) addError ("This tempo marking looks like it is further left than it should be.\nThe start of it should align with the time signature (if any) or first beat.\n(See Behind Bars, p. 183)", textObject);
						if (textObject.offsetX > 4.5) addError ("This tempo marking looks like it is further right than it should be.\nThe start of it should align with the time signature (if any) or first beat.\n(See Behind Bars, p. 183)", textObject);
					}
					
					// *** CHECK ANY METRONOME MARKING COMPONENT *** //
					if (containsMetronomeComponent) {
						
						// **** CHECK ORDER OF METRONOME AND TEMPO MARKING **** //
						// look at the bit to the right of the metronome component we matched
						// if there's anything over there, it should probably be to left
						// There may be some exceptions to this I haven't thought of, however
						// (maybe deal with this in a future version) 
						var strToRightOfMetronomeComponent = styledText.split(metronomeComponent)[1];
						if (strToRightOfMetronomeComponent != undefined) {
							strToRightOfMetronomeComponent = strToRightOfMetronomeComponent.trim();
							if (strToRightOfMetronomeComponent != '') {
								addError ("In general, you should put the mood/tempo descriptor\nbefore the metronome marking.",textObject);
								//logError('strToRightOfMetronomeComponent = '+strToRightOfMetronomeComponent);
							}
						}
						
						// **** CHECK IF c./circa etc. IS IN THE RIGHT PLACE — SHOULD BE BEFORE THE NUMBER **** //
						var theMatch = metronomeComponent.match(/(c|approx|circa)(\.|\s|<\/?b>)*(<sym>metNote.*?<\/sym>|\uECA5|\uECA7|\uECA3)+/);
						//logError (styledText.replace(/</g,'≤'));
						if (theMatch != null) addError ("In this tempo marking, put the ‘"+theMatch[1]+"’ after the = sign.", textObject);
					
						// **** CHECK THAT METRONOME MARKING MATCHES THE TIME SIGNATURE **** //
						var metronomeDuration = division; // crotchet
						var hasAugDot = augDotComponent !== '';
						var hasParentheses = lowerCaseText.includes('(') && lowerCaseText.includes(')');
						var metroStr = "crotchet/quarter note";
						if (metronomeComponent.includes('metNote8thUp') || metronomeComponent.includes('\uECA7')) {
							metronomeDuration = division / 2; // quaver
							metroStr = "quaver/eighth note";
						}
						if (metronomeComponent.includes('metNoteHalfUp') || metronomeComponent.includes('\uECA3')) {
							metronomeDuration = division * 2; // minim
							metroStr = "minim/half note";
						}
						if (hasAugDot) {
							metronomeDuration *= 1.5;
							metroStr = "dotted "+metroStr;
						}
						// some time sigs could be either
						// e.g. 3/8 could be quaver or dotted crotchet
						// e.g. 4/4 could be quaver or crotchet
						// e.g. 6/4 could be crotchet or dotted minim
						// e.g. 7/8 could be quaver or crotchet
						// e.g. 6/16 could be semiquaver or dotted quaver
						// in other words, if it's compound, it could either be the denom, or the denom * 3
						// if it's not compound it could be either the beat or the beat/2
						var metronomeOption1 = division * 4 / currentTimeSig.denominator;
						var metronomeOption2 = isCompound ? (metronomeOption1 * 3) : (metronomeOption1 / 2);
							
						if (metronomeDuration != metronomeOption1 && metronomeDuration != metronomeOption2) {
							addError ("The metronome marking of "+metroStr+" does\nnot match the time signature of "+currentTimeSig.str+".\nAre you sure this is correct?",textObject);
						}
						
						// *** CHECK FOR UNNECESSARY PARENTHESES IN TEMPO MARKINGS 			*** //
						// *** PARENTHESES ARE ONLY REALLY NEEDED FOR A TEMPO MARKINGS, ETC *** //
						// *** NB: THIS DOESN'T YET HANDLE METRIC MODULATION MARKINGS		*** //
						// *** SOMETHING FOR A FUTURE RELEASE!								*** //
						if (hasParentheses && !resetTempo) {
							addError ('You don’t normally need brackets around metronome markings\nexcept for (e.g.) Tempo Primo/Tempo Secondo/a tempo etc.\nSee ‘Behind Bars’, p. 183',textObject);
						}
						
						// *** CHECK FOR UNNECESSARY ‘APPROX’ OR ‘CIRCA’ *** //
						if (lowerCaseText.includes('approx.')) addError ('You can use ‘c.’ instead of ‘approx.’', textObject);
						if (lowerCaseText.includes('circa')) addError ('You can use ‘c.’ instead of ‘circa’', textObject);

							
						// *** CHECK IF BOLD/PLAIN *** //
						if (containsTempoComponent) {
							if (metroIsBold) {
								addError ("The metronome marking component of this tempo marking\nwill look better in a plain font style, rather than bold.\n(See ‘Behind Bars’ p. 183)",textObject);
							} else {
								if (!tempoMarkingIsBold) addError ("Tempo markings are better formatted bold, rather than plain.\n(See ‘Behind Bars’ p. 183", textObject);
							}
						} else {
							if (!containsTempoChangeComponent && metroIsBold) {
								addError ('Metronome markings are better formatted plain,\nrather than bold. (See ‘Behind Bars’ p. 183)',textObject)
							}
						}
						
						// *** CHECK FOR REPETITION OF A METRONOME MARKING *** //
						if (metronomeComponent != '' && metronomeComponent === lastMetronomeComponent) {
				
							if (lastTempoChangeMarking > -1 && !(styledText.includes('a tempo') || styledText.includes('mouv'))) {
								addError ('This looks like the same metronome marking that was set in b. '+lastMetronomeMarkingDisplayBar+'.\nDid you mean to include an ‘a tempo’ marking,\nor are you missing a rit./accel.?', textObject);
							} else {
								addError ('This looks like the same metronome marking that was set in b. '+lastMetronomeMarkingDisplayBar, textObject);
							}
						}
						lastMetronomeComponent = metronomeComponent;
						lastMetronomeMarking = textObject;
						lastMetronomeMarkingBar = getBarNumber(textObject);
						lastMetronomeMarkingDisplayBar = lastMetronomeMarkingBar + displayOffset;
						lastTempoChangeMarkingBar = -1;
						lastTempoChangeMarking = null;
						lastTempoChangeMarkingText = '';
						tempoChangeMarkingEnd = -1;
					}
								
					// *** CHECK TEMPO CHANGE MARKING IS NOT IN TEMPO TEXT OR INCORRECTLY CAPITALISED *** //
					if (containsTempoChangeComponent) {
						if (lastTempoChangeMarkingBar > -1) {
							if (styledText === lastTempoChangeMarkingText) addError ("This looks like the same tempo change marking\nas the previous ‘"+lastTempoChangeMarkingText+"’ in b. "+lastTempoChangeMarkingBar, textObject);
						}
						lastTempoChangeMarkingBar = currentBarNum;
						lastTempoChangeMarking = textObject;
						lastTempoChangeMarkingText = styledText;
						if (isTempoChangeElement) {
							if (textObject.spanner.spannerTicks.ticks <= division) {
								//logError ('not extended');
								tempoChangeMarkingEnd = currTick + division * 12;
							} else {
								tempoChangeMarkingEnd = textObject.spanner.spannerTick.ticks + textObject.spanner.spannerTicks.ticks;
							}
						} else {
							// default duration is 16 beats
							tempoChangeMarkingEnd = currTick + division * 12;
							if (!isTempoTextStyle) {
								addError( "‘"+plainText+"’ is a tempo change marking,\nbut has not been entered as Tempo Text.\nChange in Properties→Show more→Text style→Tempo.",textObject);
								return;
							}
						}
						//logError ('Found gradual tempo change: end is '+tempoChangeMarkingEnd+'; currTick = '+currTick);

						if (plainText.substr(0,1) != lowerCaseText.substr(0,1)) addError("‘"+plainText+"’ looks like it is a temporary change of tempo.\nIf it is, it should not have a capital first letter (see ‘Behind Bars’, p. 182)",textObject);
					}
		
					// *** CHECK TEMPO MARKINGS (BUT NOT TEMPO CHANGES) *** //
					if (containsTempoComponent && !containsTempoChangeComponent) {
						
						if (!containsMetronomeComponent) {
							
							// *** CHECK IF THIS IS A FREE TIME MARKING AND DOESN'T REQUIRE A METRONOME MARKING *** //
							if (lowerCaseText.includes('free time') || lowerCaseText.includes('tempo libero') || lowerCaseText.includes('senza tempo') || lowerCaseText.includes('senza misura') || lowerCaseText.includes('a piacere') || lowerCaseText.includes('in time') || lowerCaseText.includes('tempo giusto')) {
								lastMetronomeComponent = '';
								lastMetronomeMarking = '';
								lastMetronomeMarkingBar = getBarNumber(textObject);
								lastMetronomeMarkingDisplayBar = lastMetronomeMarkingBar + displayOffset;
							}
													
							// *** CHECK IF THIS TEMPO MARKING IS BOLD *** //
							if (boldText === '') addError ("All tempo markings should be in bold type.\n(See ‘Behind Bars’, p. 182)",textObject);
						}
						
						//logError ('isTempoMarking '+isTempoMarking);
						lastTempoChangeMarkingBar = -1;
						lastTempoChangeMarking = null;
						lastTempoChangeMarkingText = '';
						tempoChangeMarkingEnd = -1;
				
						// **** CHECK WHETHER TEMPO SHOULD BE CAPITALISED **** //
						if (plainText.substr(0,1) === lowerCaseText.substr(0,1) && lowerCaseText != "a tempo" && lowerCaseText.charCodeAt(0)>32 && !lowerCaseText.substr(0,4).includes("=")) addError("‘"+plainText+"’ looks like it is establishing a new tempo;\nif it is, it should have a capital first letter. (See ‘Behind Bars’, p. 182)",textObject);
						
						// *** CHECK TEMPO DOES NOT HAVE A DOT AT THE END *** //
						if (plainText.slice(-1) === '.' && !lowerCaseText.includes('mouv') && !lowerCaseText.includes('rit') && !lowerCaseText.includes('accel')) addError ("Tempo markings do not need a full-stop at the end.",textObject);
					}
				
					// *** CHECK TEMPO MARKING POINT SIZE IS BETWEEN 10–12pt *** //
					if (containsTempoComponent || containsTempoChangeComponent) {
						if (textObject.fontSize > 0) {
							// NB fontSize can be -1 for mixed sizes, so only check if it's an actual number
							if (textObject.fontSize > 12.0) addError("This tempo marking is larger than 12pt,\nand may appear overly large.",textObject);
							if (textObject.fontSize < 10.0) addError("This tempo marking is smaller than 10pt,\nand may appear overly small.",textObject);
						}
					}
					
					if (containsTempoChangeComponent || (containsTempoComponent && !containsMetronomeComponent)) lastMetronomeComponent = '';
				}
			
				if (doCheckStrings) {
					
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
					
					// **** CHECK VARIOUS MISLABELLINGS OF POCO SUL TASTO **** //
					if (lowerCaseText === "sul tasto poco" || lowerCaseText === "sul tasto un poco") {
						addError ("Change this to ‘poco sul tasto’.",textObject);
						return;
					}
					
					// **** CHECK VARIOUS MISLABELLINGS OF MOLTO SUL TASTO **** //
					if (lowerCaseText === "sul tasto molto") {
						addError ("Change this to ‘molto sul tasto’.",textObject);
						return;
					}
					
					// **** CHECK VARIOUS MISLABELLINGS OF POCO SUL PONT **** //
					if (lowerCaseText === "sul pont. poco" || lowerCaseText === "sul pont. un poco") {
						addError ("Change this to ‘poco sul pont.’",textObject);
						return;
					}
					
					// **** CHECK VARIOUS MISLABELLINGS OF MOLTO SUL PONT **** //
					if (lowerCaseText === "sul pont. molto") {
						addError ("Change this to ‘molto sul pont.’",textObject);
						return;
					}
				
					// **** CHECK SUL + STRING INDICATION **** //
					var strings = ["I","II","III","IV"];
					for (var i = 0; i < 4; i++) {
						if (lowerCaseText === "sul "+strings[i]) {
							addError ( "You don’t need ‘sul’ here;\nyou can just write the string number.", textObject);
							return;
						}
					}
				}
				
				var objectIsDynamic = tn === "dynamic";
				var includesADynamic = styledText.includes('<sym>dynamic');
				var stringIsDynamic = isDynamic(lowerCaseText);
				
				//logError("styledText = "+styledText.replace(/</g,'≤')+"; lct = "+lowerCaseText+" objectIsDynamic = "+objectIsDynamic+"; includesADynamic = "+includesADynamic+"; stringIsDynamic = "+stringIsDynamic);
				// **** CHECK REDUNDANT DYNAMIC **** //
				if (objectIsDynamic && includesADynamic && !stringIsDynamic) {
					addError ('This dynamic marking is unusual, or has an extraneous character in it somewhere',textObject);
				}
				if ((includesADynamic || stringIsDynamic) && elemPage.pagenumber >= firstPageOfMusicNum) {
					firstDynamic = true;
					//logError ('dynamic here: tickHasDynamic = '+tickHasDynamic()+'; currTick = '+currTick);

					theDynamic = textObject;
					lastDynamicTick = currTick;
					setDynamicLevel (plainText);
					
					var isError = false;
					var dynamicException = plainText.includes("fp") || plainText.includes("fmp") || plainText.includes("sf") || plainText.includes("fz");
					if (prevDynamicBarNum > 0 && doCheckDynamics) {
						
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
						prevDynamicDisplayBarNum = currentBarNum + displayOffset;
						if (currentHairpin && currTick < currentHairpinEnd) {
							prevDynamic = '';
							prevDynamicObject = null;
						} else {
							prevDynamic = plainText;
							prevDynamicObject = textObject;
						}
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
						// is there an accent on this note
						isSforzando = true;
					}
					if (isError) return;
				}

				// **** CHECK FOR DYNAMIC ENTERED AS EXPRESSION (OR OTHER) TEXT **** //
				if (doCheckDynamics && !objectIsDynamic && (includesADynamic || stringIsDynamic)) {
					addError("This text object looks like a dynamic,\nbut has not been entered using the Dynamics palette.",textObject);
					return;
				}

				// **** CHECK FOR TECHNIQUES ENTERED AS EXPRESSION TEXT **** //
				if (tn === "expression") {
					if (doCheckSpellingAndFormat){
						for (var i = 0; i < techniques.length; i ++) {
							if (lowerCaseText.includes(techniques[i])) {
								addError("This looks like a technique, but has been\nincorrectly entered as Expression text.\nPlease check whether this should be in Technique Text instead.",textObject);
								return;
							}
						}
					}
					if (doCheckTextPositions) {
						var canBeAbove = plainText === "loco" || plainText.includes("ten.") || plainText.includes("tenuto") || plainText.includes("legato") || plainText.includes("flz");
						if (textObject.placement == Placement.ABOVE && !canBeAbove && !isVoice) {
							addError("Expression text should appear below the staff.\nCheck it is attached to the right staff, or it should be a technique.",textObject);
							return;
						}
					}
				}
				
				checkInstrumentalTechniques (textObject, plainText, lowerCaseText);
			}
		} // end lowerCaseText != ''
	}	
	
	function isOnFirstBeatOfBar (e) {
		var theTick = getTick(e);
		var theBar = getBar(e);
		if (theBar == null) return false;
		var firstBeatOfBarTick = theBar.firstSegment.tick;
		return (theTick == firstBeatOfBarTick);
	}
	
	function allTracksHaveRestsAtCurrTick () {
		
		var startTrack = currentTrack - (currentTrack % 4);
		var cursor2 = curScore.newCursor();
		cursor2.staffIdx = startTrack / 4;
		cursor2.filter = Segment.ChordRest;
		
		for (var theTrack = startTrack; theTrack < startTrack + 4; theTrack ++) {
			cursor2.track = theTrack;
			cursor2.rewindToTick(currTick);
			var processingThisBar = true;
			if (cursor2.segment == null) continue;
			while (cursor2.segment.tick < currTick + division && processingThisBar ) {
				if (cursor2.element.type == Element.CHORD) return false;
				processingThisBar = cursor2.next() ? cursor2.measure.is(currentBar) : false;
				if (cursor2.segment == null) break;
			}
		}
		return true;
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
	
	function isSameChord (noteRest1, noteRest2) {
		if (noteRest1 == null || noteRest2 == null) return false;
		if (noteRest1.notes == null || noteRest2.notes == null) return false;
		if (noteRest1.notes.length != noteRest2.notes.length) return false;
		for (var i = 0; i < noteRest1.notes.length; i++) {
			if (noteRest1.notes[i].pitch != noteRest2.notes[i].pitch) return false;
		}
		return true;
	}
	
	function checkLyrics (noteRest) {
		//logError ('checking lyrics');

		var theTrack = noteRest.track;

		if (noteRest.lyrics.length > 0) {
			//logError ('lyrics found');
			// lyrics found
			for (var i = 0; i < noteRest.lyrics.length; i++) {
				var l = noteRest.lyrics[i];
				var styledText = l.text;
				var plainText = styledText.replace(/<[^>]+>/g, "");
				var dur = l.lyricTicks.ticks;
				isMelisma[theTrack] = (l.syllabic == 1 || l.syllabic == 3); // 1 == BEGIN, 3 == MIDDLE
				if (dur > 0) {
					melismaEndTick[theTrack] = noteRest.parent.tick + dur; 
					// NB — we record the melisma as ending on the START of the final note
					//logError("melismaEndTick["+theTrack+"] = "+melismaEndTick[theTrack]);
					isMelisma[theTrack] = true;
				} else {
					melismaEndTick[theTrack] = 0;
					//logError ("melismaEndTick set to 0");
				}
			}
			
			if (isMelisma[theTrack]) {
				currentWord = (currentWord == '') ? plainText : (currentWord + '-' + plainText);
				currentWordArray.push(l);
			} else {
				if (currentWord !== '') {
					currentWordArray.push(l);
					currentWord = currentWord + '-' + plainText;
					checkHyphenation(currentWord, currentWordArray);
				}
				currentWord = '';
				currentWordArray = [];
			}
			if (isSlurred & !isMelisma[theTrack]) {
				if (currTick < currentSlur.spanner.spannerTick.ticks + currentSlur.spanner.spannerTicks.ticks) addError ("This note is slurred, but is not a melisma.",noteRest);
			}
		} else {
			//logError ('lyrics not found');
			// no lyrics found
			var isTiedBack = noteRest.notes[0].tieBack != null;
				//logError ('!isTiedBack; met = '+melismaEndTick[theTrack]);
			var endOfMelisma = false;
			if (melismaEndTick[theTrack] > 0) {
				endOfMelisma = noteRest.parent.tick >= melismaEndTick[theTrack];
				//logError ('end of melisma = '+endOfMelisma+'; tick = '+noteRest.parent.tick+' endOfMelismaTick = '+melismaEndTick[theTrack]);
				if (endOfMelisma) {
					if (currentWord !== '') checkHyphenation(currentWord, currentWordArray);
					currentWord = '';
					currentWordArray = [];
				}
			}
			if (!isTiedBack) {
				if (isMelisma[theTrack]) {
					// check for slur
					//logError("isSlurred = "+isSlurred+" isTied = "+isTied);
					if (!isSlurred)	addError ("This melisma requires a slur.",noteRest);
				} else {
					if (!isSlurred) {
						if (!flaggedNoLyrics) {
							flaggedNoLyrics = true;
							//logError ("TieBack = "+noteRest.notes[0].tieBack);
							addError ("This note in a vocal part does not have any lyrics;\nif this is a melisma, it requires a slur.",noteRest);
						}
					}
				}
			}
		}
	}
	
	function checkHyphenation (str, wordArray) {
		var unhyphenatedStr = str.replace(/-/g,"").toLowerCase();
		var index = unhyphenatedWordsLower.indexOf(unhyphenatedStr);
		if (index != -1) {
			var correctlyHyphenatedStr = hyphenatedWords[index];
			if (str.toLowerCase() !== correctlyHyphenatedStr.toLowerCase()) {
				addError ('‘'+str + '’ is not correctly hyphenated. It should be ‘'+correctlyHyphenatedStr+'’',wordArray);
			}
		}
	}
	
	function isDynamic (str) {
		var exceptions = ["p.s.t","p.s.p"];
		for (var i = 0; i < exceptions.length; i++) {
			var word = exceptions[i];
			if (str.includes(word)) return false;
		}
		var dynamics = ["pppp", "ppp","pp","p", "mp", "mf", "f", "ff", "fff", "ffff","sf", "sfz","sffz","fz","fpppp", "fppp","fpp","fp", "fmp", "fmf", "ffpppp", "ffppp","ffpp","ffp", "ffmp", "sfpppp", "sfppp","sfpp","sfp", "sfmp", "sfzpppp", "sfzppp","sfzpp","sfzp", "sfzmp","mfpppp", "mfppp","mfpp","mfp", "mfmp", "sffpppp", "sffppp","sffpp","sffp", "sffmp", "sffzpppp", "sffzppp","sffzpp","sffzp", "sffzmp", "fzpppp", "fzppp","fzpp","fzp", "fzmp", "n", "niente"];
		var words = str.split(/[:\s]+/);
		for (var i = 0; i < words.length; i++) {
			var word = words[i];
			if (word === 'f' && str.includes('in f')) continue;
			if (dynamics.includes(word)) return true;
		}
		return false;
	}
	
	function tickHasDynamic () {
		return dynamicTicks[currentStaffNum][currTick] != null;
	}
	
	function setDynamicLevel (str) {
		// set multiple dynamics first and return
		// dynamicLevel — 0 = ppp–p, 1 = mp, 2 = mf, 3 = f, 4 = ff+
		if (str === 'sf' || str === 'sfz' || str === 'sffz' || str === 'rf' || str === 'rfz' || str === 'fz') return;
		var strWords = str.split(/[,;:-\s.]+/);
		if (str.includes ('meno f') || str.includes('più p')) {
			if (currDynamicLevel > 0) currDynamicLevel--;
			return;
		}
		if (str.includes ('più f') || str.includes('meno p')) {
			if (currDynamicLevel < 4) currDynamicLevel++;
			return;
		}
		// go in reverse order
		for (var i = strWords.length-1; i>=0; i--) {
			var checkStr = strWords[i];
			
			if (checkStr.includes ('p') || checkStr.includes('n')) {
				currDynamicLevel = 0;
				return;
			}
			if (checkStr === 'mp' || checkStr.includes('zmp') || checkStr.includes('fmp')) {
				currDynamicLevel = 1;
				return;
			}
			if (checkStr === 'mf') {
				currDynamicLevel = 2;
				return;
			}
			if (checkStr.includes('f') && !checkStr.includes('ff')) {
				currDynamicLevel = 3;
				return;
			}
			if (checkStr.includes('ff')) {
				currDynamicLevel = 4;
				return;
			}
		}
		logError ('setDynamicLevel() — Can’t find dynamic level for '+str+'; words are: ['+strWords.join('|')+']');
	}
	
	function checkKeySignature (keySig,sharps) {
		// *********************** KEY SIGNATURE ERRORS *********************** //
		if (sharps != prevKeySigSharps) {
			var errStr = "";
			if (sharps > 6) errStr = "This key signature has "+sharps+" sharps,\nand would be easier to read if rescored as "+(12-sharps)+" flats.";
			if (sharps < -6) errStr = "This key signature has "+Math.abs(sharps)+" flats,\nand would be easier to read if rescored as "+(12+sharps)+" sharps.";
			if (currentBarNum - prevKeySigBarNum  < 16) errStr = ((errStr !== "") ? errStr + "\nAlso, this" : "This") + " key change comes only "+ (currentBarNum - prevKeySigBarNum) +" bars after the previous one.\nPerhaps one of them could be avoided by using accidentals instead?";
			if (errStr !== "") addError(errStr,keySig);
			prevKeySigSharps = sharps;
			prevKeySigBarNum = currentBarNum;
		} else {
			addError("This key signature is the same as the one in bar "+prevKeySigBarNum+".\nPerhaps delete it?",keySig);
		}
	}
	
	function checkBarlinesConnected (str) {
		var lastVisibleStaff = 0;
		for (var i = 0; i < numStaves; i++) if (staffVisible[i]) lastVisibleStaff = i;
		
		// if str is not null, then it's a standard ensemble where all the staff lines should be connected
		if (str != null) {
			for (var i = 0; i < lastVisibleStaff; i++) {
				if (staffVisible[i]) {
					var staff = curScore.staves[i];
					//logError ('staff.staffBarlineSpan = '+staff.staffBarlineSpan);
					if (staff.staffBarlineSpan == 0) {
						addError ("In a "+str+", the barlines should go through all staves.\nClick and drag the bottom of a barline to extend down through the entire score.","system1 0");
						return;
					}
				}
			}
		}
		
		// check vocal staves and grand staff instruments that have been incorrectly connected
		var prevBarlineSpan = 0;
		for (var i = 0; i < lastVisibleStaff; i++) {
			if (staffVisible[i]) {
				var staff = curScore.staves[i];
				var barlineSpan = staff.staffBarlineSpan;
				
				// *** CHECK VOCAL STAFF INSTRUMENT BARLINES *** //
				if (staff.part.musicXmlId.includes('voice')) {
					if (barlineSpan > 0) {
						addError ("Vocal staves should not have their barlines\nconnected to other staves. Click each\nconnected barline and drag up to disconnect.","system1 "+i);
					}
				}
				
				// *** CHECK GRAND STAFF INSTRUMENT BARLINES *** //
				if (isTopOfGrandStaff[i]) {
					if (i > 0 && prevBarlineSpan > 0) {
						addError ("Grand staff instruments should not have their barlines\nconnected to other instruments.","system1 "+i);
					}
					if (barlineSpan == 0) {
						addError ("Grand staff instruments should have their barlines\nconnected between the staves.","system1 "+i);
					}
				}
				prevBarlineSpan = barlineSpan;
			}
		}
	}
	
	function checkBracketsAndBraces (str) {
		var singleJoinedBracketArray = ["string quartet", "wind quintet", "brass quintet", "string quintet"];
		var noBracketArray = ["piano trio", "piano quartet", "duo"];
		var firstVisibleStaff = -1;
		var lastVisibleStaff = -1;
		
		for (var i = 0; i < numStaves; i++) {
			if (staffVisible[i]) {
				if (firstVisibleStaff == -1) firstVisibleStaff = i;
				lastVisibleStaff = i;
			}
		}
		
		var visibleStaffSpan = lastVisibleStaff - firstVisibleStaff + 1;
		
		// check for brace on grand staves
		for (var i = firstVisibleStaff; i < lastVisibleStaff; i++) {
			if (isTopOfGrandStaff[i]) {
				// check for a brace
				var theStaff = curScore.staves[i];
				if (theStaff.brackets.length == 0) {
					addError ('Grand staves require a single brace on the left.\nAdd this from the Brackets palette.','system1 '+i);
				} else {
					if (theStaff.brackets.length == 1) {
						if (theStaff.brackets[0].systemBracket != BracketType.BRACE) {
							addError ('Grand staves require a single brace on the left.\nAdd this from the Brackets palette.','system1 '+i);
						}
					} else {
						var hasBrace = false;
						for (var j = 0; j < theStaff.brackets.length && !hasBrace; j++) {
							hasBrace = theStaff.brackets[j].systemBracket == BracketType.BRACE;
						}
						if (!hasBrace) {
							addError ('Grand staves require a single brace on the left.\nAdd this from the Brackets palette.','system1 '+i);
						}
					}
				}
			}
		}
		
		if (str != null) {
			if (singleJoinedBracketArray.includes(str)) {
				// this score only needs one bracket
				var theBrackets = [];
				for (var i = 0; i < numStaves; i++) {
					if (staffVisible[i]) {	
						var theStaff = curScore.staves[i];
						var numBrackets = theStaff.brackets.length;
						
						if (i == firstVisibleStaff) {
							
							// *** Check if no brackets have been added *** //
							if (numBrackets == 0) addError ('For '+str+'s, there should be a single bracket around the entire system.\nAdd a bracket from the Brackets palette.','system1 0');
							
							if (numBrackets == 1) {

								// *** Check if the bracket is a normal system bracket *** //
								if (theStaff.brackets[0].systemBracket != BracketType.NORMAL) {
									addError ('This bracket is the wrong kind of bracket for '+str+'.\nDelete it and add a normal bracket instead',theStaff.brackets[0]);
								} else {
									// *** Check if the bracket spans the whole system *** //
									if (theStaff.brackets[0].bracketSpan != visibleStaffSpan) addError ('For '+str+'s, the staff bracket should span the entire system.\nClick and drag the bottom of the bracket down to the end of the system.',theStaff.brackets[0]);
								}
								
							}
						}
						for (var j = 0; j < numBrackets; j++) theBrackets.push(theStaff.brackets[j]);
						
					}
				}
				if (theBrackets.length > 1) {
					var bracketsToHighlight = [];
					var foundNormalBracket = false;
					for (var j = 0; j < theBrackets.length; j++) {
						var theBracket = theBrackets[j];
						if (theBrackets[j].systemBracket == BracketType.NORMAL && ! foundNormalBracket) {
							foundNormalBracket = true;
						} else {
							bracketsToHighlight.push(theBracket);
						}
					}
					addError ('For '+str+'s, you only need one system bracket.\nSelect all unnecessary brackets and press ‘delete’.',bracketsToHighlight);
				}
			}
			
			if (noBracketArray.includes(str)) {
				for (var i = 0; i < numStaves; i++) {
					if (staffVisible[i]) {
						var theStaff = curScore.staves[i];
						if (theStaff.brackets.length != 0) {
							if (theStaff.brackets[0].systemBracket == BracketType.BRACE) {
								if (!isGrandStaff[i]) {
									addError ('You don’t need a brace here.\n(Select the bracket and press ‘delete’)',theStaff.brackets[0]);
									return;
								}
							} else {
								addError ('For '+str+'s, you don’t need a bracket around the staves.\n(Select the bracket and press ‘delete’)',theStaff.brackets[0]);
								return;
							}
						}
					}
				}
			}
		}
	}
	
	function checkTimeSignatures () {
		var segment = curScore.firstSegment();
		var prevTimeSigStr = "";
		while (segment) {
			if (segment.segmentType == Segment.TimeSig) {
				var theTimeSig = segment.elementAt(0);
				if (theTimeSig.type == Element.TIMESIG) {
					if (theTimeSig.visible) {
						var theTimeSigStr = theTimeSig.timesig.str;
						if (theTimeSigStr === prevTimeSigStr) addError("This time signature appears to be redundant (was already "+prevTimeSigStr+")\nIt can be safely deleted.",theTimeSig);
						prevTimeSigStr = theTimeSigStr;
						var n = theTimeSig.subtypeName();
						if (n.includes("Common")) addError ("The ‘Common time’ time signature is considered old-fashioned these days;\nIt is better to write this in full, as 4/4.",theTimeSig);
						if (n.includes("Cut")) addError ("The ‘Cut time’ time signature is considered old-fashioned these days;\nIt is better to write this in full, as 2/2.",theTimeSig);
					}
				}
			}
			segment = segment.next;
		}
	}
	
	function checkFermatas () {
		var ticksDone = [];
		for (var i = 0; i < numStaves; i++) {
			if (staffVisible [i]) {
				for (var j = 0; j < fermatas[i].length; j++) { 
					var fermata = fermatas[i][j];
					var theTick = fermata.parent.tick;
					// check if we've already done this fermata
					if (!ticksDone.includes(theTick)) {	
						//logError ("Found a fermata at "+theTick);		
						var fermataInAllParts = true;
						for (var k = 0; k < numStaves && fermataInAllParts; k++) {
							if (k != i && staffVisible[k]) fermataInAllParts = fermatas[k].filter (e => e.parent.tick == theTick).length > 0;	
						}
						if (!fermataInAllParts) addError("In general, a fermata should be placed in ALL parts, appearing on the same beat.\nThere are some instances where placing fermatas on different beats is permitted.\nUse your judgement as to whether you may ignore this warning (see ‘Behind Bars’, p. 190)",fermata);
						ticksDone.push(theTick);
					}
				}
			}
		}
	}
	
	function checkStaccatoIssues (noteRest) {
		if (isFermata) {
			addError ("Don’t put a fermata over a staccato note.", noteRest);
		}
		if (noteRest.duration.ticks >= division * 2) {
			addError ("Don’t put staccato dots on long notes, unless the tempo is very fast.",noteRest);
			return;
		}
		if (isDotted(noteRest) && noteRest.duration.ticks >= division * 0.5) {
			addError ("Putting staccato dots on dotted notes may be ambiguous.",noteRest);
			return;
		}
		if (noteRest.notes[0].tieForward != null) {
			addError ("Don’t put staccato dots on tied notes.",noteRest);
			return;
		}
		if (isShortDecayInstrument && flaggedStaccatoOnShortDecayInstrumentBarNum == 0) {
			addError ("Staccato dots may be meaningless for this short decay instrument.",noteRest);
			flaggedStaccatoOnShortDecayInstrumentBarNum = currentBarNum;
		}
		if (isSlurred && !isEndOfSlur && flaggedSlurredStaccatoBar < currentBarNum - 4 && (isStringInstrument || isHarp || isPercussionInstrument)) {
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
				if (!isEndOfSlur) {
					if (isStringInstrument) {
						var portatoOK = (pitch == prevPitch || pitch == nextPitch);
						if (!portatoOK && noteRest.duration.ticks >= division) {
							addError ("Slurred staccatos are not common as string articulations,\nexcept to mark portato (repeated notes under a slur).\nDid you want to consider rewriting them as legato?",noteRest);
							flaggedSlurredStaccatoBar = currentBarNum;
						}
					} else {
						if (isHarp || isPercussion) {
							addError ('Slurred staccatos don’t really make sense for '+currentInstrumentName.toLowerCase()+'.\nConsider removing the staccato articulations.',noteRest);
						}
					}
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
			if (isBassClef && noteRest.notes[0].pitch > 40 && !flaggedClefTooHigh) {
				addError ("This horn note/passage is too high for bass clef;\nit would be better in treble clef.", noteRest);
				flaggedClefTooHigh = true;
				flaggedClefTooHighBarNum = currentBarNum;
			}
			if (isTrebleClef && noteRest.notes[0].pitch < 41 && !flaggedClefTooLow) {
				addError ("This horn note/passage is too low for treble clef;\nit would be better in bass clef.", noteRest);
				flaggedClefTooLow = true;
				flaggedClefTooLowBarNum = currentBarNum;
			}
		}
		if (maxNumLedgerLines > 3 && minNumLedgerLines > 0 && !flaggedClefTooHigh) {
			if (isBassClef && readsBass && readsTenor) {
				if (!readsTreble) {
					addError("This passage is very high for bass clef;\nit may be better in tenor clef.",noteRest);
				} else {
					addError("This passage is very high for bass clef;\nit may be better in tenor or treble clef.",noteRest);
				}
				flaggedClefTooHigh = true;
				flaggedClefTooHighBarNum = currentBarNum;
			}
			if (isTenorClef && readsTenor && readsTreble) {
				addError("This passage is very high for tenor clef;\nit may be better in treble clef.",noteRest);
				flaggedClefTooHigh = true;
				flaggedClefTooHighBarNum = currentBarNum;
			}
			if (isAltoClef && readsAlto && readsTreble) {
				addError("This passage is very high for alto clef;\nit may be better in treble clef.",noteRest);
				flaggedClefTooHigh = true;
				flaggedClefTooHighBarNum = currentBarNum;
			}
		}
		if (maxNumLedgerLines > 5 && minNumLedgerLines > 2 && !flaggedClefTooHigh) {
			if (isTrebleClef && readsTreble && reads8va && !isOttava) {
				addError("This passage is very high for treble clef;\nit may be better with an 8va symbol.",noteRest);
				flaggedClefTooHigh = true;
				flaggedClefTooHighBarNum = currentBarNum;
			}
		}
		if (maxNumLedgerLines < 0 && minNumLedgerLines <= 0 && !flaggedClefTooLow) {
			if (isTrebleClef && readsTreble) {
				if (readsTenor) {
					addError("This passage is very low for treble clef;\nit may be better in tenor or bass clef.",noteRest);
					flaggedClefTooLow = true;
					flaggedClefTooLowBarNum = currentBarNum;
				} else {
					if (maxNumLedgerLines < -3 && readsBass) {
						addError("This passage is very low for treble clef;\nit may be better in bass clef.",noteRest);
						flaggedClefTooLow = true;
						flaggedClefTooLowBarNum = currentBarNum;
					} else {
						if (readsAlto) {
							addError("This passage is very low for treble clef;\nit may be better in alto clef.",noteRest);
							flaggedClefTooLow = true;
							flaggedClefTooLowBarNum = currentBarNum;
						}
					}
				}
			}
			if (isTenorClef && readsTenor && readsBass && maxNumLedgerLines < 0 && minNumLedgerLines <= 0) {
				addError("This passage is very low for tenor clef;\nit may be better in bass clef.",noteRest);
				flaggedClefTooLow = true;
				flaggedClefTooLowBarNum = currentBarNum;
			}
			if (isBassClef && readsBass && reads8va && !isOttava && maxNumLedgerLines < -5 && minNumLedgerLines < -2) {
				addError("This note/passage is very low for bass clef;\nit may be better with an 8ba.",noteRest);
				flaggedClefTooLow = true;
				flaggedClefTooLowBarNum = currentBarNum;
			}
		}
	//	if (!flaggedInstrumentRange) logError("ll length now "+ledgerLines.length);
		if (maxLedgerLines.length >= numberOfRecentNotesToCheck) {
			var averageMaxNumLedgerLines = maxLedgerLines.reduce((a,b) => a+b) / maxLedgerLines.length;
			var averageMinNumLedgerLines = minLedgerLines.reduce((a,b) => a+b) / minLedgerLines.length;
			
			if (isOttava && currentOttava != null) {
				var ottavaArray = ["an 8va","an 8ba","a 15ma","a 15mb"];
				var ottavaStr = ottavaArray[currentOttava.ottavaType]; 
				//logError("Testing 8va Here — currentOttava.ottavaType = "+currentOttava.ottavaType+"); averageNumLedgerLines "+averageNumLedgerLines+" maxLLSinceLastRest="+maxLLSinceLastRest;
				if (currentOttava.ottavaType == 0 || currentOttava.ottavaType == 2) {
					if (averageMaxNumLedgerLines < 2 && averageMinNumLedgerLines >= 0 && maxLLSinceLastRest < 2 && !flaggedOttavaTooLow) {
						addError("This passage is quite low for "+ottavaStr+" line:\nyou should be able to safely write this at pitch.",currentOttava);
						flaggedOttavaTooLow = true;
						flaggedOttavaTooLowBarNum = currentBarNum;
						return;
					}
				} else {
					if (averageMaxNumLedgerLines > -2 && averageMinNumLedgerLines <= 0 && maxLLSinceLastRest < 2 && !flaggedOttavaTooHigh) {
						addError("This passage is quite high for "+ottavaStr+" line:\nyou should be able to safely write this at pitch.",currentOttava);
						flaggedOttavaTooHigh = true;
						flaggedOttavaTooHighBarNum = currentBarNum;
						return;
					}
				}
			}
			if (isBassClef) {
				//trace(averageNumLedgerLines);
				if (readsTenor && averageMaxNumLedgerLines >= 3 && averageMinNumLedgerLines > 1 && !flaggedClefTooHigh) {
					addError("This passage is quite high;\nit may be better in tenor or treble clef.",noteRest);
					flaggedClefTooHigh = true;
					flaggedClefTooHighBarNum = currentBarNum;
				} else {
					if (readsTreble && averageMaxNumLedgerLines >= 3 && averageMinNumLedgerLines > 2 && !flaggedClefTooHigh) {
						addError("This passage is very high;\nit may be better in treble clef.",noteRest);
						flaggedClefTooHigh = true;
						flaggedClefTooHighBarNum = currentBarNum;
					} else {
						if (reads8va && averageMaxNumLedgerLines < -4 && averageMinNumLedgerLines < -2 && !isOttava && !flaggedClefTooLow) {
							addError("This passage is very low;\nit may be better with an 8ba.",noteRest);
							flaggedClefTooLow = true;
							flaggedClefTooLowBarNum = currentBarNum;
						}
					}
				}
			}

			if (isTenorClef) {
				if (readsTreble && averageMaxNumLedgerLines > 2 && averageMinNumLedgerLines > 1 && !flaggedClefTooHigh) {
					addError("This passage is quite high;\nit may be better in treble clef.",noteRest);
					flaggedClefTooHigh = true;
					flaggedClefTooHighBarNum = currentBarNum;
				} else {
					if (readsBass && averageMaxNumLedgerLines < -1  && averageMinNumLedgerLines <= 0 && !flaggedClefToolow) {
						addError("This passage is quite low;\nit may be better in bass clef.",noteRest);
						flaggedClefTooLow = true;
						flaggedClefTooLowBarNum = currentBarNum;

					}
				}
			}
			if (isTrebleClef) {
				if (reads8va && averageMaxNumLedgerLines > 4 && averageMinNumLedgerLines > 2 && !isOttava && !flaggedOttavaTooHigh) {
					addError("This passage is very high;\nit may be better with an 8va.",noteRest);
					flaggedOttavaTooHigh = true;
					flaggedOttavaTooHighBarNum = currentBarNum;
				} else {
					if (readsTenor && averageMaxNumLedgerLines < -1 && averageMinNumLedgerLines <= 0 && !flaggedOttavaTooLow) {
						addError("This passage is quite low;\nit may be better in tenor clef.",noteRest);
						flaggedOttavaTooLow = true;
						flaggedOttavaTooLowBarNum = currentBarNum;
					} else {
						if (readsBass && averageMaxNumLedgerLines < -2 && averageMinNumLedgerLines <= 0 && !flaggedClefToolow) {
							addError("This passage is quite low;\nit may be better in bass clef.",noteRest);
							flaggedClefToolow = true;
							flaggedOttavaTooLowBarNum = currentBarNum;
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
		
		var noteOnString = [-1,-1,-1,-1];
		var iName = "";
		var maxStretch = 13; // 6 + 7
		var numNotes = 0;
		var tempPitchArray = [];
		
		// ignore any bracketed notes, as they're probably just harmonic sounding
		for (var i = 0; i < chord.notes.length; i ++) {
			var theNote = chord.notes[i];
			if (!theNote.hasParentheses) {
				numNotes ++;
				tempPitchArray.push(theNote.pitch);
			}
		}
		var prevNoteRest = getPreviousNoteRest(chord);
		var prevIsChord = (prevNoteRest == null) ? false : (prevNoteRest.type == Element.CHORD);
		
		if (numNotes > 4) {
			addError ("This multiple stop has more than 4 notes in it.",chord);
			return;
		}
		
		if (numNotes > 2 && chord.duration.ticks > division * 1.5) {
			var str = numNotes == 3 ? "This triple stop" : "This quadruple stop";
			addError (str+" is too long to hear all strings playing at the same time\nYou should rewrite it with 1 or 2 of the notes as grace notes\nso that no more than 2 notes are sustained.",chord);
			return;
		}
		if (currentInstrumentId.includes("violin") || currentInstrumentName.toLowerCase().includes("violin")) {
			iName = "violin";
		}
		if (currentInstrumentId.includes("viola") || currentInstrumentName.toLowerCase().includes("viola")) {
			iName = "viola";
			maxStretch = 12;
		}
		if (currentInstrumentId.includes("cello") || currentInstrumentName.toLowerCase().includes("cello")) {
			iName = "cello";
		}
		if (currentInstrumentId.includes("bass") || currentInstrumentName.toLowerCase().includes("bass")) {
			iName = "double bass";
			maxStretch = 9;
		}
		if (iName === "") return; // unknown string instrument

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
						addError ("This chord is impossible to play, because it contains\ntwo notes that can only be played on the "+(stringNames[stringNum - 1])+" string.",chord);
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
		if (prevIsChord && prevIsMultipleStop && chord.actualDuration.ticks <= division && prevSoundingDur <= division && interval > 0 && prevMultipleStopInterval > 0 && !flaggedFastMultipleStops) {
			//logError("Checking sequence");
			
			var pi1 = interval > 7;
			var pi2 = prevMultipleStopInterval > 7;
			if (pi1 != pi2) {
				
				addError ("This sequence of double-stops looks very difficult,\nas the hand has to change its position and orientation.",chord);
				flaggedFastMultipleStops = true;
				
			} else {
				//logError("Checking identical chords");
				
				if (!chordsAreIdentical (chord,prevMultipleStop)) {
					if (interval == 7 && !isCello) {
						addError ("This looks like a sequence of relatively quick perfect fifths,\nwhich is challenging to play accurately.",chord);
					} else {
						addError ("This looks like a sequence of relatively quick double-stops,\nwhich might be challenging to play accurately.",chord);
					}
					flaggedFastMultipleStops = true;
				}
			}
		}
		prevMultipleStop = chord;
		prevIsMultipleStop = true;
		prevMultipleStopInterval = interval;
	}
	
	function checkTempoObjectNow (t) {
		if (t.type == Element.GRADUAL_TEMPO_CHANGE || t.type == Element.GRADUAL_TEMPO_CHANGE_SEGMENT) {
			return currTick >= t.spanner.spannerTick.ticks;
		} else {
			return currTick >= t.parent.tick;
		}
	}
	
	function getArticulations (noteRest) {
		if (noteRest == null || noteRest == undefined) return [];
		var a = noteRest.articulations;
		if (a == undefined || a == null) a = [];
		return a;
	}
	
	function checkStringHarmonic (noteRest) {

		var harmonicCircleIntervals = [12,19,24,28,31,34,36,38,40,42,43,45,46,47,48];
		var diamondHarmonicIntervals = [3,4,5,7,9,12,16,19,24,28,31,34,36];
		var violinStrings = [55,62,69,76];
		var violaStrings = [48,55,62,69];
		var celloStrings = [36,43,50,57];
		var bassStrings = [28,33,38,43];
		
		
		if (noteRest.notes[0].tieBack) return;
		isStringHarmonic = false;
		
		var theArticulationArray = getArticulations(noteRest);
		//logError ('Note has '+theArticulationArray.length+' artics');
		var numNotes = 0;
		var theNotes = [];
		for (var i = 0; i < noteRest.notes.length; i ++) {
			var theNote = noteRest.notes[i];
			if (!theNote.hasParentheses) {
				numNotes ++;
				theNotes.push(theNote);
			}
			// check for Bravura harmonics
			if (!flaggedBravuraHarmonics) {
				//logError (curScore.style.value('musicalSymbolFont'));
				if (curScore.style.value('musicalSymbolFont') === 'Bravura') {
					if (theNote.headGroup == NoteHeadGroup.HEAD_DIAMOND || theNote.headGroup == NoteHeadGroup.HEAD_DIAMOND_OLD) {
						flaggedBravuraHarmonics = true;
						addError ("Diamond noteheads in the ‘Bravura’ font don’t meet standard notation guidelines.\nThey are too small and oddly shaped — see ‘Behind Bars’ p. 11.\nConsider changing the music font to ‘Leland’ instead,\nor use the ‘Mi’ notehead option.", noteRest);
					}
				}
			}
		}		//logError("CHECKING STRING HARMONIC — nn = "+nn);
		if (numNotes == 2) {
			//check for possible artificial harmonic
			var noteheadStyle1 = theNotes[0].headGroup;
			var noteheadStyle2 = theNotes[1].headGroup;
			//logError("ns1 = "+noteheadStyle1+" vs "+NoteHeadGroup.HEAD_NORMAL+"); ns2 = "+noteheadStyle2+" vs "+NoteHeadGroup.HEAD_DIAMOND;
			
			// **** ARTIFICIAL HARMONICS **** //
			if (noteheadStyle1 == NoteHeadGroup.HEAD_NORMAL && (noteheadStyle2 == NoteHeadGroup.HEAD_DIAMOND || noteheadStyle2 == NoteHeadGroup.HEAD_DIAMOND_OLD)) {
				//logError ('Found artificial harmonic — isStringHarmonic = true');
				isStringHarmonic = true;
				// we have a false harmonic
				// are notes always in bottom-up order?
				var noteheadPitch1 = theNotes[0].pitch;
				var noteheadPitch2 = theNotes[1].pitch;
				var bottomNote = noteheadPitch1 < noteheadPitch2 ? theNotes[0] : theNotes[1];
				var topNote = noteheadPitch1 < noteheadPitch2 ? theNotes[1] : theNotes[0];
				//logError("FALSE HARM FOUND: np1 "+noteheadPitch1+" np2 "+noteheadPitch2);
				var interval = topNote.pitch - bottomNote.pitch;
				
				if (interval != 5) addError("This looks like an artificial harmonic, but the interval between\nthe fingered and touched pitch is not a perfect fourth.",noteRest);
				
				// check override on the top note
				if (noteRest.duration.ticks < 2 * division) {
					
					var isForceMinim = topNote.headType == NoteHeadType.HEAD_HALF;
					var isTwoNoteTremolo = (noteRest.tremoloTwoChord != null && noteRest.tremoloTwoChord != undefined);
					
					// ignore if a two-note tremolo
					if (!isForceMinim && !isTwoNoteTremolo) {
						addError("The diamond harmonic notehead should be hollow.\nIn Properties, set ‘Override visual duration’ to a minim.\n(See ‘Behind Bars’, p. 428)",noteRest);
						//logError ('noteheadType = '+noteheadType);
					}
				}
				
				// check artificial harmonic with a harmonic circle above it
				if (theArticulationArray != undefined) {
					for (var i = 0; i < theArticulationArray.length; i++) {
						if (theArticulationArray[i].visible) {
							if (theArticulationArray[i].symbol == SymId.stringsHarmonic) {
								// found a harmonic circle
								addError ("Artificial harmonics don’t require a harmonic circle.",theArticulationArray[i]);
								break;
							}
						}
					}
				}
				
				// check register
				if (bottomNote.pitch > stringsArray[3]+10) addError ("This artificial harmonic looks too high to be effective.\nConsider putting it down an octave.",noteRest);
			}
		}
		
		if (numNotes == 1) {
			var harmonicArray = [];
			var noteheadStyle = theNotes[0].headGroup;
			var isHarmonicCircle = false;
			//logError("The artic sym = "+theArticulationArray.symbol.toString()+'; noteheadStyle = '+noteheadStyle);
			// CHECK FOR HARMONIC CIRCLE ARTICULATION ATTACHED TO THIS NOTE
			for (var i = 0; i < theArticulationArray.length; i++) {
				if (theArticulationArray[i].symbol == SymId.stringsHarmonic) {
					if (theArticulationArray[i].visible) {
						isHarmonicCircle = true;
						isStringHarmonic = true;
						harmonicArray = harmonicCircleIntervals;
						break;
					}
				}
			}
			if (noteheadStyle == NoteHeadGroup.HEAD_DIAMOND || noteheadStyle == NoteHeadGroup.HEAD_DIAMOND_OLD) {
				//logError ('isDiamond');
				if (isHarmonicCircle) {
					addError ("This harmonic has both a diamond notehead and a harmonic circle.\nYou should choose one or the other, but not both.", noteRest);
					return;
				} else {
					isStringHarmonic = true;
				}
				harmonicArray = diamondHarmonicIntervals;
				// check override on the top note
				if (noteRest.duration.ticks < 2 * division) {
					var isForceMinim = theNotes[0].headType == NoteHeadType.HEAD_HALF;
					var isTwoNoteTremolo = noteRest.tremoloTwoChord != null;
					if (!isForceMinim && !isTwoNoteTremolo) addError("The diamond harmonic notehead should be hollow.\nIn Properties, set ‘Override visual duration’ to a minim.\n(See ‘Behind Bars’, p. 11)",noteRest);
				}
			}
			if (isStringHarmonic) {
				var p = theNotes[0].pitch;
				var harmonicOK = false;
				
				for (var i = 0; i < stringsArray.length && !harmonicOK; i++) {
					for (var j = 0; j < harmonicArray.length && !harmonicOK; j++) {
						harmonicOK = (p == stringsArray[i]+harmonicArray[j]);
					}
				}
				// check whether this harmonic actually exists
				if (!harmonicOK) {
					if (isHarmonicCircle) {
						if (stringsArray.includes(p)) {
							addError("You can’t get this pitch with a natural harmonic.\nIs that meant to be an open string indication instead?\nIf so, delete the harmonic circle, and replace with\na 10pt ‘0’ (zero) character as text.",noteRest);
						} else {
							addError("You can’t get this pitch with a natural harmonic.\nDid you mean a diamond notehead instead of a harmonic circle?",noteRest);
						}
					} else {
						addError("There isn’t a clear harmonic at this touched pitch.\nAs such, it won’t sound like much.\nAre you sure this is correct?",noteRest);
					}
				}
			}
		}
	}
	
	function checkDivisi (noteRest) {
		if (noteRest.notes.length > 1) {
			// we have a chord
			//logError ('Checking div — isDiv = '+isDiv+' flaggedDivError = '+flaggedDivError+' isStringHarmonic = '+isStringHarmonic);
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
	
	function checkPizzIssues (noteRest) {
					
		lastArticulationTick = currTick;
		if (currentStaffNum == lastPizzIssueStaff && currentBarNum - lastPizzIssueBar < 5) return;
		
		// check staccato		
		var theArticulationArray = getArticulations(noteRest);
		if (theArticulationArray.length > 0) {
			for (var i = 0; i < theArticulationArray.length; i++) {
				if (theArticulationArray[i].visible) {
					if (staccatoArray.includes(theArticulationArray[i].symbol)) {
						addError("It’s not recommended to have a\nstaccato articulation on a pizzicato note.", noteRest);
						lastPizzIssueBar = currentBarNum;
						lastPizzIssueStaff = currentStaffNum;
						return;
					}
				}
			}
		}
		
		// check dur >= minim
		if (noteRest.duration.ticks > 2 * division) {
			addError("It’s not recommended to have a pizzicato longer\nthan a minim unless the tempo is very fast.\nPerhaps this is supposed to be arco?",noteRest);
			lastPizzIssueBar = currentBarNum;
			lastPizzIssueStaff = currentStaffNum;
			return;
		}
		
		// check tied pizz
		if (noteRest.notes[0].tieForward && !isLv) {
			addError("In general, don’t tie pizzicato notes.\nPerhaps this is supposed to be arco?",noteRest);
			lastPizzIssueBar = currentBarNum;
			lastPizzIssueStaff = currentStaffNum;
			return;
		}
		
		// check slurred pizz
		if (isSlurred) {
			addError("In general, don’t slur pizzicato notes unless you\nspecifically want the slurred notes not to be replucked.", noteRest);
			lastPizzIssueBar = currentBarNum;
			lastPizzIssueStaff = currentStaffNum;
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
	
	function checkSlurIssues (noteRest, currentSlur) {
		//logError("Slur off1 "+currentSlur.slurUoff1+" off2 "+currentSlur.slurUoff2+" off3 "+currentSlur.slurUoff3+" off4 "+currentSlur.slurUoff4);
		var currSlurTick = noteRest.parent.tick;
		
		
		
		if (isStartOfSlur && isStringInstrument && currentSlurLength > division * 8) addError("This slur looks very long for a string instrument,\n and may need to be broken into multiple slurs.",currentSlur);
		
		if (isEndOfSlur && isRest) addError ("This slur seems to end on a rest.\nWas it supposed to be an l.v. tie instead?",currentSlur);

		// **** CHECK WHETHER SLUR HAS BEEN MANUALLY SHIFTED **** //
		if (isStartOfSlur && (flaggedManualSlurBarNum == -1 || flaggedManualSlurBarNum < currentBarNum - 4)) {
			if (currentSlur.offsetY != 0 && currentSlur.offsetX != 0) {
				addError ("This slur looks like it has been dragged from its correct position.\nIf this was not deliberate, you can reset its position by\nselecting the slur and pressing "+cmdKey+"-R.",currentSlur);
				flaggedManualSlurBarNum = currentBarNum;
			} else {
				if (currentSlur.offsetY != 0) {
					addError ("This slur looks like it has been dragged vertically from its correct position.\nIf this was not deliberate, you can reset its position by\nselecting the slur and pressing "+cmdKey+"-R.",currentSlur);
					flaggedManualSlurBarNum = currentBarNum;
				}
				if (currentSlur.offsetX != 0) {
					addError ("This slur looks like it has been dragged horizontally from its correct position.\nIf this was not deliberate, you can reset its position by\nselecting the slur and pressing "+cmdKey+"-R.",currentSlur);
					flaggedManualSlurBarNum = currentBarNum;
				}
			}
			if (Math.abs(currentSlur.spanner.slurUoff1.x) > 0.5 || Math.abs(currentSlur.spanner.slurUoff4.x) > 0.5) {
				addError ("This slur looks like it has been manually positioned by dragging an endpoint.\nIt’s usually best to use the automatic positioning of MuseScore by first\nselecting all of the notes under the slur, and then adding the slur.",currentSlur);
				flaggedManualSlurBarNum = currentBarNum;
			}
		}
		
		// **** CHECK SLUR GOING OVER A REST FOR STRINGS, WINDS & BRASS **** //
		if (isRest) {
			if ((isWindOrBrassInstrument || isStringInstrument) && !flaggedSlurredRest && currentSlurLength > 0) {
				//logError("slurStart "+currentSlurStart+"; slurEnd "+currentSlurEnd+"; isRest: "+isRest+"; currTick = "+currTick);
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
				
				if (!isStartOfSlur && prevNote != null && prevSlurNumOnTrack[currentTrack] == currentSlurNumOnTrack[currentTrack] && noteRest.notes[0].tieBack == null) {
						
					var noteheadStyle = noteRest.notes[0].headGroup;
					var prevNoteheadStyle = prevNote.notes[0].headGroup;
					if (noteRest.notes.length == prevNote.notes.length) {
						var numNotes = noteRest.notes.length;
						var numPrevNotes = prevNote.notes.length;
						
						// does it have the same number of notes?
						var chordMatches = numNotes == numPrevNotes;
						
						// are the pitches identical?
						if (chordMatches) for (var i = 0; i < numNotes && chordMatches; i++) if (noteRest.notes[i].pitch != prevNote.notes[i].pitch) chordMatches = false;

						if (chordMatches && noteheadStyle == prevNoteheadStyle) {
							if (getArticulations(noteRest).length == 0) {
								if (isEndOfSlur && prevWasStartOfSlur) {
									addError("A slur has been used between two notes of the same pitch.\nIs this supposed to be a tie, or do you need to add articulation?",currentSlur);
								} else {
									var errStr = "";
									if (numNotes == 1) {
										errStr = "Don’t repeat the same note under a slur. Either remove the slur,\nor add some articulation (e.g. tenuto/staccato).";
									} else {
										errStr = "Don’t repeat the same chord under a slur. Either remove the slur,\nor add some articulation (e.g. tenuto/staccato).";
									}
									if (isStringInstrument) errStr += '\n(Ignore this message if these notes are played on different strings)';
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
				if (isMiddleOfTie) {
					addError("Don’t end a slur in the middle of a tied note.\nExtend the slur to the end of the tie.",currentSlur);
					return;
				}
				if (isStartOfTie && !prevWasGraceNote && !isLv) {
					addError("Don’t end a slur at the beginning of a tied note.\nInclude the full duration of tied note in the slur.",currentSlur);
					return;
				}
			}
			
			// Check slurs starting from end of tie
			if (isStartOfSlur) {
				if (isMiddleOfTie) {
					addError("Don’t start a slur in the middle of a tied note.\nExtend the slur back to the start of the tie.",currentSlur);
					return;
				}
				if (isEndOfTie &&  !prevWasGraceNote && !isLv) {
					addError("Don’t start a slur at the end of a tied note.\nInclude the full duration of the tied note in the slur.",currentSlur);
					return;
				}
			}
			
			if (!isStartOfSlur && !isEndOfSlur) {
			
				var theArticulationArray = getArticulations(noteRest);
				if (theArticulationArray.length > 0) {
					for (var i = 0; i < theArticulationArray.length; i++) {
						if (theArticulationArray[i].visible) {
							if (accentsArray.includes(theArticulationArray[i].symbol) ) {
								if (isStringInstrument) addError("In general, avoid putting accents on notes in the middle of a slur\nas strings usually articulate accents with a bow change.",noteRest);
								if (isWindOrBrassInstrument) addError("In general, avoid putting accents on notes in the middle of a slur\nas winds and brass usually articulate accents with their tongue.",noteRest);
								return;
							}
						}
					}
				}
			}
		}
		
		// ** check bow length and dynamic
		if (isStartOfSlur && isStringInstrument) {
			// dynamicLevel — 0 = ppp–p, 1 = mp, 2 = mf, 3 = f, 4 = ff+
			var maxSlurDurations = [8,6,4,3,2];
			var maxSlurDuration = maxSlurDurations[currDynamicLevel];
			var cursor2 = curScore.newCursor();

			cursor2.staffIdx = currentStaffNum;
			cursor2.track = 0;
			cursor2.rewindToTick(currSlurTick);
			var beatDurInSecs = 1./cursor2.tempo;
			var tickDurInSecs = beatDurInSecs / division;
			var slurDurInSecs = currentSlurLength*tickDurInSecs;
			if (slurDurInSecs > maxSlurDuration) addError ("This slur/bow mark may be too long at the stated dynamic.\nCheck with a performer whether a shorter one would be more appropriate.",currentSlur);
		}
		
	}
	
	function checkDecayInstrumentIssues(noteRest) {
		var dur = noteRest.duration.ticks;
		var n = noteRest.notes[0];
		
		// don't check decay instrument issues if this instrument is marked as arco
		// or if this is a note with a tie going backwards
		if (isArco || n.tieBack != null) return;
		var isTied = n.tieForward != null;
		//logError ('dur = '+dur+'; isTremolo = '+isTremolo+'; isTrill = '+isTrill+' isTied = '+isTied);
		if (isShortDecayInstrument) {
			if ((dur >= division * 2 || (dur >= division && isTied)) && !isTremolo && !isTrill && !isLv) {
				addError ("This note looks like a long duration without a tremolo or trill,\nwhich may be confusing for an instrument that has no natural sustain.\nConsider shortening to one beat.",noteRest);
			}
		} else {
			if (!isPiano) {
				if ((dur > division * 4 || (dur > division * 3 && isTied)) && !isTremolo && !isTrill) {
					addError ("This note looks like a long duration without a tremolo or trill,\nwhich may be confusing for an instrument that can’t sustain\nthe same dynamic for very long. Consider shortening it.",noteRest);
				}
			}
		}
		var nextNoteRest = getNextNoteRest(noteRest);
		var currentBarStart = currentBar.firstSegment.tick;
		var whichBeat1 = Math.trunc((currTick - currentBarStart) / beatLength);
		
		// ** FOR INSTRUMENTS WITH A LONG DECAY, e.g. PEDALLED PIANO, HARP, VIBRAPHONE, ETC.
		// ** CHECK TO SEE WHETHER THEY HAVE WRITTEN A SHORT NOTE FOLLOWED BY A REST
		// ** WITHOUT ANY L.V.
		if (isLongDecayInstrument) {
			if (nextNoteRest != null && !isLv) {
				var whichBeat2 = Math.trunc((nextNoteRest.parent.tick - currentBarStart) / beatLength);
				if (nextNoteRest.type == Element.REST && (whichBeat2 - whichBeat1 < 2)) {
					if (noteRest.duration.ticks < division*2 && !isTied) {
						// is the next note in the same bar?
						var flagError = nextNoteRest.parent.parent.is(noteRest.parent.parent);
						
						// if this is a pedal instrument, is the pedal down?
						if (flagError && isPedalInstrument) flagError = isPedalled;
						if (flagError) {
							if (isPedalInstrument) {
								addError ("As the pedal is down, notes will sustain.\nShort notes may therefore be ambiguous.\nConsider using an l.v. marking or\nlengthening the note to avoid the rests.",noteRest);
							} else {
								addError ("As this instrument naturally sustains, short\nnotes followed by rests may be ambiguous.\nConsider using an l.v. marking or\nlengthening the note to avoid the rests.",noteRest);
							}
						}
					}
				}
			}
		}
	}
	
	function checkHarpIssues () {
		
		var cursor2 = curScore.newCursor();

		// collate all the notes in this bar
		var allNotes = [];
		
		var endStaffNum = currentStaffNum;
		if (isTopOfGrandStaff[currentStaffNum]) endStaffNum ++;
		for (var staffNum = currentStaffNum; staffNum <= endStaffNum; staffNum ++) {
			// set cursor staff
			for (var theTrack = staffNum * 4; theTrack < staffNum * 4 + 4; theTrack ++) {
				cursor2.filter = Segment.ChordRest;
				cursor2.track = theTrack;
				cursor2.rewindToTick(barStartTick);
				var processingThisBar = cursor2.element && cursor2.tick < barEndTick;
			
				while (processingThisBar) {
					var currSeg = cursor2.segment;
					var theTick = currSeg.tick;
					var noteRest = cursor2.element;
					if (noteRest.type == Element.CHORD) {
						var theNotes = noteRest.notes;
						var nNotes = theNotes.length;
						if (allNotes[theTick] == undefined) allNotes[theTick] = [];
						for (var  i = 0; i < nNotes; i++) allNotes[theTick].push(theNotes[i]);
					}
					processingThisBar = cursor.next() ? cursor.measure.is(currentBar) : false;
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
					var theTick = theNotes[j].parent.tick;
					if (tpc < 6) {
						addError ("You can’t use double flats in harp parts.", nn[i]);
						continue;
					}
					if (tpc > 26) {
						addError ("You can’t use double sharps in harp parts.", nn[i]);
						continue;
					}
					var pedalSetting = parseInt((tpc - 6) / 7);
					var pedalNumber = tpc % 7;
					//logError("tpc "+tpc+" pedalSetting "+pedalSetting+" pedalNum "+pedalNumber+" pedalSetting "+pedalSettings[pedalNumber]);
					
					// **** TO DO: ADD SECTION WHERE WE LOOK TO SEE HOW LONG AGO THE LAST PEDAL SETTING WAS — ARE THEY ALL IN THE LAST 4 BEATS? **** //
					
					if (pedalSettings[pedalNumber] == -1) {
						//logError(pedalLabels[pedalNumber]+pedalAccs[pedalSetting]);
						pedalSettings[pedalNumber] = pedalSetting;
						pedalSettingInThisChord[pedalNumber] = pedalSetting;
						pedalSettingLastNeededTick[pedalNumber] = theTick;
					} else {
						if (pedalSettings[pedalNumber] != pedalSetting) {
							// change of pedal
		
							pedalSettings[pedalNumber] = pedalSetting;
							// only mark if it was last changed
							if (pedalSettingLastNeededTick[pedalNumber] != -1 && theTick - pedalSettingLastNeededTick[pedalNumber] < 4 * division) pedalChangesInThisBar ++;
							//logError("pedalChangesInThisBar now "+pedalChangesInThisBar);
		
							if (pedalChangesInThisBar > 2 && !flaggedPedalChangesInThisBar) {
								addError ("There are a number of pedal changes in this bar.\nIt might be challenging for the harpist to play.",noteRest);
								flaggedPedalChangesInThisBar = true;
							}
						}
						pedalSettingLastNeededTick[pedalNumber] = theTick;
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
	
	function checkStemsAndBeams (noteRest) {
		// REINSTATE THIS ONCE THE API SUPPORTS USER_MODIFIED PROPERTY
		/*if (noteRest.beam) {
			var theBeam = noteRest.beam;
			if (!theBeam.is(prevBeam)) {
				if (!theBeam.generated) addError ("This beam seems to have been moved away from its\ndefault position. If this was not deliberate, you can reset it\nby selecting it and pressing "+cmdKey+"-R",noteRest);
				prevBeam = theBeam;
			}
		}*/
		//logError ('Checking stems and beams');
		for (var i = 0; i < noteRest.notes.length; i ++) {
			var theNote = noteRest.notes[i];
			//logError ('theNote.mirrorHead = '+theNote.mirrorHead);
			if (theNote.mirrorHead != DirectionH.AUTO) {
				addError ('This notehead has been manually positioned and may look wrong.\nYou can revert to automatic placement by selecting the notehead and\nchoosing Properties→Note→Head→Show more→Note direction→Auto.',theNote);
			}
		}
		if (noteRest.stem) {
			//logError ('noteRest.stem');
			var stemDir = noteRest.stem.stemDirection;
			var staffLines = currentStaff.lines(fractionFromTicks(currTick));
			// 1 → 0; 2 → 1; 3→ 2; etc.
			var midLine = staffLines - 1;
			if (stemDir != Direction.AUTO) {
				if (noteRest.beam == null) {
					//calc dir
					var calcDir = 0;
					var nNotes = noteRest.notes.length;
					if (nNotes == 1) {
						if (noteRest.notes[0].line < midLine) calcDir = 2;
						if (noteRest.notes[0].line > midLine) calcDir = 1;
					} else {
						var minL = noteRest.notes[0].line - midLine;
						var maxL = minL;
					
						for (var i=1; i<nNotes; i++) {
							var l = noteRest.notes[i].line - midLine;
							if (l < minL) minL = l;
							if (l > maxL) maxL = l;
						}
						if (Math.abs(minL) > Math.abs(maxL)) calcDir = 2;
						if (Math.abs(minL) < Math.abs(maxL)) calcDir = 1;
					}
					if ((lastStemDirectionFlagBarNum == -1 || currentBarNum > lastStemDirectionFlagBarNum + 8) && calcDir > 0 && stemDir != calcDir) {
						logError ('calcDir = '+calcDir+'; noteRest.notes[0].line = '+noteRest.notes[0].line);
						addError("Note has had stem direction flipped. If this is not deliberate,\nselect the note and press "+cmdKey+"-R.",noteRest);
						lastStemDirectionFlagBarNum = currentBarNum;
					}
				}
			}
			 //logError ('numVoicesInThisBar = '+numVoicesInThisBar);
			if (numVoicesInThisBar == 1) {
				if (noteRest.beam != null) {
					// is this the start of the beam?
					var currBeam = noteRest.beam;
					//logError ('beamFound — checking for equality with prev');
					if (!currBeam.is(prevBeam)) {
						// beamPos tells you where the exactly the top left-hand part of the beam is
						// A measurement of 0 is the top line
						// A negative measurement means above the top line
						// A positive measure means below the top line 
						var beamPosY = parseFloat(currBeam.beamPos.toString().match(/-?[\d\.]+/g)[1]); 
						//logError ('Checking beam pos: '+beamPosY);
						
						// unfortunately I can't figure out a way to access QPair in Qt
						//logError ('beamPos = '+beamPosY);
						//start of a new beam
						// collate all beams into an array
						prevBeam = currBeam;
						var notesInBeamArray = [];
						var currNote = noteRest;
						var isCrossStaff = false;
						while (currNote.beam != null) {
							if (!currNote.beam.is(currBeam)) break;
							if (currNote.staffMove != 0) isCrossStaff = true;

							// don't add rests to the beam array
							if (currNote.notes != null) notesInBeamArray.push(currNote);
							//logError ('Pushed note with pitch '+currNote.notes[0].pitch);
							currNote = getNextNoteRest (currNote);
							if (currNote == null) break;
						}
	
						var numNoteRests = notesInBeamArray.length;
						
						if (numNoteRests > 1) {
							var maxTopOffset = 0;
							var maxBottomOffset = 0;
							for (var i = 0; i<numNoteRests; i++) {
								var noteRestToCheck = notesInBeamArray[i];
								
								// Go through notes in the chord
								for (var j = 0; j < noteRestToCheck.notes.length; j++) {
									var note = noteRestToCheck.notes[j];
									var offsetFromMiddleLine = 4 - note.line; 
									// note.line: 0 = top line, 1 = top space, 2 = second top line, etc...
									// offsetFromMiddleLine: 0 = middle line, 1 = C, 2 = D etc.
									//logError ('Note '+j+': pitch = '+note.pitch+' offset = '+offsetFromMiddleLine);
									if (offsetFromMiddleLine < maxBottomOffset) maxBottomOffset = offsetFromMiddleLine;
									if (offsetFromMiddleLine > maxTopOffset) maxTopOffset = offsetFromMiddleLine;					
								}
							}
							// only check if the beams have to go a particular way
							//logError ('maxBottomOffset = '+maxBottomOffset+' maxTopOffset = '+maxTopOffset);
							if (Math.abs(maxBottomOffset) != Math.abs(maxTopOffset)) {
								//var maxOffsetFromMiddleLine = 0;
								var whichWayStemsShouldGo = 0;
								var calcExtremeNotePos = 0;
								if (Math.abs(maxBottomOffset) > Math.abs(maxTopOffset)) {
									//maxOffsetFromMiddleLine = Math.abs(maxBottomOffset);
									whichWayStemsShouldGo = 2; // stems should go up
									calcExtremeNotePos = (4-maxBottomOffset) * 0.5;
								} else {
									//maxOffsetFromMiddleLine = Math.abs(maxTopOffset);
									whichWayStemsShouldGo = 1; // stems should go down
									calcExtremeNotePos = (4-maxTopOffset) * 0.5;
								}
								// 1 is stems down; 2 is stems up
								// note beamPosY is the of spatiums from the top line of the staff, where negative is further up
								var calcDir = (beamPosY < calcExtremeNotePos) ? 2 : 1;
								//logError ('I calculated direction as '+calcDir+' shouldbe = '+whichWayStemsShouldGo+' because beamPosY is '+beamPosY+' maxOffset = '+maxOffsetFromMiddleLine+' and calcExtremeNotePos is '+calcExtremeNotePos);
								if (whichWayStemsShouldGo == 1 && calcDir != 1 && !isCrossStaff) addError ('This beam should be below the notes, but appears to be above.\nIf not intentional, select the beam and press '+cmdKey+'-R', noteRest);

								if (whichWayStemsShouldGo == 2 && calcDir != 2 && !isCrossStaff) addError ('This beam should be above the notes, but appears to be below.\nIf not intentional, select the beam and press '+cmdKey+'-R', noteRest);
							}
						}
					}
				}
			}
		}
	}
	
	function checkGraceNotes (graceNotes,noteRest) {

		//logError ('Checking grace notes');
		var n = graceNotes.length;
		if (n == 0) return;
		
		// ** RUN THROUGH CHECKS WITH THE GRACE NOTES ** //
		for (var i = 0; i < n; i ++) {
			var theGraceNote = graceNotes[i];
			checkSpanners(theGraceNote);
		}
		if (n == 1) {
			
			// ** CHECK GRACE NOTE HAS THE RIGHT KIND OF STEM/FLAG/BEAM/SLASH ** //
			// ** AS PER 'BEHIND BARS', p. 125 							 	  ** //
			var hasStem = graceNotes[0].stem != null;
			if (hasStem) {
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
		}
		if (n > 1 && graceNotes[0].duration.ticks < division * 0.25) addError ("It is recommended that grace notes use only\n1 or 2 beams (see ‘Behind Bars’, p. 125).",graceNotes[0]);
		
		// ** CHECK WHETHER THE GRACE-NOTES ARE SLURRED TO THE MAIN NOTE OR NOT ** //
		// ** EXCEPTIONS ARE: ARTICULATION, SAME NOTE							** //
		if (!isSlurred) {
			var theArtic = getArticulations(graceNotes[n-1]);
			var hasArtic = theArtic != null;
			var gnIsTied = graceNotes[n-1].notes[0].tieForward != null || graceNotes[n-1].notes[0].tieBack != null;
			var gnIsSamePitch = false;
			if (graceNotes[n-1].notes.length > 0 && noteRest.notes.length > 0) gnIsSamePitch = graceNotes[n-1].notes[0].pitch == noteRest.notes[0].pitch;
			if (!hasArtic && !gnIsTied && !gnIsSamePitch) addError("In general, slur grace-notes to the main note,\nunless you use staccatos or accents.",graceNotes);
		} else {
			if (graceNotes[n-1].notes.length > 0 && noteRest.notes.length > 0) gnIsSamePitch = graceNotes[n-1].notes[0].pitch == noteRest.notes[0].pitch;
			if (gnIsSamePitch) addError ("This grace note is the same pitch as the main note,\nbut is slurred. Is that meant to be a tie?",graceNotes[n-1]);
		}
	}
	
	function checkRehearsalMark (textObject) {
		
		if (currentStaffNum != firstVisibleStaff) return;
		//logError("Found reh mark "+textObject.text);
		if (!isOnFirstBeatOfBar(textObject)) addError ("This rehearsal mark is not attached to beat 1.\nAll rehearsal marks should be above the first beat of the bar.",textObject);
		//logError ("Checking rehearsal mark");
		if (currentBarNum < 2) addError ("Don’t put a rehearsal mark at the start of the piece.\nUsually your first rehearsal mark will come about 12–20 bars in.",textObject);
		var isNumeric = !isNaN(textObject.text) && !isNaN(parseFloat(textObject.text));
		if (!isNumeric) {
			var rehearsalMarkNoTags = textObject.text.replace(/<[^>]+>/g, "");
			if (rehearsalMarkNoTags !== expectedRehearsalMark && !flaggedRehearsalMarkError) {
				//logError ('expectedRehearsalMark = '+expectedRehearsalMark);
				flaggedRehearsalMarkError = true;
				addError ("This is not the rehearsal mark I expected (‘"+expectedRehearsalMark+"’).\nTo renumber all of the rehearsal marks, Select All,\nand choose Tools→Resequence Rehearsal Marks.", textObject);
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
					addError("There are only "+numRehearsalMarks+" rehearsal marks.\nWe recommend adding rehearsal marks every 8–16 bars, approximately.","pagetop");
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
	
	function checkOneNoteTremolo (noteRest) {
		var tremolo = noteRest.tremoloSingleChord; // introduced in MS 4.6
		if (tremolo == null || tremolo == undefined) logError("checkOneNoteTremolo() — tremolo is "+tremolo);
		lastArticulationTick = currTick;
		var tremSubdiv = tremolo.tremoloType;
		if (tremSubdiv > 4) tremSubdiv -= 5;
		var numStrokes = tremSubdiv + 1;
		//logError ('numStrokes = '+numStrokes);
		var dur = parseFloat(noteRest.duration.ticks) / division;
		
		switch (numStrokes) {
			case 0:
				logError("checkOneNoteTremolo() — Couldn’t calculate number of strokes");
				break;
			case 1:
				if (dur > 0.5 && !flaggedOneStrokeTrem) addError("Are you sure you want a one-stroke measured tremolo here?\nThese are almost always better written as quavers.",noteRest);
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
		if (isSlurred && !isWindOrBrassInstrument) addError("In general, don’t slur a tremolo.",noteRest);
		if (isWindOrBrassInstrument && !flzFound && !flaggedFlz) {
			addError ("I couldn't find an associated ‘flzg.’\nmarking for this fluttertongue note.",noteRest);
			flaggedFlz = true;
		}
		var hasStaccato = false;
		var theArticulationArray = getArticulations(noteRest)
		for (var i = 0; i < theArticulationArray.length; i++) {
			if (theArticulationArray[i].visible) {
				if (staccatoArray.includes(theArticulationArray[i].symbol)) {
					hasStaccato = true;
					break;
				}
			}
		}
		if (hasStaccato) addError ("It doesn’t make sense to have a staccato articulation on a tremolo.",noteRest);
	}
	
	function checkTwoNoteTremolo (noteRest) {
		var tremolo = noteRest.tremoloTwoChord;
		if (tremolo == null || tremolo == undefined) logError("checkTwoNoteTremolo() — tremolo is "+tremolo);
		lastArticulationTick = currTick;
		var tremSubdiv = tremolo.tremoloType;
		if (tremSubdiv > 4) tremSubdiv -= 5;
		var numStrokes = tremSubdiv + 1;
		//logError ('numStrokes = '+numStrokes);

		var dur = 2 * parseFloat(noteRest.duration.ticks) / division;
		//logError("TWO-NOTE TREMOLO HAS "+numStrokes+" strokes; dur is "+dur+"; isSlurred = "+isSlurred+"; isPitchedPercussionInstrument = "+isPitchedPercussionInstrument);
		if (!isSlurred) {
			if (isStringInstrument) {
				addError("Fingered tremolos for strings should always be slurred.",noteRest);
				return;
			}
			if (isWindOrBrassInstrument) {
				addError("Two-note tremolos for winds or brass should always be slurred.",noteRest);
				return;
			}
		}
		if (isPitchedPercussionInstrument) {
			addError("It’s best to write "+currentInstrumentName.toLowerCase()+" tremolos as one-note tremolos (through stem),\nrather than two-note tremolos (between notes).",noteRest);
			return;
		}
		switch (numStrokes) {
			case 0:
				logError("checkTwoNoteTremolo() — Couldn’t calculate number of strokes");
				break;
			case 1:
				if (dur > 0.5) addError("Are you sure you want a one-stroke measured tremolo here?\nThese are almost always better written as quavers.",noteRest);
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
		
		var hasStaccato = false;
		var theArticulationArray = getArticulations(noteRest);
		for (var i = 0; i < theArticulationArray.length; i++) {
			if (theArticulationArray[i].visible) {
				if (staccatoArray.includes(theArticulationArray[i].symbol)) {
					hasStaccato = true;
					break;
				}
			}
		}
		if (hasStaccato) addError ("It doesn’t make sense to have a staccato articulation on a tremolo.",noteRest);
	}
	
	function checkSpanners (noteRest) {
		var notes = noteRest.notes;
		for (var i = 0; i < notes.length; i++) {
			var note = notes[i];
			var spanners = note.spannerForward;
			for (var j = 0; j < spanners.length; j++) {
				var spanner = spanners[j];
				var spannerType = spanner.type;
				if (spannerType == Element.GLISSANDO || spannerType == Element.GLISSANDO_SEGMENT) {
					checkGliss(noteRest,spanner);
				}
			}
		}
	}
	
	function checkGliss (noteRest, gliss) {
		//logError ('Found gliss');
		if (gliss == null || gliss == undefined) logError("checkGliss() — gliss is "+gliss);
		if (gliss.glissType == Glissando.WAVY) {
			if (isStringInstrument) addError ("Strings generally don’t read wavy glissando lines.\nIn Properties→Glissando, change to ‘Straight’.",gliss);
			if (isTrombone) addError ("Trombones can’t perform wavy glissandi, unless it’s a rip.\nIn Properties→Glissando, change to ‘Straight’.",gliss);
		}
		if (gliss.glissType == Glissando.STRAIGHT) {
			var nextNoteRest = getNextNoteRest(noteRest);
			if (nextNoteRest != null) {
				if (nextNoteRest.type == Element.CHORD) {
					var p1 = noteRest.notes[0].pitch;
					var p2 = nextNoteRest.notes[0].pitch;
					var interval = Math.abs (p2 - p1);
					if (isWindInstrument) {
						if (interval > 4) addError ("This gliss. may be too wide to perform smoothly\nand may be better notated as a wavy gliss.\nCheck with a performer.", gliss);
					}
					if (isTrombone) {
						if (interval > 6 && interval < 12) addError ("This gliss. is too wide to be a slide gliss\nand too narrow to be a rip.\nPerhaps reconsider or check with a performer.", gliss);
						if (p1 < 54 && p2 < 54) {
							var h1 = Math.floor((p1 - 40) / 6);
							var h2 = Math.floor((p2 - 40) / 6);
							if (h1 != h2) addError ("This gliss. is not possible on the tenor trombone.\nYou might want to reconsider.", gliss);
						}
					}
				}
				if (isSameChord (noteRest, nextNoteRest)) addError ("This looks like a gliss. between the same note.\nIs that correct?", gliss);
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
			logError("addError() — ‘element’ undefined for error: "+text);
		} else {
			errorStrings.push(text);
			errorObjects.push(element);
		}
	}
	
	//---------------------------------------------------------
	//	showAllErrors
	//	goes through array of errors, setting up comment boxes
	//	and automatically positioning them to avoid
	//	collisions
	//---------------------------------------------------------
	
	function showAllErrors () {
		
		var firstStaffNum = 0;
		var comments = [];
		var commentPages = [];
		var commentPageNumbers = [];
		var commentsDesiredPosX = [];
		var commentsDesiredPosY = [];
		var pages = curScore.pages;
		
		for (var i = 0; i < (curScore.nstaves-1) && !curScore.staves[i].part.show; i++) firstStaffNum ++;
		
		// limit the number of errors shown to 100 to avoid a massive wait
		var numErrors = (errorStrings.length > 100) ? 100 : errorStrings.length;
		var desiredPosX, desiredPosY;
		
		// create new cursor to add the comments
		var commentCursor = curScore.newCursor();
		commentCursor.filter = Segment.ChordRest;
		
		// save undo state
		curScore.startCmd();

		for (var i = 0; i < numErrors; i++) {

			var theText = errorStrings[i];
			var element = errorObjects[i];
			var objectArray = (Array.isArray(element)) ? element : [element];
			desiredPosX = desiredPosY = 0;
			
			for (var j = 0; j < objectArray.length; j++) {

				element = objectArray[j];
				var eType = element.type;
				var isString = eType == undefined;
				var eSubtype = isString ? '' : element.subtypeName();
				var staffNum = firstStaffNum;
			
				// the errorObjects array includes a list of the Elements to attach the text object to
				// Instead of an Element, you can use one of the following strings instead to indicate a special location unattached to an element:
				// 		top 			— top of bar 1, staff 1
				// 		pagetop			— top left of page 1
				//		pagetopright	— top right of page 1
				//		system1 n		— top of bar 1, staff n
				//		system2 n		— first bar in second system, staff n
			
				var theLocation = element;
				if (isString) {
					if (element.includes(' ')) {
						staffNum = parseInt(element.split(' ')[1]); // put the staff number as an 'argument' in the string
						theLocation = element.split(' ')[0];
						if (theLocation.includes('system') && theLocation !== 'system1' && !hasMoreThanOneSystem) continue; // don't show if only one system
					}
				} else {
					// calculate the staff number that this element is on
					if (element.bbox == undefined) {
						logError("showAllErrors() — bbox undefined — elem type is "+element.name);
					} else {
						if (eType != Element.MEASURE) {
							var elemStaff = element.staff;
							if (elemStaff == undefined) {
								isString = true;
								theLocation = "";
								desiredPosX = element.pagePos.x;
								desiredPosY = element.pagePos.y;
							} else {
								staffNum = element.staffIdx;
								// Handle the case where a system-attached object reports a staff that is hidden
								if (eType == Element.TEMPO_TEXT || eType == Element.SYSTEM_TEXT || eType == Element.REHEARSAL_MARK || eType == Element.METRONOME) {
									staffNum = element.effectiveStaffIdx;
								}
							}
						}
					}
				}
				
				// style the element
				if (element !== "pagetop" && element !== "top" && element !== "pagetopright") {
					if (eType == Element.CHORD) {
						element.color = "hotpink";
						for (var k = 0; k<element.notes.length; k++) element.notes[k].color = "hotpink";
					} else {
						element.color = "hotpink";
					}
				}
				
				// add text object to score for the first object in the array
				if (j == 0) {
					var tick = 0;		
					if (isString) {
						if (theLocation.includes("pagetop")) {
							desiredPosX = 2.5;
							desiredPosY = 2.5;
						}
						if (theLocation.includes('system')) {
							desiredPosX = 5.0;
							if (theLocation === 'system2') {
								tick = firstBarInSecondSystem.firstSegment.tick;
							} else {
								if (theLocation !== 'system1') {
									var sysNum = parseInt(theLocation.substring(6));
									tick = curScore.systems[sysNum-1].firstMeasure.firstSegment.tick;
								}
							}
						}
					} else {
						tick = getTick(element);
					}
					
					commentCursor.staffIdx = staffNum;
					commentCursor.track = staffNum * 4;
					commentCursor.rewindToTick(tick);
					
					// add a text object at the location where the element is
					var comment = newElement(Element.STAFF_TEXT);
					comment.text = theText;
					
					// style the text object
					comment.frameType = 1;
					comment.framePadding = 0.6;
					comment.frameWidth = 0.2;
					comment.frameBgColor = "yellow";
					comment.frameFgColor = "black";
					comment.fontSize = 7.0;
					comment.fontFace = "Helvetica";
					comment.align = Align.TOP;
					comment.autoplace = false;
					comment.offsetX = 0;
					comment.offsetY = 0;
					commentCursor.add(comment);
					comment.z = currentZ;
					currentZ ++;
					comments.push (comment);
					var commentPage = getPage(comment);
					// NOTE: I had tried pushing the page to an array, but that caused
					// all sorts of crashes further down the line. Instead, I push the page number
					// and just refer to that instead
					if (commentPage == null) {
						commentPageNumbers.push(0);
					} else {
						commentPageNumbers.push(commentPage.pagenumber);
					}
					commentsDesiredPosX.push (desiredPosX);
					commentsDesiredPosY.push (desiredPosY);
				}
			}
		} // var i

		// NOW TWEAK LOCATIONS OF COMMENTS
		var offx = [];
		var offy = [];
		var checkObjectPage = false;
		var objectPageNumber = 0;
		
		for (var i = 0; i < comments.length; i++) {
			
			var commentOffset = 1.0; // how much to shift it by each time
			var comment = comments[i];
			offx.push(0);
			offy.push(-(comment.bbox.height) - 2.5);			
			desiredPosX = commentsDesiredPosX[i];
			desiredPosY = commentsDesiredPosY[i];
			var commentHeight = comment.bbox.height;
			var commentWidth = comment.bbox.width;
			var element = null;
			var eType = 0;
			if (errorObjects.length < i-1) {
				logError ('errorObjects too short');
				element = null;
			} else {
				element = errorObjects[i];
				eType = element.type;
			}
			var isString = eType == undefined;
			var eSubtype = isString ? '' : element.subtypeName();

			checkObjectPage = false;
			if (eType == Element.TEXT) {
				checkObjectPage = true;
				objectPageNumber = getPageNumber(element);
			}
			theLocation = element;
			var placedX = comment.pagePos.x;
			var placedY = comment.pagePos.y;
			if (desiredPosX != 0) offx[i] = desiredPosX - placedX;
			if (desiredPosY != 0) offy[i] = desiredPosY - placedY;
			if (placedX + offx[i] < 0) offx[i] = -placedX;
			if (placedY + offy[i] < 0) offy[i] = -placedY;
			
			var pageNumber = commentPageNumbers[i];
			var commentPage = pages[pageNumber];
			
			if (commentPage) {
				var commentPageWidth = commentPage.bbox.width;
				var commentPageHeight = commentPage.bbox.height;
				var commentPageNumber = commentPageNumbers[i];
				
				// move over to the top right of the page if needed
				if (isString && theLocation === "pagetopright") offx[i] = commentPageWidth - commentWidth - 2.5 - placedX;
			
				// FIX IN 4.6 — Composer pagePos currently returning the wrong location
				if (eSubtype === 'Composer') {
					offx[i] = commentPageWidth - desiredPosX - placedX - commentWidth + 10.0;
					offy[i] += 4.0;
				}

				// check to see if this comment has been placed too close to other comments
				var maxOffset = 10;
				var minOffset = 1.5;
				var commentOriginalX = placedX;
				var commentOriginalY = placedY;
				var commentRHS = placedX + commentWidth;
				var commentB = placedY + commentHeight;
				
				// check comment is within the page bounds
				if (placedX < 0) offx[i] -= placedX; // LEFT HAND SIDE
				if (commentRHS > commentPageWidth) offx[i] -= (commentRHS - commentPageWidth); // RIGHT HAND SIDE
				if (placedY < 0) offy[i] -= placedY; // TOP
				if (commentB > commentPageHeight) offy[i] -= (commentB - commentPageHeight); // BOTTOM*/
				
				for (var k = 0; k < i; k++) {
					var otherComment = comments[k];
					var otherCommentPageNumber = commentPageNumbers[k];
					var otherCommentPage = pages[k];
					var otherCommentX = otherComment.pagePos.x + offx[k];
					var otherCommentY = otherComment.pagePos.y + offy[k];
					var actualCommentX = placedX + offx[i];
					var actualCommentRHS = commentRHS + offx[i];
					var actualCommentY = placedY + offy[i];
					var actualCommentB = commentB + offy[i];

					if (commentPageNumber == otherCommentPageNumber) {
						var dx = Math.abs(actualCommentX - otherCommentX);
						var dy = Math.abs(actualCommentY - otherCommentY);
						if (dx <= minOffset || dy <= minOffset) {
							var otherCommentRHS = otherCommentX + otherComment.bbox.width;
							var otherCommentB = otherCommentY + otherComment.bbox.height;
							var overlapsH = dy < minOffset && actualCommentX < otherCommentRHS && actualCommentRHS > otherCommentX;
							var overlapsV = dx < minOffset && actualCommentY < otherCommentB && actualCommentB > otherCommentY;
							var generalProximity = dx + dy < maxOffset;
							var isCloseToOtherComment =  overlapsH || overlapsV || generalProximity;
							var isNotTooFarFromOriginalPosition = true;
							//logError ("text = "+comment.text+"; otherText = "+otherComment.text+"; close = "+isCloseToOtherComment+"; far = "+isNotTooFarFromOriginalPosition+'; rhs = '+(actualCommentRHS < commentPageWidth)+' y = '+(actualCommentY > 0));
							var shiftAttempts = 0;
							while (isCloseToOtherComment && isNotTooFarFromOriginalPosition && actualCommentRHS < commentPageWidth && actualCommentY > 0 && shiftAttempts < 5) {
								shiftAttempts ++;
								if (actualCommentRHS < commentPageWidth - commentOffset) offx[i] += commentOffset;
								if (actualCommentY > commentOffset) offy[i] -= commentOffset;
								actualCommentX = placedX + offx[i];
								actualCommentY = placedY + offy[i];
								actualCommentRHS = actualCommentX + commentWidth;
								actualCommentB = actualCommentY + commentHeight;
								dx = Math.abs(actualCommentX - otherCommentX);
								dy = Math.abs(actualCommentY - otherCommentY);
								overlapsH = dy < minOffset && actualCommentX < otherCommentRHS && actualCommentRHS > otherCommentX;
								overlapsV = dx < minOffset && actualCommentY < otherCommentB && actualCommentB > otherCommentY;
								generalProximity = (dx <= minOffset || dy <= minOffset) && (dx + dy < maxOffset);
								isCloseToOtherComment =  overlapsH || overlapsV || generalProximity;
								isNotTooFarFromOriginalPosition = Math.abs(actualCommentX - commentOriginalX) < maxOffset && Math.abs(actualCommentY - commentOriginalY) < maxOffset;
								//logError ("Too close: shifting comment.offsetX = "+offx[i]+" comment.offsetY = "+offy[i]+" tooClose = "+isCloseToOtherComment);				
							}
						}
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
					} */
				}
				if (checkObjectPage && commentPageNumber != objectPageNumber) comment.text = '[The object this comment refers to is on p. '+(objectPageNumber+1)+']\n' +comment.text;
			}
		}

		// now reposition all the elements
		for (var i = 0; i < comments.length; i++) {
			var comment = comments[i];
			comment.offsetX = offx[i];
			comment.offsetY = offy[i];
		}
		curScore.endCmd();
	}

	//---------------------------------------------------------
	//	getTick
	//	returns the tick of the element
	//---------------------------------------------------------
	
	function getTick (e) {
		if (e == null) {
			logError ("getTick() — tried to get tick of null");
			return 0;
		}
		var eType = e.type;
		if (eType == Element.BEAM) {
			// In MS 4.6 currently, there's no way to get the tick of a beam, or to get its child elements to get their ticks
			// as such, we should probably avoid highlighting beams until this is fixed
			logError ('Found beam: tick = '+e.tick);
		}
		if (e.spanner != undefined) {
			return e.spanner.spannerTick.ticks;
		} else {
			if (eType == Element.MEASURE) {
				return e.firstSegment.tick;
			} else {
				if (e.parent == undefined || e.parent == null) {
					logError("getTick() — ELEMENT PARENT IS "+e.parent+"); etype is "+e.name);
				} else {
					var p;
					if (eType == Element.TUPLET) {
						p = e.elements[0].parent;
					} else {
						p = e.parent;
					}
					if (p != null) for (var i = 0; i < 10 && p.type != Element.SEGMENT; i++) {
						if (p.parent == null) {
							logError ("getTick() — Parent of "+e.name+" was null");
							return 0;
						}
						p = p.parent;
					}
					if (p.type == Element.SEGMENT) return p.tick;
				}
			}
		}
		return 0;
	}
	
	function getBar (e) {
		var p = e.parent;
		var ptype = null;
		if (p != null && p != undefined) ptype = p.type;
		while ((p != null && p != undefined) && ptype != Element.MEASURE) {
			p = p.parent;
			if (p != null && p != undefined) ptype = p.type;
		}
		if (p == undefined) p = null;
		return p;
	}
	
	function getBarNumber (e) {
		var theTick = getTick(e);
		return measureTicks.filter (e => e <= theTick).length;
	}
	
	function getPage (e) {
		var p = e.parent;
		var ptype = null;
		if (p != null && p != undefined) ptype = p.type;
		while ((p != null && p != undefined) && ptype != Element.PAGE) {
			p = p.parent;
			if (p != null && p != undefined) ptype = p.type;
		}
		if (p == undefined) p = null;
		return p;
	}
	
	function getPageNumber (e) {
		var p = getPage(e);
		if (p == null) return 0;
		return p.pagenumber;
	}
	
	function logError (str) {
		numLogs ++;
		errorMsg += "<p>Staff "+currentStaffNum+", b. "+(currentBarNum + displayOffset)+": "+str+"</p>";
	}
		
	function selectNone () {
		cmd('escape');
	}
	
	
	function deleteAllCommentsAndHighlights () {

		var elementsToRemove = [];
		var elementsToRecolor = [];
				
		// ** CHECK TITLE TEXT FOR HIGHLIGHTS ** //
		for (var i = 0; i < frames.length; i++) {
			var frame = frames[i];
			var elems = frame.elements;
			for (var j = 0; j < elems.length; j++) {
				var e = elems[j];
				var c = e.color;	
				// style the element pink
				if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
			}
		}
		
		// ** CHECK BRACKETS FOR HIGHLIGHTS ** //
		for (var i = 0; i < curScore.nstaves; i++) {
			var staff = curScore.staves[i];
			var brackets = staff.brackets;
			for (j = 0; j < brackets.length; j++) {
				var e = brackets[j];
				var c = e.color;
				if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
			}
		}
		
		// ** CHECK HEADER CLEFS FOR HIGHLIGHTS ** //
		var headerCursor = curScore.newCursor();
		headerCursor.filter = Segment.HeaderClef;
		for (var staffIdx = 0; staffIdx < curScore.nstaves; staffIdx ++) {
			headerCursor.staffIdx = staffIdx;
			headerCursor.voice = 0;
			headerCursor.rewind(Cursor.SCORE_START);
			if (headerCursor.element != undefined && headerCursor.element != null) {
				var e = headerCursor.element;
				var c = e.color;
				if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
			}
		}
		
		// **** SELECT ALL **** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
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
		for (var i = 0; i < elementsToRecolor.length; i++) elementsToRecolor[i].color = "black";
		curScore.startCmd();
		for (var i = 0; i < elementsToRemove.length; i++) removeElement(elementsToRemove[i]);
		curScore.endCmd();

	}
	
	StyledDialogView {
		id: dialog
		title: "CHECK COMPLETED"
		contentHeight: 232
		contentWidth: 505
		property var msg: ""
		property var titleText: ""
		property var fontSize: 18

		Text {
			id: theText
			width: parent.width-40
			anchors {
				left: parent.left
				top: parent.top
				leftMargin: 20
				topMargin: 20
			}
			text: dialog.titleText
			font.bold: true
			font.pointSize: dialog.fontSize
			color: ui.theme.fontPrimaryColor
		}
		
		Rectangle {
			id: dialogRect
			anchors {
				top: theText.bottom
				topMargin: 10
				left: parent.left
				leftMargin: 20
			}
			width: parent.width-45
			height: 2
			color: ui.theme.fontPrimaryColor
		}

		ScrollView {
			id: view
			anchors {
				top: dialogRect.bottom
				topMargin: 10
				left: parent.left
				leftMargin: 20
			}
			height: parent.height-100
			width: parent.width-40
			leftInset: 0
			leftPadding: 0
			ScrollBar.vertical.policy: ScrollBar.AsNeeded
			TextArea {
				height: parent.height
				text: dialog.msg
				textFormat: Text.RichText
				wrapMode: TextEdit.Wrap
				leftInset: 0
				leftPadding: 0
				readOnly: true
				background: Rectangle {
					color: "transparent"
				}
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
	
	//MARK: OPTIONS DIALOG
	StyledDialogView {
		id: options
		title: "MN CHECK LAYOUT & INSTRUMENTATION"
		contentHeight: 525
		contentWidth: 740
		property color backgroundColor: ui.theme.backgroundSecondaryColor
		
		Settings {
			property alias settingsScoreStyle: options.scoreStyle
			property alias settingsPartStyle: options.partStyle
			property alias settingsPageSettings: options.pageSettings
			property alias settingsMusicSpacing: options.musicSpacing
			property alias settingsStaffNamesAndOrder: options.staffNamesAndOrder
			property alias settingsFonts: options.fonts
			
			property alias settingsClefs: options.clefs
			property alias settingsTimeSignatures: options.timeSignatures
			property alias settingsKeySignatures: options.keySignatures
			property alias settingsOttavas: options.ottavas
			property alias settingsSlursAndTies: options.slursAndTies
			property alias settingsArticulation: options.articulation
			property alias settingsArpeggios: options.arpeggios
			property alias settingsTremolosAndFermatas: options.tremolosAndFermatas
			property alias settingsGraceNotes: options.graceNotes
			property alias settingsStemsAndBeams: options.stemsAndBeams
			property alias settingsExpressiveDetail: options.expressiveDetail
			property alias settingsBarStretches: options.barStretches
			
			property alias settingsDynamics: options.dynamics
			property alias settingsTempoMarkings: options.tempoMarkings
			property alias settingsTitleAndSubtitle: options.titleAndSubtitle
			property alias settingsSpellingAndFormat: options.spellingAndFormat
			property alias settingsRehearsalMarks: options.rehearsalMarks
			property alias settingsTextPositions: options.textPositions
			
			property alias settingsRangeRegister: options.rangeRegister
			property alias settingsOrchestralSharedStaves: options.orchestralSharedStaves
			property alias settingsVoice: options.voice
			property alias settingsWindsAndBrass: options.windsAndBrass
			property alias settingsPianoHarpAndPercussion: options.pianoHarpAndPercussion
			property alias settingsStrings: options.strings
		}
		
		property var numOptionsChecked: 0
		property var scoreStyle: true
		property var partStyle: true
		property var pageSettings: true
		property var musicSpacing: true
		property var staffNamesAndOrder: true
		property var fonts: true
		
		property var clefs: true
		property var timeSignatures: true
		property var keySignatures: true
		property var ottavas: true
		property var slursAndTies: true
		property var articulation: true
		property var arpeggios: true
		property var tremolosAndFermatas: true
		property var graceNotes: true
		property var stemsAndBeams: true
		property var expressiveDetail: true
		property var barStretches: true
		
		property var dynamics: true
		property var tempoMarkings: true
		property var titleAndSubtitle: true
		property var spellingAndFormat: true
		property var rehearsalMarks: true
		property var textPositions: true
		
		property var rangeRegister: true
		property var orchestralSharedStaves: true
		property var voice: true
		property var windsAndBrass: true
		property var pianoHarpAndPercussion: true
		property var strings: true
	
		Text {
			id: styleText
			anchors {
				left: parent.left;
				leftMargin: 20;
				top: parent.top;
				topMargin: 20;
				bottomMargin: 10;
			}
			text: "Options"
			font.bold: true
			font.pointSize: 16
			color: ui.theme.fontPrimaryColor
		}
		
		Rectangle {
			id: rect
			anchors {
				left: styleText.left;
				top: styleText.bottom;
				topMargin: 10;
			}
			width: parent.width-45
			height: 1
			color: ui.theme.fontPrimaryColor
		}
		
		GridLayout {
			id: grid
			columns: 3
			columnSpacing: 15
			rowSpacing: 10
			width: parent.width-20;
			anchors {
				left: rect.left;
				top: rect.bottom;
				topMargin: 10;
			}
			Text {
				id: layoutLabel
				text: "Layout"
				font.bold: true
				Layout.columnSpan: 3
				color: ui.theme.fontPrimaryColor
			}
            CheckBox {
                text: "Check optimal score style settings"
                checked: options.scoreStyle
                onClicked: { options.scoreStyle = !options.scoreStyle; checked = options.scoreStyle; }
            }
            CheckBox {
                text: "Check optimal part style settings"
                checked: options.partStyle
                onClicked: { options.partStyle = !options.partStyle; checked = options.partStyle; }
            }
            CheckBox {
                text: "Check optimal page settings"
                checked: options.pageSettings
                onClicked: { options.pageSettings = !options.pageSettings; checked = options.pageSettings; }
            }
            CheckBox {
                text: "Check names, order & brackets"
                checked: options.staffNamesAndOrder
                onClicked: { options.staffNamesAndOrder = !options.staffNamesAndOrder; checked = options.staffNamesAndOrder; }
            }
            CheckBox {
                text: "Check fonts"
                checked: options.fonts
                onClicked: { options.fonts = !options.fonts; checked = options.fonts; }
            }
            CheckBox {
                text: "Check music spacing"
                checked: options.musicSpacing
                onClicked: { options.musicSpacing = !options.musicSpacing; checked = options.musicSpacing; }
            }

            Text {
                text: "Fundamentals"
                font.bold: true
                Layout.columnSpan: 3
                color: ui.theme.fontPrimaryColor
            }
            CheckBox {
                text: "Check clefs"
                checked: options.clefs
                onClicked: { options.clefs = !options.clefs; checked = options.clefs; }
            }
            CheckBox {
                text: "Check time signatures"
                checked: options.timeSignatures
                onClicked: { options.timeSignatures = !options.timeSignatures; checked = options.timeSignatures; }
            }
            CheckBox {
                text: "Check key signatures"
                checked: options.keySignatures
                onClicked: { options.keySignatures = !options.keySignatures; checked = options.keySignatures; }
            }
            CheckBox {
                text: "Check ottavas"
                checked: options.ottavas
                onClicked: { options.ottavas = !options.ottavas; checked = options.ottavas; }
            }
            CheckBox {
                text: "Check slurs & ties"
                checked: options.slursAndTies
                onClicked: { options.slursAndTies = !options.slursAndTies; checked = options.slursAndTies; }
            }
            CheckBox {
                text: "Check articulation"
                checked: options.articulation
                onClicked: { options.articulation = !options.articulation; checked = options.articulation; }
            }
            CheckBox {
                text: "Check arpeggios"
                checked: options.arpeggios
                onClicked: { options.arpeggios = !options.arpeggios; checked = options.arpeggios; }
            }
            CheckBox {
                text: "Check tremolos & fermatas"
                checked: options.tremolosAndFermatas
                onClicked: { options.tremolosAndFermatas = !options.tremolosAndFermatas; checked = options.tremolosAndFermatas; }
            }
            CheckBox {
                text: "Check grace notes"
                checked: options.graceNotes
                onClicked: { options.graceNotes = !options.graceNotes; checked = options.graceNotes; }
            }
            CheckBox {
                text: "Check stems, noteheads & beams"
                checked: options.stemsAndBeams
                onClicked: { options.stemsAndBeams = !options.stemsAndBeams; checked = options.stemsAndBeams; }
            }
            CheckBox {
                text: "Check expressive detail"
                checked: options.expressiveDetail
                onClicked: { options.expressiveDetail = !options.expressiveDetail; checked = options.expressiveDetail; }
            }
            CheckBox {
                text: "Check bar stretches"
                checked: options.barStretches
                onClicked: { options.barStretches = !options.barStretches; checked = options.barStretches; }
            }

            Text {
                text: "Text and dynamics"
                font.bold: true
                Layout.columnSpan: 3
                color: ui.theme.fontPrimaryColor
            }

            CheckBox {
                text: "Check dynamics"
                checked: options.dynamics
                onClicked: { options.dynamics = !options.dynamics; checked = options.dynamics; }
            }
            CheckBox {
                text: "Check tempo markings"
                checked: options.tempoMarkings
                onClicked: { options.tempoMarkings = !options.tempoMarkings; checked = options.tempoMarkings; }
            }
            CheckBox {
                text: "Check title, subtitle & composer"
                checked: options.titleAndSubtitle
                onClicked: { options.titleAndSubtitle = !options.titleAndSubtitle; checked = options.titleAndSubtitle; }
            }
            CheckBox {
                text: "Check spelling & formatting errors"
                checked: options.spellingAndFormat
                onClicked: { options.spellingAndFormat = !options.spellingAndFormat; checked = options.spellingAndFormat; }
            }
            CheckBox {
                text: "Check rehearsal marks"
                checked: options.rehearsalMarks
                onClicked: { options.rehearsalMarks = !options.rehearsalMarks; checked = options.rehearsalMarks; }
            }
            CheckBox {
                text: "Check text object positions"
                checked: options.textPositions
                onClicked: { options.textPositions = !options.textPositions; checked = options.textPositions; }
            }

            Text {
                text: "Instrumentation"
                font.bold: true
                Layout.columnSpan: 3
                color: ui.theme.fontPrimaryColor
            }
            CheckBox {
                text: "Check range/register issues"
                checked: options.rangeRegister
                onClicked: { options.rangeRegister = !options.rangeRegister; checked = options.rangeRegister; }
            }
            CheckBox {
                text: "Check orchestral shared staves"
                checked: options.orchestralSharedStaves
                onClicked: { options.orchestralSharedStaves = !options.orchestralSharedStaves; checked = options.orchestralSharedStaves; }
            }
            CheckBox {
                text: "Check voice typesetting"
                checked: options.voice
                onClicked: { options.voice = !options.voice; checked = options.voice; }
            }
            CheckBox {
                text: "Check winds & brass"
                checked: options.windsAndBrass
                onClicked: { options.windsAndBrass = !options.windsAndBrass; checked = options.windsAndBrass; }
            }
            CheckBox {
                text: "Check piano, harp & percussion"
                checked: options.pianoHarpAndPercussion
                onClicked: { options.pianoHarpAndPercussion = !options.pianoHarpAndPercussion; checked = options.pianoHarpAndPercussion; }
            }
            CheckBox {
                text: "Check strings"
                checked: options.strings
                onClicked: { options.strings = !options.strings; checked = options.strings; }
            }
		}
		
		ButtonBox {
			width: parent.width-185;
			anchors {
				left: parent.left;
				bottom: parent.bottom;
				leftMargin: 20;
				bottomMargin: 20;
			}
			FlatButton {
				text: 'Tick all'
				buttonRole: ButtonBoxModel.CustomRole
				buttonId: ButtonBoxModel.CustomButton + 1
				width: 50
				isLeftSide: true
				onClicked: {
					var c = grid.children;
					for (var i = 1; i < c.length; i++) {
						var e = c[i];
						if (e.toString().includes('CheckBox')) {
							if (!e.checked) {
								e.checked = true;
								e.clicked();
							}
						}
					}
				}
			}
			FlatButton {
				text: 'Untick all'
				buttonRole: ButtonBoxModel.CustomRole
				buttonId: ButtonBoxModel.CustomButton + 2
				width: 50
				isLeftSide: true
				onClicked: {
					var c = grid.children;
					for (var i = 1; i < c.length; i++) {
						var e = c[i];
						if (e.toString().includes('CheckBox')) {
							if (e.checked) {
								e.checked = false;
								e.clicked();
							}
						}
					}
				}
			}
			FlatButton {
				text: "Cancel"
				width: 50
				buttonRole: ButtonBoxModel.ApplyRole
				buttonId: ButtonBoxModel.Cancel
				onClicked: {
					options.close()
				}
			}			
			
		}
		
		ButtonBox {
			
			anchors {
				right: parent.right;
				bottom: parent.bottom;
				rightMargin: 20;
				bottomMargin: 20;
			}
			navigationPanel.section: options.navigationSection;
			
			FlatButton {
				text: "OK"
				enabled: true
				visible: true
				width: 50
				buttonRole: ButtonBoxModel.AcceptRole
				buttonId: ButtonBoxModel.Ok
				isClickOnKeyNavTriggered: true
				accentButton: true
				onClicked: {
					var c = grid.children;
					options.numOptionsChecked = 0;
					for (var i = 0; i < c.length; i++) {
						if (c[i].toString().includes('CheckBox')) options.numOptionsChecked += c[i].checked;
					}
					checkScore();
				}
			}
		}
	}
}
