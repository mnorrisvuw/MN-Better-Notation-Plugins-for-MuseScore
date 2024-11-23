/*
 * Copyright (C) 2024 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.4 or later

import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.15
import Muse.UiComponents 1.0
import FileIO 3.0


MuseScore {
	version:  "1.0"
	description: "This plugin checks your score for common music layout issues"
	menuPath: "Plugins.MNCheckLayout";
	requiresScore: true
	title: "MN Check Layout"
	id: mnchecklayout
	
	// **** TEXT FILE DEFINITIONS **** //
	FileIO { id: techniquesfile; source: Qt.resolvedUrl("./assets/techniques.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: canbeabbreviatedfile; source: Qt.resolvedUrl("./assets/canbeabbreviated.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: metronomemarkingsfile; source: Qt.resolvedUrl("./assets/metronomemarkings.txt").toString().slice(8); onError: { console.log(msg); } }
	FileIO { id: sharedstaffsearchtermsfile; source: Qt.resolvedUrl("./assets/sharedstaffsearchterms.txt").toString().slice(8); onError: { console.log(msg); } }
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
	
	// **** PROPERTIES **** //
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
	property var commentPosArray: []
	property var instrumentIds: []
	property var isGrandStaff: []
	property var isTopOfGrandStaff: []
	property var grandStaves: []
	property var scoreHasStrings: false
	property var scoreHasWinds: false
	property var scoreHasBrass: false
	property var techniques: ""
	property var canbeabbreviated: ""
	property var metronomemarkings: ""
	property var sharedstaffsearchterms: ""
	property var shouldbelowercase: ""
	property var shouldhavefullstop: ""
	property var spellingerrorsanywhere: ""
	property var spellingerrorsatstart: ""
	property var tempomarkings: ""
	property var tempochangemarkings: ""
	property var prevTimeSig: ""
	property var currentInstrumentName: ""
	property var currentInstrumentId: ""
	property var prevClef: null
	property var prevDynamic: ""
	property var prevDynamicBarNum: 0
	property var tickHasDynamic: false
	property var theDynamic: null
	property var errorStrings: []
	property var errorObjects: []
	property var isWindOrBrassInstrument: false
	property var isStringInstrument: false
	property var isStringSection: false
	property var isFlute: false
	property var isPitchedPercussionInstrument: false
	property var isUnpitchedPercussionInstrument: false
	property var isPercussionInstrument: false
	property var isKeyboardInstrument: false
	property var isPedalInstrument: false
	property var isSoloScore: false
	property var currentMute: ""
	property var currentPlayingTechnique: ""
	property var currentContactPoint: ""
	property var ledgerLines: []
	property var flaggedLedgerLines: false;
	property var fullInstNamesShowing: false
	property var shortInstNamesShowing: false
	property var firstBarInScore: null
	property var lastBarInScore: null
	property var firstBarInSecondSystem: null
	property var systemStartBars: []
	property var articulations: []
	property var fermatas: []
	property var fermataLocs: []
	property var hairpins: []
	property var isHairpin: false
	property var pedals: []
	property var isPedalled: false
	property var slurs:[]
	property var oneNoteTremolos:[]
	property var twoNoteTremolos:[]
	property var glisses:[]
	property var expectedRehearsalMark: 'A'
	property var expectedRehearsalMarkLength: 1
	property var flaggedRehearsalMarkError: false
	property var isSlurred: false
	property var isDiv: false
	property var flaggedDivError: false
	property var isStringHarmonic: false
	property var isSharedStaffArray: []
	property var weKnowWhosPlaying: false
	property var flaggedWeKnowWhosPlaying: false
	property var flaggedSlurredRest: false
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
	
  onRun: {
		if (!curScore) return;
		
		// **** DECLARATIONS & DEFAULTS **** //
		var scoreHasTuplets = false;
		
		// **** READ IN TEXT FILES **** //
		techniques = techniquesfile.read().trim().split('\n');
		canbeabbreviated = canbeabbreviatedfile.read().trim().split('\n');
		metronomemarkings = metronomemarkingsfile.read().trim().split('\n');
		sharedstaffsearchterms = sharedstaffsearchtermsfile.read().trim().split('\n');
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
		hasMoreThanOneSystem = !lastSystem.is(firstSystem);	
		var flaggedLedgerLines = false;
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		var instrumentNames = [];
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
		var sharedStaffIndicators = ["I, II", "I, III", "II, III", "II, IV", "III, IV", "V, VI", "V, VII", "VI, VIII", "VII, VIII",
		"1, 2", "1, 3", "2, 3", "2, 4", "3, 4", "5, 6","5, 7", "6, 8", "7, 8",
		"1 &amp; 2", "1 &amp; 3", "2 &amp; 3", "2 &amp; 4", "3 &amp; 4", "5 &amp; 6","5 &amp; 7", "6 &amp; 8", "7 &amp; 8"];
		for (var i = 0; i < numStaves; i++) {
			var id = staves[i].part.instrumentId;
			instrumentIds.push(id);
			var staffName = staves[i].part.longName;
			instrumentNames.push(staffName);
			//errorMsg += "\nInstrument ID "+id+" "+staffName+" ";
			
			isSharedStaffArray[i] = false;
			for (var j = 0; j < sharedStaffIndicators.length; j++) {
				if (staffName.includes(sharedStaffIndicators[j])) {
					isSharedStaffArray[i] = true;
					break;
				}
			}
		}
		
		// ************  		DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS 		************ //
		deleteAllCommentsAndHighlights();

		// ************  							CHECK SCORE & PAGE SETTINGS 					************ // 
		checkScoreAndPageSettings();
		
		// ************  				SELECT AND PRE-PROCESS ENTIRE SCORE 				************ //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
		curScore.endCmd();
		
		// **** INITIALISE ALL ARRAYS **** //
		for (var i = 0; i<numStaves; i++) {
			articulations[i] = [];
			slurs[i] = [];
			pedals[i] = [];
			hairpins[i] = [];
			oneNoteTremolos[i] = [];
			twoNoteTremolos[i] = [];
			glisses[i] = [];
		}
		
		// **** LOOK FOR AND STORE ANY ELEMENTS THAT CAN ONLY BE ACCESSED FROM SELECTION: **** //
		// **** THIS INCLUDES: HAIRPINS, OTTAVAS, TREMOLOS, SLURS, ARTICULATION, FERMATAS **** //
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var theTick;
			var e = elems[i];
			var staffIdx = 0;
			while (!curScore.staves[staffIdx].is(e.staff)) staffIdx++;
			if (e.type == Element.HAIRPIN) {
				//errorMsg += "\nFOUND HAIRPIN "+e+" spannerTick: "+e.spannerTick.ticks+" ticks: "+e.spannerTicks.ticks;
				hairpins[staffIdx].push(e);
			}
			if (e.type == Element.OTTAVA) {
				//errorMsg += "\nFOUND OTTAVA "+e; //+" @ ticks "+e.ticks;
			}
			if (e.type == Element.GLISSANDO) {
				//errorMsg += "\nFOUND GLISS parent = "+e.parent.name+" parent parent = "+e.parent.parent.name; //+" @ ticks "+e.ticks;
				
				theTick = e.parent.parent.parent.tick;
				glisses[staffIdx][theTick] = e;
				//errorMsg += "\nFOUND GLISS @staff "+staffIdx+" @ ticks "+theTick;
			}
			if (e.type == Element.SLUR) slurs[staffIdx].push(e);
			if (e.type == Element.PEDAL_SEGMENT || e.type == Element.PEDAL) {
				
				theTick = e.spannerTick.ticks; //e.parent.tick;
				pedals[staffIdx].push(e);
				//errorMsg += "\nFOUND PEDAL @staff "+staffIdx+" @ ticks "+theTick;
			}
			
			if (e.type == Element.TREMOLO_SINGLECHORD) {
				theTick = e.parent.parent.tick;
				oneNoteTremolos[staffIdx][theTick] = e;
				//errorMsg += "\nFOUND 1-NOTE TREMOLO @staff "+staffIdx+" @ ticks "+theTick;
			}
			if (e.type == Element.TREMOLO_TWOCHORD) {
				theTick = e.parent.parent.tick;
				twoNoteTremolos[staffIdx][theTick] = e;
				//errorMsg += "\nFOUND 2-NOTE TREMOLO @staff "+staffIdx+" @ ticks "+theTick;
			}
			if (e.type == Element.ARTICULATION || e.type == Element.FERMATA) {
				if (e.type == Element.ARTICULATION) {
					theTick = e.parent.parent.tick; // artics attached to chord
					articulations[staffIdx][theTick] = e;
					//errorMsg += "\nFOUND ARTIC "+e.symbol+" tick: "+theTick;					
				} else {
					theTick = e.parent.tick; // fermatas
					fermatas.push(e);
					var locArr = staffIdx+' '+theTick;
					fermataLocs.push(locArr);
					//errorMsg += "\nFOUND FERMATA "+e.symbol+" tick: "+theTick;
				}
			}
		}
		
		// ************ 								CHECK TIME SIGNATURES								************ //
		checkTimeSignatures();
		
		// ************ 										CHECK SCORE TEXT								************ //
		checkScoreText();
		
		// ************  								CHECK STAFF NAMES 									************ // 
		checkStaffNames();
		
		// ************ 					CHECK FOR STAFF ORDER ISSUES 							************ //
		checkStaffOrder();
		
		// ************ 							CHECK FOR FERMATA ISSUES 							************ //
		if (!isSoloScore && numStaves > 2) checkFermatas();
		
		// ************ 			PREP FOR A FULL LOOP THROUGH THE SCORE 				************ //
		var currentStaffNum, currentBar, prevBarNum, numBarsProcessed, wasTied, isFirstNote;
		var firstStaffNum, firstBarNum, firstSegmentInScore, numBars;
		var prevSoundingDur, prevDisplayDur, tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;
		var containsTransposingInstruments = false;
		var currentSlur, currentSlurNum, numSlurs, nextSlurStart, currentSlurEnd;
		var currentPedal, currentPedalNum, numPedals, nextPedalStart, currentPedalEnd, flaggedPedalLocation;
		var currentHairpin, currentHairpinNum, numHairpins, nextHairpinStart, currentHairpinEnd;
		var numSystems, currentSystem, currentSystemNum, numNotesInThisSystem, numBeatsInThisSystem, noteCountInSystem, beatCountInSystem;
		var maxNoteCountPerSystem, minNoteCountPerSystem, maxBeatsPerSystem, minBeatsPerSystem, actualStaffSize;
		var isSharedStaff;
		
		firstBarInScore = curScore.firstMeasure;
		currentBar = firstBarInScore;
		lastBarInScore = curScore.lastMeasure;
		numBars = curScore.nmeasures;
		cursor.rewind(Cursor.SCORE_END);
		errorMsg += "\n————————\n\nSTARTING LOOP\n\n";
		noteCountInSystem = [];
		beatCountInSystem = [];
		var inchesToMM = 25.4;
		var spatiumDPI = 360.;
		var spatium = curScore.style.value("spatium")*inchesToMM/spatiumDPI; // spatium value is given in 360 DPI
		var actualStaffSize = spatium*4;
		maxNoteCountPerSystem = (10.0 - actualStaffSize) * 10.0 + 18;
		minNoteCountPerSystem = (10.0 - actualStaffSize) * 4.0 + 4;
		maxBeatsPerSystem = (10.0 - actualStaffSize) * 4.0 + 12;
		minBeatsPerSystem = (10.0 - actualStaffSize) * 4.0;
		
		// ************ 					START LOOP THROUGH WHOLE SCORE 						************ //
		for (currentStaffNum = 0; currentStaffNum < numStaves; currentStaffNum ++) {
			errorMsg += "\n——— currentStaff = "+currentStaffNum;
			
			// INITIALISE VARIABLES BACK TO DEFAULTS A PER-STAFF BASIS
			prevKeySigSharps = -99; // placeholder/dummy variable
			prevKeySigBarNum = 0;
			prevBarNum = 0;
			prevClef = null;
			prevDynamic = "";
			prevDynamicBarNum = 0;
			currentMute = "senza";
			currentPlayingTechnique = "arco";
			currentContactPoint = "ord";
			ledgerLines = [];
			flaggedLedgerLines = false;
			flaggedDivError = false;
			isFirstNote = true;
			weKnowWhosPlaying = false;
			isSharedStaff = isSharedStaffArray[currentStaffNum];
			flaggedWeKnowWhosPlaying = false;
			flaggedPedalLocation = false;
			flaggedSlurredRest = false;
			currentSlur = null;
			currentPedal = null;
			isSlurred = false;
			isPedalled = false;
			currentSlurNum = 0;
			currentPedalNum = 0;
			numSlurs = slurs[currentStaffNum].length;
			nextSlurStart = (numSlurs == 0) ? 0 : slurs[currentStaffNum][0].spannerTick.ticks;
			numPedals = pedals[currentStaffNum].length;
			nextPedalStart = (numPedals == 0) ? 0 : pedals[currentStaffNum][0].spannerTick.ticks;
			currentSlurEnd = 0;
			currentHairpin = null;
			isHairpin = false;
			currentHairpinNum = 0;
			numHairpins = hairpins[currentStaffNum].length;
			nextHairpinStart = (numHairpins == 0) ? 0 : hairpins[currentStaffNum][0].spannerTick.ticks;
			currentHairpinEnd = 0;
			
			// **** REWIND TO START OF SELECTION **** //
			// **** GET THE STARTING CLEF OF THIS INSTRUMENT **** //
			cursor.filter = Segment.HeaderClef;
			cursor.staffIdx = currentStaffNum;
			cursor.voice = 0;
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == null) cursor.next();
			var clef = cursor.element;
			if (clef == null) checkClef(clef);
			
			currentBar = cursor.measure;
			currentSystem = null;
			currentSystemNum = 0;
			numNotesInThisSystem = 0;
			numBeatsInThisSystem = 0;
			
			currentInstrumentName = instrumentNames[currentStaffNum];
			currentInstrumentId = instrumentIds[currentStaffNum];
			setInstrumentVariables();			
			prevTimeSig = currentBar.timesigNominal.str;
						
			for (currentBarNum = 1; currentBarNum <= numBars && currentBar; currentBarNum ++) {
				var barStartTick = currentBar.firstSegment.tick;
				var barEndTick = currentBar.lastSegment.tick;
				var barLength = barEndTick - barStartTick;
				var startTrack = currentStaffNum * 4;
				var goneToNextBar = false;
				var firstNoteInThisBar = null;
				//errorMsg += "\nBAR "+currentBarNum;
				if (currentStaffNum == 0) {
					var timeSig = currentBar.timesigNominal;
					var numBeats = timeSig.numerator;
					if (timeSig.denominator > 8) numBeats /= 2;
					numBeatsInThisSystem += numBeats;
				}
				if (!currentBar.parent.is(currentSystem)) {
					// start of system
					currentSystem = currentBar.parent;
					if (currentStaffNum == 0) systemStartBars.push(currentBar);
					if (currentBarNum > 1) {
						if (currentStaffNum == 0) {
							beatCountInSystem.push(numBeatsInThisSystem);
							//errorMsg += "\nPushed beatCountInSystem[] = "+numBeatsInThisSystem;
						}
						if (noteCountInSystem.length <= currentSystemNum) {
							noteCountInSystem.push(numNotesInThisSystem > numBeatsInThisSystem ? numNotesInThisSystem : numBeatsInThisSystem);
							//errorMsg += "\nPushed noteCountInSystem["+currentSystemNum+"] = "+noteCountInSystem[currentSystemNum];
						} else {
							if (numNotesInThisSystem > noteCountInSystem[currentSystemNum]) {
								noteCountInSystem[currentSystemNum] = numNotesInThisSystem;
								//errorMsg += "\nExpanded noteCountInSystem["+currentSystemNum+"] = "+numNotesInThisSystem;
							}
						}
						currentSystemNum ++;
					}
					numNotesInThisSystem = 0;
					numBeatsInThisSystem = 0;
				}
				var numTracksWithNotes = 0;
				var chordFound = false;
				
				for (var currentTrack = startTrack; currentTrack < startTrack + 4; currentTrack ++) {
					cursor.filter = Segment.All;
					cursor.track = currentTrack;
					cursor.rewindToTick(barStartTick);
					var processingThisBar = cursor.element;
					var numNotesInThisTrack = 0;
					
					while (processingThisBar) {
						var currSeg = cursor.segment;
						var currTick = currSeg.tick;
						tickHasDynamic = false;
						var annotations = currSeg.annotations;
						var elem = cursor.element;
						var eType = elem.type;
						var eName = elem.name;
						//errorMsg += '\neName = '+eName;
						
						// ************ UNDER A SLUR? ************ //
						var readyToGoToNextSlur = false;
						if (currentSlurNum < numSlurs) {
							if (currentSlur == null) {
								readyToGoToNextSlur = true;
							} else {
								if (currTick > currentSlurEnd) {
									//errorMsg += "\nSlur ended";
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
								//errorMsg += "\nSlur started at "+currTick+" & ends at "+currentSlurEnd;
								if (currentSlurNum < numSlurs - 1) {
									nextSlurStart = slurs[currentStaffNum][currentSlurNum+1].spannerTick.ticks;
									//errorMsg += "\nNext slur starts at "+nextSlurStart;
								} else {
									nextSlurStart = 0;
									//errorMsg += "\nThis is the last slur in this staff ";
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
									//errorMsg += "\nPedal ended";
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
								//errorMsg += "\nPedal started at "+currTick+" & ends at "+currentPedalEnd;
								if (isPedalInstrument) {
									if (isTopOfGrandStaff[currentStaffNum] && !flaggedPedalLocation) {
										flaggedPedalLocation = true;
										addError("Pedal markings should go below the bottom staff of a grand staff",currentPedal);
									}
								} else {
									addError("This instrument does not have a pedal",currentPedal);
								}
								if (currentPedalNum < numPedals - 1) {
									nextPedalStart = pedals[currentStaffNum][currentPedalNum+1].spannerTick.ticks;
									//errorMsg += "\nNext pedal starts at "+nextPedalStart;
								} else {
									nextPedalStart = 0;
									//errorMsg += "\nThis is the last pedal in this staff ";
								}
							}
						}
						
						// ************ UNDER A HAIRPIN? ************ //
						var readyToGoToNextHairpin = false;
						if (currentHairpinNum < numHairpins) {
							if (currentHairpin == null) {
								readyToGoToNextHairpin = true;
							} else {
								if (currTick > currentHairpinEnd) {
									//errorMsg += "\nHairpin ended";
									currentHairpin = null;
									isHairpin = false;
									currentHairpinNum ++;
									if (currentHairpinNum < numHairpins) {
										nextHairpinStart = hairpins[currentStaffNum][currentHairpinNum].spannerTick.ticks;
										readyToGoToNextHairpin = true;
									}
								}
							}
						}
						if (readyToGoToNextHairpin) {
							if (currTick >= nextHairpinStart) {
								isHairpin = true;
								currentHairpin = hairpins[currentStaffNum][currentHairpinNum];
								currentHairpinEnd = currentHairpin.spannerTick.ticks + currentHairpin.spannerTicks.ticks;
								//errorMsg += "\nHairpin started at "+currTick+" & ends at "+currentHairpinEnd;
								if (currentHairpinNum < numHairpins - 1) {
									nextHairpinStart = hairpins[currentStaffNum][currentHairpinNum+1].spannerTick.ticks;
									//errorMsg += "\nNext slur starts at "+nextHairpinStart;
								} else {
									nextHairpinStart = 0;
									//errorMsg += "\nThis is the last slur in this staff ";
								}
							}
						}
						
						// ************ FOUND A CLEF ************ //
						if (eType == Element.CLEF) checkClef(elem);
						
						// ************ FOUND A KEY SIGNATURE ************ //
						if (eType == Element.KEYSIG && currentStaffNum == firstStaffNum) checkKeySignature(elem,cursor.keySignature);		
						
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
										errorMsg += "\n Found non-text annotion "+aName;
										
									}
								
									// **** FOUND AN OTTAVA **** // — // DOESN'T WORK — TO FIX
									if (aType == Element.OTTAVA || aType == Element.OTTAVA_SEGMENT) checkOttava(theAnnotation);
								}
							}
						}
						
						// ************ FOUND A CHORD ************ //

						if (eType == Element.CHORD || eType == Element.REST) {
							
							// GLISS? MAYBE DELETE
							//errorMsg += "\nChord / Rest found @ tick "+currTick;
							
							numNotesInThisTrack ++;
							numNotesInThisSystem ++;
							var noteRest = cursor.element;
							//if (noteRest.glissType != null) errorMsg += "\nFOUND GLISS "+noteRest.glissType;
							if (firstNoteInThisBar == null) firstNoteInThisBar = noteRest;
							var isHidden = !noteRest.visible;
							var isRest = noteRest.type == Element.REST;
							var isNote = !isRest;
							var displayDur = noteRest.duration.ticks;
							var soundingDur = noteRest.actualDuration.ticks;
							var tuplet = noteRest.tuplet;
							var barsSincePrevNote = currentBarNum - prevBarNum;
							if (barsSincePrevNote > 1) {
								ledgerLines = [];
								flaggedLedgerLines = false;
							}
							
							//if (typeof currentStaffNum !== 'number') errorMsg += "\nArtic error in main loop";
							
							//if (beam) isCrossStaff = beam.cross;
							// TO FIX
							//errorMsg += "\nFOUND NOTE";
							
							// **** CHECK SLUR ISSUES **** //
							if (isSlurred && currentSlur != null) checkSlurIssues(noteRest, currentStaffNum, currentSlur);
							
							if (isRest) {
								if (tickHasDynamic) addError ("In general, you shouldn’t put dynamic markings under rests.", theDynamic);
							} else {
															
								// ************ CHECK GRACE NOTES ************ //
								
								var graceNotes = noteRest.graceNotes;
								if (graceNotes.length > 0) {
									checkGraceNotes(graceNotes);
									numNotesInThisSystem += graceNotes.length / 2; // grace notes only count for half
								}
								
								if (noteRest.notes[0].glissType != null) errorMsg += "\nFOUND GLISS 2 "+noteRest.notes[0].glissType;
								
								// ************ CHECK STACCATO ISSUES ************ //
								var theArtic = getArticulation (noteRest, currentStaffNum);
								
								if (theArtic != null) {
									if (staccatoArray.includes(theArtic.symbol)) {
										checkStaccatoIssues (noteRest);
									}
								}
								
								var nn = noteRest.notes.length;
								if (nn > 1) { 
									chordFound = true;
								} else {
									if (chordFound) chordFound = false;
								}
								
								if (isFirstNote) {
									isFirstNote = false;
									
									// ************ CHECK IF INITIAL DYNAMIC SET ************ //
									if (!tickHasDynamic) addError("This note should have an initial dynamic level set.",noteRest);
									
									// ************ CHECK IF SCORE IS TRANSPOSED ************ //
									if (!containsTransposingInstruments) {
										var note = noteRest.notes[0];
										var containsTransposingInstruments = note.tpc1 != note.tpc2;
										if (containsTransposingInstruments && note.tpc == note.tpc1) addError("This score includes a transposing instrument, but the score is currently in Concert pitch.\nIt is generally preferred to have the score transposed.\nUntick ‘Concert pitch’ in the bottom right to view the transposed score.","pagetop");
									}
								
								} else {
									
									// ************ CHECK DYNAMIC RESTATEMENT ************ //
									if (barsSincePrevNote > 4 && !tickHasDynamic) addError("Consider (re)stating a dynamic here, after the "+barsSincePrevNote+" bars’ rest.",noteRest);
									
								}
								prevBarNum = currentBarNum;
								
								// ************ CHECK STEM DIRECTION ************ //
								checkStemDirection(noteRest);
								
								// ************ CHECK LEDGER LINES ************ //
								checkLedgerLines(noteRest);
								
								// ************ CHECK STRING ISSUES ************ //
								if (isStringInstrument) {
									
									// ************ CHECK STRING HARMONIC ************ //
									checkStringHarmonic(noteRest, currentStaffNum);
									
									// ************ CHECK DIVISI ************ //
									if (isStringSection) checkDivisi (noteRest, currentStaffNum);
									
									// ************ CHECK PIZZ ISSUES ************ //
									if (currentPlayingTechnique === "pizz") checkPizzIssues(noteRest, currentBarNum, currentStaffNum);
								} // end isStringInstrument
								
								// ************ CHECK FLUTE HARMONIC ************ //
								if (isFlute) checkFluteHarmonic(noteRest);
								
								// ************ CHECK PIANO STRETCH ************ //
								if (isKeyboardInstrument && chordFound) checkPianoStretch(noteRest);
								
								// ************ CHECK TREMOLOS ************ //
								if (oneNoteTremolos[currentStaffNum][currTick] != null) checkOneNoteTremolo(noteRest,oneNoteTremolos[currentStaffNum][currTick]);
								if (twoNoteTremolos[currentStaffNum][currTick] != null) checkTwoNoteTremolo(noteRest,twoNoteTremolos[currentStaffNum][currTick]);
								
								// ************ CHECK GLISSES ************ //
								if (glisses[currentStaffNum][currTick] != null) checkGliss(noteRest,glisses[currentStaffNum][currTick]);
								
							} // end is rest
						} // end if eType == Element.Chord || .Rest

						if (cursor.next()) {
							processingThisBar = cursor.measure.is(currentBar);
						} else {
							processingThisBar = false;
						}
					} // end while processingThisBar
					if (numNotesInThisTrack > 0) numTracksWithNotes ++;
				} // end track loop
				if (isWindOrBrassInstrument && isSharedStaff) {
					//errorMsg += "\nnumTracksWithNotes = "+numTracksWithNotes+" flaggedWeKnowWhosPlaying = "+flaggedWeKnowWhosPlaying+" weKnowWhosPlaying = "+weKnowWhosPlaying + " chordFound "+chordFound;
					if (numTracksWithNotes > 1 || chordFound) {
						weKnowWhosPlaying = false;
						//errorMsg+="\nweKnowWhosPlaying is now "+weKnowWhosPlaying;
						
						flaggedWeKnowWhosPlaying = false;
					} else {
						
						if (numTracksWithNotes == 1 && !weKnowWhosPlaying && !flaggedWeKnowWhosPlaying) {
							addError("This bar has only one melodic line on a shared staff\nThis needs to be marked with, e.g., 1./2./a 2",firstNoteInThisBar);
							flaggedWeKnowWhosPlaying = true;
						}
					}
				}
				if (currentBar) currentBar = currentBar.nextMeasure;
				numBarsProcessed ++;
			}// end currentBar num
			
			if (currentStaffNum == 0) {
				beatCountInSystem.push(numBeatsInThisSystem);
				//errorMsg += "\nPushed beatCountInSystem[] = "+numBeatsInThisSystem;
			}
			if (noteCountInSystem[currentSystemNum] == undefined) {
				if (numNotesInThisSystem > numBeatsInThisSystem) {
					noteCountInSystem[currentSystemNum] = numNotesInThisSystem;
					//errorMsg += "\nPushed noteCountInSystem["+currentSystemNum+"] = "+numNotesInThisSystem;
				} else {
					noteCountInSystem[currentSystemNum] = numBeatsInThisSystem;
					//errorMsg += "\nPushed noteCountInSystem["+currentSystemNum+"] = "+numBeatsInThisSystem;
				}
			} else {
				if (numNotesInThisSystem > noteCountInSystem[currentSystemNum]) {
					noteCountInSystem[currentSystemNum] = numNotesInThisSystem;
					//errorMsg += "\nExpanded noteCountInSystem["+currentSystemNum+"] = "+numNotesInThisSystem;
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
			//errorMsg += "\nCHECKING SYS "+sys+": nc="+noteCountInSys+" nb="+numBeatsInSys+" mmin="+mmin+" mmax="+mmax;
			if (bar == undefined) {
				errorMsg += "\nBAR UNDEFINED";
			} else {
				if (noteCountInSys < minNoteCountPerSystem) addError("This system doesn’t have many notes in it, and may be quite spread out.\nTry including more bars in this system.",bar);
				if (noteCountInSys > maxNoteCountPerSystem) addError("This system has a lot of notes in it, and may be quite squashed.\nTry moving some of the bars out of this system.",bar);
				if (numBeatsInSys < minBeatsPerSystem && noteCountInSys < mmin) addError("This system doesn’t have many bars in it and may be quite spread out.\nTry including more bars in this system.",bar);
				if (numBeatsInSys > maxBeatsPerSystem && noteCountInSys > mmax) addError("This system has quite a few bars in it, and may be quite squashed.\nTry moving some of the bars out of this system.",bar);
			}
		}
		
		// ** SHOW ALL OF THE ERRORS ** //
		showAllErrors();
		
		// ** SHOW INFO DIALOG ** //
		if (!debug) {
			var numErrors = errorStrings.length;
			if (numErrors == 0) {
				errorMsg = "SCORE CHECK COMPLETED!\n\nNo errors found!";
			}
			if (numErrors == 1) {
				errorMsg = "SCORE CHECK COMPLETED!\n\nOne error found.";
			}
			if (numErrors > 1) {
				errorMsg = "SCORE CHECK COMPLETED!\n\nI found "+numErrors+" errors";
			}
		}
		dialog.msg = errorMsg;
		dialog.show();
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
	
	function setInstrumentVariables () {
		if (currentInstrumentId != "") {
			isStringInstrument = currentInstrumentId.includes("strings.");
			isStringSection = currentInstrumentId === "strings.group";
			isFlute = currentInstrumentId.includes("wind.flutes");
			isPitchedPercussionInstrument = currentInstrumentId.includes("pitched-percussion") || currentInstrumentId.includes("crotales") || currentInstrumentId.includes("almglocken");
			isUnpitchedPercussionInstrument = false;
			if (!isPitchedPercussionInstrument) {
				isUnpitchedPercussionInstrument = currentInstrumentId.includes("drum.") || currentInstrumentId.includes("effect.") || currentInstrumentId.includes("metal.") || currentInstrumentId.includes("wood.");
			}
			isPercussionInstrument = isPitchedPercussionInstrument || isUnpitchedPercussionInstrument;
			isKeyboardInstrument = currentInstrumentId.includes("keyboard");
			isPedalInstrument = currentInstrumentId.includes("piano") || currentInstrumentId.includes("vibraphone");
			isWindOrBrassInstrument = currentInstrumentId.includes("wind.") || currentInstrumentId.includes("brass.");
		
			checkClefs = false;
			reads8va = false;
			readsTreble = true;
			readsAlto = false;
			readsTenor = false;
			readsBass = false;
			checkClefs = false;

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
			if (currentInstrumentId.includes("instrument.keyboard") || currentInstrumentId.includes("pluck.harp") || currentInstrumentId.includes(".marimba")) {
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
			if (currentInstrumentId.includes("voice.")) {
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
		var parts = curScore.parts;
		var numParts = parts.length;
		var style = curScore.style;
		var numStaves = curScore.nstaves;
		var staffSpacing = style.value("staffDistance");		
		var akkoladeDistance = style.value("akkoladeDistance");
		var minSystemDistance = style.value("minSystemDistance");
		var maxSystemDistance = style.value("maxSystemDistance");
		var inchesToMM = 25.4;
		var spatiumDPI = 360.;
		var spatium = style.value("spatium")*inchesToMM/spatiumDPI; // spatium value is given in 360 DPI
		var staffSize = spatium*4;
		//errorMsg+= "\nspatium = "+spatium+"; staffSize = "+staffSize;
		var staffLineWidth = style.value("staffLineWidth")*inchesToMM;
		var pageEvenLeftMargin = style.value("pageEvenLeftMargin")*inchesToMM;
		var pageOddLeftMargin = style.value("pageOddLeftMargin")*inchesToMM;
		var pageEvenTopMargin = style.value("pageEvenTopMargin")*inchesToMM;
		var pageOddTopMargin = style.value("pageOddTopMargin")*inchesToMM;
		var pageEvenBottomMargin = style.value("pageEvenBottomMargin")*inchesToMM;
		var pageOddBottomMargin = style.value("pageOddBottomMargin")*inchesToMM;
		var tupletsFontFace = style.value("tupletFontFace");
		var tupletsFontStyle = style.value("tupletFontStyle");
		var barlineWidth = style.value("barWidth");
		var minimumBarWidth = style.value("minMeasureWidth");
		errorMsg += "\nbarlineWidth = "+barlineWidth;
		
		// **** TEST 1A: CHECK MARGINS ****
		var maxMargin = 15;
		var minMargin = 5;
		if ((pageEvenLeftMargin > maxMargin) + (pageOddLeftMargin > maxMargin) + (pageEvenTopMargin > maxMargin) + (pageOddTopMargin > maxMargin) +  (pageEvenBottomMargin > maxMargin) + (pageOddBottomMargin > maxMargin)) pageSettingsComments.push("Decrease your margins to no more than "+maxMargin+"mm");
		if ((pageEvenLeftMargin < minMargin) + (pageOddLeftMargin < minMargin) + (pageEvenTopMargin < minMargin) + (pageOddTopMargin < minMargin) +  (pageEvenBottomMargin < minMargin) + (pageOddBottomMargin < minMargin)) pageSettingsComments.push("Increase your margins to at least "+minMargin+"mm");
		// **** TEST 1B: CHECK STAFF SIZE ****
		var maxSize = 6.8;
		var minSize = 6.5;
		if (numStaves == 2) {
			maxSize = 6.7;
			minSize = 6.2;
		}
		if (numStaves == 3) {
			maxSize = 6.5;
			minSize = 5.5;
		}
		if (numStaves > 3 && numStaves < 8) {
			maxSize = 6.5 - ((numStaves - 3) * 0.1);
			minSize = 5.5 - ((numStaves - 3) * 0.1);
		}
		if (numStaves > 7) {
			maxSize = 5.4;
			minSize = 4.4;
		}
		
		if (staffSize > maxSize) pageSettingsComments.push("Your stave space is too large: it should be in the range "+(minSize/4.0)+"–"+(maxSize/4.0)+"mm");
		if (staffSize < minSize) {
			if (staffSize < 4.4) {
				if (staffSize < minSize) pageSettingsComments.push("Your stave space is very small and will be very hard to read: try to increase it to at least 1.1mm");
			} else {
				pageSettingsComments.push("Your stave space is too small: it should be in the range "+(minSize/4.0)+"–"+(maxSize/4.0)+"mm");
			}
		}
		
		// **** 1C: CHECK STAFF SPACING
		
	
		
		// ** CHECK FOR STAFF NAMES ** //
		isSoloScore = (numParts == 1);
		//errorMsg += "\nfirstStaffNameShouldBeHidden = "+firstStaffNameShouldBeHidden;
		
		var subsequentStaffNamesShouldBeHidden = numParts < 6;
		
		// ** are the first staff names visible? ** //
		var firstStaffNamesVisible = false;
		var firstStaffNamesVisibleSetting = style.value("firstSystemInstNameVisibility"); //  0 = long names, 1 = short names, 2 = hidden
		var hideInstrumentNameForSolo = isSoloScore && style.value("hideInstrumentNameIfOneInstrument");
		if (!hideInstrumentNameForSolo && firstStaffNamesVisibleSetting < 2) {
			for (var i = 0; i < numParts; i++) {
				var partName = "";
				if (firstStaffNamesVisibleSetting == 0) {
					partName = parts[i].longName;
				} else {
					partName = parts[i].shortName;
				}
				if (partName !== "") {
					firstStaffNamesVisible = true;
					break;
				}
			}
		}
		
		// **** STYLE SETTINGS — 1. SCORE TAB **** //
		if (isSoloScore && !hideInstrumentNameForSolo) styleComments.push("(Score tab) Tick ‘Hide if there is only one instrument’");
		if (!isSoloScore && firstStaffNamesVisibleSetting != 0) styleComments.push("(Score tab) Set Instrument names→On first system of sections to ‘Long name’.");
		var subsequentStaffNamesVisibleSetting = style.value("subsSystemInstNameVisibility");  //  0 = long names, 1 = short names, 2 = hidden
		var subsequentStaffNamesVisible = false;
		if (!hideInstrumentNameForSolo && subsequentStaffNamesVisibleSetting < 2) {
			for (var i = 0; i < numParts; i++) {
				var partName = "";
				if (subsequentStaffNamesVisibleSetting == 0) {
					partName = parts[i].longName;
				} else {
					partName = parts[i].shortName;
				}
				if (partName !== "") {
					subsequentStaffNamesVisible = true;
					break;
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
			if (minSystemDistance < 12) styleComments.push("(Page tab) Increase the ‘Min. system distance’ to at least 12");
			if (minSystemDistance > 16) styleComments.push("(Page tab) Decrease the ‘Min. system distance’ to no more than 16");
			if (maxSystemDistance < 12) styleComments.push("(Page tab) Increase the ‘Max. system distance’ to at least 12");
			if (maxSystemDistance > 16) styleComments.push("(Page tab) Decrease the ‘Max. system distance’ to no more than 16");
		}
		
		// **** STYLE SETTINGS — 3. BARS TAB **** //
		if (minimumBarWidth < 10.0) styleComments.push("(Bars tab) Set ‘Minimum bar width’ to 10.0sp")
		
		// **** STYLE SETTINGS — 4. BARLINES TAB **** //
		if (barlineWidth != 1.6) styleComments.push("(Barlines tab) Set ‘Thin Barline thickness’ to 0.16sp");
		
		// **** STYLE SETTINGS — 6. TEXT STYLES TAB **** //
		//errorMsg += "tupletsFontFace = "+tupletsFontFace+" tupletsFontStyle = "+tupletsFontStyle;
		if (tupletsFontFace !== "Times New Roman" || tupletsFontStyle != 2) styleComments.push("(Text Styles→Tuplet) Use Times New Roman italic for tuplets");
		
		// ** OTHER STYLE ISSUES ** //
		
		// ** POST STYLE COMMENTS
		if (styleComments.length>0) {
			var styleCommentsStr = "";
			if (styleComments.length == 1) {
				styleCommentsStr = "I recommend making the following change to the score’s Style (Format→Style…):\n"+styleComments.join('\n');
			} else {
				var theList = styleComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				styleCommentsStr = "I recommend making the following changes to the score’s Style (Format→Style…):\n"+theList;
			}
			addError(styleCommentsStr,"pagetop");
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments.length > 0) {
			var pageSettingsCommentsStr = "";
			if (pageSettingsComments.length == 1) {	
				pageSettingsCommentsStr = "I recommend making the following change to the score’s Page Settings (Format→Page settings…)\n"+pageSettingsComments.join("\n");
			} else {
				var theList = pageSettingsComments.map((line, index) => `${index + 1}) ${line}`).join('\n');
				pageSettingsCommentsStr = "I recommend making the following changes to the score’s Page Settings (Format→Page settings…)\n"+theList;
			}
			addError(pageSettingsCommentsStr,"pagetop");
		}
	}
	
	function checkTextObject (textObject,barNum) {
		var windAndBrassMarkings = ["1.","2.","3.","4.","5.","6.","7.","8.","a 2","a 3","a 4","a 5","a 6","a 7","a 8","solo","1. solo","2. solo","3. solo","4. solo","5. solo","6. solo","7. solo","8. solo"];
		var eType = textObject.type;
		var eName = textObject.name;
		var styledText = textObject.text;
		
		if (eType == Element.REHEARSAL_MARK) {
			checkRehearsalMark (textObject);
		}
		
		//errorMsg += "\nstyledtext = "+styledText;
		// ** CHECK IT'S NOT A COMMENT WE'VE ADDED ** //
		if (!Qt.colorEqual(textObject.frameBgColor,"yellow") || !Qt.colorEqual(textObject.frameFgColor,"black")) {	
			var textStyle = textObject.subStyle;
			var tn = textObject.name.toLowerCase();
			//errorMsg += "\nText style is "+textStyle+"; tn = "+tn;
			var plainText = styledText.replace(/<[^>]+>/g, "");
			var lowerCaseText = plainText.toLowerCase();
			//errorMsg += "\ntn = "+tn+"; plainText = "+plainText+"; lowerCaseText = "+lowerCaseText;
			
			if (lowerCaseText != '') {
				var len = plainText.length;
				var isVisible = textObject.visible;
		
				// **** CHECK WHETHER INITIAL TEMPO MARKING EXISTS **** //
				if (!initialTempoExists && eType == Element.TEMPO_TEXT && barNum == 1) initialTempoExists = true;
		
				// **** IS THIS A TEMPO CHANGE MARKING??? **** //
				var isTempoChangeMarking = false;
				for (var i = 0; i < tempochangemarkings.length; i++) {
					if (lowerCaseText.includes(tempochangemarkings[i])) {
						isTempoChangeMarking = true;
						break;
					}
				}
				
				// **** CHECK TEMPO CHANGE MARKING IS NOT IN TEMPO TEXT OR INCORRECTLY CAPITALISED **** //
				if (isTempoChangeMarking) {
					if (eType != Element.TEMPO_TEXT) {
						addError( "‘"+plainText+"’ is a tempo change marking\nbut has not been entered as Tempo Text",textObject);
						return;
					}
					if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) {
						addError("‘"+plainText+"’ looks like it is a temporary change of tempo\nif it is, it should not have a capital first letter (see Behind Bars, p. 182)",textObject);
						return;
					}
				}
		
				// **** IS THIS A TEMPO MARKING? **** //
				var isTempoMarking = false;
		
				for (var j = 0; j < tempomarkings.length; j++) {
					if (lowerCaseText.includes(tempomarkings[j])) {
						isTempoMarking = true;
						break;
					}
				}
				if (isTempoMarking) {
					
					// **** CHECK TEMPO MARKING IS IN TEMPO TEXT **** //
					if (eType != Element.TEMPO_TEXT) addError("Text ‘"+plainText+"’ is a tempo marking\nbut has not been entered as Tempo Text",textObject);
				
					// **** CHECK TEMPO SHOULD BE CAPITALISED **** //
					if (plainText.substring(0,1) === lowerCaseText.substring(0,1) && lowerCaseText != "a tempo" && lowerCaseText.charCodeAt(0)>32 && !lowerCaseText.substring(0,4).includes("=")) addError("‘"+plainText+"’ looks like it is establishing a new tempo;\nif it is, it should have a capital first letter. (See Behind Bars, p. 182)",textObject);
				}
				
				// **** CHECK DIV **** //
				if (lowerCaseText.includes('div.')) {
					if (isStringSection) {
						isDiv = true;
						flaggedDivError = false;
					} else {
						addError("You’ve written a string div. marking,\nbut this doesn’t seem to be a string section.",textObject);
						return;
					}
				}
				
				if (lowerCaseText.includes('unis.')) {
					if (isStringSection) {
						isDiv = false;
						flaggedDivError = false;
					} else {
						addError("You’ve written a string unis. marking,\nbut this doesn’t seem to be a string section.",textObject);
						return;
					}
				}
				
				// **** CHECK WRITTEN OUT TREM **** //
				if (lowerCaseText === "trem" || lowerCaseText === "trem." || lowerCaseText === "tremolo") {
					addError("You don’t need to write ‘"&plainText&"’;\njust use a tremolo marking.",textObject);
					return;
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
			
				// **** CHECK FOR STRAIGHT QUOTES THAT SHOULD BE CURLY **** //
				if (lowerCaseText.includes("'")) {
					addError("This text has a straight single quote mark in it (').\nChange to curly: ‘ or ’.",textObject);
					return;
				}
				if (lowerCaseText.includes('\"')) {
					addError('This text has a straight double quote mark in it (").\nChange to curly: “ or ”.',textObject);
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
			
				// **** IS THIS A DYNAMICS SYMBOL OR MANUALLY ENTERED DYNAMICS? **** //
				var objectIsDynamic = tn === "dynamic";
				var containsADynamic = styledText.includes('<sym>dynamics');
				var stringIsDynamic = isDynamic(lowerCaseText);
				//errorMsg += "\nobjectIsDynamic = "+objectIsDynamic+" containsADynamic = "+containsADynamic+" stringIsDynamic = "+stringIsDynamic;
				
				// **** CHECK REDUNDANT DYNAMIC **** //
				if (objectIsDynamic || containsADynamic || stringIsDynamic) {
					tickHasDynamic = true;
					theDynamic = textObject;
					var isError = false;
					var plainDynamicMark = lowerCaseText;
					if (containsADynamic) plainDynamicMark = lowerCaseText
						.replace('<sym>dynamicforte</sym>','f')
						.replace('<sym>dynamicmezzo</sym>','m')
						.replace('<sym>dynamicpiano</sym>','p')
						.replace('<sym>dynamicrinforzando</sym>','r')
						.replace('<sym>dynamicsubito</sym>','s')
						.replace('<sym>dynamicz</sym>','z');
					//errorMsg += "\nprevDynamicBarNum = "+prevDynamicBarNum;
					var dynamicException = plainDynamicMark.includes("fp") || plainDynamicMark.includes("sf") || plainDynamicMark.includes("fz");
					
					if (prevDynamicBarNum > 0) {
						var barsSincePrevDynamic = barNum - prevDynamicBarNum;
						if (plainDynamicMark === prevDynamic && barsSincePrevDynamic < 5 && !dynamicException) {
							addError("This dynamic may be redundant:\nthe same dynamic was set in b. "+prevDynamicBarNum+".",textObject);
							isError = true;
						}
					}
					
					if (!dynamicException) {
						prevDynamicBarNum = barNum;
						prevDynamic = plainDynamicMark;
					}
					if (isError) return;
				}
				//errorMsg += "\n"+lowerCaseText+" isDyn = "+isDyn;
				
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
				
				// **** CHECK FOR TEXT STARTING WITH SPACE OR NON-ALPHANUMERIC **** //
				if (plainText.charCodeAt(0) == 32) {
					addError("‘"+plainText+"’ begins with a space, which could be deleted.",textObject);
					return;
				}
				if (plainText.charCodeAt(0) < 32) {
					addError("‘"+plainText+"’ does not seem to begin with a letter: is that correct?",textObject);
					return;
				}
			
				// **** CHECK TEXT THAT IS INCORRECTLY CAPITALISED **** //
				for (var i = 0; i < shouldbelowercase.length; i++) {
					var lowercaseMarking = shouldbelowercase[i];
					//if (plainText === "Ord.") errorMsg += "\nOrd. — Checking "+lowercaseMarking;
					if (plainText.length >= lowercaseMarking.length) {
						if (lowerCaseText.substring(0,lowercaseMarking.length) === lowercaseMarking) {
							//errorMsg += "\nMatch "+lowercaseMarking;
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
					if (plainText === shouldhavefullstop[i]) {
						addError("‘"+plainText+"’ should have a full-stop at the end.",textObject);
						return;
					}
				}
			
				// **** CHECK COMMON SPELLING ERRORS & ABBREVIATIONS **** //
				var isSpellingError = false;
				for (var i = 0; i < spellingerrorsatstart.length / 2; i++) {
					var spellingError = spellingerrorsatstart[i*2];
					if (lowerCaseText.substring(0,spellingError.length) === spellingError) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsatstart[i*2+1];
						var diff = plainText.length-spellingError.length;
						var correctText = '';
						if (diff > 0) {
							correctText = correctSpelling+plainText.substring(spellingError.length,diff);
						} else {
							correctText = correctSpelling;
						}
						addError("‘"+plainText+"’ is misspelled; it should be ‘"+correctText+"’.",textObject);
						return;
					}
				}
				// **** CHECK TEXT WITH SPELLING ERRORS ANY WHERE **** //
				if (!isSpellingError) {
					for (var i = 0; i < spellingerrorsanywhere.length / 2; i++) {
						var spellingError = spellingerrorsanywhere[i*2];
						if (plainText.includes(spellingError)) {
							isSpellingError = true;
							var correctSpelling = spellingerrorsanywhere[i*2+1];
							var correctText = plainText.replace(spellingError,correctSpelling);
							addError("‘"+plainText+"’ is misspelled; it should be ‘"+correctText+"’.",textObject);
							return;
						}
					}
				}
				// **** CHECK TEXT CAN BE ABBREVIATED **** //
				if (!isSpellingError) {
					for (var i = 0; i < canbeabbreviated.length / 2; i++) {
						var fullText = canbeabbreviated[i*2];
						if (plainText.includes(fullText)) {
							var abbreviatedText = canbeabbreviated[i*2+1];
							var correctText = plainText.replace(fullText,abbreviatedText);
							addError("‘"+plainText+"’ can be abbreviated to ‘"+correctText+"’.",textObject);
							return;
						}
					}
				}
				
				checkInstrumentalTechniques (textObject, plainText, lowerCaseText, barNum);
				
				// **** CHECK IF THIS IS A WOODWIND OR BRASS MARKING **** //
				if (windAndBrassMarkings.includes(lowerCaseText) && isWindOrBrassInstrument) {
					weKnowWhosPlaying = true;
					flaggedWeKnowWhosPlaying = false;
					errorMsg+="\nWW weKnowWhosPlaying is now "+weKnowWhosPlaying;
				}
			} // end lowerCaseText != ''
		} // end check comments
	}
	
	function checkInstrumentalTechniques (textObject, plainText, lowerCaseText, barNum) {
		var isBracketed = false; // TO FIX
		
		if (isWindOrBrassInstrument) {
			if (lowerCaseText.includes("tutti")) {
				addEerror("Don’t use ‘Tutti’ for winds and brass; write ‘a 2’/‘a 3’ etc. instead",textObject);
				return;
			}
			if (lowerCaseText.includes("unis.")) {
				addEerror("Don’t use ‘unis.’ for winds and brass; write ‘a 2’/‘a 3’ etc. instead",textObject);
				return;
			}
			if (lowerCaseText.includes("div.")) {
				addEerror("Don’t use ‘div.’ for winds and brass.",textObject);
				return;
			}
		}
		if (isStringInstrument) {
			
			//errorMsg += "IsString: checking "+lowerCaseText;
			// **** CHECK INCORRECT 'A 2 / A 3' MARKINGS **** //
			if (lowerCaseText === "a 2" || lowerCaseText === "a 3") {
				addEerror("Don’t use ‘"+lowerCaseText+"’ for strings; write ‘unis.’ etc. instead",textObject);
				return;
			}
			
			// **** CHECK ALREADY PLAYING ORD. **** .//
			if (lowerCaseText.substring(0,4) === "ord.") {
				if (currentContactPoint === "ord" && (currentPlayingTechnique === "arco" || currentPlayingTechnique === "pizz")) {
					addError("Instrument is already playing ord?",textObject);
					return;
				} else {
					currentContactPoint = "ord";
				}
			}

			// **** CHECK ALREADY PLAYING FLAUT **** //
			if (lowerCaseText.includes("flaut")) {
				if (currentContactPoint === "flaut") {
					if (!isBracketed) {
						addError("Instrument is already playing flautando?",textObject);
						return;
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
						return;
					}
				} else {
					currentContactPoint = "mute";
				}
			}
		
			// **** CHECK ALREADY PLAYING SUL PONT **** //
			if (lowerCaseText.includes("pont") || lowerCaseText.includes("s.p.") || lowerCaseText.includes("psp") || lowerCaseText.includes("msp")) {
				if (lowerCaseText.includes("poco sul pont") || lowerCaseText.includes("p.s.p") || lowerCaseText.includes("psp")) {
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
			if (lowerCaseText.includes("tasto") || lowerCaseText.includes("s.t.") || lowerCaseText.includes("pst") || lowerCaseText.includes("mst")) {
				if (lowerCaseText.includes("poco sul tasto") || lowerCaseText.includes("p.s.t") || lowerCaseText.includes("pst")) {
					if (currentContactPoint === "pst") {
						if (!isBracketed) {
							addError("Instrument is already playing poco sul tasto?",textObject);
							return;
						}
					} else {
						currentContactPoint = "pst";
					}
				} else {
					if (lowerCaseText.includes("molto sul tasto",t) || lowerCaseText.includes("m.s.t",t) || lowerCaseText.includes("mst",t)) {
						if (currentContactPoint === "mst") {
							if (!isBracketed) {
								addError("Instrument is already playing molto sul tasto?",textObject);
								return;
							}
						} else {
							currentContactPoint = "mst";
						}
					} else {
						if (currentContactPoint === "st") {
							if (!isBracketed) {
								addError("Instrument is already playing sul tasto?",textObject);
								return;
							}
						} else {
							currentContactPoint = "st";
						}
					}
				}
			}
		
			// **** CHECK ALREADY PLAYING ARCO **** //
			if (lowerCaseText.substring(0,4) === "arco") {
				if (currentPlayingTechnique === "arco") {
					if (!isBracketed) {
						addError("Instrument is already playing arco?",textObject);
						return;
					}
				} else {
					currentPlayingTechnique = "arco";
				}
			}
			
			// **** CHECK ALREADY PLAYING PIZZ **** //
			if (lowerCaseText.substring(0,4) === "pizz") {
				if (currentPlayingTechnique === "pizz") {
					if (!isBracketed) {
						addError("Instrument is already playing pizz?",textObject);
						return;
					}
				} else {
					currentPlayingTechnique = "pizz";
					var pizzStartedInThisBar = true; // TO FIX
				}
			}
			
			// **** CHECK HAMMER ON **** //
			if (lowerCaseText === "senza arco" || lowerCaseText.includes("hammer")) {
				 if (currentPlayingTechnique === "hammer") {
					if (!isBracketed) {
						addError("Instrument is already playing senza arco?",textObject);
						return;
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
							return;
						}
					} else {
						currentPlayingTechnique = "clb";
					}
				} else {
					if (lowerCaseText.includes("tratto")) {
						if (currentPlayingTechnique === "clt") {
							if (!isBracketed) {
								addError("Instrument is already playing col legno tratto?",textObject);
								return;
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
						return
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
						return;
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
					return;
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
					return;
				}
			} else {
				currentMute = "senza";
			}
		}

	}
	
	function checkClef (clef) {
		var clefId = clef.subtypeName();
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
		if (clef.is(prevClef)) addError("This clef is redundant: already was "+clefId.toLowerCase()+"\nIt can be safely deleted",clef);
		prevClef = clef;
	}
	
	function checkOttava (ottava) {
		errorMsg += "Found OTTAVA: "+ottava.subtypeName()+" "+ottava.subtype+" "+ottava.lineType;
		/*	if (l.StyleId = "line.staff.octava.minus8") {
				if (clefId = "clef.alto") {
					storeError(errors,"Never use 8vb in alto clef.",l.Type,l);
				}
				if (clefId = "clef.percussion") {
					storeError(errors,"Never use 8vb in percussion clef.",l.Type,l);
				}
				if (clefId = "clef.treble") {
					if (readsBass) {
						storeError(errors,"Never use 8vb in treble clef. Change to bass clef instead.",l.Type,l);
					} else {
						storeError(errors,"Never use 8vb in treble clef.",l.Type,l);
					}
				}
				if (clefId = "clef.tenor") {
					storeError(errors,"Never use 8vb in tenor clef. Change to bass clef instead.",l.Type,l);
				}
				if (reads8va = false) {
					storeError(errors,"This instrument does not normally read 8vb lines. It’s best to write the note(s) out at pitch.",l.Type,l);
				}
			}
			if (l.StyleId = "line.staff.octava.plus8" or l.StyleId = "line.staff.octava.plus15") {
				line = "8va";
				if (l.StyleId = "line.staff.octava.plus15") {
					line = "15ma";
				}
				if (clefId = "clef.alto") {
					storeError(errors,"Never use "&line&" in alto clef. Change to treble clef instead.",l.Type,l);
				}
				if (clefId = "clef.percussion") {
					storeError(errors,"Never use "&line&" in percussion clef.",l.Type,l);
				}
				if (clefId = "clef.bass") {
					storeError(errors,"Never use "&line&" in bass clef. Change to tenor or treble clef instead.",l.Type,l);
				}
				if (clefId = "clef.tenor") {
					storeError(errors,"Never use "&line&" in tenor clef. Change to treble clef instead.",l.Type,l);
				}
				if (reads8va = false) {
					storeError(errors,"This instrument does not normally read "&line&" lines. It’s best to write the note(s) out at pitch.",l.Type,l);
				}
			}
		}	*/
	}
	
	function checkScoreText() {
		var title = curScore.title;
		// var subtitle = curScore.subtitle;
		var composer = curScore.composer;
		var titlePlainText = title.replace(/<[^>]+>/g, "");
		//var subtitlePlainText = subtitle.replace(/<[^>]+>/g, "");
		
		// TO FIX — CAN'T GET SUBTITLE OF SCORE???
		
		// **** CHECK DEFAULT SUBTITLE HASN'T BEEN CHANGED **** //
		//if (subtitle === 'Subtitle') addError( "You haven’t changed the Subtitle in File→Project Properties","pagetop");
		
		// **** CHECK DEFAULT TITLE HASN'T BEEN CHANGED **** //
		if (title === 'Untitled score') {
			addError( "You haven’t changed the Work Title in File→Project Properties","pagetop");
		} else {
			
			// **** CHECK IF THERE IS A SPELLING ERROR IN THE TITLE OR SUBTITLE **** //
			var lowerCaseTitle = titlePlainText.toLowerCase();
			//var lowerCaseSubtitle = subtitlePlainText.toLowerCase();
			
			var isSpellingError = false;
			for (var i = 0; i < spellingerrorsatstart.length / 2; i++) {
				var spellingError = spellingerrorsatstart[i*2];
				if (lowerCaseTitle.substring(0,spellingError.length) === spellingError) {
					isSpellingError = true;
					var correctSpelling = spellingerrorsatstart[i*2+1];
					var diff = titlePlainText.length-spellingError.length;
					var correctText = '';
					if (diff > 0) {
						correctText = correctSpelling+titlePlainText.substring(spellingError.length,diff);
					} else {
						correctText = correctSpelling;
					}
					addError("The title has a spelling error in it\nit should be ‘"+correctText+"’.","pagetop");
					break;
				}
			/*	if (lowerCaseSubtitle.substring(0,spellingError.length) === spellingError) {
					isSpellingError = true;
					var correctSpelling = spellingerrorsatstart[i*2+1];
					var diff = subtitlePlainText.length-spellingError.length;
					var correctText = '';
					if (diff > 0) {
						correctText = correctSpelling+subtitlePlainText.substring(spellingError.length,diff);
					} else {
						correctText = correctSpelling;
					}
					addError("The subtitle has a spelling error in it\nit should be ‘"+correctText+"’.","pagetop");
					break;
				}*/
			}
			if (!isSpellingError) {
				for (var i = 0; i < spellingerrorsanywhere.length / 2; i++) {
					var spellingError = spellingerrorsanywhere[i*2];
					if (titlePlainText.includes(spellingError)) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsanywhere[i*2+1];
						var correctText = titlePlainText.replace(spellingError,correctSpelling);
						addError("The title has a spelling error in it; it should be ‘"+correctText+"’.","pagetop");
						break;
					}
					/*if (subtitlePlainText.includes(spellingError)) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsanywhere[i*2+1];
						var correctText = subtitlePlainText.replace(spellingError,correctSpelling);
						addError("The subtitle has a spelling error in it; it should be ‘"+correctText+"’.","pagetop");
						break;
					}*/
				}
			}
		}
		
		// **** CHECK DEFAULT COMPOSER TEXT **** //
		if (composer === 'Composer / arranger') addError( "You haven’t changed the default composer in File → Project Properties","pagetop");
	}
	
	function checkKeySignature (keySig,sharps) {
		// *********************** KEY SIGNATURE ERRORS *********************** //
		var keySigSegment = keySig.parent;
		if (sharps != prevKeySigSharps) {
			if (sharps > 6) addError("This key signature has "+sharps+" sharps,\nand would be easier to read if rescored as "+(12-sharps)+" flats.",keySig);
			if (sharps < -6) addError("This key signature has "+Math.abs(sharps)+" flats, and would be easier to read if rescored as "+(12+sharps)+" sharps.",keySig);
			if (currentBarNum - prevKeySigBarNum  < 16) addError("This key change comes only "+ (currentBarNum - prevKeySigBarNum) +" bars after the previous one.\nPerhaps the previous one could be avoided by using accidentals instead.",keySig);
			prevKeySigSharps = sharps;
			prevKeySigBarNum = currentBarNum;
		} else {
			addError("This key signature is the same as the one in bar "+prevKeySigBarNum+".\nPerhaps delete it?",keySig);
		}
	}
	
	function checkTimeSignatures () {
		var segment = curScore.firstSegment();
		prevTimeSig = "";
		while (segment) {
			if (segment.segmentType == Segment.TimeSig) {
				var theTimeSig = segment.elementAt(0);
				if (theTimeSig.type == Element.TIMESIG) {
					var theTimeSigStr = theTimeSig.timesig.str;
					errorMsg += "\n found time sig "+theTimeSigStr;
					if (theTimeSigStr === prevTimeSig) {
						addError("This time signature appears to be redundant (was already "+prevTimeSig+")\nIt can be safely deleted.",theTimeSig);
					}
					prevTimeSig = theTimeSigStr;
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
					var searchFermata = j+' '+theTick;
					//errorMsg+="\nLooking for "+searchFermata;
					
					if (j!=staffIdx) {
						fermataInAllParts = fermataLocs.includes(searchFermata);
						//if (!fermataInAllParts) errorMsg+="\nCouldn't find this fermata";
						
					}
				}
				if (!fermataInAllParts) addError("If you have a fermata in one staff,\nall staves should also have a fermata at the same place",fermata);
				ticksDone.push(theTick);
			}
		}
	}
	
	function checkStaccatoIssues (noteRest) {
		if (noteRest.duration.ticks >= division * 2) {
			addError ("Don’t put staccato dots on long notes",noteRest);
			return;
		}		
		if (noteRest.notes[0].dots != null && noteRest.duration.ticks >= (division * 0.5)) {
			addError ("Don’t put staccato dots on dotted notes",noteRest);
			return;
		}
		if (noteRest.notes[0].tieForward != null) {
			addError ("Don’t put staccato dots on tied notes",noteRest);
			return;
		}
	}
	
	function checkStaffNames () {
		var numStaves = curScore.nstaves;
		var staves = curScore.staves;
		var cursor = curScore.newCursor();
		cursor.rewind(Cursor.SCORE_START);

	//	errorMsg += "fullInstNamesShowing = "+fullInstNamesShowing+"; shortInstNamesShowing = "+shortInstNamesShowing;
		for (var i = 0; i < numStaves-1 ; i++) {
			var staff1 = staves[i];

			var full1 = staff1.part.longName;
			var short1 = staff1.part.shortName;
			// Check those dumb default musescore names
			if (full1 === 'Violins 1') addError ("Change the long name to Violin I (see Behind Bars, p. 509)", "system1 "+i);
			if (full1 === 'Violins 2') addError ("Change the long name to Violin II (see Behind Bars, p. 509)", "system1 "+i);
			if (full1 === 'Violas') addError ("Change the long name to Viola (see Behind Bars, p. 509)", "system1 "+i);
			if (full1 === 'Violoncellos') addError ("Change the long name to Cello (see Behind Bars, p. 509)", "system1 "+i);
			if (full1 === 'Contrabasses') addError ("Change the long name to Double Bass or D. Bass (see Behind Bars, p. 509)", "system1 "+i);
			if (short1 === 'Vlns. 1') addError ("Change the short name to Vln. I (see Behind Bars, p. 509)", "system2 "+i);
			if (short1 === 'Vlns. 2') addError ("Change the short name to Vln. II (see Behind Bars, p. 509)", "system2 "+i);
			if (short1 === 'Vlas.') addError ("Change the short name to Vla. (see Behind Bars, p. 509)", "system2 "+i);
			if (short1 === 'Vcs.') addError ("Change the short name to Vc. (see Behind Bars, p. 509)", "system2 "+i);
			if (short1 === 'Cbs.') addError ("Change the short name to D.B. (see Behind Bars, p. 509)", "system2 "+i);
			
			//errorMsg += "\nStaff "+i+" long = "+full1+" short = "+short1;
			var checkThisStaff = true;
			if (full1 === "" && short1 === "") checkThisStaff = false;
			if (isGrandStaff[i] && !isTopOfGrandStaff[i]) checkThisStaff = false;
			if (checkThisStaff) {
				for (var j = i+1; j < numStaves; j++) {
					if (isGrandStaff[j] && !isTopOfGrandStaff[j]) checkThisStaff = false;
					if (checkThisStaff) {
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
	}
	
	function checkLedgerLines (noteRest) {
		var maxNumLedgerLines = getMaxNumLedgerLines(noteRest);
		//errorMsg += "maxNumLL = "+maxNumLedgerLines;
		var numberOfLedgerLinesToCheck = 4;
		if (ledgerLines.length > numberOfLedgerLinesToCheck) ledgerLines = ledgerLines.slice(1);
		ledgerLines.push(maxNumLedgerLines);
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
			if (maxNumLedgerLines > 5) {
				if (isTrebleClef && reads8va) {
					addError("This passage is very high for treble clef;\nit may be better with an 8va symbol",noteRest);
					flaggedLedgerLines = true;
				}
			}
			if (maxNumLedgerLines < -5) {
				if (isTrebleClef) {
					if (readsBass) {
						addError("This passage is very low for treble clef;\nit may be better in bass clef",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsAlto) {
							addError("This passage is very low for treble clef;\nit may be better in alto clef",noteRest);
							flaggedLedgerLines = true;
						}
					}
				}
				if (isTenorClef && readsBass) {
					addError("This passage is very low for tenor clef;\nit may be better in bass clef",noteRest);
					flaggedLedgerLines = true;
				}
				if (isBassClef && reads8va) {
					addError("This passage is very low for bass clef;\nit may be better with an 8ba",noteRest);
					flaggedLedgerLines = true;
				}
			}
			if (!flaggedLedgerLines && ledgerLines.length >= numberOfLedgerLinesToCheck) {
				var averageNumLedgerLines = ledgerLines.reduce((a,b) => a+b) / ledgerLines.length;
				if (isBassClef) {
					//trace(averageNumLedgerLines);
					if (readsTenor && averageNumLedgerLines > 2) {
						addError("This passage is quite high;\nit may be better in tenor or treble clef",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsTreble && averageNumLedgerLines > 3) {
							addError("This passage is very high;\nit may be better in treble clef",noteRest);
							flaggedLedgerLines = true;
						} else {
							if (reads8va && averageNumLedgerLines < -4) {
								addError("This passage is very low;\nit may be better with an 8ba",noteRest);
								flaggedLedgerLines = true;
							}
						}
					}
				}

				if (isTenorClef) {
					if (readsTreble && averageNumLedgerLines > 2) {
						addError("This passage is quite high;\nit may be better in treble clef",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsBass && averageNumLedgerLines < -1) {
							addError("This passage is quite low;\nit may be better in bass clef",noteRest);
							flaggedLedgerLines = true;
						}
					}
				}
				if (isTrebleClef) {
					if (reads8va && averageNumLedgerLines > 4) {
						addError("This passage is very high;\nit may be better with an 8va",noteRest);
						flaggedLedgerLines = true;
					} else {
						if (readsTenor && averageNumLedgerLines < -1) {
							addError("This passage is quite low;\nit may be better in tenor clef",noteRest);
							flaggedLedgerLines = true;
						} else {
							if (readsBass && averageNumLedgerLines < -2) {
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
			var numLedgerLines = 0;
			
			var note = noteRest.notes[i];
			var centreLineOffset = getOffsetFromMiddleLine (note); 
			if (centreLineOffset > 5) {
				numLedgerLines = Math.trunc((centreLineOffset - 6) / 2) + 1; // num ledger lines above staff; e.g. A5 is centreLineOffset 6 = 1 ll
			} else {
				if (centreLineOffset < -5) numLedgerLines = Math.trunc((centreLineOffset + 6) / 2) - 1; // num ledger lines below staff — will be negative number — e.g. C4 = centrelineoffset -6 = -1
			}
			if (Math.abs(numLedgerLines) > Math.abs(maxNumLedgerLines)) maxNumLedgerLines = numLedgerLines;
		}
		return maxNumLedgerLines;
	}
	
	function checkStringHarmonic (noteRest, staffNum) {

		var harmonicCircleIntervals = [12,19,24,28,31,34,36,38,40,42,43,45,46,47,48];
		var diamondHarmonicIntervals = [3,4,5,7,12,19,24,28,31,34,36];
		var violinStrings = [55,62,69,76];
		var violaStrings = [48,55,62,69];
		var celloStrings = [36,43,50,57];
		var bassStrings = [40,45,50,55];
		isStringHarmonic = false;
		
		if (noteRest.notes[0].tieBack) return;
		var nn = noteRest.notes.length;
		//errorMsg += "\nCHECKING STRING HARMONIC — nn = "+nn;
		if (nn == 2) {
			//check for possible artificial harmonic
			var noteheadStyle1 = noteRest.notes[0].headGroup;
			var noteheadStyle2 = noteRest.notes[1].headGroup;
			//errorMsg += "\nns1 = "+noteheadStyle1+" vs "+NoteHeadGroup.HEAD_NORMAL+"; ns2 = "+noteheadStyle2+" vs "+NoteHeadGroup.HEAD_DIAMOND;
			if (noteheadStyle1 == NoteHeadGroup.HEAD_NORMAL && noteheadStyle2 == NoteHeadGroup.HEAD_DIAMOND) {
				isStringHarmonic = true;
				// we have a false harmonic
				var noteheadPitch1 = noteRest.notes[0].pitch;
				var noteheadPitch2 = noteRest.notes[1].pitch;
				//errorMsg += "\nFALSE HARM FOUND: np1 "+noteheadPitch1+" np2 "+noteheadPitch2;
				var interval = noteheadPitch2 - noteheadPitch1;
				
				if (interval != 5) {
					addError("This looks like an artificial harmonic, but the interval between\nthe fingered and touched pitch is not a perfect fourth.",noteRest);
				}
			}
		}
		
		if (nn == 1) {
			var harmonicArray = [];
			var stringsArray = [];
			var noteheadStyle = noteRest.notes[0].headGroup;

			if (typeof currentStaffNum !== 'number') errorMsg += "\nArtic error in checkStrigHaronic nn1";
			var theArticulation = getArticulation(noteRest, staffNum);
			//errorMsg += "\nThe artic sym = "+theArticulation.symbol.toString();
			if (theArticulation) {
				if (theArticulation.symbol == kHarmonicCircle) {
					isStringHarmonic = true;
					harmonicArray = harmonicCircleIntervals;
				}
			}
			if (noteheadStyle == NoteHeadGroup.HEAD_DIAMOND) {
				isStringHarmonic = true;
				harmonicArray = diamondHarmonicIntervals;
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
				addError ("Chord found in string section, but not marked as div.",noteRest);
				flaggedDivError = true;
			}
		} else {
			if (isDiv && !flaggedDivError) {
				addError ("Single note found in string section, but no unis. marked",noteRest);
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
		if (typeof staffNum !== 'number') errorMsg += "\nArtic error in check pizz";
		
		var theArtic = getArticulation (noteRest, staffNum);
		if (theArtic) {
			if (noPizzArticArray.includes(theArtic.symbol)) {
				addError("It’s not recommended to have a staccato articulation on a pizzicato note.",noteRest);
				lastPizzIssueBar = barNum;
				lastPizzIssueStaff = staffNum;
				return;
			}
		}
		
		// check dur >= minim
		if (noteRest.duration.ticks >= Minim) {
			addError("It’s not recommended to have a pizzicato minim or longer (unless the tempo is very fast).\nPerhaps this is supposed to be arco?",noteRest);
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
		var slurEnd = slurStart + currentSlur.spannerTicks.ticks;
		var isEndOfSlur = currTick == slurEnd;

		//errorMsg += "\nCHECKING SLUR: isRest: "+isRest;
		
		if (isRest) {
			if (!isKeyboardInstrument && !flaggedSlurredRest) {
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
			if (!isStartOfSlur) {
				if (typeof staffNum !== 'number') errorMsg += "\nArtic error in check slur issues";
			
				var theArtic = getArticulation(noteRest, staffNum);
				if (theArtic) {
					//errorMsg += "\nNote has artic "+theArtic.symbol;
					if (accentsArray.includes(theArtic.symbol) ) {
						addError("Don’t put accents on notes in the middle of a slur.",noteRest);
						return;
					}
				}
			}
		
			// Check ties to middle of slurs
			if (isStartOfSlur) {
				//errorMsg += "\nSlur started — mid = "+isMiddleOfTie+"; end = "+isEndOfTie;
				if (isMiddleOfTie) {
					addError("Don’t begin a slur in the middle of a tied note.\nExtend the slur back to the start of the tie",currentSlur);
					return;
				}
				if (isEndOfTie) {
					addError("Don’t begin a slur at the end of a tied note.\nStart the slur at the beginning of the next note",currentSlur);
					return;
				}
			}
		
			// Check ties to middle of slurs
			if (isEndOfSlur) {
				//errorMsg += "\nSlur started — mid = "+isMiddleOfTie+"; start = "+isStartOfTie;
				if (isMiddleOfTie) {
					addError("Don’t end a slur in the middle of a tied note.\nExtend the slur to the end of the tie",currentSlur);
					return;
				}
				if (isStartOfTie) {
					addError("Don’t end a slur at the beginning of a tied note.\nInclude the full duration of tied note in the slur",currentSlur);
					return;
				}
			}
		

			var iterationArticulationArray = [kTenutoAbove,kTenutoBelow,
				kStaccatissimoAbove, kStaccatissimoAbove+1,
				kStaccatissimoStrokeAbove, kStaccatissimoStrokeAbove+1,
				kStaccatissimoWedgeAbove, kStaccatissimoWedgeAbove+1,
				kStaccatoAbove, kStaccatoAbove+1];
		
			if (!noteRest.notes[0].tieBackward) {
				if (typeof staffNum !== 'number') errorMsg += "\nArtic error in slur issues tieBackward";
			
				var theArtic = getArticulation(noteRest, staffNum);
				var noteheadStyle = noteRest.notes[0].headGroup;
			}
		}
		// TO FIX
			/*if (nn = prevnn && pitch = prevPitch && noteheadStyle != NoteHeadGroup. && prevNotehead != HeadlessNoteStyle && voiceNum = prevVoiceNum && n.GetArticulation(TenutoArtic) = false && !theArtic = false && prevArtic = false) {
				//trace ("pitch = "&pitch&" prevPitch = "&prevPitch&"; currentBarNum = "&currentBarNum&"; staffNum = "&staffNum);
				addError("Don’t repeat a pitch under a slur.\nEither remove the slur, or add some articulation, such as a tenuto or staccato.",NoteRest);
		}*/
		
	}
	
	function checkStemDirection (noteRest) {
		if (noteRest.stem) {
			if (noteRest.stem.stemDirection > 0) addError("Note has had stem direction flipped. If this is not deliberate,\nreset it by clicking ‘Format→Reset Shapes and Positions’",noteRest);
		}
	}
	
	function checkGraceNotes (graceNotes) {
		var n = graceNotes.length;
		var hasSlash = false;
		var totalDur = 0;
		for (var i = 0; i < n; i ++) {
			var graceNote = graceNotes[i];
			if (graceNote.stemSlash != null) hasSlash = true;
			totalDur += graceNote.duration.ticks;
		}
		var errorStr = "In general, always use ";
		if (totalDur != division * 0.5 * n) errorStr += "quaver ";
		errorStr += "grace-notes ";
		if (!hasSlash) errorStr += "with a slash through the stem";
		if (errorStr !== "In general, always use grace-notes ") addError (errorStr,graceNotes[0]);
		
		if (!isSlurred) {
			addError("In general, grace-notes should always be slurred to the main note,\nunless you specifically add staccato articulation",graceNotes[0]);
		}
	}
	
	function getArticulation (noteRest, staffNum) {
		// I WISH: you could just get the articulations of a note instead of having to do this hack
		// I WISH: you could get the staffidx of a note/staff
		if (typeof staffNum !== 'number') errorMsg += "\nArtic error staffNum wrong";
		var theTick = noteRest.parent.tick;
		if (theTick == undefined || theTick == null) {
			errorMsg += "\nERROR articulation tick = "+theTick;
		} else {
			var articArray = articulations[staffNum];
			if (articArray == null || articArray == undefined) {
				errorMsg += "\nERROR articArray undefined | staffNum is "+staffNum+" = "+staffNum.length;
			} else {
				return articulations[staffNum][theTick];
			}
		}
		return null;
	}
	
	function checkRehearsalMark (textObject) {
		errorMsg += "\nFound reh mark "+textObject.text;
		
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
		errorMsg += "\nFound "+numRehearsalMarks+" rehearsal marks";
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
	
	function getOffsetFromMiddleLine (note) {
		var theTPC = note.tpc2;
		var thePitch = note.pitch;
		var octave = Math.trunc(thePitch/12); // where middle C = 5
		var diatonicPitchClass = (((theTPC+1)%7)*4+3) % 7; // where C = 0, D = 1 etc.
		var diatonicPitch = diatonicPitchClass+octave*7; // where middle C = 35
		return diatonicPitch - diatonicPitchOfMiddleLine; // 41 = treble B
	}
	
	function checkStaffOrder () {
		// **** CHECK STANDARD CHAMBER LAYOUTS FOR CORRECT SCORE ORDER **** //
		var numGrandStaves = 0;
		var prevPart = null;
		var prevPrevPart = null;
		var parts = curScore.parts;
		var numParts = parts.length;
		var numStaves = curScore.nstaves;
		
		for (var i = 0; i < curScore.nstaves; i++) {
			var part = curScore.staves[i].part;
			if (i > 0 && part.is(prevPart)) {
				isGrandStaff[i-1] = true;
				isGrandStaff[i] = true;
				if (prevPart != prevPrevPart) isTopOfGrandStaff[i-1] = true;
				grandStaves.push(i-1);
				grandStaves.push(i);
				numGrandStaves ++;
			} else {
				isTopOfGrandStaff[i] = false;
				isGrandStaff[i] = false;
			}
			prevPrevPart = prevPart;
			prevPart = part;
		}
		
		// ** FIRST CHECK THE ORDER OF STAVES IF ONE OF THE INSTRUMENTS IS A GRAND STAFF ** //
		if (numGrandStaves > 0) {
			// CHECK ALL SEXTETS, OR SEPTETS AND LARGER THAT DON"T MIX WINDS & STRINGS
			for (var i = 0; i < numStaves; i++) {
				var instrumentType = instrumentIds[i];
				if (instrumentType.includes("strings.")) scoreHasStrings = true;
				if (instrumentType.includes("wind.")) scoreHasWinds = true;
				if (instrumentType.includes("brass.")) scoreHasBrass = true;
			}
			// do we need to check the order of grand staff instruments?
			// only if there are less than 7 parts, or all strings or all winds or only perc + piano
			var checkGrandStaffOrder = (numParts < 7) || ((scoreHasWinds || scoreHasBrass) != scoreHasStrings) || (!(scoreHasWinds || scoreHasBrass) && !scoreHasStrings);
	
			if (checkGrandStaffOrder) {
				for (var i = 0; i < numGrandStaves;i++) {
					var bottomGrandStaffNum = grandStaves[i*2+1];
					if (bottomGrandStaffNum < numStaves && !isGrandStaff[bottomGrandStaffNum+1]) addError("For small ensembles, grand staff instruments should be at the bottom of the score.\nMove ‘"+curScore.staves[bottomGrandStaffNum].part.longName+"’ down using the Instruments tab.","pagetop");
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
		var flStaff, obStaff, clStaff, bsnStaff, hnStaff;
		var tpt1Staff, tpt2Staff, tbnStaff, tbaStaff;
	
		// Check Quintets
		if (numStaves == 5) {
			for (var i = 0; i < 5; i ++) {
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
			}
			// **** CHECK WIND QUINTET STAFF ORDER **** //
			if (numFl == 1 && numOb == 1 && numCl == 1 && numBsn == 1 && numHn == 1) {
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
			if (numTpt == 2 && numHn == 1 && numTbn == 1 && numTba == 1) {
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
		if (stretch > 14 && stretch < 16) addError("This chord may be too wide to stretch for some pianists. Consider splitting it between hands.",noteRest);
		if (stretch > 16) addError("This chord is too wide to stretch. Consider splitting it between hands.",noteRest);
		if (stretch < 14 && numNotes > 5) addError("It looks like there are too many notes in this chord to play in one hand.",noteRest);
	}
	
	function checkOneNoteTremolo (noteRest, tremolo) {
		if (tremolo == null || tremolo == undefined) errorMsg += "\ntremolo is "+tremolo;
		//errorMsg += "\nCHECKING 1-NOTE TREMOLO: parent is "+tremolo.parent.name+" parent parent is "+tremolo.parent.parent.name;
		//errorMsg += "\nTREMOLO: parent parent tick is "+tremolo.parent.parent.tick;
		//errorMsg += "\nTREMOLO: username is "+tremolo.userName()+" name is "+tremolo.name+" subtype is "+tremolo.subtype+" symbol is "+tremolo.symbol;
		//errorMsg += "\nTREMOLO: bbox height is "+tremolo.bbox.height+" elements is "+tremolo.elements;
		var numStrokes = parseInt((Math.round(tremolo.bbox.height * 10.)-2)/8);
		var dur = parseFloat(noteRest.duration.ticks) / division;
		errorMsg += "\n TREMOLO HAS "+numStrokes+" strokes; dur is "+dur;
		switch (numStrokes) {
			case 0:
				errorMsg += "\nCouldn't calculate number of strokes";
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
	
	function checkTwoNoteTremolo (noteRest, tremolo) {
		if (tremolo == null || tremolo == undefined) errorMsg += "\ntremolo is "+tremolo;
		errorMsg += "\nCHECKING 2-NOTE TREMOLO: height is "+tremolo.bbox.height;
		if (isStringInstrument && !isSlurred) {
			addError("Fingered tremolos for strings should always be slurred.",noteRest);
			return;
		}
		/*if (n.DoubleTremolos > 3) {
			storeError(errors,"You don’t need more than 3 strokes for an unmeasured tremolo.","NoteRest",n);
		}
		if (n.DoubleTremolos = 1) {
			storeError(errors,"Are you sure you want a one-stroke measured tremolo here (should be written as quavers).","NoteRest",n);
		}
		if (n.DoubleTremolos > 0 and isPitchedPercussion) {
			storeError(errors,"Write "&utils.LowerCase(instrumentName)&" tremolos as single tremolos.","NoteRest",n);
		}*/
	}
	
	function checkGliss (noteRest, gliss) {
		if (gliss == null || gliss == undefined) errorMsg += "\ngliss is "+gliss;
		//errorMsg += "\nCHECKING GLISS — "+gliss.glissShowText+" | "+gliss.glissText+" | "+gliss.glissType+" | "+gliss.glissandoStyle;
		//if (gliss.glissShowText) {
			//addError("Including the word ‘gliss.’ in glissandi is  — switch it off in Properties",gliss);
			//return;
			//}
	}
	
	function addError (text,element) {
		errorStrings.push(text);
		errorObjects.push(element);
	}
	
	function showAllErrors () {
		curScore.startCmd()
		
		for (var i in errorStrings) {
			var text = errorStrings[i];
			var element = errorObjects[i];
			var eType = element.type;
			var staffNum = 0;
			var elementHeight = 0;
			var commentOffset = 1.0;
			
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
					//if (theLocation === "system2") errorMsg += "\nsystem2";
					if (theLocation === "system2" && !hasMoreThanOneSystem) continue; // don't show if only one system
				}
			} else {
				// calculate the staff number that this element is on
				elementHeight = element.bbox.height;
				if (eType != Element.MEASURE) {
					var elemStaff = element.staff;
					while (!curScore.staves[staffNum].is(elemStaff)) staffNum ++; // I WISH: staffNum = element.staff.staffidx
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
			var tick = 0, desiredPosX = 0, desiredPosY = 0;
			var spannerArray = [Element.HAIRPIN, Element.SLUR, Element.PEDAL, Element.PEDAL_SEGMENT];
			if (isString) {
				if (theLocation === "pagetop") {
					desiredPosX = 2.5;
					desiredPosY = 10.;
				}
				if (theLocation === "system1" || theLocation === "system2") desiredPosX = 5.0;
				if (theLocation === "system2") {
					tick = firstBarInSecondSystem.firstSegment.tick;
					//errorMsg += "\nPlacing system2 at tick: "+tick;
				}
			} else {
				if (spannerArray.includes(eType)) {
					tick = element.spannerTick.ticks;
				} else {
					if (eType == Element.MEASURE) {
						tick = element.firstSegment.tick;
					} else {
						tick = element.parent.tick;
					}
				}
			}
		
			// add text object to score
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
			while (commentPosArray[commentTopRounded+1000]) {
				commentTopRounded -= commentOffset;
				comment.offsetY -= commentOffset;
				comment.offsetX += commentOffset;
			}
			commentPosArray[commentTopRounded+1000] = true;
		
			// style the element
			if (element !== "pagetop" && element !== "top") {
				if (element.type == Element.CHORD) {
					element.color = "hotpink";
					for (var i=0; i<element.notes.length; i++) element.notes[i].color = "hotpink";
				} else {
					if (element.type == Element.TIMESIG) errorMsg += "\ncoloring time sig "+element.timesigNominal.str;
					element.color = "hotpink";
				}
			}
		}
		curScore.endCmd();
	}
	
	function deleteAllCommentsAndHighlights () {
		// ** SAVE CURRENT SELECTION ** //
		var s = curScore.selection;
		var startStaff = s.startStaff;
		var endStaff = s.endStaff;
		var startTick = 0;
		if (s.startSegment) startTick = s.startSegment.tick;
		var endTick = curScore.lastSegment.tick;
		if (s.endSegment) endTick = s.endSegment.tick + 1;
		
		// **** GET ALL ITEMS **** //
		curScore.startCmd()
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,curScore.nstaves);
		curScore.endCmd()
		var elems = curScore.selection.elements;
		//errorMsg = "Num elemns: "+elems.length;
		var elementsToRemove = [];
		var elementsToRecolor = [];
		for (var i = 0; i < elems.length; i++) {

			var e = elems[i];
			var t = e.type;
			var c = e.color;
			
			// style the element
			if (Qt.colorEqual(c,"hotpink")) {
				elementsToRecolor.push(e);
			} else {
				if (t == Element.STAFF_TEXT) {
					if (Qt.colorEqual(e.frameBgColor,"yellow") && Qt.colorEqual(e.frameFgColor,"black")) {
						elementsToRemove.push(e);
					}
				}
			}
		}
		curScore.startCmd();
		for (var i = 0; i < elementsToRecolor.length; i++) {
			elementsToRecolor[i].color = "black";
		}
		for (var i = 0; i < elementsToRemove.length; i++) {
			removeElement(elementsToRemove[i]);
		}
		
		curScore.selection.selectRange(0,endTick,startStaff,endStaff);
		curScore.endCmd();
		
	}
	
	ApplicationWindow {
		id: dialog
		title: "WARNING!"
		property var msg: ""
		visible: false
		flags: Qt.Dialog | Qt.WindowStaysOnTopHint
		width: 500
		height: 400        

		ScrollView {
			id: view
			anchors {
				fill: parent
				horizontalCenter: parent.horizontalCenter
				verticalCenter: parent.verticalCenter
				margins: 2
			}
			background: Rectangle {
				color: "white"
			}
			ScrollBar.vertical.policy: ScrollBar.AlwaysOn
			TextArea {
				text: errorMsg
				wrapMode: TextEdit.Wrap         
			}
		}
		
		FlatButton {            
			accentButton: true
			text: "Ok"
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				margins: 10
			}
			onClicked: dialog.close()
		}
	}

}