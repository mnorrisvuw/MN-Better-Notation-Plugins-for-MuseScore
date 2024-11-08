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

  onRun: {
		if (!curScore) return;
		
		// **** INITIALISE VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var currentBar, segment;
		var numBars, totalNumBars;
		var tiedNotes = [];
		var rests = [];
		var	simplifiedDuration = [];
		var d = division;
		var Semibreve = 4*d;
		var DottedMinim = 3*d;
		var Minim = 2*d;
		var DottedCrotchet = 1.5*d;
		var Crotchet = d;
		var DoubleDottedQuaver = 0.875*d;
		var DottedQuaver = 0.75*d;
		var Quaver = 0.5*d;
		var DottedSemiquaver = 0.375*d;
		var Semiquaver = 0.25*d;
		
		var possibleOnbeatSimplificationDurs = [Semiquaver,DottedSemiquaver,Quaver,DottedQuaver,DoubleDottedQuaver,Crotchet,DottedCrotchet,Minim,DottedMinim,Semibreve];
		var possibleOnbeatSimplificationLabels = ["semiquaver","dotted semiquaver","quaver","dotted quaver","double-dotted quaver","crotchet","dotted crotchet","minim","dotted minim","semibreve"];
		var possibleOffbeatSimplificationDurs = [Semiquaver,DottedSemiquaver,Quaver,DottedQuaver,DoubleDottedQuaver,Crotchet,DottedCrotchet];
		var	possibleOffbeatSimplificationLabels = ["semiquaver","dotted semiquaver","quaver","dotted quaver","double-dotted quaver","crotchet","dotted crotchet"];

		
		dialog.msg = "";
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) {
			// ** SELECT ALL ** //
			curScore.startCmd();
			curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
			curScore.endCmd();
		}
		
		firstStaffNum = curScore.selection.startStaff;
		lastStaffNum = curScore.selection.endStaff;
		dialog.msg+="firstStaffNum= "+firstStaffNum+"; lastStaffNum = "+lastStaffNum;
		
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
		dialog.msg += "\nlastBarNum: "+lastBarNum;
		
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
				dialog.msg += "\nFound a time sig elem: "+ts.timesigNominal.str;
			}
			cursor.next();
		}
		if (timeSigs.length == 0) dialog.msg += "\nDidn't find any time sigs";
		
		numBars = (lastBarNum-firstBarNum)+1;
		totalNumBars = numBars*numStaves;


		// ** OPEN THE PROGRESS DIALOG BOX ** //
		/*
		Sibelius.CreateProgressDialog("Check Rhythmic Notation",1,100);
		if (Sibelius.UpdateProgressDialog(1,"Progress: 1% completed") = 0) {
			Sibelius.DestroyProgressDialog();
			return false;
		}

		Sibelius.ResetStopWatch(1);
		prevTimer = 0;
		progress = 1;
		numBarsProcessed = 0;
		numErrors = 0;
		noteNum = 0;

		ClearCommentsAndColours();
		*/
		
		// **** INITIALISE VARIABLES FOR THE LOOP **** //
		var currentBarNum, currentStaffNum;
		var numBarsProcessed;
		var wasTied;
		var currentTimeSig;
		var prevSoundingDur, prevDisplayDur, prevNoteWasDoubleTremolo;
		var tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;
		var numRests, restCrossesBeat, restStartedOnBeat, isLastRest;
		var prevItemIsNote, prevNoteCount, prevPitch, prevTupletSubDiv;
		var lastNoteInBar, lastRest;
		var numComments, totalDur;
		
		numBarsProcessed = 0;
		
		// **** LOOP THROUGH THE SELECTED STAVES AND THE SELECTED BARS **** //
		// ** NB — lastStaffNum IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //
		for (currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum; currentStaffNum ++) {
			
			//staff = score.NthStaff(currentStaff);

			wasTied = false;
			
			// ** REWIND TO START OF SELECTION ** //
			cursor.filter = Segment.All;
			cursor.rewind(Cursor.SELECTION_START);
			cursor.staffIdx = currentStaffNum;
			cursor2.staffIdx = currentStaffNum;
			cursor.filter = Segment.ChordRest;
			cursor2.filter = Segment.ChordRest;
			currentBar = cursor.measure;
			//dialog.msg += "\ncurrentBar: "+currentBar;
			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
				
				dialog.msg += "\n—————————————————\nBAR "+currentBarNum;
				
				// ** UPDATE PROGRESS MESSAGE ** //
								
				// **** GET TIME SIGNATURE **** //
				currentTimeSig = currentBar.timesigActual;
				var timeSigNum = currentTimeSig.numerator;
				var timeSigDenom = currentTimeSig.denominator;
				var barStart = currentBar.firstSegment.tick;
				var barLength = currentBar.lastSegment.tick - barStart;
				
				dialog.msg += "\nbarStart = "+barStart+"; barLength = "+barLength;
				
				var beatLength = Crotchet;
				var isPickupBar = false;
				var expectedDuration = timeSigNum * (Semibreve/timeSigDenom);
				dialog.msg += "\nexpectedDur = "+expectedDuration;
				
				if (currentBarNum == 1 && expectedDuration != barLength) isPickupBar = true;
				var canCheckThisBar = false;
				var isCompound = false;
				
				if (timeSigDenom == 8) {
					isCompound = !(timeSigNum % 3);
					if (isCompound) beatLength = DottedCrotchet;
				}
				if (timeSigDenom == 4 || timeSigDenom == 2) isCompound = !(timeSigNum % 3) && (timeSigNum > 3);
				canCheckThisBar = ((isCompound && timeSigDenom > 4) || timeSigNum < 5 || !(timeSigNum % 2) || timeSigDenom == 4);
				if (!canCheckThisBar) dialog.msg += "\ncouldn't check this bar as time sig was too batty";
	
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
					prevItemIsNote = false;
					numRests = 0;
					restCrossesBeat = false;
					restStartedOnBeat = false;
					isLastRest = false;
					prevNoteCount = 0;
					prevPitch = 0;
					tieIsSameTuplet = false;
					prevTupletSubDiv = 0;
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
						//dialog.msg += "\ncursorTick = "+cursor.tick;
						dialog.msg += "\nTrack "+track;
						
							// ** LOOP THROUGH EACH VOICE ** //
					
						totalDur = 0;
						//currentBar = cursor.measure;
						var processingThisBar = cursor.element;
						while (processingThisBar) {
							var noteRest = cursor.element;
							var isHidden = !noteRest.visible;
							var isRest = noteRest.type == Element.REST;
							var isNote = !isRest;
							var displayDur = noteRest.duration.ticks;
							var soundingDur = noteRest.actualDuration.ticks;
							var tuplet = noteRest.tuplet;
							if (noteRest.tuplet) {
								var tupletNumerator = noteRest.tuplet.actualDuration.numerator;
								dialog.msg += "\nisRest = "+isRest+"; dur = "+displayDur+"; sounding = "+soundingDur;
								
							} else {
								dialog.msg += "\nisRest = "+isRest+"; dur = "+soundingDur;
								
							}
							var noteStart = cursor.tick - barStart;
							var noteEnd = noteStart + soundingDur;
							dialog.msg += "\nnoteStart = "+noteStart+"; noteEnd = "+noteEnd;
							/*var nextItemPos;
							cursor2.rewindToTick(pos);
							//if (cursor2) dialog.msg += "\n1 cursor2Tick = "+cursor2.tick;
							
							cursor2.next();
							//if (cursor2) dialog.msg += "\n2 cursor2Tick now = "+cursor2.tick;
							
							var actualDur;
							
							if (cursor2) {
								nextItemPos = cursor2.tick;
								actualDur = nextItemPos - pos;
								dialog.msg += "\ncursor2: "+cursor2.tick;
							} else {
								actualDur = barLength - pos;
								dialog.msg += "\nbarLength: "+barLength;
							}
								
							totalDur = totalDur + actualDur;
							dialog.msg += "\nactualDur = "+actualDur+"; totalDur = "+totalDur;*/
						
							if (isHidden) {
								numRests = 0;
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
							}
							// ** GET ALL THE VALUES FOR THE VARIOUS PARAMETERS ** //
							
							var isTied = false;
							var lastNoteInTie = false;
							var noteStartFrac = noteStart % beatLength;
							var noteStartBeat = Math.trunc(noteStart/beatLength);
							var noteEndFrac = noteEnd % beatLength;
							var noteEndBeat = Math.trunc(noteEnd/beatLength);
							var noteFinishesBeat = !noteEndFrac;
							var numBeatsHidden = noteEndBeat-noteStartBeat-noteFinishesBeat;
							var noteHidesBeat = numBeatsHidden > 0;
							var isOnTheBeat = !noteStartFrac;
							var hasPause = false; // TO FIX
							var isBarRest = isRest && soundingDur == barLength;
							var isManuallyEnteredBarRest = isBarRest && noteRest.durationType.type < 14;
							
							
							dialog.msg += "\nnoteStartFrac = "+noteStartFrac+"; noteStartBeat = "+noteStartBeat+"\nnoteEndFrac = "+noteEndFrac+"; noteEndBeat = "+noteEndBeat+"\nnoteFinishesBeat = "+noteFinishesBeat+"; numBeatsHidden = "+numBeatsHidden;
							
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
							// hasPause = noteRest.GetArticulation(TriPauseArtic) or noteRest.GetArticulation(PauseArtic) or noteRest.GetArticulation(SquarePauseArtic);
							// nextItemHasPause = false;
							//nextItemIsHidden = false;
							if (beam) dialog.msg += "\nBEAM = "+noteRest.beamMode;
							var hasBeam = beam != null;
							
							var noteTypeString = "Note";
							if (isRest) noteTypeString = "Rest";
							
							// ** ————————————————————————————————————————————————— ** //
							// **   CHECK 1: CHECK FOR MANUALLY ENTERED BAR REST    ** //
							// ** ————————————————————————————————————————————————— ** //
							
							if (isManuallyEnteredBarRest) showError ("Bar rest has been manually entered, and is therefore incorrectly positioned.\nSelect the bar, and press delete to revert to a correctly positioned bar rest.",noteRest);
							
							// ** ————————————————————————————————————————————————— ** //
							// **         CHECK 2: DOES THE NOTE HIDE THE BEAT??    ** //
							// ** ————————————————————————————————————————————————— ** //

							// check special case rests
							var hidingBeatError = noteHidesBeat && !isBarRest; // make a temp version
							if (hidingBeatError) {
								if (isOnTheBeat) {
									// ON THE BEAT RESTS
									if (isRest) {
										// dotted minim in 4/4 (anywhere)
										if (timeSigNum == 4 && timeSigDenom == 4) {
											if (soundingDur == DottedMinim) hidingBeatError = !hasPause;
											if (soundingDur == Minim) hidingBeatError = (noteStartBeat == 1) && !hasPause;
										}
				
										// dotted minim in 12/8
										if (timeSigNum == 12 && timeSigDenom == 8) {
											if (soundingDur == DottedMinim) hidingBeatError = (noteStartBeat == 1) && !hasPause;
										}
			
										// minim in 3/4 (anywhere)
										if (timeSigNum == 3 && timeSigDenom == 4) {
											if (soundingDur == Minim) hidingBeatError = !hasPause;
										}
								
										// onbeat dotted crotchet in 4
										if (!isCompound && timeSigDenom > 2) {
											if (soundingDur == DottedCrotchet) hidingBeatError = !hasPause;
										}
								
										if (timeSigNum == 5 && timeSigDenom == 4) hidingBeatError = (soundingDur == Semibreve);
									} else {
										if (isCompound) {
											if (soundingDur == beatLength * 2 || soundingDur == beatLength * 4) hidingBeatError = false;
					
										} else {
									
											// no semibreves in 5/4
											if (timeSigNum == 5 && timeSigDenom == 4) {
												hidingBeatError = (soundingDur == Semibreve);
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
											if ((noteStart == Quaver || noteStart == Minim+Quaver) && (soundingDur == Crotchet || soundingDur == DottedCrotchet) && isNote) {
												hidingBeatError = false; // OK to use crotchet or dotted crotchet,  rest or dotted rest here
											}
										} else {
											if ((noteStartFrac == Quaver || noteStartFrac == 0) && (soundingDur == Crotchet || soundingDur == DottedCrotchet) && isNote) {
												hidingBeatError = false; // OK to use crotchet or dotted crotchet,  rest or dotted rest here
											}
										}
									}

									// ** EXCLUDE LONG TUPLET
									//if (tupletPlayedDuration > Crotchet) hidingBeatError = false;
									// TO FIX

									// ** EXCLUDE DOUBLE TREMOLOS ** //
									//if (isDoubleTremolo) hidingBeatError = false;
									// TO FIX

									//if (actualDur == prevActualDur && prevNoteWasDoubleTremolo) hidingBeatError = false;
								}
								
								if (hidingBeatError) {
									if (isNote) {
										if (timeSigNum == 5 && timeSigDenom == 4 && soundingDur == Semibreve) {
											showError("Never use a semibreve in 5/4\nsplit the note to show the bar division of either 2+3 or 3+2",noteRest);
										} else {
											if (numBeatsHidden == 1) {
												showError("Note hides beat "+(noteStartBeat + 2)+"\nsplit with a tie",noteRest);
											} else {
												var errStr = "Note hides beats ";

												for (var i = 0; i < numBeatsHidden; i++) {
													dialog.msg += "\ni="+i+"; nbh="+numBeatsHidden;
													var beatStr = (noteStartBeat+2+i).toString();
													errStr += beatStr;
													dialog.msg += "\nerrStr="+errStr;
													
													if (i < numBeatsHidden - 2) {
														errStr += ", ";
														dialog.msg += "\nerrStr="+errStr;
														
													} else {
														if (i == numBeatsHidden - 2) {
															errStr += " + ";
															dialog.msg += "\nerrStr="+errStr;
															
														} else {
															errStr += " — split with a tie";
															dialog.msg += "\nerrStr="+errStr;
															
														}
													}
												}
												dialog.msg += "\nFinal errStr=‘"+errStr+"’";
												
												showError(errStr,noteRest);
											}
										}
									} else {
										if (timeSigNum == 5 && timeSigDenom == 4 && soundingDur == Semibreve) {
											showError("Never use a semibreve rest in 5/4\nsplit the rest to show the bar division of either 2+3 or 3+2",noteRest);
										} else {
											showError( "Rest hides beat "+(noteStartBeat + 2)+" — split into two rests",noteRest);
											if (numBeatsHidden = 1) {
												showError( "Rest hides beat "+(noteStartBeat + 2)+" — split into two rests",noteRest);
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
												showError(errStr,noteRest);
											}
										}
									}
								}
							} // end if hidesBeat
									
							// ** ————————————————————————————————————————————————— ** //
							// **       CHECK 3: NOTE/REST SHOULD NOT BREAK BEAM    ** //
							// ** ————————————————————————————————————————————————— ** //
						
							
							var thisNoteAndPrevAreLessThanCrotchets = displayDur < Crotchet && prevDisplayDur < Crotchet && prevItemIsNote;
							var restAtEndOfBeat = isRest && noteFinishesBeat;
							var beamBroken = !isOnTheBeat && !hasBeam;
							dialog.msg += "\nbeamBroken = "+beamBroken;


							if (beamBroken && thisNoteAndPrevAreLessThanCrotchets && !restAtEndOfBeat) {
								// go through rest of beat looking for a note
								//trace("Here 1");
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
												dialog.msg += "Here 3: tempPos = "+tempPos+"; tempBeat = "+tempBeat;
												dontBreakBeam = tempNote.actualDuration.ticks < Crotchet && tempBeat == noteStartBeat;
												var tempNoteIsRest = tempNote.type == Element.REST;
												if (tempNoteIsRest) {
													cursor2.next();
													if (!cursor2.measure.is(currentBar)) {
														tempNote = null;
														tempBeat = startBeat + 1;
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
										showError("Note should be beamed to previous note",noteRest);
									} else {
										showError("Rest should not break beam of previous note",noteRest);
									}
								}
							} // end if beamBroken
							
							
							if (cursor.next()) {
								processingThisBar = cursor.measure.is(currentBar);
							} else {
								processingThisBar = false;
							}
							//wasTied = isTied;	
							//if (!isTied) {
								//tiedActualDur = 0;
								//tiedDisplayDur = 0;
								//}

							prevSoundingDur = soundingDur;
							prevDisplayDur = displayDur;
							prevItemIsNote = isNote;
							//prevNoteWasDoubleTremolo = isDoubleTremolo;
							//prevNoteCount = noteCount;
							prevPitch = pitch;
							//prevTupletSubdiv = tupletSubdiv;
						} // end while processingThisBar
					} // end track loop
				} // end if canCheckThisBar
				
				if (currentBar) {
					dialog.msg += "\nTrying to get next measure";
					currentBar = currentBar.nextMeasure;
				}
				if (!currentBar) dialog.msg += "\nnextMeasure failed";

				numBarsProcessed ++;
				
				dialog.msg += "\nProcessed "+numBarsProcessed+" bars";
				
			} // end for currentBarNum	
		} // end for currentStaff
		
		dialog.show();
	}
	
	function showError (text, element) {
		curScore.startCmd()
		
		// add a text object at the location where the element is

		var comment = newElement(Element.STAFF_TEXT);
		comment.text = text;
		
		// style the text object
		comment.frameType = 1;
		comment.framePadding = 0.6;
		comment.frameWidth = 0.2;
		comment.frameBgColor = "yellow";
		comment.frameFgColor = "black";
		comment.fontSize = 8.0;
		comment.fontFace = "Helvetica"
		comment.autoplace = false;
		
		if (element === "top") {
			var firstMeasure = curScore.firstMeasure;
			var pagePos = firstMeasure.pagePos;
			element = firstMeasure;
			comment.offsetY = 4.0-pagePos.y;
			
		} else {
			
			var objectHeight = element.bbox.height;
			comment.offsetY = element.posY - 5.0 - objectHeight;
			comment.offsetX = element.posX;
			
		}
		var segment = element.parent;
		var tick = segment.tick;
		
		// add text object to score
		var cursor = curScore.newCursor();
		cursor.rewindToTick(tick);
		cursor.add(comment);
		
		// style the element
		element.color = "hotpink";
		curScore.endCmd();
	}
	
	ApplicationWindow {
		id: dialog
		title: "WARNING!"
		property var msg: "Warning message here."
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

}
