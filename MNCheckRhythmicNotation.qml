/*
 * Copyright (C) 2025 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.4 or later

import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.15
import Muse.UiComponents 1.0
import FileIO 3.0

MuseScore {
	version: "1.0"
	description: "bob"
	requiresScore: true
	title: "MN Check Rhythmic Notation"
	id: mncheckrhythmicnotation
	thumbnailName: "MNCheckRhythmicNotation.png"
	menuPath: "Plugins.MNCheckLayoutAndInstrumentation"
	FileIO { id: versionnumberfile; source: Qt.resolvedUrl("./assets/versionnumber.txt").toString().slice(8); onError: { console.log(msg); } }

	// **** GLOBALS **** //
	property var numLogs: 0
	property var currTick: 0
	property var currentBarNum: 0
	property var selectionArray: []
	property var timeSigs: []
	property var timeSigTicks: []
	property var rests: []
	property var tiedNotes: []
	property var errorMsg: ''
	property var errorStrings: []
	property var errorObjects: []
	property var glisses:[]
	property var isGliss: false
	property var currentZ: 16384
	property var timeSigNum: 0
	property var timeSigDenom: 0
	property var timeSigStr: ''
	property var isOnTheBeat: false
	property var barDur: 0
	property var isRest: false
	property var isNote: false
	property var prevIsNote: false
	property var displayDur: 0
	property var prevDisplayDur: 0
	property var soundingDur: 0
	property var prevSoundingDur: 0
	property var noteFinishesBeat: false
	property var hasBeam: false
	property var nextHasBeam: false
	property var cursor: null
	property var cursor2: null
	property var noteStartBeat: 0
	property var noteEndBeat: 0
	property var barStart: 0
	property var beatLength: 0
	property var virtualBeatLength: 0
	property var noteHidesBeat: false
	property var numBeatsHidden: 0
	property var noteStart: 0
	property var noteEnd: 0
	property var noteStartFrac: 0
	property var nextItem: null
	property var nextItemIsNote: false
	property var nextItemPos: 0
	property var nextItemDur: 0
	property var nextDisplayDur: 0
	property var nextItemBeat: 0
	property var nextNextItem: null
	property var nextNextItemIsNote: false
	property var nextNextItemPos: 0
	property var nextNextItemDur: 0
	property var nextNextItemBeat: 0
	property var hasPause: false
	property var nextItemHasPause: false
	property var isBarRest: false
	property var isManuallyEnteredBarRest: false
	property var currentBar: null
	property var isCompound: false
	property var restStartBeat: 0.875
	property var currentBeam: null
	property var currentBeamMode: 0
	property var currentBeamPos: 0
	property var nextBeam: null
	property var nextBeamMode: 0
	property var isPickupBar: false
	property var isTied: false
	property var haveHadFirstNote: false
	property var totalRestDur: 0
	property var flaggedWrittenStaccato: false
	property var dottedminim: 0
	property var minim: 0
	property var dottedcrotchet: 0
	property var crotchet: 0
	property var doubledottedquaver: 0
	property var dottedquaver: 0
	property var quaver: 0
	property var dottedsemiquaver: 0
	property var semiquaver: 0
	property var semibreve: 0
	property var lastCheckedTuplet: null
	property var numConsecutiveSemiquaverTriplets: 0
	property var frames: []
	
	property var possibleOnbeatSimplificationDurs: []
	property var possibleOnbeatSimplificationLabels: []
	property var possibleOffbeatSimplificationDurs: []
	property var possibleOffbeatSimplificationLabels: []
	
	property var debug: true
	property var progressShowing: false
	property var progressStartTime: 0
	property var twoNoteTremolos:[]
	property var currentStaffNum: 0
	property var isStringInstrument: false
	property var isKeyboardInstrument: false
	property var isWindOrBrassInstrument: false
	property var isVoice: false

	onRun: {
		if (!curScore) return;
		setProgress (0);
		
		
		// **** VERSION CHECK **** //
		var version46 = mscoreMajorVersion > 4 || (mscoreMajorVersion == 4 && mscoreMinorVersion > 5);
		if (!version46) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin requires MuseScore v. 4.6 or later.</p> ";
			dialog.show();
			return;
		}
		
		saveSelection();
		
		if (Qt.platform.os !== "osx") {
			dialog.fontSize = 12;
		}
		
		// **** INITIALISE VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		cursor = curScore.newCursor();
		cursor2 = curScore.newCursor();
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var numBars, totalNumBars;
		var d = division;
		semibreve = 4*d;
		dottedminim = 3*d;
		minim = 2*d;
		dottedcrotchet = 1.5*d;
		crotchet = d;
		doubledottedquaver = 0.875*d;
		dottedquaver = 0.75*d;
		quaver = 0.5*d;
		dottedsemiquaver = 0.375*d;
		semiquaver = 0.25*d;
		possibleOnbeatSimplificationDurs = [semiquaver, dottedsemiquaver, quaver, dottedquaver, doubledottedquaver, crotchet, dottedcrotchet, minim, dottedminim, semibreve];
		possibleOnbeatSimplificationLabels = ["semiquaver", "dotted semiquaver", "quaver", "dotted quaver", "double-dotted quaver", "crotchet", "dotted crotchet", "minim", "dotted minim", "semibreve"];
		possibleOffbeatSimplificationDurs = [semiquaver, dottedsemiquaver, quaver, dottedquaver, doubledottedquaver, crotchet, dottedcrotchet];
		possibleOffbeatSimplificationLabels = ["semiquaver", "dotted semiquaver", "quaver", "dotted quaver", "double-dotted quaver", "crotchet", "dotted crotchet"];
		var versionNumber = versionnumberfile.read().trim();
		getFrames();

		// **** DELETE ALL EXISTING COMMENTS AND HIGHLIGHTS **** //
		deleteAllCommentsAndHighlights();
		
		// **** SELECT ALL **** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		curScore.startCmd();

		firstStaffNum = curScore.selection.startStaff;
		lastStaffNum = curScore.selection.endStaff;
		
		// **** CHECK FOR GLISSES **** //
		var numTracks = numStaves * 4;
		for (var i = 0; i < numTracks; i++) glisses[i] = [];
		checkScoreForGlisses();
		
		// **** CHECK FOR 2-NOTE TREMS **** //
		for (var i = 0; i<numStaves; i++) twoNoteTremolos[i] = [];
		checkScoreForTwoNoteTremolos();
		setProgress (1);
		
		// **** CALCULATE FIRST BAR IN SCORE & SELECTION **** //
		firstBarInScore = curScore.firstMeasure;
		cursor.rewind(Cursor.SELECTION_START);
		firstBarInSelection = cursor.measure;
		firstTickInSelection = cursor.tick;
		firstBarNum = 1;
		currentBar = firstBarInScore;
			
		while (!currentBar.is(firstBarInSelection)) {
			firstBarNum ++;
			currentBar = currentBar.nextMeasure;
		}
		
		// **** CALCULATE LAST BAR IN SCORE & SELECTION **** //
		lastBarInScore = curScore.lastMeasure;
		cursor.rewind(Cursor.SELECTION_END);
		lastBarInSelection = cursor.measure;
		if (lastBarInSelection == null) lastBarInSelection = lastBarInScore;
		lastTickInSelection = cursor.tick;
		if (lastTickInSelection == 0) lastTickInSelection = curScore.lastSegment.tick + 1;
		lastBarNum = firstBarNum;
		while (!currentBar.is(lastBarInSelection)) {
			lastBarNum ++;
			currentBar = currentBar.nextMeasure;
		}
		setProgress (2);
		
		// **** CALCULATE TOTAL NUMBER OF BARS **** //
		numBars = lastBarNum-firstBarNum+1;
		totalNumBars = numBars*numStaves;
		setProgress (3);
		
		// **** SET UP USEFUL VARIABLES **** //
		var firstSystem = firstBarInScore.parent;
		var lastSystem = lastBarInScore.parent;
		var firstPage = firstSystem.parent;
		var lastPage = lastSystem.parent;
		var firstPageNum = firstPage.pagenumber;
		var lastPageNum = lastPage.pagenumber;
		
		// **** INITIALISE VARIABLES FOR THE LOOP **** //
		var numBarsProcessed,wasTied, currentTimeSig;
		var prevNoteWasDoubleTremolo;
		var tiedSoundingDur, tiedDisplayDur, tieIndex;
		var restCrossesBeat, restStartedOnBeat, isLastRest;
		var lastNoteInBar, lastRest, prevNoteRest;
		var totalDur, numComments;
		var firstNoteInTuplet, prevTuplet;
		var loop = 0;
		var totalNumLoops = numStaves * numBars * 4;
		setProgress (5);
		
		// *********************************************************************** //
		// ****     LOOP THROUGH THE SELECTED STAVES AND THE SELECTED BARS    **** //
		// **** NB — lastStaffNum IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS **** //
		// *********************************************************************** //
		for (currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum; currentStaffNum ++) {
			
			var theStaff = staves[currentStaffNum];
			if (theStaff == undefined) {
				logError("main loop — staff is undefined");
				continue;
			}
			
			// don't process this staff if it's hidden
			var thePart = theStaff.part;
			if (!thePart.show) continue;
			
			setInstrumentVariables(thePart);
			wasTied = false;
			prevNoteRest = null;
			firstNoteInTuplet = false;
			prevTuplet = null;
			numConsecutiveSemiquaverTriplets = 0;
			
			// ** REWIND TO START OF SELECTION ** //
			cursor.filter = Segment.All;
			cursor.rewind(Cursor.SELECTION_START);
			cursor.staffIdx = currentStaffNum;
			cursor2.staffIdx = currentStaffNum;
			cursor.filter = Segment.ChordRest;
			cursor2.filter = Segment.ChordRest;
			currentBar = cursor.measure;
			flaggedWrittenStaccato = false;
			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
												
				// **** GET TIME SIGNATURE **** //
				currentTimeSig = currentBar.timesigNominal;
				timeSigNum = currentTimeSig.numerator;
				timeSigDenom = currentTimeSig.denominator;
				timeSigStr = currentTimeSig.str;
				
				// **** GET BAR START & END TICKS **** //
				barStart = currentBar.firstSegment.tick;
				var barEnd = currentBar.lastSegment.tick;
				
				// **** CALCULATE BAR DURATION, BEAT LENGTH **** //
				barDur = barEnd - barStart;
				beatLength = crotchet;
				
				// **** IS THIS A PICKUP BAR? **** //
				isPickupBar = false;
				var expectedDuration = timeSigNum * (semibreve/timeSigDenom);
				isPickupBar = currentBarNum == 1 && expectedDuration != barDur;
				
				// **** CALCULATE IF THIS IS A COMPOUND TIME SIGNATURE **** //
				var canCheckThisBar = false;
				isCompound = false;
				if (timeSigDenom == 8 || timeSigDenom == 16) {
					isCompound = !(timeSigNum % 3);
					if (isCompound) beatLength = (division * 12) / timeSigDenom;
				}
				if (timeSigDenom == 4 || timeSigDenom == 2) isCompound = !(timeSigNum % 3) && (timeSigNum > 3);

				
				// ****             CALCULATE THE 'VIRTUAL BEAT LENGTH' 				   **** //
				// **** This is the underlying pulse, e.g. in 5/16, it would be 16th notes **** //
				// **** However, this is different from the 'beaming beat length'          **** //
				// **** Beaming beat length is typically either a ¼ or a dotted ¼ note     **** //
				virtualBeatLength = isCompound ? ((division * 3) / timeSigDenom) : ((division * 4) / timeSigDenom);
				
				// WE CAN'T REALLY CHECK 5/8, 7/8 etc, where the underlying beat patterns may vary
				// SO WE CAN CHECK THIS BAR IF:
				// 1) it's a compound time signature where the denominator is 8, 16, etc. (this allows 6/8, 9/16, 12/8, etc.)
				// 2) the numerator is 1, 2, 3 or 4 (this allows 4/4, 3/2, etc)
				// 3) the numerator is even (this allows 10/2, 14/8, etc)
				// 4) the timeSigDenom is <= 4 (this allows 5/4, etc)
				canCheckThisBar = (isCompound && timeSigDenom > 4) || timeSigNum < 5 || timeSigNum % 2 == 0 || timeSigDenom <= 4;
		
				// ** LOOP THROUGH ALL THE NOTERESTS IN THIS BAR ** //
				if (canCheckThisBar) {
				
					var startTrack = currentStaffNum * 4;
					var endTrack = startTrack + 4;
					var maxMusicDurThisBar = 0;
					var totalMusicDurThisTrack;
					for (var currentTrack = startTrack; currentTrack < endTrack; currentTrack++) {
						
						totalMusicDurThisTrack = 0;
						
						// **** UPDATE PROGRESS MESSAGE **** //
						loop++;
						setProgress(5+loop*95./totalNumLoops);
						cursor.track = currentTrack;
						cursor.rewindToTick(barStart);
						var processingThisBar = cursor.element && cursor.tick < barEnd;
						
						if (processingThisBar) {
							// ** INITIALISE PARAMETERS ** //
							totalRestDur = 0;
							haveHadFirstNote = false;
							rests = [];
							tiedNotes = [];
							prevSoundingDur = 0;
							prevDisplayDur = 0;
							prevNoteWasDoubleTremolo = false;
							numComments = 0;
							tiedSoundingDur = 0;
							tiedDisplayDur = 0;
							prevIsNote = false;
							restCrossesBeat = false;
							restStartedOnBeat = false;
							isLastRest = false;
							tieIndex = 0;
							lastRest = false;
							cursor2.track = currentTrack;
						}
						
						while (processingThisBar) {
							
							currTick = cursor.tick;
							
							// *** GET THE NOTE/REST, AND ITS VARIOUS PROPERTIES THAT WE'LL NEED *** //
							var noteRest = cursor.element;
							var isHidden = !noteRest.visible;
							isRest = noteRest.type == Element.REST;
							isNote = !isRest;
							displayDur = noteRest.duration.ticks; // what the note looks like
							soundingDur = noteRest.actualDuration.ticks; // what its actual length is, taking tuplets into account
							noteStart = cursor.tick - barStart; // offset from the start of the bar
							noteEnd = noteStart + soundingDur; // the tick at the end of the note
							lastNoteInBar = noteStart + soundingDur >= barDur; // is this the last note in the bar (in this track?)
							isTied = isNote ? (noteRest.notes[0].tieBack != null || noteRest.notes[0].tieForward != null) : false; // is this note tied either forwards or backwards?
							noteStartFrac = noteStart % beatLength; // whereabouts this note starts within its beat
							noteStartBeat = Math.trunc(noteStart/beatLength); // which beat in the bar
							var noteEndFrac = noteEnd % beatLength;
							noteEndBeat = Math.trunc(noteEnd/beatLength);
							noteFinishesBeat = !noteEndFrac; // is this the last note in the beat?
							numBeatsHidden = noteEndBeat-noteStartBeat-noteFinishesBeat; // how many beats does this note span?
							noteHidesBeat = numBeatsHidden > 0; // does this note hide a beat(s)
							isOnTheBeat = !noteStartFrac;
							currentBeam = noteRest.beam;	
							currentBeamMode = noteRest.beamMode;
							currentBeamPos = noteRest.beamPos;
							hasBeam = currentBeam != null;
							isGliss = glisses[currentTrack][currTick] != null;
							if (!isHidden) totalMusicDurThisTrack += soundingDur;
							//logError ("duration ="+noteRest.duration.ticks+" actualDuration = "+noteRest.actualDuration.ticks+" globalDuration = "+noteRest.globalDuration.ticks+" — totalMusic = "+totalMusicDurThisTrack);
							if (isPickupBar && isRest && noteRest.durationTypeWithDots.type == 14) addError ("This looks like a manually entered bar rest,\nwhich may not match the duration of the pickup bar.\nSelect it and press ‘delete’.",noteRest);
							
							
							// *** GET INFORMATION ON THE NEXT ITEM AND THE ONE AFTER THAT *** //
							cursor2.rewindToTick(currTick);
							var nextItemIsHidden;
							nextItem = null;
							nextItemIsHidden = false;
							nextItemIsNote = false;
							nextItemPos = 0;
							nextItemDur = 0;
							nextDisplayDur = 0;
							nextItemPos = 0;
							nextDisplayDur = -1;
							nextItemDur = -1;
							nextItemBeat = -1;
							nextHasBeam = false;
							nextBeam = null;
							nextBeamMode = Beam.NONE;
							
							if (cursor2.next()) {
								nextItem = cursor2.element;
								nextItemIsNote = nextItem.type != Element.REST;
								nextItemPos = cursor2.tick - cursor2.measure.firstSegment.tick;
								nextDisplayDur = nextItem.duration.ticks;
								nextItemDur = nextItem.actualDuration.ticks;
								nextItemBeat = Math.trunc(nextItemPos / beatLength);
								nextItemIsHidden = !nextItem.visible;
								nextBeam = nextItem.beam;
								nextHasBeam = (nextBeam != null);
								nextBeamMode = nextItem.beamMode;
								if (cursor2.next()) {
									nextNextItem = cursor2.element;
									nextNextItemIsNote = nextNextItem.type != Element.REST;
									nextNextItemPos = cursor2.tick - cursor2.measure.firstSegment.tick;
									nextNextItemDur = nextNextItem.actualDuration.ticks;
									nextNextItemBeat = Math.trunc(nextNextItemPos / beatLength);
								}
							}
						
							if (isHidden) {
								rests = [];
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
								tiedNotes = [];
								isTied = false;
							}
							
							// *** CHECK TO SEE WHETHER THIS NOTE & NEXT NOTE HAVE A PAUSE *** //
							var annotations = noteRest.parent.annotations;
							hasPause = false;
							if (annotations && annotations.length) {
								for (var i = 0; i < annotations.length && !hasPause; i++) {
									var theAnnotation = annotations[i];
									if (theAnnotation.track == currentTrack && theAnnotation.type == Element.FERMATA) hasPause = true;
								}
							}
							nextItemHasPause = false;
							
							if (nextItem) {
								annotations = nextItem.parent.annotations;
								if (annotations && annotations.length) {
									for (var i = 0; i < annotations.length && !hasPause; i++) {
										var theAnnotation = annotations[i];
										if (theAnnotation.track == currentTrack && theAnnotation.type == Element.FERMATA) nextItemHasPause = true;
									}
								}
							}
							
							// *** CALCULATE IF THIS IS THE END OF A TIE OR NOTE *** ///
							var lastNoteInTie = false;
							if (isTied) {
								lastNoteInTie = noteRest.notes[0].tieForward == null || lastNoteInBar || nextItemHasPause;
								if (!lastNoteInTie) {
									// check that the notes are the same as the next
									if (nextItemIsNote) {
										if (noteRest.notes.length == nextItem.notes.length) {
											for (var k = 0; k < noteRest.notes.length && !lastNoteInTie; k ++) {
												if (noteRest.notes[k].MIDIpitch != nextItem.notes[k].MIDIpitch) lastNoteInTie = true;
											}
										} else {
											lastNoteInTie = true;
										}
									} else {
										lastNoteInTie = true;
									}
								}
								tiedNotes.push(noteRest);
								//if (lastNoteInTie) logError(lastNoteInTie");
							} else {
								if (wasTied) tiedNotes = [];
							}
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 	CHECK 1: CHECK FOR MANUALLY ENTERED BAR REST	** //
							// ** ————————————————————————————————————————————————— ** //
							
							checkManuallyEnteredBarRest(noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 2: DOES THE NOTE HIDE THE BEAT??		** //
							// ** ————————————————————————————————————————————————— ** //
		
							checkHidingBeatError(noteRest);
									
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 3: NOTE/REST SHOULD NOT BREAK BEAM	** //
							// ** ————————————————————————————————————————————————— ** //
						
							checkBeamBrokenError(noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 4: BEAMED to NOTES IN NEXT BEAT 		** //
							// ** ————————————————————————————————————————————————— ** //
		
							checkBeamedToNotesInNextBeat(noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 5: CONDENSE OVERSPECIFIED REST 		** //
							// ** ————————————————————————————————————————————————— ** //
							
							// if this is a rest, then start building an array of rests
							// until you get to the last one, then check whether any of the rests
							// could be condensed into a single rest
							if (isNote || hasPause) {
								rests = [];
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
								totalRestDur = 0;
								//logError(Rest length now "+rests.length);
							} else {
								rests.push(noteRest);
								totalRestDur += noteRest.actualDuration.ticks;
								if (rests.length == 1) {
									restStartedOnBeat = isOnTheBeat;
									restStartBeat = noteStartBeat;
								} else {
									if (noteStartBeat != restStartBeat) restCrossesBeat = true;
								}
								isLastRest = (lastNoteInBar || nextItemIsNote || nextItem == null || nextItemHasPause || nextItemIsHidden);
								//logError(Found a rest: rest length now "+rests.length+"); isLastRest = "+isLastRest;
								if (isLastRest && rests.length > 1) condenseOverSpecifiedRest(noteRest);
							}
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 6: CHECK TIE SIMPLIFICATIONS			** //
							// ** ————————————————————————————————————————————————— ** //
							if (lastNoteInTie && !isGliss) {
								if (tiedNotes.length > 1) checkTieSimplifications(noteRest);
								tiedNotes = [];
							}
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 			CHECK 7: COULD BE STACCATO				** //
							// ** ————————————————————————————————————————————————— ** //
							if (isRest && displayDur == semiquaver && !isOnTheBeat && (noteStart % quaver != 0)) { 
								if (prevIsNote && nextItemIsNote && prevDisplayDur == semiquaver && !flaggedWrittenStaccato) {
									flaggedWrittenStaccato = true;
									if (isWindOrBrassInstrument || isVoice || isKeyboardInstrument) addError ("Consider simplifying this passage by making this note (and any similar notes)\na quaver and adding a staccato dot(s) as necessary.",[prevNoteRest,noteRest]);
									if (isStringInstrument) addError ("Consider simplifying this passage by making this note (and any similar notes) a quaver,\nand adding a staccato dot(s) if arco.",[prevNoteRest,noteRest]);
									if (!isWindOrBrassInstrument && !isVoice && !isStringInstrument && !isKeyboardInstrument) addError ("Consider simplifying this passage by making this note\n(and any similar notes) a quaver.",[prevNoteRest,noteRest]);
								}
							}
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 8: SPLIT NON-BEAT-BREAKING RESTS		** //
							// ** ————————————————————————————————————————————————— ** //
							if (isRest && !noteHidesBeat) {
								if (isOnTheBeat) {
									checkOnbeatRestSpelling(noteRest);
								} else {
									checkOffbeatRestSpelling(noteRest);
								}
							}
							
							// ** ————————————————————————————————————————————————— ** //
							// ** 		CHECK 9: CHECK TUPLET SETTINGS				** //
							// ** ————————————————————————————————————————————————— ** //
							if (noteRest.tuplet == null) {
								firstNoteInTuplet = null;
								numConsecutiveSemiquaverTriplets = 0;
							} else {
								if (!noteRest.tuplet.is(prevTuplet) || !firstNoteInTuplet) {
									firstNoteInTuplet = true;
									checkTupletSettings (noteRest.tuplet);
									prevTuplet = noteRest.tuplet;
								}
								
								// Is it a semiquaver triplet?
								if (noteRest.tuplet.actualDuration.ticks == division / 2 && noteRest.tuplet.actualNotes == 3) {
									if (numConsecutiveSemiquaverTriplets == 0) {
										if (firstNoteInTuplet && isOnTheBeat) numConsecutiveSemiquaverTriplets = 1;
									} else {
										numConsecutiveSemiquaverTriplets ++;
									}
									if (numConsecutiveSemiquaverTriplets == 6) addError ('These semiquaver triplets could be rewritten\nas a semiquaver sextuplet.',noteRest);
								} else {
									numConsecutiveSemiquaverTriplets = 0;
								}
							}
							
							// *** GO TO NEXT SEGMENT *** //
							if (cursor.next()) {
								processingThisBar = cursor.measure.is(currentBar);
							} else {
								processingThisBar = false;
							}
							prevSoundingDur = soundingDur;
							prevDisplayDur = displayDur;
							prevIsNote = isNote;
							prevNoteRest = noteRest;
							//prevNoteWasDoubleTremolo = isDoubleTremolo;
						} // end while processingThisBar
						if (totalMusicDurThisTrack > maxMusicDurThisBar) maxMusicDurThisBar = totalMusicDurThisTrack;
					} // end track loop
					
					
					// ** ————————————————————————————————————————————————— ** //
					// ** 	CHECK 10: CHECK TOO MUCH OR NOT ENOUGH MUSIC	** //
					// ** ————————————————————————————————————————————————— ** //
					//logError ("maxMusicDurThisBar = "+maxMusicDurThisBar+" barDur = "+barDur);
					// note I leave a 5 tick buffer here, because certain durations like septuplets are irrational, and their ints don't nicely sum to the bar duration
					if (maxMusicDurThisBar > 0 && maxMusicDurThisBar > barDur + 5) addError("This bar seems to have too many beats in it for "+timeSigStr, currentBar);
					if (maxMusicDurThisBar > 0 && maxMusicDurThisBar < barDur - 5) addError("This bar doesn’t seem to have enough beats in it for "+timeSigStr, currentBar);
				} // end if canCheckThisBar
				
				if (currentBar) currentBar = currentBar.nextMeasure;
				numBarsProcessed ++;
			} // end for currentBarNum	
		} // end for currentStaff
		
		// ** SHOW ALL OF THE ERRORS ** //
		showAllErrors();
		
		// ************ DESELECT ALL AND FORCE REDRAW ************ //
		selectNone();
				
		// ** SHOW INFO DIALOG ** //
		var numErrors = errorStrings.length;
		if (errorMsg != "") errorMsg = "<p>————————————<p><p>ERROR LOG (for developer use):</p>" + errorMsg;
		if (numErrors == 0) errorMsg = "<p>CHECK COMPLETED: Congratulations — no issues found!</p><p><font size=\"6\">🎉</font></p>"+errorMsg;
		if (numErrors == 1) errorMsg = "<p>CHECK COMPLETED: I found one issue.</p><p>Please check the score for the yellow comment box that provides more details of the issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove the comment and pink highlight.</p>" + errorMsg;
		if (numErrors > 1 && numErrors <= 100) errorMsg = "<p>CHECK COMPLETED: I found "+numErrors+" issues.</p><p>Please check the score for the yellow comment boxes that provide more details on each issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove all of these comments and highlights.</p>" + errorMsg;
		if (numErrors > 100) errorMsg = "<p>CHECK COMPLETED: I found over 100 issues — I have only flagged the first 100.<p>Please check the score for the yellow comment boxes that provide more details on each issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove all of these comments and highlights.</p>" + errorMsg;

		if (progressShowing) progress.close();
		curScore.endCmd();

		var h = 250+numLogs*10;
		if (h > 500) h =500;
		dialog.height = h;
		dialog.contentHeight = h;
		dialog.msg = errorMsg;
		dialog.titleText = 'MN CHECK RHYTHMIC NOTATION '+versionNumber;

		dialog.show();
	
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
	
	function selectNone () {
		// ************  								DESELECT AND FORCE REDRAW 							************ //
		//curScore.startCmd();
		cmd('escape');
		//curScore.doLayout(fraction(0, 1), fraction(-1, 1));
		//curScore.endCmd();
	}
	
	function saveSelection () {
		selectionArray = [];
		if (curScore.selection.isRange) {
			selectionArray[0] = curScore.selection.startSegment.tick;
			if (curScore.selection.endSegment == null) {
				selectionArray[1] = curScore.lastSegment.tick;
			} else {
				selectionArray[1] = curScore.selection.endSegment.tick;
			}
			selectionArray[2] = curScore.selection.startStaff;
			selectionArray[3] = curScore.selection.endStaff;
		}
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
	
	function setInstrumentVariables (thePart) {
		var currentInstrumentId = thePart.musicXmlId;
		//logError(id = "+currentInstrumentId);
		if (currentInstrumentId != "") {
			isStringInstrument = currentInstrumentId.includes("strings.");
			isKeyboardInstrument = currentInstrumentId.includes("keyboard");
			isWindOrBrassInstrument = currentInstrumentId.includes("wind.") || currentInstrumentId.includes("brass.");
			isVoice = currentInstrumentId.includes("voice.");
		}
	
		//logError(isStringInstrument = "+isStringInstrument+"); isKeyboardInstrument="+isKeyboardInstrument+"; isKeyboardInstrument="+isKeyboardInstrument+"; isWindOrBrassInstrument="+isWindOrBrassInstrument+"; isVoice="+isVoice;
	}
	
	function checkManuallyEnteredBarRest (noteRest) {
		if (isPickupBar) return;
		isBarRest = isRest && soundingDur == barDur;
		isManuallyEnteredBarRest = isBarRest && noteRest.durationTypeWithDots.type < 14;
		if (isManuallyEnteredBarRest) addError ("Bar rest has been manually entered, and is therefore incorrectly positioned.\nSelect the bar and press ‘delete’ to create a correctly positioned bar rest.",noteRest);
	}
	
	function isTwoNoteTremolo(noteRest) {
		if (noteRest.type == Element.REST) return false;
		var currTick = noteRest.parent.tick;
		if (twoNoteTremolos[currentStaffNum][currTick] != null) return true;
		var prevNote = getPreviousNoteRest(noteRest);
		if (prevNote == null || prevNote == undefined) return false;
		if (prevNote.type == Element.REST) return false;
		var prevTick = prevNote.parent.tick;
		var trem = twoNoteTremolos[currentStaffNum][prevTick];
		if (trem == null || trem == undefined) return false;
		return true;
	}
	
	function checkHidingBeatError (noteRest) {
		var hidingBeatError;
		var startTick = noteRest.parent.tick;
		var startOffset = startTick - barStart;

		// ** FIRST CHECK IF THIS IS A TUPLET ** //
		if (noteRest.tuplet == null) {
			hidingBeatError = noteHidesBeat && !isBarRest && !hasPause; // make a temp version
		} else {
			var theTuplet = noteRest.tuplet;
			// if it's already part of a tuplet then don't flag it
			var isInTuplet = false;
			if (theTuplet != null) isInTuplet = theTuplet.is(lastCheckedTuplet);
			if (isInTuplet) {
				hidingBeatError = false;
			} else {
				lastCheckedTuplet = theTuplet;
				// does this tuplet cross a beat?
				var endTick = theTuplet.actualDuration.ticks + startTick;
				var startBeatOffset = startTick % beatLength;
				var endOffset = endTick - barStart - 1;
				var startBeat = Math.floor(startOffset / beatLength);
				var endBeat = Math.floor(endOffset / beatLength);
				//logError("t: "+startTick+"–"+endTick+"; beat "+startBeat+"–"+endBeat);
				// does this tuplet cross a beat?
				hidingBeatError = false;
				if (endBeat != startBeat) {
					// yes it crosses a beat
					// if it's offbeat, don't allow it
					if (startBeatOffset != 0) {
						addError ("Offbeat tuplets that cross beats can be difficult to read and are not recommended.\nEither split up the tuplet, or consider rewriting.",theTuplet);
					} else {
						// it's on-beat, but lasts longer than one beat
						hidingBeatError = false;
						var d = noteRest.duration.ticks;
						var tupletDivision = theTuplet.actualDuration.ticks / theTuplet.normalNotes;
						//logError ("d = "+d+"; tupletDiv = "+tupletDivision);
						if (d != tupletDivision) {
							addError ("The first note in this tuplet does not match the tuplet’s primary subdivision.\nConsider splitting the tuplet up into one-beat tuplets.", theTuplet)
						} else {
							for (var i = 0; i < theTuplet.elements.length; i ++) {
								var e = theTuplet.elements[i];
								if (e.type == Element.CHORD && e.duration.ticks != d) hidingBeatError = true;
							}
							if (hidingBeatError) {
								addError ("This tuplet crosses a beat and has complex rhythms.\nIt is therefore potentially difficult to read.\nConsider splitting it up into one-beat tuplets.",theTuplet);
							}
						}
					}
				}
			}
		}
		
		if (!hidingBeatError) return;
		if (isTwoNoteTremolo(noteRest)) return;
		
		//logError(Checking beat Hiding");
		if (isOnTheBeat) {
			
			// ** ON THE BEAT — RESTS ** //
			if (isRest) {
				if (soundingDur == dottedminim) {
					if (timeSigStr === "4/4" || timeSigStr === "9/8") {
						addError ("Never write a dotted minim rest in "+timeSigStr+"\n(See ‘Behind Bars’ p. 162)",noteRest);
						return;
					}
				}
	
				if (soundingDur == crotchet) {
					if (timeSigStr === "3/8") {
						addError ("Never write a crotchet rest in 3/8\n(See ‘Behind Bars’ p. 162)",noteRest);
						return;
					}
				}
				if (isCompound) {
					hidingBeatError = soundingDur % beatLength;
					if (soundingDur == dottedminim && timeSigStr === "12/8" && startOffset == dottedcrotchet) {
						addError ("Never write a dotted minim rest on beat 2 of a 12/8 bar\n(See ‘Behind Bars’ p. 163)",noteRest);
						return;
					}
				} else {
					if (soundingDur == minim) {
						// ok in 4/4 on 1 & 3
						if (timeSigStr === "3/4") {
							addError ("Never write a minim rest in 3/4\n(See ‘Behind Bars’ p. 161)",noteRest);
							return;
						}
						hidingBeatError = false;
						if ((timeSigStr === "4/4" || timeSigStr === "5/4" || timeSigStr === "2/2") && noteStartBeat == 1) hidingBeatError = true;
						if (timeSigStr === "6/4") hidingBeatError = true;
					}
					
					if (soundingDur == dottedcrotchet && timeSigDenom > 2) {
						addError ("Never write a dotted crotchet rest in "+timeSigStr+"\n(See ‘Behind Bars’ p. 162)",noteRest);
						return;
					}
				}
			} else {
				
				// ** ON THE BEAT — NOTES ** //
				if (isCompound) {
					hidingBeatError = soundingDur % beatLength;
				} else {
					hidingBeatError = false;
					
					// no dotted/double-dotted crotchet on beat two in 4/4 or 2/2
					if ((soundingDur >= dottedcrotchet && soundingDur < minim) && (timeSigStr == "4/4" || timeSigStr == "2/2")) hidingBeatError = noteStartBeat % 2;
					
					// no semibreves in 5/4
					if (timeSigStr == "5/4") hidingBeatError = (soundingDur == semibreve);
				}
			}
	
		} else {
	
			// ** OFF THE BEAT — RESTS ** //
			
			// ** FIRST, WE ASSUME THAT THE NOTE IS HIDING THE BEAT ** //
			// ** exclude dotted crotchet if on 0.5 or 2.5
			// ** exclude crotchet if on 0.5 or 2.5
			
			// EXCLUDE OFFBEAT CROTCHET IFF
			// 1) it's on the right place
			// 2) it's not tied
			if (isRest) {
				if (soundingDur == dottedminim) {
					if (timeSigStr === "4/4" || timeSigStr === "9/8") {
						addError ("Never write a dotted minim rest in "+timeSigStr+"\n(See ‘Behind Bars’ p. 162)",noteRest);
						return;
					}
				}
				if (soundingDur >= dottedquaver && soundingDur < crotchet) {
					if (!isCompound) {
						addError("Don’t use an offbeat dotted quaver rest in simple time\nSplit it into a semiquaver and quaver rest\n(See ‘Behind Bars’ p. 162)",noteRest);
						return;
					}
				}
				if (soundingDur == dottedcrotchet && timeSigDenom > 2) {
					addError ("Never write a dotted crotchet rest in "+timeSigStr+"\n(See ‘Behind Bars’ p. 162)",noteRest);
					return;
				}
				
				if (soundingDur == crotchet) {
					if (timeSigStr == "3/8") {
						addError ("Never write a crotchet rest in "+timeSigStr+"\n(See ‘Behind Bars’ p. 161)",noteRest);
						return;
					}
					if (!isCompound) {
						if (!prevIsNote && prevDisplayDur == quaver) {
							addError ("This crotchet is hiding the beat.\nConsider swapping with the previous quaver rest.\n(Select them and choose Tools→Regroup rhythms).",noteRest);
							return;
						}
					}
				}
			}
			
			// ** OFF THE BEAT — NOTES ** //	
			
			// ** CROTCHET ** //
			if (displayDur == crotchet) {
				//logError("Found offbeat crotchet");
				if (noteRest.tuplet == null) {
					if (isNote && noteStartFrac == quaver) {

						// FOR COMPOUND TIME SIGNATURES (6/8 etc), allow only if on the quaver offbeat
						if (isCompound && beatLength == dottedcrotchet) hidingBeatError = false;	
						
						// FOR SIMPLE TIME SIGNATURES, allow only if a) even-numbered numerator, b) previous and next notes are quavers, c) it's on the off of an odd-numbered note
						//logError ("p = "+(prevDisplayDur == quaver)+" n = "+(nextDisplayDur == quaver)+" t= "+(timeSigNum % 2 == 0) +" d = "+(timeSigDenom < 4) +" h = "+(startOffset % minim != quaver));
						//logError ("startOffset = "+startOffset+" % = "+ (startOffset % minim));
						if (!isCompound && prevDisplayDur == quaver && nextDisplayDur <= quaver) {
							if (timeSigNum % 2 == 0 || timeSigDenom < 4) {
								hidingBeatError = startOffset % minim != quaver;
							} else {
								hidingBeatError = false;
							}
						}						
					}
				} else {
				// check crotchet triplet
					if (displayDur == crotchet && prevDisplayDur == crotchet && nextDisplayDur == crotchet) {
						if (timeSigDenom <= 4) hidingBeatError = false; // default is that we allow it
						var allowedNoteStarts32 = [division * 2 / 3, division * 8 / 3, division * 14 / 3];
						var allowedNoteStarts34 = [division * 2 / 3, division * 5 / 3];
						var allowedNoteStarts44 = [division * 2 / 3, division * 8 / 3];
						var allowedNoteStarts54 = [division * 2 / 3, division * 5 / 3, division * 8 / 3, division * 11 / 3];
						if (timeSigStr === "3/2" || timeSigStr === "6/4") hidingBeatError = !allowedNoteStarts32.includes(noteStart);
						if (timeSigStr === "2/4" || timeSigStr === "4/4" || timeSigStr === "4/8" || timeSigStr === "8/8" || timeSigStr === "2/2") hidingBeatError = !allowedNoteStarts44.includes(noteStart);
						if (timeSigStr === "3/4") hidingBeatError = !allowedNoteStarts34.includes(noteStart);
						if (timeSigStr === "5/4") hidingBeatError = !allowedNoteStarts54.includes(noteStart);
					}
				}
			}
				
			// ** OFF THE BEAT BEAT DOTTED CROTCHET ** //
			if (displayDur == dottedcrotchet && noteRest.tuplet == null) {
				//logError(Checking dotted crotchet");
				if (isNote) {
					//logError(Here1");
					if (timeSigNum % 2 == 0 || timeSigDenom < 4) {
						if (noteStart % minim == quaver && prevDisplayDur >= quaver) hidingBeatError = false;
					} else {
						//logError(noteStartFrac = "+noteStartFrac+" prevDisplayDur="+prevDisplayDur);
						if (noteStartFrac == quaver && (prevDisplayDur == quaver || prevDisplayDur == dottedcrotchet)) hidingBeatError = false;
					}
				}
			}
			
		}
		
		if (hidingBeatError) {
			if (isNote) {
				if (timeSigStr === "5/4" && soundingDur == semibreve) {
					addError("Never use a semibreve in 5/4\nsplit the note to show the bar division of either 2+3 or 3+2",noteRest);
				} else {
					if (numBeatsHidden == 1) {
						addError("This note is hiding beat "+(noteStartBeat + 2)+"\nSplit the note with a tie, so that it shows beat "+(noteStartBeat + 2),noteRest);
					} else {
						var errStr = "This note is hiding beats ";
	
						for (var i = 0; i < numBeatsHidden; i++) {
							var beatStr = (noteStartBeat+2+i).toString();
							errStr += beatStr;
							if (i < numBeatsHidden - 2) {
								errStr += ", ";
							} else {
								if (i == numBeatsHidden - 2) {
									errStr += " &amp; ";									
								} else {
									errStr += "\nSplit it with a tie, so that the beats are shown";
									
								}
							}
						}
						addError(errStr,noteRest);
					}
				}
			} else {
				if (timeSigStr == "5/4" && soundingDur == semibreve) {
					addError("Never use a semibreve rest in 5/4\nSplit it to show the bar division of either 2+3 or 3+2 crotchets",noteRest);
				} else {
					if (numBeatsHidden == 1) {
						addError( "This rest is hiding beat "+(noteStartBeat + 2)+"\nSplit it into two rests, so that beat "+(noteStartBeat + 2)+" is shown.",noteRest);
					} else {
						var errStr = "This rest is hiding beats ";
	
						for (var i = 0; i < numBeatsHidden; i++) {
							var beatStr = (noteStartBeat+2+i).toString();
							errStr += beatStr;
							if (i < numBeatsHidden - 2) {
								errStr += ", ";
							} else {
								if (i == numBeatsHidden - 2) {
									errStr += " &amp; ";
								} else {
									errStr += "\nSplit it so that the beats are shown";
								}
							}
						}
						addError(errStr,noteRest);
					}
				}
			}
		} // end if hidingBeatError
	}
	
	
	
	function checkOnbeatRestSpelling (noteRest) {
		if (timeSigStr == "3/8" && displayDur == crotchet) {
			addError ("It is recommended to spell crotchet rests in 3/8 as two quaver rests\n(See ‘Behind Bars’ p. 161)",noteRest);
			return;
		}
	}
	
	function checkOffbeatRestSpelling (noteRest) {
		if (timeSigDenom < 8 && noteStartFrac == semiquaver && displayDur == dottedquaver) {
			addError ("It is recommended to spell offbeat dotted quaver rests as\na semiquaver rest followed by a quaver rest\n(See ‘Behind Bars’ p. 162)",noteRest);
			return;
		}
		if (isCompound && noteStartFrac == quaver && displayDur == crotchet) {
			addError ("It is recommended to spell offbeat crotchet rests in\ncompound time as two quaver rests\n(See ‘Behind Bars’ p. 161)",noteRest);
			return;
		}
	}
	
	function checkTupletSettings (tuplet) {
		var normalSettings = [0,0,3,2,3,4,4,4,12,8,8,8,8,8,8,8,8];
		var a = tuplet.actualNotes;
		// check ratio is on
		if (tuplet.numberType == 0 && a < normalSettings.length) {
			var normalRatio = normalSettings[tuplet.actualNotes];
			if (tuplet.normalNotes != normalRatio) addError ("This tuplet is non-standard, and should therefore show the ratio.\nIn Properties, switch Number to ‘Ratio’", tuplet);
		}
		var l = tuplet.elements.length;
		var nn = 0;
		for (var i = 0; i < l; i++) nn += tuplet.elements[i].type == Element.CHORD || tuplet.elements[i].type == Element.REST;
		if (nn >= a * 2) {
			if (nn == 6 && a == 3) {
				//logError ('actualDuration = ' + tuplet.actualDuration.ticks);
				if (tuplet.actualDuration.ticks <= beatLength) {
					var allNotesEqual = true;
					
					//logError ('tuplet.duration.ticks / 6 = ' + (tuplet.duration.ticks / 6));
					for (var i = 0; i < 6 && allNotesEqual; i++) {
						//logError ('tuplet.elements[i].actualDuration.ticks = ' + tuplet.elements[i].actualDuration.ticks);
						if (tuplet.elements[i].actualDuration.ticks != tuplet.duration.ticks / 6) allNotesEqual = false;
					}
					if (allNotesEqual) addError ("This triplet should be a sextuplet", tuplet);
				}
			} else {
				addError ("This tuplet is meant to have "+a+" notes/rests,\nbut instead contains "+nn+".\nConsider rewriting the tuplet",tuplet);
			}
		}
	}
	
	function condenseOverSpecifiedRest (noteRest) {
		//logError(*** CHECKING CONDENSING OVER-SPECIFIED REST ***"); 
		
		var possibleSimplification = -1;
		var simplificationIsOnBeat = true;
		var simplificationFound = false;
		var possibleSimplificationLastRestIndex = 0;
		var possibleSimplificationFirstRestIndex = 0;
		var maxOnbeatSimplification = possibleOnbeatSimplificationDurs.length-1;
		var maxOffbeatSimplification = possibleOffbeatSimplificationDurs.length-1;
		//logError(rests: "+rests.length+" "+maxOnbeatSimplification+" "+maxOffbeatSimplification); 
		
		// CHECK THAT IT COULD BE SIMPLIFIED AS A BAR REST
		if (totalRestDur == barDur && !isPickupBar) {
			addError ('These rests can be turned into a bar rest.\nSelect the bar and press ‘delete’', rests)
		} else {
			//logError(Here with "+rests.length+" rests"); 
			var maxSimplificationFound = false;
			
			for (var i = 0; i < rests.length-1 && !maxSimplificationFound; i++) {
				var startRest = rests[i];
				var startRestTick = startRest.parent.tick;
				var restDisplayDur = startRest.duration.ticks;
				var restActualDur = startRest.actualDuration.ticks
				var startPos = getPositionInBar(startRest);
				//logError(startPos = "+startPos+" startDur = "+restActualDur); 
				var startBeat = Math.trunc(startPos/beatLength);
				var startFrac = startPos % beatLength;
				var restIsOnBeat = !startFrac;
				var startTuplet = startRest.tuplet;
								
				for (var j = i+1; j < rests.length && !maxSimplificationFound; j++) {
					var theRest = rests[j];
					var tempDisplayDur = theRest.duration.ticks;
					var tempActualDur = theRest.actualDuration.ticks;
					var tempPos = getPositionInBar(theRest);
					var tempBeat = Math.trunc(tempPos/beatLength);
					var sameBeat = (tempBeat == startBeat);
					restActualDur += tempActualDur;
					restDisplayDur += tempDisplayDur;
					//logError(Added "+tempActualDur+" — restActualDur is now = "+restActualDur); 
	
					// **** ONBEAT REST CONDENSATION **** //
	
					if (restIsOnBeat) {
						//logError(onbeat actual"); 
						
						// ** CHECK CONDENSATION OF ACTUAL DURATIONS ** //
						if (startTuplet == null) {
							for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
								var canBeCondensed = true;
								var p = possibleOnbeatSimplificationDurs[k];
								// don't simplify anything tied over a beat that is less than a crotchet
								if (restActualDur == dottedminim) {
									canBeCondensed = false;
									if (timeSigStr === "6/4" || timeSigStr === "9/4") canBeCondensed = !(startBeat % 3);
									if (timeSigStr === "12/8") canBeCondensed = !(startBeat % 2);
								}
								if (restActualDur == semibreve) canBeCondensed = timeSigStr === "4/4" || timeSigStr === "2/2";
								if (restActualDur == minim) canBeCondensed = (timeSigStr === "4/4" || timeSigStr === "2/2" || timeSigStr === "3/2") && !(startBeat % 2);
								if (restActualDur == dottedcrotchet && !isCompound) canBeCondensed = ((timeSigDenom <= 2) || isCompound) && !(startBeat % 2);
								if (restActualDur == dottedquaver) canBeCondensed = timeSigDenom <= 4;
								if (restActualDur == dottedsemiquaver) canBeCondensed = timeSigDenom <= 8;
								if (canBeCondensed && isCompound) canBeCondensed = restActualDur <= beatLength || (restActualDur % beatLength == 0);
							
								if (restActualDur == p && canBeCondensed) {
									if (k > possibleSimplification) {
										//logError(found a possibleSimplification actual dur on beat = "+k); 
										possibleSimplification = k;
										possibleSimplificationLastRestIndex = j;
										possibleSimplificationFirstRestIndex = i;
										simplificationIsOnBeat = true;
										simplificationFound = true;
										maxSimplificationFound = (k == maxOnbeatSimplification);
										//logError(simplificationFound = "+simplificationFound); 
									}
								}
							}
						} else {
						// ** CHECK CONDENSATION OF DISPLAY DURATIONS ** //
							if (startTuplet.is(theRest.tuplet)) {
								//logError(onbeat display"); 
								
								for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
									var p = possibleOnbeatSimplificationDurs[k];
									//logError((onbeat disp) looking for match: "+restDisplayDur+" = "+p+" = "+(restDisplayDur==p)); 
									if (restDisplayDur == p) {
										if (k > possibleSimplification) {
											//logError(found a possibleSimplification display dur on beat = "+k);
											possibleSimplification = k;
											possibleSimplificationLastRestIndex = j;
											possibleSimplificationFirstRestIndex = i;
											simplificationIsOnBeat = true;
											simplificationFound = true;
											maxSimplificationFound = (k == maxOnbeatSimplification);
										}
									}
								}
							}
						}
					} else {
	
						// **** OFFBEAT REST CONDENSATION **** //

						// CHECK ACTUAL DURS
						if (startTuplet == null) {
							//logError(offbeat actual "); 
							if (isCompound && restActualDur == crotchet + semiquaver && tempActualDur != quaver && startFrac == semiquaver) {
								var theArray = [];
								for (var m = i; m <= j; m++) theArray.push(rests[m]);
								addError('Respell these rests as a dotted quaver plus a quaver',theArray);
								return;
							}
							for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
								var canBeCondensed = true;
								var p = possibleOffbeatSimplificationDurs[k];
								if (restActualDur != p) continue;
							
								// don't simplify anything tied over a beat that is less than a crotchet
								if (p == dottedcrotchet) canBeCondensed = startFrac == quaver && timeSigDenom == 2;
								if (p == crotchet) canBeCondensed = (isCompound && tempDisplayDur !== quaver);
								if (p < crotchet) canBeCondensed = sameBeat;
								if (canBeCondensed && isCompound && restActualDur == beatLength * 2 / 3) canBeCondensed = false;
								//logError(p="+p+" canBeCondensed = "+canBeCondensed+" isCompound="+isCompound); 
							
								if (canBeCondensed && k > possibleSimplification) {
									//logError(found a possibleSimplification actual dur off beat = "+k); 
									possibleSimplification = k;
									possibleSimplificationLastRestIndex = j;
									possibleSimplificationFirstRestIndex = i;
									simplificationIsOnBeat = false;
									simplificationFound = true;
									maxSimplificationFound = (k == maxOffbeatSimplification);
								}
							}
						} else {
						// CHECK DISPLAY DURS
							if (startTuplet.is(theRest.tuplet)) {
								var tupletStartPos = getPositionInBar(startTuplet.elements[0]);
								//logError(offbeat display start="+tupletStartPos+" dur="+startTuplet.duration.ticks+" div="+startTuplet.duration.ticks/startTuplet.actualNotes); 
								var allowedCondensation = beatLength / startTuplet.normalNotes;
								var beatDivision = beatLength / startTuplet.actualNotes;
								//logError(allowed condensation = "+allowedCondensation);
								for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
									var p = possibleOffbeatSimplificationDurs[k];
									if (restDisplayDur != p) continue;
									//logError((offbeat disp) found match: "+restDisplayDur+" = "+p); 
									
									if (p == dottedquaver) canBeCondensed = j == rests.length - 1;
									var alignsToBeatDivision = ((startPos - tupletStartPos) % beatDivision) == 0;
									if (p == allowedCondensation) canBeCondensed = alignsToBeatDivision;
									//logError(StartPos = "+startPos+" tupletStartPos="+tupletStartPos+" Aligns to beat division = "+alignsToBeatDivision);
									if (canBeCondensed && k > possibleSimplification) {
									
									//	logError(found a possibleSimplification display dur off beat = "+k); 
									
										possibleSimplification = k;
										possibleSimplificationLastRestIndex = j;
										possibleSimplificationFirstRestIndex = i;
										simplificationIsOnBeat = false;
										simplificationFound = true;
										maxSimplificationFound = (k == maxOffbeatSimplification);
									}
								}
							}
						}
					}
				}
			}
			//logError(Final: simplificationFound = "+simplificationFound); 
			
			if (simplificationFound) {
				//logError(final simplification chosen = "+possibleSimplification); 
				
				var exception = isPickupBar && possibleSimplification > 6;
				if (simplificationIsOnBeat) {
					if (!exception) {
						var simplificationText = possibleOnbeatSimplificationLabels[possibleSimplification];
						var tempText = (restDisplayDur == dottedcrotchet && !isCompound)? '[Suggestion] ' : '';
						var theArray = [];
						for (var i = possibleSimplificationFirstRestIndex; i <= possibleSimplificationLastRestIndex; i++) theArray.push(rests[i]);
						
						if (restDisplayDur == dottedquaver) {
							addError(tempText+'Condense rests as a '+simplificationText+'.\n(Ignore if using rest to show placement of fermata/etc.)',theArray);
							return;
						}
						// respell as two quavers if we're in a compound time signature
						if (restDisplayDur == crotchet && isCompound) {
							if (tempDisplayDur != quaver) addError('Respell rests as two quavers.\n(Ignore if using rest to show placement of fermata/etc.)',theArray);
							return;
						}
						addError(tempText+'Condense rests as a '+simplificationText+' by selecting them\nand choosing Tools→Regroup rhythms. (Ignore if using\nrest to show placement of fermata/etc.)',theArray);
					}
				} else {
					var simplificationText = possibleOffbeatSimplificationLabels[possibleSimplification];
					var p = possibleOffbeatSimplificationDurs[possibleSimplification];
					var tempText = (restDisplayDur == dottedcrotchet && !isCompound)? '[Suggestion] ' : '';
					var totalNumRests = possibleSimplificationLastRestIndex-possibleSimplificationFirstRestIndex+1;
					var lastRestDur = rests[possibleSimplificationLastRestIndex].duration.ticks;
					// Dotted quaver duration, but they've done quaver-semiquaver instead of semiquaver-quaver — OR they've used more than 2 notes
					var theArray = [];
					for (var i = possibleSimplificationFirstRestIndex; i <= possibleSimplificationLastRestIndex; i++) {
						theArray.push(rests[i]);
					}
					if (p == dottedquaver) {
						if (lastRestDur != quaver || totalNumRests > 2) {
							addError ('Spell as a semiquaver followed by a quaver.',theArray);
							return;
						}
						if (!isCompound) return;
					}
					addError(tempText+'Condense rests as a '+simplificationText+' by selecting them\nand choosing Tools→Regroup rhythms. (Ignore if using\nrest to show placement of fermata/etc.)',theArray);
				}
			}
		}		
	}
	
	// ————————————————————————————————————————————————————————————————————————————————— //
	// **						CHECKTIESIMPLIFICATIONS (noteRest)			    	  ** //
	// **           	Checks to see whether tied notes can be condensed		      ** //
	// ————————————————————————————————————————————————————————————————————————————————— //
	
	function checkTieSimplifications (noteRest) {
		//logError ("Checking tie simplifications");

		// ** DO TIE SIMPLIFICATION IF WE'RE ON THE LAST NOTE OF THE TIE ** //
		// ** LOOP THROUGH THE NUMBER OF NOTES IN TIE ** //
		
		var possibleSimplification = -1;
		var simplificationIsOnBeat = true;
		var possibleSimplificationLastNoteIndex = 0;
		var possibleSimplificationFirstNoteIndex = 0;
		var simplificationFound = false;
		var maxOnbeatSimplification = possibleOnbeatSimplificationDurs.length-1;
		var maxOffbeatSimplification = possibleOffbeatSimplificationDurs.length-1;
		var maxSimplificationFound = false;
		
		for (var i = 0; i < tiedNotes.length-1 && !maxSimplificationFound; i++) {
			var startNote = tiedNotes[i];
			var tiedDisplayDur = startNote.duration.ticks;
			var tiedActualDur = startNote.actualDuration.ticks;
			var startPos = getPositionInBar(startNote);
			var startBeat = Math.trunc(startPos/beatLength);
			var startFrac = startPos % beatLength;
			var tieIsOnBeat = startFrac == 0;
			//logError ("tieIsOnBeat = "+tieIsOnBeat+" startFrac = "+startFrac);

			var prevNoteRest = i == 0 ? getPreviousNoteRest(startNote) : null;
			var prevIsNote = (prevNoteRest == null) ? false : prevNoteRest.type == Element.CHORD;
			var startTuplet = startNote.tuplet;

			// check onbeat simplifications
			for (var j = i+1; j < tiedNotes.length && !maxSimplificationFound; j++) {	
				var tempNote = tiedNotes[j];
				var tempDisplayDur = tempNote.duration.ticks;
				var tempActualDur = tempNote.actualDuration.ticks;
				var tempPos = getPositionInBar(tempNote);
				var tempBeat = Math.trunc(tempPos/beatLength);
				var sameBeat = (tempBeat == startBeat);
				var tempTuplet = tempNote.tuplet;
				var tempNextItem = getNextNoteRest(tempNote);
				var tempNextItemIsNote = (tempNextItem == null) ? false : tempNextItem.type == Element.CHORD;
				tiedActualDur += tempActualDur;
				tiedDisplayDur += tempDisplayDur;
				var checkDisplayDur = false;
				if (startTuplet != null) checkDisplayDur = (tiedDisplayDur != tiedActualDur) && startTuplet.is(tempTuplet);
				var canBeSimplified, simplification;
				
				if (tieIsOnBeat) {
					//logError ("Tie is on beat: tiedDisplayDur "+tiedDisplayDur+" tiedActualDur "+tiedActualDur+" tempActualDur "+tempActualDur);

					// ** CHECK ONBEAT TIE SIMPLIFICATIONS ** //
					for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
						canBeSimplified = true;
						simplification = possibleOnbeatSimplificationDurs[k];
						//logError ("Testing simplification "+simplification);

						if (tiedActualDur == simplification) {
							//logError ("Match ("+tiedActualDur+")");

							if (isCompound) {
								if (tiedActualDur >= beatLength) canBeSimplified = (tiedActualDur % beatLength) == 0; // can be simplified if it's a multiple of the beat length
							} else {
								if (tiedActualDur == minim) {
									// Exception for two tied crotchets on beat 2
									//logError (noteRest.track+' '+startBeat+' '+startFrac+' '+timeSigDenom+' '+timeSigNum);
									var isASimpleTimeSig = (timeSigDenom == 2 || timeSigDenom == 4) && timeSigNum % 2 == 0
									var isTwoCrotchets = tiedNotes.length == 2 && tempDisplayDur == crotchet;
									var startsOnBeat2 = startBeat == 1 &&  startFrac == 0;
									if (noteRest.track % 4 == 0 && startsOnBeat2 && isTwoCrotchets && isASimpleTimeSig) {
										if (checkForMinimInVoice2(currentStaffNum, tempNote.parent.tick)) canBeSimplified = false;
									}
								}
								if (tiedActualDur == dottedcrotchet) {
									if (timeSigNum % 2 == 0) canBeSimplified = startBeat % 2 == 0; // for 4/4, 6/4 etc — can be simplified if it's on an even numbered beat (0, 2, etc)
									if (tempNextItem.actualDuration.ticks != quaver) canBeSimplified = false; 
								}
								if (tiedActualDur == semibreve) canBeSimplified = timeSigDenom == 2 || (timeSigDenom == 4 && !(timeSigNum % 3)); // only use a semibreve if we're in 3/2 4/4 or 7/4 etc
							}
			
							if (canBeSimplified) {
								if (k > possibleSimplification) {
									possibleSimplification = k;
									possibleSimplificationLastNoteIndex = j;
									possibleSimplificationFirstNoteIndex = i;
									simplificationIsOnBeat = true;
									simplificationFound = true;
									maxSimplificationFound = (k == maxOnbeatSimplification);
								}
							} // end if check
						}
					}
					if (checkDisplayDur && !maxSimplificationFound) {
						for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
							var canBeSimplified = true;
							simplification = possibleOnbeatSimplificationDurs[k];
							if (tiedDisplayDur == simplification && canBeSimplified) {
								if (k > possibleSimplification) {
									possibleSimplification = k;
									possibleSimplificationLastNoteIndex = j;
									possibleSimplificationFirstNoteIndex = i;
									simplificationIsOnBeat = true;
									simplificationFound = true;
									maxSimplificationFound = (k == maxOnbeatSimplification);
								} // end if k >
							} // end if tied
						} // end k
					} // end checkDisplay
					
				} else {
					
					// ** OFFBEAT TIE CONDENSATION ** //
						
					
					// CHECK ACTUAL DURS

					for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
						simplification = possibleOffbeatSimplificationDurs[k];
						if (tiedActualDur == simplification) {
							// don't simplify anything tied over a beat that is less than a crotchet
							//logError ("Found simplification tiedActualDur = "+tiedActualDur);

							if (isCompound) {
								canBeSimplified = simplification < beatLength;
							} else {
								canBeSimplified = simplification < (beatLength * 2);
							}
							if (canBeSimplified) {
								// DOTTED CROTCHET
								// Only simplify a dotted crotchet if it's in simple time with an even numerator, and it was preceded by a quaver, and it's on the offbeat of an odd-numbered beat
								if (simplification == dottedcrotchet && !isCompound) {
									if (prevNoteRest == null) {
										canBeSimplified = false;
									} else {
										// there's a special case to flag here, which is a crotchet tied to a quaver on a quaver offbeat of 2
										var isCrotchetTiedToQuaver = tiedNotes.length == 2 && tempDisplayDur == quaver;
										var isOnOffOfBeat2 = startBeat == 1 && startFrac == quaver;
										if (isCrotchetTiedToQuaver && isOnOffOfBeat2) {
											canBeSimplified = false;
											addError ('These notes should be swapped.\n(Select them and choose Tools→Regroup Rhythms).',[tiedNotes[0],tiedNotes[1]]);
										} else {
											canBeSimplified =  (timeSigNum % 2 == 0 || timeSigDenom < 4) && prevNoteRest.duration.ticks == quaver && startPos % minim == quaver;
										}
										//logError ("startPos = "+startPos);
										//logError ("Can be simplified = "+canBeSimplified+" because "+(timeSigNum % 2 == 0 || timeSigDenom < 4)+" "+(prevNoteRest.duration.ticks == quaver)+" "+(startPos % minim == quaver));
									}
								}
								if (simplification == crotchet) {
									canBeSimplified = (startFrac == quaver);
									if (!isCompound) {
										var offbeatCrotchetException = false;
										if (prevNoteRest != null && tempNextItem != null && i == 0) offbeatCrotchetException = prevNoteRest.duration.ticks == quaver && prevIsNote && tempNextItem.duration.ticks == quaver && tempNextItemIsNote;
										if (startBeat % 2) offbeatCrotchetException = false;
										canBeSimplified = canBeSimplified && offbeatCrotchetException;
									} // end timeSigDenom
								}
								if (simplification < crotchet) canBeSimplified = sameBeat;
							} // end if check
							if (canBeSimplified) {
								if (k > possibleSimplification) {
									possibleSimplification = k;
									possibleSimplificationFirstNoteIndex = i;
									possibleSimplificationLastNoteIndex = j;
									simplificationIsOnBeat = false;
									simplificationFound = true;
									maxSimplificationFound = (k == maxOffbeatSimplification);
								}
							} // end if check
						} // end if tied
					}
					// CHECK DISPLAY DURS
					//logError ("checkDisplayDur = "+checkDisplayDur+" maxSimplificationFound = "+maxSimplificationFound);

					if (checkDisplayDur && !maxSimplificationFound) {
						for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
							simplification = possibleOffbeatSimplificationDurs[k];
							if (tiedDisplayDur == simplification && k > possibleSimplification) {
								//logError ("Found display simplification: "+tiedDisplayDur);

								possibleSimplification = k;
								possibleSimplificationFirstNoteIndex = i;
								possibleSimplificationLastNoteIndex = j;
								simplificationIsOnBeat = false;
								simplificationFound = true;
								maxSimplificationFound = (k == maxOffbeatSimplification);
							}
						}
					} // end checkDisplayDur
				}
			}
		}
		if (simplificationFound) {
			if (simplificationIsOnBeat) {
				var simplificationText = possibleOnbeatSimplificationLabels[possibleSimplification];
				var tempText = '';
				if (tiedDisplayDur == dottedcrotchet && !isCompound) tempText = '[Suggestion] ';
				var theArray = [];
				for (var i = possibleSimplificationFirstNoteIndex; i <= possibleSimplificationLastNoteIndex; i++) {
					theArray.push(tiedNotes[i]);
				}
				addError (tempText+'These tied notes can be simplified to a '+simplificationText+'.\nSelect them and choose Tools→Regroup Rhythms.\n(Ignore if the tie is being used to show placement of dynamics etc.)', theArray);
			} else {
				var simplificationText = possibleOffbeatSimplificationLabels[possibleSimplification];
				var tempText = '';
				if (tiedDisplayDur == dottedcrotchet && !isCompound) tempText = '[Suggestion] ';
				var theArray = [];
				for (var i = possibleSimplificationFirstNoteIndex; i <= possibleSimplificationLastNoteIndex; i++) {
					theArray.push(tiedNotes[i]);
				}
				addError(tempText+'These tied notes can be simplified to a '+simplificationText+'.\nSelect them and choose Tools→Regroup Rhythms.\n(Ignore if the tie is being used to show placement of dynamics etc.)', theArray);
			}
		} else {
			// check for two note ties wrong way around
			if (tiedNotes.length == 2) {
				var note1 = tiedNotes[0];
				var note2 = tiedNotes[1];
				if (note1.tuplet == null && note2.tuplet == null) {
					var startPos = getPositionInBar(note1);
					var startBeat = Math.trunc(startPos/beatLength);
					var startFrac = startPos % beatLength;
					checkTiedPair (note1,note2,startPos,startBeat,startFrac);
				}
			}
		}
	}
	
	function checkForMinimInVoice2 (theStaffIdx, theTick) {
		cursor2.staffIdx = theStaffIdx
		cursor2.voice = 1;
		cursor2.rewindToTick(theTick);
		var tempNote = cursor2.element;
		if (tempNote != null) return (tempNote.duration.ticks == minim)
		return false;
	}
	
	function checkTiedPair (note1,note2,startPos,startBeat,startFrac) {
		var d1 = note1.actualDuration.ticks;
		var d2 = note2.actualDuration.ticks;
		var onBeat = startFrac == 0;
		var noteArray = [note1,note2];
		if (onBeat) {
			// semiquaver crotchet
			// quaver crotchet
			if (beatLength == crotchet) {
				if (d1 < crotchet && d2 == crotchet) addError ("Consider putting the crotchet first in this tie.",noteArray);
				if (d1 < crotchet && d2 == minim) addError ("Consider putting the minim first in this tie.",noteArray);
				if (d1 == crotchet && d2 == dottedcrotchet && startBeat % 2 == 0) addError ("Consider rewriting this tied note as a minim tied to a quaver.",noteArray);
				if (d1 == dottedcrotchet && d2 == crotchet) addError ("Consider rewriting this tied note as a minim tied to a quaver.",noteArray);
				if (d1 == minim && d2 == dottedcrotchet) addError ("Consider rewriting this tied note as a dotted minim tied to a quaver.",noteArray);
				if (d1 == dottedcrotchet && d2 == semiquaver) addError ("Consider rewriting this tied note as a crotchet tied to a dotted quaver.", noteArray);
			} 
		} else {
			if (beatLength == crotchet) {
				if (d1 == dottedcrotchet && d2 == minim) addError ("Consider rewriting this tied note as a quaver tied to a dotted minim",noteArray);
				if (startFrac == division / 2 && d1 == crotchet && d2 == semiquaver) addError ("Consider rewriting this tied note as a quaver tied to a dotted quaver.\n(Select both notes and choose Tools→Regroup rhythms)",noteArray);
			}
		}
	}
	
	// ————————————————————————————————————————————————————————————————————————————————— //
	// **						CHECKBEAMBROKENERROR (noteRest)			    		  ** //
	// **	Checks if the beam is incorrectly broken, or should be broken but isn't   ** //
	// ————————————————————————————————————————————————————————————————————————————————— //
	
	function checkBeamBrokenError (noteRest) {		
		
		// NB — don't process this note if there is no beam possible
		if (displayDur >= crotchet) return;
		//logError ('—checkBeamBroken—');
		
		// **** INITIALISE VARIABLES **** //
		var isOnlyNoteInBeat = false;
		var isLastItemInBeat = nextItemBeat != noteStartBeat;
		var acceptableBeamSettings = [];
		var isLastRestBeforeNote = false, isFirstNoteInBeat = false, isLastNoteInBeat = false, isMiddleNoteInBeat = false, isMiddleRestInBeat = false, isLastRestsInBeat = false;

		// The following beam settings will give us the correct beaming
		// ** 1) FIRST RESTS IN THE BEAT BEFORE WE'VE HAD A NOTE, BUT AS LONG AS IT'S NOT IMMEDIATELY BEFORE A NOTE WITHIN THE BEAT
		// ** Their beam setting can be set to anything, so we don't need to check it
		if (isRest && !haveHadFirstNote && (!nextItemIsNote || isLastItemInBeat)) return;
		
		// ** 2) THE LAST REST IMMEDIATELY BEFORE THE FIRST NOTE IN A BEAT
		// ** Beam setting can be set to only AUTO or NONE ** //
		if (isRest && nextItemIsNote && !haveHadFirstNote && !isLastItemInBeat) {
			if (nextDisplayDur >= crotchet) return; // if next note doesn't have a beam, it doesn't matter
			acceptableBeamSettings = [Beam.AUTO, Beam.NONE];
			isLastRestBeforeNote = true;
		}

		// ** 3) THE FIRST NOTE IN A BEAT WHERE THERE ARE MORE NOTES COMING IN THE BEAT
		// ** Beam setting can be set to anything except NONE ** //
		if (isNote && !haveHadFirstNote) {
			if (isLastItemInBeat || nextDisplayDur >= crotchet) return; // don't beam if it's the only note in the beat or next note doesn't have a beam
			haveHadFirstNote = true;
			acceptableBeamSettings = [Beam.AUTO,Beam.BEGIN,Beam.BEGIN32,Beam.BEGIN64,Beam.MID];
			isFirstNoteInBeat = true;
		}
		
		if (!isLastRestBeforeNote) {
			var foundAnotherRest = false;
			var foundAnotherNote = false;
			cursor2.rewindToTick(cursor.tick);

			if (cursor2.next()) {
				var withinBeat = true;
				var tempNote = cursor2.element;
				while (tempNote != null && cursor2.measure.is(currentBar) && withinBeat ) {
					var tempEnd = (cursor2.tick - barStart) + tempNote.actualDuration.ticks - 1; // end just before
					var tempEndBeat = Math.trunc(tempEnd / beatLength);
					withinBeat = tempEndBeat == noteStartBeat;
					//logError(withinbeat = "+tempEnd+" "+tempEndBeat+" "+withinBeat);

					if (withinBeat) {
						if (tempNote.type == Element.CHORD) {
							foundAnotherNote = true;
						} else {
							foundAnotherRest = true;
						}
						if (cursor2.next()) {
							tempNote = cursor2.element
						} else {
							tempNote = null;
						}
					}
				}
			}

			// now set the values of isOnlyNoteInBeat, lastRestsInBeat
			if (isFirstNoteInBeat && !foundAnotherNote) isOnlyNoteInBeat = true;
			if (isNote && !isFirstNoteInBeat && foundAnotherNote) isMiddleNoteInBeat = true;

			if (isNote && isLastItemInBeat) isLastNoteInBeat = true;
			if (isRest && !isLastRestBeforeNote) {
				if (foundAnotherNote) {
					isMiddleRestInBeat = true;
				} else {
					isLastRestsInBeat = true;
				}
			}
		}
		
		if (isOnlyNoteInBeat) {
			if (isLastItemInBeat) haveHadFirstNote = false; // reset for next beat
			return; // if this is incorrectly beamed, it will get caught in 'check beamed to next beat' function (note to self: these could be combined)
		}
		
		// check out the case for a semiquaver or less preceded by a rest 
		if (isNote && !prevIsNote && haveHadFirstNote && !isFirstNoteInBeat) {
			if (isLastItemInBeat) haveHadFirstNote = false;
			if (hasBeam) {
				if (displayDur < quaver && currentBeamMode != Beam.BEGIN32) addError("This note should have its secondary beam broken.\nSet its ‘Beam type’ property to ‘Break inner beams (8th)’.",noteRest);
				return;
			} else {
				if (displayDur >= quaver && currentBeamMode != Beam.AUTO && currentBeamMode != Beam.MID) addError("This note should be beamed to the previous note\nSet its ‘Beam type’ property to either ‘AUTO’ or ‘Join beams’.",noteRest);
				if (displayDur < quaver) {
					if (currentBeamMode != Beam.BEGIN32) {
						addError("This note should have its secondary beam broken.\nSet its ‘Beam type’ property to ‘Break inner beams (8th)’.",noteRest);
						return;
					} else {
						if (currentBeamMode != Beam.MID && currentBeamMode != Beam.AUTO) addError("This note should be beamed to the previous note\nSet the ‘Beam type’ property of this note to ‘AUTO’.",noteRest);
						return;
					}
				}
			}
		}
		if (isLastItemInBeat) haveHadFirstNote = false; // NB: FROM THIS POINT ON 'haveHadFirstNote' may be incorrect, so don't test it
		
		if (isMiddleNoteInBeat) {
			if (!hasBeam) {
				addError("This note should be included in a beam\nwith all other notes and rests in this beat.\nSet the ‘Beam type’ property of this note to ‘AUTO’.",noteRest);
			} else {
				if (prevIsNote) {
					if (currentBeamMode == Beam.NONE || currentBeamMode == Beam.BEGIN) addError("This note should be beamed to the previous note\nSet the ‘Beam type’ property of this note to ‘AUTO’.",noteRest);
				} else {
					if (displayDur >= quaver && currentBeamMode != Beam.AUTO && currentBeamMode != Beam.MID) addError("This note should be beamed to the previous note\nSet its ‘Beam type’ property to either ‘AUTO’ or ‘Join beams’.",noteRest);
				}
			}
			return;
		}
		
		if (isMiddleRestInBeat) {
			if (!hasBeam) addError("This rest should be included in a beam with\nall other notes and rests in this beat.\nSet the ‘Beam type’ property of this note to ‘Join beams’.",noteRest);
			return;
		}
		
		// Last rests in a beat — set to 0, 1 or 2
		if (isLastRestsInBeat) acceptableBeamSettings = [Beam.AUTO,Beam.NONE,Beam.BEGIN];
		
		var correctlyBeamed = false;
		correctlyBeamed = acceptableBeamSettings.includes(currentBeamMode);
		//logError(beamMode is "+beamMode+"); correctlyBeamed = "+correctlyBeamed;
		if (!correctlyBeamed) {
		///	logError(Not correctly beamed");
			if (isNote) {
				if (isFirstNoteInBeat && currentBeamMode != Beam.AUTO) addError("This note should be beamed to the next note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
				if (isLastNoteInBeat && currentBeamMode != Beam.AUTO && currentBeamMode != Beam.MID) {
					addError("This note should be beamed to the previous note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
				}
			} else {
				if (isLastRestBeforeNote) addError("This rest should not be beamed to the next note\nSet the ‘Beam type’ property of this rest to ‘AUTO’",noteRest);
				if (isLastRestsInBeat) addError("This rest should not be beamed to the previous note\nSet the ‘Beam type’ property of this rest to ‘AUTO’",noteRest);
			}
		} // end !correctlyBeamed
	}
	
	// ————————————————————————————————————————————————————————————————————————————————— //
	// **				CHECKBEAMEDTONOTESINNEXTBEAT (noteRest)			    		  ** //
	// **	Checks if the beam is is incorrectly beamed to next beat, or should be    ** //
	// ————————————————————————————————————————————————————————————————————————————————— //
	
	function checkBeamedToNotesInNextBeat (noteRest) {

		var lastNoteInBeat = nextItemBeat != noteStartBeat;
				
		if (hasBeam && nextHasBeam && lastNoteInBeat) {
			
			var beamTriesToGoForwards = currentBeamMode != Beam.NONE;
			var nextBeamTriesToGoBack = nextBeamMode == Beam.BEGIN32 || nextBeamMode == Beam.BEGIN64 || nextBeamMode == Beam.MID;
			var specificDumbMuseScoreBreakCase = isNote && nextItemIsNote && soundingDur == quaver && prevSoundingDur == quaver && nextItemDur == quaver && nextNextItemDur == quaver && !nextNextItemIsNote;
			// this specific case I disagree with MuseScore's automatic beaming practice. So there.
			if (specificDumbMuseScoreBreakCase && nextBeamMode == Beam.AUTO) nextBeamTriesToGoBack = true;

			if (beamTriesToGoForwards && nextBeamTriesToGoBack) {
								
				// ** EXCEPTION WHERE QUAVERS ARE BEAMED TOGETHER IN 4/4 ** //
				var exception1 = isNote && soundingDur == quaver && prevSoundingDur == quaver && nextItemDur == quaver && nextNextItemDur == quaver && nextNextItemIsNote;
				
				if (!exception1) {
					if (isNote) {
						if (specificDumbMuseScoreBreakCase) {
							addError( "This note should not be beamed to the next note.\nSet the ‘Beam type’ property of the following note to ‘No beam’.",noteRest);
						} else {
							addError( "This note should not be beamed to the next note.\nSet the ‘Beam type’ property of this note and the following to AUTO.",noteRest);
						}
					} else {
						addError( "This rest should not be included in the beam group of the next beat\nSet the ‘Beam type’ property of this note to AUTO.", noteRest);
					}
				}
			}
		}
	}
	
	function addError (text,element) {
		errorStrings.push(text);
		errorObjects.push(element);
	}
	
	function showAllErrors () {
		
		var objectPageNum = 0;
		var firstStaffNum = 0;
		var comments = [];
		var commentPages = [];
		var commentsDesiredPosX = [];
		var commentsDesiredPosY = [];
		for (var i = 0; i < (curScore.nstaves-1) && !curScore.staves[i].part.show; i++) firstStaffNum ++;
		
		// limit the number of errors shown to 100 to avoid a massive wait
		var numErrors = (errorStrings.length > 100) ? 100 : errorStrings.length;
		var desiredPosX, desiredPosY;
		
		// create new cursor to add the comments
		var cursor = curScore.newCursor();
		cursor.filter = Segment.All;
		cursor.next();
		
		// save undo state
		//curScore.startCmd();
	
		for (var i = 0; i < numErrors; i++) {
	
			var theText = errorStrings[i];
			var element = errorObjects[i];
			var objectArray = (Array.isArray(element)) ? element : [element];
			desiredPosX = 0;
			desiredPosY = 0;
			for (var j = 0; j < objectArray.length; j++) {
				var checkObjectPage = false;
				element = objectArray[j];
				var eType = element.type;
				var staffNum = firstStaffNum;
			
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
						if (eType != Element.MEASURE) {
							var elemStaff = element.staff;
							if (elemStaff == undefined) {
								isString = true;
								theLocation = "";
							} else {
								staffNum = 0;
								while (!curScore.staves[staffNum].is(elemStaff)) {
									staffNum ++; // I WISH: staffNum = element.staff.staffidx
									if (curScore.staves[staffNum] == null || curScore.staves[staffNum] == undefined) {
										logError ("showAllErrors() — got staff error "+staffNum+" — bailing");
										return;
									}
								}
								// Handle the case where a system-attached object reports a staff that is hidden
								if (eType == Element.TEMPO_TEXT || eType == Element.SYSTEM_TEXT || eType == Element.REHEARSAL_MARK || eType == Element.METRONOME) {
									while (!curScore.staves[staffNum].part.show && staffNum < curScore.nstaves) staffNum ++;
								}
							}
						}
					}
				}
				
				// style the element
				if (element !== "pagetop" && element !== "top" && element !== "pagetopright") {
					if (element.type == Element.CHORD) {
						element.color = "hotpink";
						for (var k = 0; k<element.notes.length; k++) element.notes[k].color = "hotpink";
					} else {
						element.color = "hotpink";
					}
				}
				
				// add text object to score for the first object in the array
				if (j == 0) {
					var tick;		
					if (isString) {
						//logError ('Attaching comment '+i+' to '+theLocation);
						tick = 0;
						if (theLocation.includes("pagetop")) {
							desiredPosX = 2.5;
							desiredPosY = 2.5;
						}
						if (theLocation === "system1" || theLocation === "system2") desiredPosX = 5.0;
						if (theLocation === "system2") tick = firstBarInSecondSystem.firstSegment.tick;
					} else {
						tick = getTick(element);
						//logError ('Comment '+i+' tick = '+tick+' staffNum = '+staffNum);
					}
					
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
					comment.offsetx = 0;
					comment.offsety = 0;
					cursor.staffIdx = staffNum;
					cursor.track = staffNum * 4;
					cursor.rewindToTick(tick);
					cursor.add(comment);
					comment.z = currentZ;
					currentZ ++;
					comments.push (comment);
					var commentPage = comment.parent;
					while (commentPage != null && commentPage.type != Element.PAGE && commentPage.parent != undefined) commentPage = commentPage.parent; // in theory this should get the page
					var pushed = false;
					if (commentPage != null && commentPage != undefined) {
						if (commentPage.type == Element.PAGE) {
							commentPages.push (commentPage);
							pushed = true;
						}
					}
					if (!pushed) commentPages.push (null);
					if (theLocation === "pagetopright" && commentPage != null) desiredPosX = commentPage.bbox.width - comment.bbox.width - 2.5;
					commentsDesiredPosX.push (desiredPosX);
					commentsDesiredPosY.push (desiredPosY);
				}
			}
		} // var i
		curScore.endCmd();
	
		// NOW TWEAK LOCATIONS OF COMMENTS
		var offx = [];
		var offy = [];
		
		for (var i = 0; i < comments.length; i++) {
			var elementHeight = 0;
			var commentOffset = 1.0;
			var comment = comments[i];
			offx.push(0);
			offy.push(-(comment.bbox.height) - 2.5);
			desiredPosX = commentsDesiredPosX[i];
			desiredPosY = commentsDesiredPosY[i];
			var commentHeight = comment.bbox.height;
			var commentWidth = comment.bbox.width;
			var element = errorObjects[i];
			if (eType == Element.TEXT) {
				checkObjectPage = true;
				objectPageNum = getPageNumber(element);
			}
			theLocation = element;
			var placedX = comment.pagePos.x;
			var placedY = comment.pagePos.y;
			if (desiredPosX != 0) offx[i] = desiredPosX - placedX;
			if (desiredPosY != 0) offy[i] = desiredPosY - placedY;
			if (placedX + offx[i] < 0) offx[i] = -placedX;
			if (placedY + offy[i] < 0) offy[i] = -placedY;
			
			var commentPage = comment.parent;
			while (commentPage != null && commentPage.type != Element.PAGE && commentPage.parent != undefined) commentPage = commentPage.parent; // in theory this should get the page
		
			if (commentPage != null && commentPage != undefined) {
				if (commentPage.type == Element.PAGE) {
		
					var commentPageWidth = commentPage.bbox.width;
					var commentPageHeight = commentPage.bbox.height;
					var commentPageNum = commentPage.pagenumber; // get page number
					
					// move over to the top right of the page if needed
					if (theLocation === "pagetopright") comment.offsetX = commentPageWidth - commentWidth - 2.5 - placedX;
		
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
					if (commentB > commentPageHeight) offy[i] -= (commentB - commentPageHeight); // BOTTOM
					
					for (var k = 0; k < i; k++) {
						var otherComment = comments[k];
						var otherCommentPage = commentPages[k];
						var otherCommentX = otherComment.pagePos.x + offx[k];
						var otherCommentY = otherComment.pagePos.y + offy[k];
						var actualCommentX = placedX + offx[i];
						var actualCommentRHS = commentRHS + offx[i];
						var actualCommentY = placedY + offy[i];
						var actualCommentB = commentB + offy[i];
	
						if (commentPage.is(otherCommentPage)) {
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
								//logError ("Same page. dx = "+dx+" dy = "+dy+" close = "+isCloseToOtherComment+" far = "+isNotTooFarFromOriginalPosition);
								while (isCloseToOtherComment &&  isNotTooFarFromOriginalPosition && actualCommentRHS < commentPageWidth && actualCommentY > 0) {
									offx[i] += commentOffset;
									offy[i] -= commentOffset;
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
					if (checkObjectPage && commentPageNum != objectPageNum) comment.text = '[The object this comment refers to is on p. '+(objectPageNum+1)+']\n' +comment.text;
				} else {
					//logError ("parent parent parent parent was not a page — element = "+element.name);
					// this will fail if MMR
				}
			}
		}
		
		// now reposition all the elements
		//curScore.startCmd();
		for (var i = 0; i < comments.length; i++) {
			var comment = comments[i];
			comment.offsetX = offx[i];
			comment.offsetY = offy[i];
		}
		//curScore.endCmd();
	}
		
	function getTick (e) {
		var tick = 0;
		var eType = e.type;
		var spannerArray = [Element.HAIRPIN, Element.SLUR, Element.PEDAL, Element.PEDAL_SEGMENT, Element.OTTAVA, Element.OTTAVA_SEGMENT, Element.GRADUAL_TEMPO_CHANGE];
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
					if (p != null) for (var i = 0; i < 10 && p.type != Element.SEGMENT; i++) p = p.parent;
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
	
	function checkScoreForGlisses () {
		var prevGlissandoSegment = null;
		var elems = curScore.selection.elements;

		for (var i = 0; i<elems.length; i++) {
		
			var e = elems[i];
			if (!e.visible) continue;			
			var etype = e.type;
			var etrack = e.track;

			// *** GLISSANDI *** //
			if (etype == Element.GLISSANDO) glisses[etrack][e.parent.parent.parent.tick] = e;
			if (etype == Element.GLISSANDO_SEGMENT) {
				var sameLoc = false;
				var sameGlissando = false;
				if (prevGlissandoSegment != null) {
					sameLoc = (e.spanner.spannerTick.ticks == prevGlissandoSegment.spanner.spannerTick.ticks) && (e.spanner.spannerTicks.ticks == prevGlissandoSegment.spanner.spannerTicks.ticks);
					if (sameLoc) sameGlissando = !e.spanner.is(prevGlissandoSegment.spanner);
				}
				if (!sameGlissando) glisses[etrack][e.spanner.spannerTick.ticks] = e;
				prevGlissandoSegment = e;
			}
		}
	}
	
	function checkScoreForTwoNoteTremolos () {
		var staves = curScore.staves;
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			var etype = e.type;
			var staffIdx = 0;
			while (!staves[staffIdx].is(e.staff)) staffIdx++;
			if (etype == Element.TREMOLO_TWOCHORD) twoNoteTremolos[staffIdx][e.parent.parent.tick] = e;
		}
	}
	
	function getPreviousNoteRest (noteRest) {
		cursor2.track = noteRest.track;
		cursor2.rewindToTick(noteRest.parent.tick);
		if (cursor2.prev()) return cursor2.element;
		return null;
	}
	
	function getNextNoteRest (noteRest) {
		cursor2.track = noteRest.track;
		cursor2.rewindToTick(noteRest.parent.tick);
		if (cursor2.next()) return cursor2.element;
		return null;
	}
	
	function getPositionInBar (noteRest) {
		// returns the offset (in ticks) of the note/rest from the start of the bar it's in
		// calculate by subtracting tick of first segment of parent bar from the noteRest's tick
		return noteRest.parent.tick - noteRest.parent.parent.firstSegment.tick;
	}
	
	function logError (str) {
		numLogs ++;
		errorMsg += "<p>Staff "+currentStaffNum+", b. "+currentBarNum+": "+str+"</p>";
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
				textFormat: Text.RichText
				text: dialog.msg
				wrapMode: TextEdit.Wrap
				leftInset: 0
				leftPadding: 0
				readOnly: true
				color: ui.theme.fontPrimaryColor
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
