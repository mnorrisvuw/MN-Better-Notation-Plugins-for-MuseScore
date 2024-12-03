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
	thumbnailName: "MNCheckRhythmicNotation.png"
	
	// **** GLOBALS **** //
	property var timeSigs: []
	property var timeSigTicks: []
	property var commentPosArray: []
	property var rests: []
	property var tiedNotes: []
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
	property var prevSoundingDur: 0
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
	property var nextBeam: null
	property var nextBeamMode: 0
	property var isPickupBar: false
	property var isTied: false
	property var beamBeat: -1
	property var haveHadFirstNote: false
	property var totalRestDur: 0
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
	
	property var possibleOnbeatSimplificationDurs: []
	property var possibleOnbeatSimplificationLabels: []
	property var possibleOffbeatSimplificationDurs: []
	property var possibleOffbeatSimplificationLabels: []
	
	property var debug: true
	property var progressShowing: false
	property var progressStartTime: 0


  onRun: {
		if (!curScore) return;
		setProgress (0);
		
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
		commentPosArray = Array(10000).fill(0);

		// **** DELETE ALL EXISTING COMMENTS AND HIGHLIGHTS **** //
		deleteAllCommentsAndHighlights();
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) selectAll();
		firstStaffNum = curScore.selection.startStaff;
		lastStaffNum = curScore.selection.endStaff;
		errorMsg+="\nfirstStaffNum= "+firstStaffNum+"; lastStaffNum = "+lastStaffNum;
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
		
		// ** GET ALL TIME SIGS ** //
		cursor.filter = Segment.All;
		cursor.rewind(Cursor.SCORE_START);
		cursor.filter = Segment.TimeSig;
		cursor.next();
 
		while (cursor.segment) {
			if (cursor.element) {
				var ts = cursor.element;
				timeSigs.push(ts);
				timeSigTicks.push(cursor.tick);
			}
			cursor.next();
		}
		if (timeSigs.length == 0) errorMsg += "\nDidn't find any time sigs";
		
		numBars = (lastBarNum-firstBarNum)+1;
		totalNumBars = numBars*numStaves;
		setProgress (3);
		
		// **** INITIALISE VARIABLES FOR THE LOOP **** //
		var currentBarNum, currentStaffNum, numBarsProcessed,  wasTied, currentTimeSig;
		var prevNoteWasDoubleTremolo;
		var tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, tieIndex;
		var restCrossesBeat, restStartedOnBeat, isLastRest;
		var lastNoteInBar, lastRest;
		var totalDur, numComments;
		
		var loop = 0;
		var totalNumLoops = numStaves * numBars * 4;
		setProgress (5);
		
		// **** LOOP THROUGH THE SELECTED STAVES AND THE SELECTED BARS **** //
		// ** NB — lastStaffNum IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //
		for (currentStaffNum = firstStaffNum; currentStaffNum <= lastStaffNum; currentStaffNum ++) {
			errorMsg += "\n—————————————————\nSTAFF "+currentStaffNum;

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
				barStart = currentBar.firstSegment.tick;
				barLength = currentBar.lastSegment.tick - barStart;
				beatLength = crotchet;
				isPickupBar = false;
				var expectedDuration = timeSigNum * (semibreve/timeSigDenom);
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
					prevIsNote = false;
					rests = [];
					tiedNotes = [];
					restCrossesBeat = false;
					restStartedOnBeat = false;
					isLastRest = false;
					tieIndex = 0;
					lastRest = false;
					var startTrack = currentStaffNum * 4;
					var endTrack = startTrack + 4;
					
					for (var currentTrack = startTrack; currentTrack < endTrack; currentTrack++) {
						loop++;
						setProgress(5+loop*95./totalNumLoops);
						cursor.track = currentTrack;
						cursor.rewindToTick(barStart);
						cursor2.track = currentTrack;
						totalDur = 0;
						totalRestDur = 0;
						beamBeat = -1;
						haveHadFirstNote = false;
						
						var processingThisBar = cursor.element;
						while (processingThisBar) {
							
							// *** GET THE NOTE/REST, AND ITS VARIOUS PROPERTIES THAT WE'LL NEED *** //
							var noteRest = cursor.element;
							var isHidden = !noteRest.visible;
							isRest = noteRest.type == Element.REST;
							isNote = !isRest;
							displayDur = noteRest.duration.ticks; // what the note looks like
							soundingDur = noteRest.actualDuration.ticks; // what its actual length is, taking tuplets into account
							noteStart = cursor.tick - barStart; // offset from the start of the bar
							noteEnd = noteStart + soundingDur; // the tick at the end of the note
							lastNoteInBar = noteStart + soundingDur >= barLength; // is this the last note in the bar (in this track?)
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
							hasBeam = currentBeam != null;
							
							// *** GET INFORMATION ON THE NEXT ITEM AND THE ONE AFTER THAT *** //
							cursor2.rewindToTick(cursor.tick);
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
							nextBeam = null;
							nextBeamMode = Beam.NONE;
							
							if (cursor2.next()) {
								if (cursor2.measure.is(currentBar)) {
									nextItem = cursor2.element;
									nextItemIsNote = nextItem.type != Element.REST;
									nextItemPos = cursor2.tick - barStart;
									nextDisplayDur = nextItem.duration.ticks;
									nextItemDur = nextItem.actualDuration.ticks;
									nextItemBeat = Math.trunc(nextItemPos / beatLength);
									nextItemIsHidden = !nextItem.visible;
									nextBeam = nextItem.beam;
									nextBeamMode = nextItem.beamMode;
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
								tiedNotes.push(noteRest);
								if (lastNoteInTie) errorMsg += "\nlastNoteInTie";
							} else {
								if (wasTied) tiedNotes = [];
							}
							
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

							checkBeamedToNotesInNextBeat(noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// **       CHECK 5: CONDENSE OVERSPECIFIED REST       ** //
							// ** ————————————————————————————————————————————————— ** //

							if (isNote || hasPause) {
								rests = [];
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
								totalRestDur = 0;
							} else {
								rests.push(noteRest);
								totalRestDur += noteRest.actualDuration.ticks;
								if (rests.length == 1) {
									restStartedOnBeat = isOnTheBeat;
									restStartBeat = noteStartBeat;
								} else {
									if (noteStartBeat != restStartBeat) restCrossesBeat = true;
								}
								if (nextItemIsNote || nextItem == null || nextItemHasPause || nextItemIsHidden) isLastRest = true;
								if (isLastRest && rests.length > 1) condenseOverSpecifiedRest(noteRest);
							}
							
							// ** ————————————————————————————————————————————————— ** //
							// **       CHECK 6: CHECK TIE SIMPLIFICATIONS          ** //
							// ** ————————————————————————————————————————————————— ** //
							
							if (lastNoteInTie) {
								checkTieSimplifications(noteRest);
								tiedNotes = [];
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
						} // end while processingThisBar
					} // end track loop
				} // end if canCheckThisBar
				
				if (currentBar) currentBar = currentBar.nextMeasure;
				numBarsProcessed ++;
			} // end for currentBarNum	
		} // end for currentStaff
		
		// ** SHOW ALL OF THE ERRORS ** //
		showAllErrors();
		
		// ** SHOW INFO DIALOG ** //
		if (!debug) {
			var numErrors = errorStrings.length;
			if (numErrors == 0) errorMsg = "SCORE CHECK COMPLETED!\n\nNo errors found!";
			if (numErrors == 1) errorMsg = "SCORE CHECK COMPLETED!\n\nI found one error.";
			if (numErrors > 1) errorMsg = "SCORE CHECK COMPLETED!\n\nI found "+numErrors+" errors";
		}
		if (progressShowing) progress.close();
		dialog.msg = errorMsg;
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
				progress.progressBar.value = percentage;
			}
		}
	}
	
	function selectAll () {
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,curScore.nstaves);
		curScore.endCmd();
	}
	
	function checkManuallyEnteredBarRest (noteRest) {
		isBarRest = isRest && soundingDur == barLength;
		isManuallyEnteredBarRest = isBarRest && noteRest.durationType.type < 14;
		if (isManuallyEnteredBarRest) addError ("Bar rest has been manually entered, and is therefore incorrectly positioned.\nSelect the bar and press ‘delete’ to create a correctly positioned bar rest.",noteRest);
	}
	
	function checkHidingBeatError (noteRest){
		var hidingBeatError = noteHidesBeat && !isBarRest && !hasPause; // make a temp version
		if (!hidingBeatError) return;
		errorMsg += "\nChecking beat Hiding";
		if (isOnTheBeat) {
			
			// ** ON THE BEAT RESTS ** //
			if (isRest) {
				if (soundingDur == minim) {
					// ok in 4/4 on 1 & 3
					if (timeSigStr === "4/4" && noteStartBeat % 2 == 0) hidingBeatError = false;
					if (timeSigStr === "5/4" && (noteStartBeat == 0 || noteStartBeat == 2 || noteStartBeat == 3)) hidingBeatError = false;
				}	
			} else {
				
				// ** ON THE BEAT NOTES ** //
				if (isCompound) {
					hidingBeatError = soundingDur % beatLength;
				} else {
					hidingBeatError = false;
					// no semibreves in 5/4
					if (timeSigStr == "5/4") hidingBeatError = (soundingDur == semibreve);
				}
			}

		} else {

			errorMsg += "\nOff beat";
			// ** OFF THE BEAT NOTES & RESTS ** //
			// ** FIRST, WE ASSUME THAT THE NOTE IS HIDING THE BEAT ** //
			// ** exclude dotted crotchet if on 0.5 or 2.5
			// ** exclude crotchet if on 0.5 or 2.5
			
			// EXCLUDE OFFBEAT CROTCHET IFF
			// 1) it's on the right place
			// 2) it's not tied
			
			// ** OFFBEAT CROTCHET ** //
			if (displayDur == crotchet) {
				if (noteRest.tuplet == null) {
					if (isNote && !isTied) {
						if (timeSigStr === "4/4" || timeSigStr == "2/2") {
							if (noteStart == quaver || noteStart == minim+quaver) hidingBeatError = false;
						} else {
							if (noteStartFrac == quaver) hidingBeatError = false;
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
				
			// ** OFFBEAT DOTTED CROTCHET ** //
			if (displayDur == dottedcrotchet && noteRest.tuplet == null) {

				errorMsg += "\nChecking dotted crotchet";
				if (isNote) {
					errorMsg += "\nHere1";
					
					if (timeSigStr === "4/4" || timeSigStr == "2/2") {
						if ((noteStart == quaver || noteStart == minim+quaver) && prevDisplayDur == quaver) hidingBeatError = false;
					} else {
						errorMsg += "\nnoteStartFrac = "+noteStartFrac+" prevDisplayDur="+prevDisplayDur;
						if (noteStartFrac == quaver && prevDisplayDur == quaver) hidingBeatError = false;
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
									errStr += " and ";									
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
					addError( "This rest is hiding beat "+(noteStartBeat + 2)+"\nSplit it into two rests, so that beat "+(noteStartBeat + 2)+" is shown.",noteRest);
					if (numBeatsHidden = 1) {
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
									errStr += " and ";
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
	
	function condenseOverSpecifiedRest (noteRest) {
		//errorMsg += "\n*** CHECKING CONDENSING OVER-SPECIFIED REST ***"; 
		
		var possibleSimplification = -1;
		var simplificationIsOnBeat = true;
		var simplificationFound = false;
		var possibleSimplificationLastRestIndex = 0;
		var possibleSimplificationFirstRestIndex = 0;
		var maxOnbeatSimplification = possibleOnbeatSimplificationDurs.length-1;
		var maxOffbeatSimplification = possibleOffbeatSimplificationDurs.length-1;
		errorMsg += "\nrests: "+rests.length+" "+maxOnbeatSimplification+" "+maxOffbeatSimplification; 
		
		// CHECK THAT IT COULD BE SIMPLIFIED AS A BAR REST
		if (totalRestDur == barLength && !isPickupBar) {
			addError ('These rests can be turned into a bar rest.\nSelect the bar and press ‘delete’', rests)
		} else {
			errorMsg += "\nHere 1"; 
			var maxSimplificationFound = false;
			
			for (var i = 0; i < rests.length-1 && !maxSimplificationFound; i++) {
				var startRest = rests[i];
				var startRestTick = startRest.parent.tick;
				var restDisplayDur = startRest.duration.ticks;
				var restActualDur = startRest.actualDuration.ticks
				var startPos = getPositionInBar(startRest);
				errorMsg += "\nstartPos = "+startPos; 
				
				var startBeat = Math.trunc(startPos/beatLength);
				var startFrac = startPos % beatLength;
				var restIsOnBeat = !startFrac;
				
								
				for (var j = i+1; j < rests.length && !maxSimplificationFound; j++) {
					var theRest = rests[j];
					var tempDisplayDur = theRest.duration.ticks;
					var tempActualDur = theRest.actualDuration.ticks;
					var tempPos = getPositionInBar(theRest);
					var tempBeat = Math.trunc(tempPos/beatLength);
					var sameBeat = (tempBeat == startBeat);
					restActualDur += tempActualDur;
					restDisplayDur += tempDisplayDur;
					errorMsg += "\nrestActualDur = "+restActualDur; 
	
					// **** ONBEAT REST CONDENSATION **** //
	
					if (restIsOnBeat) {
						// ** CHECK CONDENSATION OF ACTUAL DURATIONS ** //
						for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
							var canBeCondensed = true;
							var p = possibleOnbeatSimplificationDurs[k];
							// don't simplify anything tied over a beat that is less than a crotchet
							if (restActualDur == dottedminim) canBeCondensed = (timeSigStr == "6/4" || timeSigStr == "9/4") && !(startBeat % 3);
							if (restActualDur == minim) canBeCondensed = !isCompound && !(startBeat % 2);
							if (restActualDur == dottedcrotchet && !isCompound) canBeCondensed = ((timeSigDenom <= 2) || isCompound) && !(startBeat % 2);
							if (restActualDur == dottedquaver) canBeCondensed = timeSigDenom <= 4;
							if (restActualDur == dottedsemiquaver) canBeCondensed = timeSigDenom <= 8;
							if (canBeCondensed && isCompound) canBeCondensed = restActualDur <= beatLength || (restActualDur % beatLength == 0);
							errorMsg += "\n(onbeat act) looking for match: "+restActualDur+" = "+p+" = "+(restActualDur==p); 
							
							if (restActualDur == p && canBeCondensed) {
								if (k > possibleSimplification) {
									errorMsg += "\nfound a possibleSimplification actual dur on beat = "+k; 
									
									possibleSimplification = k;
									possibleSimplificationLastRestIndex = j;
									possibleSimplificationFirstRestIndex = i;
									simplificationIsOnBeat = true;
									simplificationFound = true;
									maxSimplificationFound = (k == maxOnbeatSimplification);
									errorMsg += "\nsimplificationFound = "+simplificationFound; 
									
								}
							}
						}
						// ** CHECK CONDENSATION OF DISPLAY DURATIONS ** //
						if (restDisplayDur != restActualDur && !simplificationFound) {
							for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
								var p = possibleOnbeatSimplificationDurs[k];
								//errorMsg += "\n(onbeat disp) looking for match: "+restDisplayDur+" = "+p+" = "+(restDisplayDur==p); 
								
								if (restDisplayDur == p) {
									if (k > possibleSimplification) {
										
										//errorMsg += "\nfound a possibleSimplification display dur on beat = "+k; 
										
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
					} else {
	
						// **** OFFBEAT REST CONDENSATION **** //

						// CHECK ACTUAL DURS
						for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
							var canBeCondensed = true;
							var p = possibleOffbeatSimplificationDurs[k];
							
							// don't simplify anything tied over a beat that is less than a crotchet
							if (p == dottedcrotchet) canBeCondensed = !isCompound && startFrac == quaver && timeSigDenom <= 2;
							if (p == crotchet) canBeCondensed = false;
							if (p < crotchet) canBeCondensed = sameBeat;
							if (canBeCondensed && isCompound && restActualDur == beatLength * 2 / 3) canBeCondensed = false;
							//errorMsg += "\n(offbeat act) looking for match: "+restActualDur+" = "+p+" = "+(restActualDur==p); 
							
							if (restActualDur == p && canBeCondensed) {
								if (k > possibleSimplification) {
									
									//errorMsg += "\nfound a possibleSimplification actual dur off beat = "+k; 
									
									possibleSimplification = k;
									possibleSimplificationLastRestIndex = j;
									possibleSimplificationFirstRestIndex = i;
									simplificationIsOnBeat = false;
									simplificationFound = true;
									maxSimplificationFound = (k == maxOffbeatSimplification);
								}
							}
						}
		
						// CHECK DISPLAY DURS
						if (restDisplayDur != restActualDur && !simplificationFound) {
							for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
								var p = possibleOffbeatSimplificationDurs[k];
								//errorMsg += "\n(offbeat disp) looking for match: "+restDisplayDur+" = "+p+" = "+(restDisplayDur==p); 
								
								if (restDisplayDur == p) {
									if (k > possibleSimplification) {
										
										//errorMsg += "\nfound a possibleSimplification display dur off beat = "+k; 
										
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
			errorMsg += "\nFinal: simplificationFound = "+simplificationFound; 
			
			if (simplificationFound) {
				errorMsg += "\nfinal simplification chosen = "+possibleSimplification; 
				
				var exception = isPickupBar && possibleSimplification > 6;
				if (simplificationIsOnBeat) {
					if (!exception) {
						var simplificationText = possibleOnbeatSimplificationLabels[possibleSimplification];
						var tempText = (restDisplayDur == dottedcrotchet && !isCompound)? '[Suggestion] ' : '';
						var theArray = [];
						for (var i = possibleSimplificationFirstRestIndex; i <= possibleSimplificationLastRestIndex; i++) {
							theArray.push(rests[i]);
							errorMsg += "\nPushing rest "+i; 
							
						}
						addError(tempText+'Condense rests as a '+simplificationText+' by selecting them and pressing ‘delete’.\n(Ignore if using rest to show placement of fermata/etc.)',theArray);
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
					if (p == dottedquaver && (lastRestDur != quaver || totalNumRests > 2)) {
						addError ('Spell as a semiquaver followed by a quaver.',theArray);
					} else {
						addError(tempText+'Condense rests as a '+simplificationText+' by selecting them and pressing ‘delete’.\n(Ignore if using rest to show placement of fermata/etc.)',theArray);
					}
				}
			}
		}		
	}
	
	function checkTieSimplifications (noteRest) {
		
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
			var tieIsOnBeat = !startFrac;
			var tieStartedOnBeat = !(startPos % beatLength);
			var prevNoteRest = i == 0 ? getPreviousNoteRest(startNote) : null;
			var prevIsNote = (prevNoteRest == null) ? false : prevNoteRest.type == Element.CHORD;

			// do onbeat simplifications
			for (var j = i+1; j < tiedNotes.length && !maxSimplificationFound; j++) {	
				var tempNote = tiedNotes[j];
				var tempDisplayDur = tempNote.duration.ticks;
				var tempActualDur = tempNote.actualDuration.ticks;
				var tempPos = getPositionInBar(tempNote);
				var tempBeat = Math.trunc(tempPos/beatLength);
				var sameBeat = (tempBeat == startBeat);
				var tempNextItem = getNextNoteRest(tempNote);
				var tempNextItemIsNote = (tempNextItem == null) ? false : tempNextItem.type == Element.CHORD;
				tiedActualDur += tempActualDur;
				tiedDisplayDur += tempDisplayDur;
				var checkDisplayDur = tiedDisplayDur != tiedActualDur;
				var canBeSimplified, simplification;
				
				if (tieIsOnBeat) {
					
					// ** CHECK ONBEAT TIE SIMPLIFICATIONS ** //
					for (var k = 0; k < possibleOnbeatSimplificationDurs.length; k++) {
						canBeSimplified = true;
						simplification = possibleOnbeatSimplificationDurs[k];
						if (tiedActualDur == simplification) {
							if (isCompound) {
								canBeSimplified = (tiedActualDur >= beatLength) && !(tiedActualDur % beatLength); // can be simplified if it's a multiple of the beat length
							} else {
								if (tiedActualDur == dottedcrotchet && !(timeSigNum % 2)) canBeSimplified = !(startBeat % 2); // for 4/4, 6/4 etc — can be simplified if it's on an even numbered beat (0, 2, etc)
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
							if (isCompound) {
								canBeSimplified = simplification < beatLength;
							} else {
								canBeSimplified = simplification < (beatLength * 2);
							}
							if (canBeSimplified) {
								if (simplification == dottedcrotchet && !isCompound) canBeSimplified = (prevNoteRest == null) ? false : prevNoteRest.duration.ticks == quaver;
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
					if (checkDisplayDur && !maxSimplificationFound) {
						for (var k = 0; k < possibleOffbeatSimplificationDurs.length; k++) {
							simplification = possibleOffbeatSimplificationDurs[k];
							if (tiedDisplayDur == simplification && k > possibleSimplification) {
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
				addError (tempText+'These tied notes can be simplified to a '+simplificationText+'.\n(Ignore if using tie to show placement of fermata etc.)', theArray);
			} else {
				var simplificationText = possibleOffbeatSimplificationLabels[possibleSimplification];
				var tempText = '';
				if (tiedDisplayDur == dottedcrotchet && !isCompound) tempText = '[Suggestion] ';
				var theArray = [];
				for (var i = possibleSimplificationFirstNoteIndex; i <= possibleSimplificationLastNoteIndex; i++) {
					theArray.push(tiedNotes[i]);
				}
				addError(tempText+'These tied notes can be simplified to a '+simplificationText+'.\n(Ignore if using tie to show placement of fermata etc.)', theArray);
			}
		} // possSimp > -1
	}
	
	function checkBeamBrokenError (noteRest) {		
		// is this note able to be beamed?
		if (displayDur >= crotchet) return;
		errorMsg += "\n\nChecking beam broken";
		var isOnlyNoteInBeat = false;
		
		if (beamBeat == -1) {
			beamBeat = noteStartBeat;
			haveHadFirstNote = false;
		} else {
			if (beamBeat != noteStartBeat) haveHadFirstNote = false;
		}
		var isLastItemInBeat = nextItemBeat != noteStartBeat;
		errorMsg += "\nisLastItemInBeat = "+isLastItemInBeat+"; nextItemBeat = "+nextItemBeat+" noteStartBeat "+noteStartBeat;
		
		var acceptableBeamSettings = [];
		var isLastRestBeforeNote = false, isFirstNoteInBeat = false, isLastNoteInBeat = false, isMiddleNoteInBeat = false, isLastRestsInBeat = false;

		// The following beam settings will give us the correct beaming
		// ** FIRST RESTS IN THE BEAT BEFORE A NOTE — can be set to anything, except for ...
		if (isRest && !haveHadFirstNote && (!nextItemIsNote || isLastItemInBeat)) {
			errorMsg += "\nfirst rests in beat ";
			return;
		}
		
		// ** ...the REST IMMEDIATELY BEFORE FIRST NOTE — can be set to only 0 or 1 ** //
		if (isRest && nextItemIsNote && !haveHadFirstNote && !isLastItemInBeat) {
			if (nextDisplayDur >= crotchet) return; // if next note doesn't have a beam, it doesn't matter
			acceptableBeamSettings = [Beam.AUTO, Beam.NONE];
			isLastRestBeforeNote = true;
			errorMsg += "\nlast rest before note";
			
			//errorMsg += "\nAcc beams = "+Beam.AUTO+" "+Beam.NONE+"; actual "+currentBeamMode+"; includes? "+acceptableBeamSettings.includes(currrentBeamMode);
		}
				
		// ** FIRST NOTE IN A BEAT — set to anything but not 1 ** //
		if (isNote && !haveHadFirstNote) {
			if (isLastItemInBeat) {
				errorMsg += "\nLast item in beat so returning";
				return; // don't beam if it's the only note in the beat
			}
			if (nextDisplayDur >= crotchet) return; // if next note doesn't have a beam, it doesn't matter
			haveHadFirstNote = true;
			acceptableBeamSettings = [Beam.AUTO,Beam.BEGIN,Beam.BEGIN32,Beam.BEGIN64,Beam.MID];
			isFirstNoteInBeat = true;
			isOnlyNoteInBeat = true;
			errorMsg += "\nfirst note in beat — isOnlyNoteInBeat="+isOnlyNoteInBeat;
		}
		
		if (!isLastRestBeforeNote) {
			if (isNote && nextItemIsNote && nextItemBeat == noteStartBeat && !isFirstNoteInBeat) {
				isMiddleNoteInBeat = true;
			} else {
				isLastNoteInBeat = isNote;
				isLastRestsInBeat = isRest;
				cursor2.rewindToTick(cursor.tick);
				if (cursor2.next()) {
					var withinBeat = true;
					var tempNote = cursor2.element;
					while (tempNote != null && cursor2.measure.is(currentBar) && withinBeat ) {
						var tempEnd = (cursor2.tick - barStart) + tempNote.duration.ticks - 1; // end just before
						var tempEndBeat = Math.trunc(tempEnd / beatLength);
						withinBeat = tempEndBeat == noteStartBeat;
						errorMsg += "\nwithinbeat = "+tempEnd+" "+tempEndBeat+" "+withinBeat;
						
						if (withinBeat) {
							var tempNoteIsRest = tempNote.type == Element.REST;
							// found a rest looking forwards
							if (!tempNoteIsRest) {
								isLastRestsInBeat = false;
								isLastNoteInBeat = false;
								if (isFirstNoteInBeat) {
									errorMsg += "\nFound another note, so not only note in beat";
									isOnlyNoteInBeat = false;
								} else {
									isMiddleNoteInBeat = true;
								}
							}
							if (cursor2.next()) {
								tempNote = cursor2.element
							} else {
								tempNote = null;
							}
						}
					}
				}
			}
		}
		if (isOnlyNoteInBeat) {
			acceptableBeamSettings = [Beam.AUTO,Beam.NONE];
		}
		if (isMiddleNoteInBeat) {
			// Middle note — set to 0, 3, 4 or 5
			errorMsg += "\nmiddle note in beat";
			
			acceptableBeamSettings = [Beam.AUTO,Beam.BEGIN32,Beam.BEGIN64,Beam.MID];
			if (!hasBeam) {
				addError("This note should be beamed to the next note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
				return;
			}
		}
		if (isLastNoteInBeat && !isOnlyNoteInBeat) {
			errorMsg += "\nlast note in beat";
			
		// Last note in a beat — anything except 1 or 2
			acceptableBeamSettings = [Beam.AUTO,Beam.BEGIN32,Beam.BEGIN64,Beam.MID];

			if (!hasBeam) {
				addError("This note should be beamed to the previous note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
				return;
			}
		}
		if (isLastRestsInBeat) {
			errorMsg += "\nlast rests in beat";
			
			// Last rests in a beat — set to 0, 1 or 2
			acceptableBeamSettings = [Beam.AUTO,Beam.NONE,Beam.BEGIN];
		}
		
		var correctlyBeamed = false;
		var beamMode = hasBeam ? currentBeamMode : Beam.NONE;
		correctlyBeamed = acceptableBeamSettings.includes(beamMode);
		errorMsg += "\nbeamMode is "+beamMode;
		if (!correctlyBeamed) {
			errorMsg += "\nNot correctly beamed";
			if (isNote) {
				if (hasBeam) {
					if (beamMode == Beam.BEGIN || beamMode == Beam.BEGIN32 || beamMode == Beam.BEGIN64) {
						addError("This note should be beamed to the previous note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
					} else {
						addError("This note should be beamed to the next note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
					}
				} else {
					if (isFirstNoteInBeat) addError("This note should be beamed to the next note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
					if (isMiddleNoteInBeat) addError("This note should be beamed to the previous and next notes\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
					if (isLastNoteInBeat) addError("This note should be beamed to the next note\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
					
				}
			} else {
				if (hasBeam) {
					if (beamMode == Beam.BEGIN || beamMode == Beam.BEGIN32 || beamMode == Beam.BEGIN64) {
						addError("This rest should be under a beam\nSet the ‘Beam type’ property of this note to AUTO",noteRest);
					} else {
						addError("Rest should not break beam of previous note\nSet the ‘Beam type’ property of this note to ‘Join beams’",noteRest);
					}
				} else {
					addError("This rest should not break beam of previous note\nSet the ‘Beam type’ property of this note to ‘AUTO’",noteRest);
				}
			}
		} // end if beamBroken
	}
	
	function checkBeamedToNotesInNextBeat (noteRest) {
		var beamedToNext = false;
		var lastNoteInBeat = nextItemBeat > noteStartBeat;
		var beamTriesToGoForwards = currentBeamMode == Beam.MID || currentBeamMode == Beam.BEGIN;
		var nextBeamTriesToGoBack = nextBeamMode == Beam.MID || nextBeamMode == Beam.END;
		
		//errorMsg += "\n*** CHECKING BEAMED TO NOTES IN NEXT BEAT ERROR ***";
		//if (lastNoteInBeat) errorMsg += "\nBEAM: "+currentBeamMode+" "+nextBeamMode;
		
		// ADD — 
		if (hasBeam && lastNoteInBeat && nextItem && beamTriesToGoForwards && nextBeamTriesToGoBack) {
			
			//errorMsg += "\n beamed to notes in next beat"
			
			// ** EXCEPTION WHERE QUAVERS ARE BEAMED TOGETHER IN 4/4 ** //
			var exception1 = isNote && soundingDur == quaver && prevSoundingDur == quaver && nextItemDur == quaver && nextNextItemDur == quaver && nextNextItemIsNote;
			//var exception2 = barLength == semibreve && noteStartBeat == 1;
			if ( !exception1 ) {
				if (isNote) {
					addError( "Note should not be beamed to notes in next beat\nSet the ‘Beam type’ property of this note and the following to AUTO",noteRest);
				} else {
					addError( "Rest should not be included in beam group of next beat\nSet the ‘Beam type’ property of this note to AUTO", noteRest);
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
			var elementObject = errorObjects[i]; // this can be a single object, or an array of objects
			var element = elementObject;
			var isArray = Array.isArray(element);
			var elementArray = [elementObject];
			if (isArray) {
				elementArray = elementObject;
				element = elementArray[0];
			}
					
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
			var eType = isString ? null : element.type;
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
			
			for (var j in elementArray) {
				
				var elementToColour = elementArray[j];
				// colour the element
				if (elementToColour !== "pagetop" && elementToColour !== "top") {
					if (elementToColour.type == Element.CHORD) {
						elementToColour.color = "hotpink";
						for (var k=0; k<elementToColour.notes.length; k++) elementToColour.notes[k].color = "hotpink";
					} else {
						//if (elementToColour.type == Element.TIMESIG) errorMsg += "\ncoloring time sig "+element.timesigNominal.str;
						elementToColour.color = "hotpink";
					}
				}
			}
		}
		curScore.endCmd();
	}
	
	function deleteAllCommentsAndHighlights () {
		// ** SAVE CURRENT SELECTION ** //
		var s = curScore.selection;
		var isRange = s.isRange;
		var startStaff = 0, endStaff = 0, startTick = 0, endTick = curScore.lastSegment.tick;
		if (isRange) {
			startStaff = s.startStaff;
			endStaff = s.endStaff;
			if (s.startSegment) startTick = s.startSegment.tick;
			if (s.endSegment) endTick = s.endSegment.tick + 1;
		}
		
		// **** GET ALL ITEMS **** //
		selectAll();
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
		// ** RESTORE SELECTION
		if (isRange) {
			curScore.selection.selectRange(startTick,endTick+1,startStaff,endStaff);
		} else {
			curScore.selection.clear();
		}
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
				text: dialog.msg
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
	
	ApplicationWindow {
		id: progress
		title: "PROGRESS"
		property var progressValue: 0
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
			value: 0
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
