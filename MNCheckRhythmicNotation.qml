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
	description: "This plugin checks your score for common rhythmic notation issues"
	menuPath: "Plugins.MNCheckRhythmicNotation";
	requiresScore: true
	title: "MN Check Rhythmic Notation"
	id: mncheckrhythmicnotation
	
	// **** GLOBALS **** //
	property var timeSigs: []
	property var timeSigTicks: []
	property var commentPosArray: []
	property var errorMsg: ''
	property var errorStrings: []
	property var errorObjects: []
	property var currentZ: 16384
	property var timeSigNum: 0
	property var timeSigDenom: 0
	property var timeSigStr: ''
	property var isOnTheBeat: false
	property var barLength: 0
	property var isRest: false
	property var isNote: false
	property var prevIsNote: false
	property var displayDur: 0
	property var prevDisplayDur: 0
	property var soundingDur: 0
	property var noteFinishesBeat: false
	property var hasBeam: false
	property var cursor: null
	property var cursor2: null
	property var noteStartBeat: 0
	property var noteEndBeat: 0
	property var barStart: 0
	property var beatLength: 0
	property var noteHidesBeat: false
	property var numBeatsHidden: 0
	property var noteStartFrac: 0
	property var nextItem: null
	property var nextItemIsNote: false
	property var nextItemPos: 0
	property var nextItemDur: 0
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
	
	
	property var dottedminim
	property var minim
	property var dottedcrotchet
	property var crotchet
	property var doubledottedquaver
	property var dottedquaver
	property var quaver
	property var dottedsemiquaver
	property var semiquaver
	property var semibreve
	
	property var debug: true


  onRun: {
		if (!curScore) return;
		
		// **** INITIALISE VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		cursor = curScore.newCursor();
		cursor2 = curScore.newCursor();
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var numBars, totalNumBars;
		var tiedNotes = [];
		var rests = [];
		var	simplifiedDuration = [];
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
		
		var possibleOnbeatSimplificationDurs = [semiquaver, dottedsemiquaver, quaver, dottedquaver, doubledottedquaver, crotchet, dottedcrotchet, minim, dottedminim, semibreve];
		var possibleOnbeatSimplificationLabels = ["semiquaver", "dotted semiquaver", "quaver", "dotted quaver", "double-dotted quaver", "crotchet", "dotted crotchet", "minim", "dotted minim", "semibreve"];
		var possibleOffbeatSimplificationDurs = [semiquaver, dottedsemiquaver, quaver, dottedquaver, doubledottedquaver, crotchet, dottedcrotchet];
		var	possibleOffbeatSimplificationLabels = ["semiquaver", "dotted semiquaver", "quaver", "dotted quaver", "double-dotted quaver", "crotchet", "dotted crotchet"];
		commentPosArray = Array(10000).fill(0);

		// **** DELETE ALL EXISTING COMMENTS AND HIGHLIGHTS **** //
		
		deleteAllCommentsAndHighlights();
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) {
			// ** SELECT ALL IF NO SELECTION ** //
			curScore.startCmd();
			curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
			curScore.endCmd();
		}
		
		firstStaffNum = curScore.selection.startStaff;
		lastStaffNum = curScore.selection.endStaff;
		errorMsg+="firstStaffNum= "+firstStaffNum+"; lastStaffNum = "+lastStaffNum;
		
		// **** CALCULATE FIRST BAR IN SCORE & SELECTION **** //
		firstBarInScore = curScore.firstMeasure;
		cursor.rewind(Cursor.SELECTION_START);
		firstBarInSelection = cursor.measure;
		firstTickInSelection = cursor.tick;
		//var firstTrackInSelection = cursor.track;
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
		errorMsg += "\nlastBarNum: "+lastBarNum;
		
		// ** GET ALL TIME SIGS ** //
		cursor.filter = Segment.All;
		cursor.rewind(Cursor.SCORE_START);
		cursor.filter = Segment.TimeSig;
		cursor.next();
 
		while (cursor.segment) {
			if (cursor.element) {
				var ts = cursor.element;
				// do something with keySig 
				timeSigs.push(ts);
				timeSigTicks.push(cursor.tick);
				errorMsg += "\nFound a time sig elem: "+ts.timesigNominal.str;
			}
			cursor.next();
		}
		if (timeSigs.length == 0) errorMsg += "\nDidn't find any time sigs";
		
		numBars = (lastBarNum-firstBarNum)+1;
		totalNumBars = numBars*numStaves;
		
		// **** INITIALISE VARIABLES FOR THE LOOP **** //
		var currentBarNum, currentStaffNum, numBarsProcessed,  wasTied, currentTimeSig;
		var prevSoundingDur, prevNoteWasDoubleTremolo;
		var tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex;
		var numRests, restCrossesBeat, restStartedOnBeat, isLastRest;
		var prevPitch;
		var lastNoteInBar, lastRest;
		var totalDur, numComments;
		
		numBarsProcessed = 0;
		
		// **** LOOP THROUGH THE SELECTED STAVES AND THE SELECTED BARS **** //
		// ** NB — lastStaffNum IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //
		for (currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum; currentStaffNum ++) {

			wasTied = false;
			
			// ** REWIND TO START OF SELECTION ** //
			cursor.filter = Segment.All;
			cursor.rewind(Cursor.SELECTION_START);
			cursor.staffIdx = currentStaffNum;
			cursor2.staffIdx = currentStaffNum;
			cursor.filter = Segment.ChordRest;
			cursor2.filter = Segment.ChordRest;
			currentBar = cursor.measure;
			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
				
				errorMsg += "\n—————————————————\nBAR "+currentBarNum;
				
				// ** UPDATE PROGRESS MESSAGE ** //
								
				// **** GET TIME SIGNATURE **** //
				currentTimeSig = currentBar.timesigActual;
				timeSigNum = currentTimeSig.numerator;
				timeSigDenom = currentTimeSig.denominator;
				timeSigStr = currentTimeSig.str;
				errorMsg += "\ntimeSigStr = "+timeSigStr;
				
				barStart = currentBar.firstSegment.tick;
				barLength = currentBar.lastSegment.tick - barStart;
				
				errorMsg += "\nbarStart = "+barStart+"; barLength = "+barLength;
				
				beatLength = crotchet;
				var isPickupBar = false;
				var expectedDuration = timeSigNum * (semibreve/timeSigDenom);
				errorMsg += "\nexpectedDur = "+expectedDuration;
				
				if (currentBarNum == 1 && expectedDuration != barLength) isPickupBar = true;
				var canCheckThisBar = false;
				isCompound = false;
				
				if (timeSigDenom == 8) {
					isCompound = !(timeSigNum % 3);
					if (isCompound) beatLength = dottedcrotchet;
				}
				if (timeSigDenom == 4 || timeSigDenom == 2) isCompound = !(timeSigNum % 3) && (timeSigNum > 3);
				canCheckThisBar = ((isCompound && timeSigDenom > 4) || timeSigNum < 5 || !(timeSigNum % 2) || timeSigDenom == 4);
				if (!canCheckThisBar) errorMsg += "\ncouldn't check this bar as time sig was too batty";
	
				// ** LOOP THROUGH ALL THE NOTERESTS IN THIS BAR ** //
				if (canCheckThisBar) {
				
					// ** INITIALISE PARAMETERS ** //
			
					prevSoundingDur = 0;
					prevDisplayDur = 0;
					prevNoteWasDoubleTremolo = false;
					numComments = 0;
					tiedSoundingDur = 0;
					tiedDisplayDur = 0;
					tieStartedOnBeat = false;
					isTied = false;
					prevIsNote = false;
					numRests = 0;
					restCrossesBeat = false;
					restStartedOnBeat = false;
					isLastRest = false;
					prevPitch = 0;
					lastNoteInBar = false;
					tieIndex = 0;
					lastRest = false;
					var startTrack = currentStaffNum * 4;
					var endTrack = startTrack + 4;
					for (var track = startTrack; track < endTrack; track++) {
						// **** GET SEGMENT **** //
						//segment = currentBar.firstSegment;
						cursor.voice = track;
						cursor2.voice = track;
						cursor.rewindToTick(barStart);
						//cursor.next();
						//errorMsg += "\ncursorTick = "+cursor.tick;
						errorMsg += "\nTrack "+track;
						
							// ** LOOP THROUGH EACH VOICE ** //
					
						totalDur = 0;
						//currentBar = cursor.measure;
						var processingThisBar = cursor.element;
						while (processingThisBar) {
							var noteRest = cursor.element;
							var isHidden = !noteRest.visible;
							isRest = noteRest.type == Element.REST;
							isNote = !isRest;
							isTied = false;
							if (isNote) isTied = noteRest.notes[0].tieBack != null || noteRest.notes[0].tieForward != null;
							displayDur = noteRest.duration.ticks;
							soundingDur = noteRest.actualDuration.ticks;
							var noteStart = cursor.tick - barStart;
							var noteEnd = noteStart + soundingDur;
							errorMsg += "\nnoteStart = "+noteStart+"; noteEnd = "+noteEnd;
							
							// calculate next item and next next item
													
							cursor2.rewindToTick(cursor.tick);
							nextItem = null;
							var nextItemIsHidden = false;
							nextItemIsNote = false;
							nextItemPos = 0;
							nextItemDur = 0;
							
							if (cursor2.next()) {
								if (cursor2.measure.is(currentBar)) {
									nextItem = cursor2.element;
									nextItemIsNote = nextItem.type != Element.REST;
									nextItemPos = cursor2.tick - barStart;
									nextItemDur = nextItem.actualDuration.ticks;
									nextItemBeat = Math.trunc(nextItemPos / beatLength);
									nextItemIsHidden = !nextItem.visible;
									if (cursor2.next()) {
										if (cursor2.measure.is(currentBar)) {
											nextNextItem = cursor2.element;
											nextNextItemIsNote = nextNextItem.type != Element.REST;
											nextNextItemPos = cursor2.tick - barStart;
											nextNextItemDur = nextNextItem.actualDuration.ticks;
											nextNextItemBeat = Math.trunc(nextNextItemPos / beatLength);
										}
									}
								}
							}
						
							if (isHidden) {
								numRests = 0;
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
							}
							// ** GET ALL THE VALUES FOR THE VARIOUS PARAMETERS ** //
							
							var lastNoteInTie = false;
							noteStartFrac = noteStart % beatLength;
							noteStartBeat = Math.trunc(noteStart/beatLength);
							var noteEndFrac = noteEnd % beatLength;
							noteEndBeat = Math.trunc(noteEnd/beatLength);
							noteFinishesBeat = !noteEndFrac;
							numBeatsHidden = noteEndBeat-noteStartBeat-noteFinishesBeat;
							noteHidesBeat = numBeatsHidden > 0;
							isOnTheBeat = !noteStartFrac;
							
							
							errorMsg += "\nnoteStartFrac = "+noteStartFrac+"; noteStartBeat = "+noteStartBeat+"\nnoteEndFrac = "+noteEndFrac+"; noteEndBeat = "+noteEndBeat+"\nnoteFinishesBeat = "+noteFinishesBeat+"; numBeatsHidden = "+numBeatsHidden;
							
							//isAcc = noteRest.IsAcciaccatura or noteRest.IsAppoggiatura;
							//isDoubleTremolo = noteRest.DoubleTremolos > 0;
							var beam = noteRest.beam;	
							//nextNextItem = null;
							//nextNextItemDur = 0;
							//nextItemIsNote = false;
							//nextNextItemIsNote = false;
							//nextItemNoteCount = 0;
							//nextItemPitch = 0;
							var pitch = 0;
							if (isNote) pitch = noteRest.notes[0].pitch;
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
							
							//nextItemIsHidden = false;
							//if (beam) errorMsg += "\nBEAM = "+noteRest.beamMode;
							hasBeam = beam != null;
							
							var noteTypeString = "Note";
							if (isRest) noteTypeString = "Rest";
							
							// ** ————————————————————————————————————————————————— ** //
							// **   CHECK 1: CHECK FOR MANUALLY ENTERED BAR REST    ** //
							// ** ————————————————————————————————————————————————— ** //
							
							checkManuallyEnteredBarRest(noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// **         CHECK 2: DOES THE NOTE HIDE THE BEAT??    ** //
							// ** ————————————————————————————————————————————————— ** //

							checkHidingBeatError(noteRest);
									
							// ** ————————————————————————————————————————————————— ** //
							// **       CHECK 3: NOTE/REST SHOULD NOT BREAK BEAM    ** //
							// ** ————————————————————————————————————————————————— ** //
						
							checkBeamBrokenError(noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// **       CHECK 4: BEAMED to NOTES IN NEXT BEAT       ** //
							// ** ————————————————————————————————————————————————— ** //

							// ** If note is off the beat, at the end of the beat, continuous beam, next beam is continuous or single, then the beam continues over the beat
							checkBeamedToNotesInNextBeat(noteRest);
							
							if (isNote || hasPause) {
								rests = [];
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
							} else {
								rests.push(noteRest);
								if (rests.length == 1) {
									restStartedOnBeat = isOnTheBeat;
									restStartBeat = noteStartBeat;
								} else {
									if (noteStartBeat != restStartBeat) restCrossesBeat = true;
								}
								
								if (nextItemIsNote || nextItem == null || nextItemHasPause || nextItemIsHidden) isLastRest = true;
								
								if (isLastRest && numRests > 1) {
									// ** ————————————————————————————————————————————————— ** //
									// **       CHECK 4: CONDENSE OVERSPECIFIED REST       ** //
									// ** ————————————————————————————————————————————————— ** //

									// ** If note is off the beat, at the end of the beat, continuous beam, next beam is continuous or single, then the beam continues over the beat
									condenseOverSpecifiedRest(noteRest);
								}
							}
							
							if (cursor.next()) {
								processingThisBar = cursor.measure.is(currentBar);
							} else {
								processingThisBar = false;
							}

							prevSoundingDur = soundingDur;
							prevDisplayDur = displayDur;
							prevIsNote = isNote;
							//prevNoteWasDoubleTremolo = isDoubleTremolo;
							prevPitch = pitch;
						} // end while processingThisBar
					} // end track loop
				} // end if canCheckThisBar
				
				if (currentBar) {
					errorMsg += "\nTrying to get next measure";
					currentBar = currentBar.nextMeasure;
				}
				if (!currentBar) errorMsg += "\nnextMeasure failed";

				numBarsProcessed ++;
				
				errorMsg += "\nProcessed "+numBarsProcessed+" bars";
				
			} // end for currentBarNum	
		} // end for currentStaff
		
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
	
	
	function checkManuallyEnteredBarRest (noteRest) {
		errorMsg += "\n*** CHECKING MANUALLY ENTERED BAR REST ***"; 
		isBarRest = isRest && soundingDur == barLength;
		isManuallyEnteredBarRest = isBarRest && noteRest.durationType.type < 14;
		if (isManuallyEnteredBarRest) addError ("Bar rest has been manually entered, and is therefore incorrectly positioned.\nSelect the bar, and press delete to revert to a correctly positioned bar rest.",noteRest);
	}
	
	function checkHidingBeatError (noteRest){
		errorMsg += "\n*** CHECKING HIDING BEAT ERROR ***";
		var hidingBeatError = noteHidesBeat && !isBarRest && !hasPause; // make a temp version
		if (!hidingBeatError) return;
		
		// hidingBeatError is now true — but there are some exceptions
		if (isOnTheBeat) {
			// ON THE BEAT RESTS
			if (isRest) {
				if (soundingDur == minim) {
					// ok in 4/4 on 1 & 3
					if (timeSigStr === "4/4" && noteStartBeat % 2 == 0) hidingBeatError = false;
					if (timeSigStr === "5/4" && (noteStartBeat == 0 || noteStartBeat == 2 || noteStartBeat == 3)) hidingBeatError = false;
				}	
			} else {
				
				// ON THE BEAT NOTES
				if (isCompound && (soundingDur == beatLength * 2 || soundingDur == beatLength * 4)) {
					hidingBeatError = false;

					// no semibreves in 5/4
					if (timeSigStr == "5/4") {
						hidingBeatError = (soundingDur == semibreve);
					} else {
						hidingBeatError = false;
					}
				}
			}			

		} else {
			// ** OFF THE BEAT ** //
			// ** FIRST, WE ASSUME THAT THE NOTE IS HIDING THE BEAT ** //

			// ** exclude dotted crotchet if on 0.5 or 2.5

			// ** exclude crotchet if on 0.5 or 2.5
			if (timeSigDenom == 4) {
				if (timeSigNum == 4) {
					if ((noteStart == quaver || noteStart == minim+quaver) && (soundingDur == crotchet || soundingDur == dottedcrotchet) && isNote) {
						hidingBeatError = false; // OK to use crotchet or dotted crotchet,  rest or dotted rest here
					}
				} else {
					if ((noteStartFrac == quaver || noteStartFrac == 0) && (soundingDur == crotchet || soundingDur == dottedcrotchet) && isNote) {
						hidingBeatError = false; // OK to use crotchet or dotted crotchet,  rest or dotted rest here
					}
				}
			}

			// ** EXCLUDE LONG TUPLET
			//if (tupletPlayedDuration > crotchet) hidingBeatError = false;
			// TO FIX

			// ** EXCLUDE DOUBLE TREMOLOS ** //
			//if (isDoubleTremolo) hidingBeatError = false;
			// TO FIX

			//if (actualDur == prevActualDur && prevNoteWasDoubleTremolo) hidingBeatError = false;
		}
		
		if (hidingBeatError) {
			if (isNote) {
				if (timeSigStr === "5/4" && soundingDur == semibreve) {
					addError("Never use a semibreve in 5/4\nsplit the note to show the bar division of either 2+3 or 3+2",noteRest);
				} else {
					if (numBeatsHidden == 1) {
						addError("Note hides beat "+(noteStartBeat + 2)+"\nsplit with a tie",noteRest);
					} else {
						var errStr = "Note hides beats ";

						for (var i = 0; i < numBeatsHidden; i++) {
							errorMsg += "\ni="+i+"; nbh="+numBeatsHidden;
							var beatStr = (noteStartBeat+2+i).toString();
							errStr += beatStr;
							errorMsg += "\nerrStr="+errStr;
							
							if (i < numBeatsHidden - 2) {
								errStr += ", ";
								errorMsg += "\nerrStr="+errStr;
								
							} else {
								if (i == numBeatsHidden - 2) {
									errStr += " + ";
									errorMsg += "\nerrStr="+errStr;
									
								} else {
									errStr += " — split with a tie";
									errorMsg += "\nerrStr="+errStr;
									
								}
							}
						}
						errorMsg += "\nFinal errStr=‘"+errStr+"’";
						addError(errStr,noteRest);
					}
				}
			} else {
				if (timeSigStr == "5/4" && soundingDur == semibreve) {
					addError("Never use a semibreve rest in 5/4\nsplit the rest to show the bar division of either 2+3 or 3+2",noteRest);
				} else {
					addError( "Rest hides beat "+(noteStartBeat + 2)+" — split into two rests",noteRest);
					if (numBeatsHidden = 1) {
						addError( "Rest hides beat "+(noteStartBeat + 2)+" — split into two rests",noteRest);
					} else {
						var errStr = "Rest hides beats ";

						for (var i = 0; i < numBeatsHidden; i++) {
							var beatStr = (noteStartBeat+2+i).toString();
							errStr += beatStr;
							if (i < numBeatsHidden - 2) {
								errStr += ", ";
							} else {
								if (i == numBeatsHidden - 2) {
									errStr += " + ";
								} else {
									errStr += " — split into two rests";
								}
							}
						}
						addError(errStr,noteRest);
					}
				}
			}
		} // end if hidingBeatError
	}
	
	function condenseOverSpecifiedRest (noteRest) {
		errorMsg += "\n*** CHECKING CONDENSING OVER-SPECIFIED REST ***"; 
		
		var possibleSimplification = -1;
		var simplificationIsOnBeat = true;
		
		// CHECK THAT IT COULD BE SIMPLIFIED AS A BAR REST
		var firstRest = rests[0];
		var firstTick = firstRest.parent.tick;
		var lastRest = rests[numRests-1];
		var lastTick = lastRest.parent.tick;
		var lastDur = lastRest.duration.ticks;
		
		if (firstTick == barStart && (lastTick + lastDur == barLength) && !isPickupBar) {
			addError ('Rests can be deleted to make a bar rest.', noteRest)
		} else {
		
			for (var i = 0; i < numRests-1; i++) {
				var startRest = rests[i];
				var startRestTick = startRest.parent.tick;
				var startRestPrev = getPrevNoteRest(startRest);
				var restDisplayDur = startRest.duration.ticks;
				var restActualDur = startRest.actualDuration.ticks
				var startPos = getPositionInBar(startRest);
				var startBeat = Math.trunc(startPos/beatLength);
				var startFrac = startPos % beatLength;
				var restIsOnBeat = startFrac == 0;
								
				simplifiedDuration = '';
				for (var j = i+1; j < numRests; j++) {
					prevNote = (i == 0) ? startRestPrev : rests[i-1];
					var theRest = rests[j];
					var tempDisplayDur = theRest.duration.ticks;
					var tempActualDur = theRest.actualDuration.ticks;
					var tempPos = getPositionInBar(theRest);
					var tempBeat = Math.trunc(tempPos/beatLength);
					sameBeat = (tempBeat == startBeat);
					restActualDur += tempActualDur;
					restDisplayDur += tempDisplayDur;
	
					// **** ONBEAT REST CONDENSATION **** //
	
					if (restIsOnBeat) {
						for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
							var check = restActualDur < dottedminim;
							var p = possibleOnbeatSimplificationDurs[k];
							// don't simplify anything tied over a beat that is less than a crotchet
							
							if (restActualDur == semibreve) check = timeSigStr === "4/4";
							if (restActualDur == minim) check = !isCompound && !(startBeat % 2);
							if (restActualDur == dottedcrotchet && !isCompound) check = ((timeSigDenom <= 2) || isCompound) && !(startBeat % 2);
							if (restActualDur == dottedquaver) check = timeSigDenom <= 4;
							if (restActualDur == dottedsemiquaver) check = timeSigDenom <= 8;
							if (check && isCompound) check = !(restActualDur % beatLength);
							if (check && isCompound && timeSigNum == 4) check = restActualDur <= dottedcrotchet;
							if (restActualDur == p && check) {
								if (k > possibleSimplification) {
									possibleSimplification = k;
									possibleSimplificationLastRestIndex = j;
									possibleSimplificationFirstRestIndex = i;
									simplificationIsOnBeat = true;
								}
							}
						}

						if (checkDisplayDur) {
							for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
								var check = true;
								var p = possibleOnbeatSimplificationDurs[k];
								if (restDisplayDur == p && check) {
									if (k > possibleSimplification) {
										possibleSimplification = k;
										possibleSimplificationLastRestIndex = j;
										possibleSimplificationFirstRestIndex = i;
										simplificationIsOnBeat = true;
									}
								}
							}
						}
					} else {
	
						// **** OFFBEAT REST CONDENSATION **** //

						// CHECK ACTUAL DURS
						for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
							var check = true;
							var p = possibleOffbeatSimplificationDurs[k];

							// don't simplify anything tied over a beat that is less than a crotchet
							if (p == dottedcrotchet) check = !isCompound && startFrac == quaver && timeSigDenom <= 2;
							if (p == crotchet) check = false;
							if (p < crotchet) check = sameBeat;
							if (check && isCompound && restActualDur == beatLength * 2 / 3) check = false;
							if (restActualDur == p && check) {
								if (k > possibleSimplification) {
									possibleSimplification = k;
									possibleSimplificationLastRestIndex = j;
									possibleSimplificationFirstRestIndex = i;
									simplificationIsOnBeat = false;
								}
							}
						}
		
						// CHECK DISPLAY DURS
						if (checkDisplayDur) {
							for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
								var p = possibleOffbeatSimplificationDurs[k];
								if (restDisplayDur == p) {
									if (k > possibleSimplification) {
										possibleSimplification = k;
										possibleSimplificationLastRestIndex = j;
										possibleSimplificationFirstRestIndex = i;
										simplificationIsOnBeat = false;
									}
								}
							}
						}
					}
				}
			}
			if (possibleSimplification > -1) {
				var exception = isPickupBar && possibleSimplification > 6;
				if (simplificationIsOnBeat) {
					if (!exception) {
						var simplification = possibleOnbeatSimplificationLabels[possibleSimplification];
						var tempText = (restDisplayDur == dottedcrotchet && !isCompound)? '[Suggestion] ' : '';
						addError(tempText+'Condense rests as a '+simplification+'.\n(Ignore if using rest to show placement of fermata/etc.)',noteRest);
					}
				} else {
					simplification = possibleOffbeatSimplificationLabels[possibleSimplification];
					p = possibleOffbeatSimplificationDurs[possibleSimplification];
					tempText = (restDisplayDur == dottedcrotchet && !isCompound)? '[Suggestion] ' : '';
					addComment = true;
					addColors = true;
					numRests = possibleSimplificationLastRestIndex-possibleSimplificationFirstRestIndex+1;
					if (p == dottedquaver && rests[possibleSimplificationLastRestIndex].duration.ticks != quaver || numRests>2) {
						addError ('Spell as a semiquaver followed by a quaver.',noteRest);
					} else {
						addError('Condense rests as a '+simplification+'.\n(Ignore if using rest to show placement of fermata/etc.)',noteRest);
					}
				}
			}
		}		
	}
	
	function checkTieSimplifications (noteRest) {
		
		errorMsg += "\n*** CHECKING TIED NOTE SIMPLIFICATIONS ***";
		
		// ** DO TIE SIMPLIFICATION IF WE'RE ON THE LAST NOTE OF THE TIE ** //
		if (lastNoteInTie || (isTied && lastNoteInBar)) {
			// ** LOOP THROUGH THE NUMBER OF NOTES IN TIE ** //
			var possibleSimplification = -1;
			var simplificationIsOnBeat = true;
			var possibleSimplificationLastNoteIndex = 0;
			var possibleSimplificationFirstNoteIndex = 0;
			var theN = tiedNotes[0];
			// v = theN.VoiceNumber; TO FIX
			
			// TO FIX
//			prevNote = theN.PreviousItem(v,'NoteRest');
			
			for (var i = 0; i < tiedNotes.length-1; i++) {
				var startNote = tiedNotes[i];
				var tiedDisplayDur = startNote.duration.ticks;
				var tiedActualDur = startNote.actualDuration.ticks;
				var startPos = getPositionInBar(startNote);
				var startBeat = Math.trunc(startPos/beatLength);
				var startFrac = startPos % beatLength;
				var tieIsOnBeat = startFrac == 0;
				var tieStartedOnBeat = startPos % beatLength == 0;
				var tempNextItem = getNextNoteRest(startNote);
				var tiedActualDur = startNote.duration.ticks;
				var simplifiedDuration = '';
	
				// do onbeat simplifications
				for (var j = i+1; j < tiedNotes.length; j++) {	
					var theNote = tiedNotes[j];
					var tempDisplayDur = theNote.duration.ticks;
					var tempActualDur = theNote.actualDuration.ticks;
					var tempPos = theNote.parent.tick;
					var tempBeat = Math.trunc(tempPos/beatLength);
					var sameBeat = (tempBeat == startBeat);
					var tempNextItem = getNextNoteRest(theNote);
					
					tiedActualDur += tempActualDur;
					tiedDisplayDur += tempDisplayDur;
					var check, simplification;
					
					if (tieIsOnBeat) {
						for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
							check = true;
							simplification = possibleOnbeatSimplificationDurs[k];
							if (tiedActualDur == simplification) {
								if (isCompound) {
									check = tiedActualDur > beatLength && !(tiedActualDur % beatLength);
								} else {
									if (tiedActualDur == dottedcrotchet) check = !(startBeat % 2);
									if (tiedActualDur == semibreve) check = timeSigStr === "4/4";
								}
				
								if (check) {
									if (k > possibleSimplification) {
										possibleSimplification = k;
										possibleSimplificationLastNoteIndex = j;
										possibleSimplificationFirstNoteIndex = i;
										simplificationIsOnBeat = true;
									}
								} // end if check
							}
						}
						if (checkDisplayDur) {
							for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
								check = true;
								simplification = possibleOnbeatSimplificationDurs[k];
								if (tiedDisplayDur == simplification && check) {
									if (k > possibleSimplification) {
										possibleSimplification = k;
										possibleSimplificationLastNoteIndex = j;
										possibleSimplificationFirstNoteIndex = i;
										simplificationIsOnBeat = true;
									} // end if k >
								} // end if tied
							} // end k
						} // end checkDisplay
					} else {
						// **** OFFBEAT TIE CONDENSATION **** //
			
						// CHECK ACTUAL DURS
	
						for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
							simplification = possibleOffbeatSimplificationDurs[k];
							if (tiedActualDur == simplification) {
								// don't simplify anything tied over a beat that is less than a crotchet
								if (isCompound) {
									check = simplification < beatLength;
								} else {
									check = simplification < (beatLength * 2);
								}
								if (check) {
									if (simplification == dottedcrotchet) check = false;
									if (simplification == crotchet) {
										check = (startFrac == quaver);
										if (timeSigDenom == 4) {
											var surr = false;
											if (prevNote != null && tempNextItem != null) surr = prevNote.duration.ticks == quaver && prevNote.notes.length > 0 && tempNextItem.duration.ticks == quaver && tempNextItem.notes.length > 0;
											var sb = startBeat == 0 || startBeat == 2;
											check = check && sb && surr;
										} // end timeSigDenom
									}
									if (simplification < crotchet) {
										var placement = startFrac % (beatLength / 4);
										var placementCheck = placement == 0;
										check = sameBeat && placementCheck;
									} // end if simp
								} // end if check
								if (check) {
									if (k > possibleSimplification) {
										possibleSimplification = k;
										possibleSimplificationLastNoteIndex = j;
									}
								} // end if check
							} // end if tied
						}
						// CHECK DISPLAY DURS
						if (checkDisplayDur) {
							for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
								simplification = possibleOffbeatSimplificationDurs[k];
								if (tiedDisplayDur == simplification && k > possibleSimplification) {
									possibleSimplification = k;
									possibleSimplificationLastNoteIndex = j;
									possibleSimplificationFirstNoteIndex = i;
									simplificationIsOnBeat = false;
								}
							}
						} // end checkDisplayDur
					}
				}
			}
			if (possibleSimplification > -1) {
				if (simplificationIsOnBeat) {
					simplification = possibleOnbeatSimplificationLabels[possibleSimplification];
					tempText = '';
					if (tiedDisplayDur == dottedcrotchet && !isCompound) tempText = '[Suggestion] ';
					addError (tempText+'Tied note can be simplified to a '+simplification+'.\n(Ignore if using tie to show placement of fermata/dynamic/articulation/gliss etc.)', noteRest);
				} else {
					simplification = possibleOffbeatSimplificationLabels[possibleSimplification];
					tempText = '';
					if (tiedDisplayDur == dottedcrotchet && !isCompound) tempText = '[Suggestion] ';
					addError(tempText+'Tied note can be simplified to a '+simplification+'. (Ignore if using tie to show placement of fermata/dynamic/articulation/gliss etc.)',noteRest);
				}
			} // possSimp > -1
		} // if lastNoteInTie
	}
	
	function checkBeamBrokenError (noteRest) {

		errorMsg += "\n*** CHECKING BEAM BROKEN ERROR ***";
		var thisNoteAndPrevAreLessThancrotchets = displayDur < crotchet && prevDisplayDur < crotchet && prevIsNote;
		var restAtEndOfBeat = isRest && noteFinishesBeat;
		var beamBroken = !isOnTheBeat && !hasBeam;
		errorMsg += "\nbeamBroken = "+beamBroken;

		if (beamBroken && thisNoteAndPrevAreLessThancrotchets && !restAtEndOfBeat) {
			// go through rest of beat looking for a note
			var dontBreakBeam = true;
			if (!noteFinishesBeat) {
				cursor2.rewindToTick(cursor.tick);
				if (cursor2.next()) {
					if (cursor2.measure.is(currentBar)) {
						var tempPos = cursor2.tick;
						var tempBeat = noteStartBeat;
						var tempNote = cursor2.element;
						var dontBreakBeam = false;
						while (tempNote && tempBeat == noteStartBeat && !dontBreakBeam ) {
							tempPos = cursor2.tick - barStart;
							tempBeat = Math.trunc(tempPos / beatLength);
							errorMsg += "Here 3: tempPos = "+tempPos+"; tempBeat = "+tempBeat;
							dontBreakBeam = tempNote.actualDuration.ticks < crotchet && tempBeat == noteStartBeat;
							var tempNoteIsRest = tempNote.type == Element.REST;
							if (tempNoteIsRest) {
								cursor2.next();
								if (!cursor2.measure.is(currentBar)) {
									tempNote = null;
									tempBeat = noteStartBeat + 1;
								} else {
									tempNote = cursor2.element;
									tempPos = cursor2.ticks-barStart;
									tempBeat = Math.trunc(tempPos / beatLength);
								}
							} else {
								tempBeat = noteStartBeat + 1;
							}
						}
					}
				}
			}
			if (dontBreakBeam) {
				if (isNote) {
					addError("Note should be beamed to previous note",noteRest);
				} else {
					addError("Rest should not break beam of previous note",noteRest);
				}
			}
		} // end if beamBroken
	}
	
	function checkBeamedToNotesInNextBeat (noteRest) {

		errorMsg += "\n*** CHECKING BEAMED TO NOTES IN NEXT BEAT ERROR ***";
		// ADD — 
		if (nextItem && hasBeam && nextItemBeat > noteStartBeat) {
			errorMsg += "\n beamed to notes in next beat"
			
			// ** EXCEPTION WHERE QUAVERS ARE BEAMED TOGETHER IN 4/4 ** //
			var exception1 = isNote && soundingDur == quaver && prevSoundingDur == quaver && nextItemDur == quaver && nextNextItemDur == quaver && nextNextItemIsNote;
			//var exception2 = barLength == semibreve && noteStartBeat == 1;
			if ( !exception1 ) {
				if (isNote) {
					addError( "Note should not be beamed to notes in next beat\nSwitch all following note(s)/rest(s) under the beam to AUTO",noteRest);
				} else {
					addError( "Rest should not be included in beam group of next beat\nSwitch its beam type to AUTO", noteRest);
				}
			}
		}
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
						if (element.parent.type == Element.CHORD) {
							// it's a grace note, so need to get parent of parent
							tick = element.parent.parent.tick;
						} else {
							tick = element.parent.tick;
						}
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
