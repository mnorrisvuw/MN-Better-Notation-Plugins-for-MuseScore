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
	

  onRun: {
		if (!curScore) return;
		
		// **** INITIALISE VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		var cursor = curScore.newCursor();
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var currentBar, segment;
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) {
			// ** SELECT ALL ** //
			curScore.startCmd();
			curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
			curScore.endCmd();
		}
		
		firstStaffNum = curScore.selection.startStaff;
		lastStaffNum = curScore.selection.endStaff;
		
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
		
		dialog.msg = "";


/*		numBars = (lastBarNum-firstBarNum)+1;
		numStaves = lastStaffNum-firstStaffNum+1;
		totalNumBars = numBars*numStaves;
		comment = CreateArray();
		commentPosition = CreateArray();
		tiedNotes = CreateSparseArray();
		rests = CreateSparseArray();
		simplifiedDuration = CreateSparseArray();

		possibleOnbeatSimplificationDurs = CreateSparseArray(Semiquaver,DottedSemiquaver,Quaver,DottedQuaver,224,Crotchet,DottedCrotchet,Minim,DottedMinim,Semibreve); // semibreve, dotted minim, minim, dotted crotchet, crotchet
		possibleOnbeatSimplificationLabels = CreateSparseArray("semiquaver","dotted semiquaver","quaver","dotted quaver","double-dotted quaver","crotchet","dotted crotchet","minim","dotted minim","semibreve");
		possibleOffbeatSimplificationDurs = CreateSparseArray(Semiquaver,DottedSemiquaver,Quaver,DottedQuaver,224,Crotchet,DottedCrotchet);
		possibleOffbeatSimplificationLabels = CreateSparseArray("semiquaver","dotted semiquaver","quaver","dotted quaver","double-dotted quaver","crotchet","dotted crotchet"); */

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
		var currentBarNum = firstBarNum;
		for (var currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum+1; currentStaffNum ++) {
			/*
			staff = score.NthStaff(currentStaff);
			wasTied = false;
			*/
			
			while (currentBar) {

		
		// ** LOOP THROUGH THE SELECTED STAVES AND THE SELECTED BARS ** //

			
//			for currentBar = firstBarNum to (lastBarNum+1) {
				/*
				numBarsProcessed = numBarsProcessed + 1;
				// ** UPDATE PROGRESS MESSAGE ** //
				timer = Sibelius.GetElapsedSeconds(1);
				if (timer != prevTimer) {
					prevTimer = timer;

					progressRatio = (numBarsProcessed)/(totalNumBars*1.0);
					progress = RoundUp(progressRatio*24.0)+1;
					continue = Sibelius.UpdateProgressDialog(progress,"Progress: "&progress&"% completed");
					if (continue = False) {
						Sibelius.DestroyProgressDialog();
						return false;
					}
				}
				*/
		//dialog.msg += "\nbar num = "+barNum;
				segment = currentBar.firstSegment;
				while (segment && segment.tick < lastTickInSelection) {
					var startTrack = currentStaffNum * 4;
					var endTrack = startTrack + 4;
					var canCheckThisBar = false;
		
				/*
		
				// ** GET INFO ON THE CURRENT TIME SIGNATURE ** //
				ts = systemstaff.CurrentTimeSignature(currentBar);
				timeSigNum = ts.Numerator;
				timeSigDenom = ts.Denominator;
				barLength = bar.Length;
				beatLength = Crotchet;
		
				isPickupBar = false;
				expectedDuration = timeSigNum * (Semibreve/timeSigDenom);
				//trace("expectedDUr = "&expectedDuration&" = timeSigNum ("&timeSigNum&") * (1024/"&timeSigDenom&")");
				if (currentBar = 1) {
					if (expectedDuration != barLength) {
						isPickupBar = true;
					}	
				}
				*/

				/*
				isCompound = false;
				if (timeSigDenom = 8) {
					isCompound = (timeSigNum % 3) = 0;
					if (isCompound) {
						beatLength = DottedCrotchet;
					}
				}
				if (timeSigDenom = 4) {
					isCompound = ((timeSigNum % 3) = 0) and (timeSigNum > 3);
				}
				if (timeSigDenom = 2) {
					isCompound = ((timeSigNum % 3) = 0) and (timeSigNum > 3);
				}
				if (isCompound and timeSigDenom > 4) {
					// we don"t triple the beat length for 6/4, etc
					canCheckThisBar = true;
				} else {
					if (timeSigNum < 5 or (timeSigNum % 2 = 0) or (timeSigDenom = 4)) {
						canCheckThisBar = true;
					}
				}
				*/

				// ** INITIALISE PARAMETERS ** //
				/*
				prevActualDur = 0;
				prevDisplayDur = 0;
				prevNoteWasDoubleTremolo = false;
				numComments = 0;
				tiedActualDur = 0;
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
				*/

				// ** LOOP THROUGH ALL THE NOTERESTS IN THIS BAR ** //
					if (canCheckThisBar) {
						for (var track = startTrack; track < endTrack; track++) {					
				
		
					// ** LOOP THROUGH EACH VOICE ** //
						
						/*
						totalDur = 0;
						*/
						// ** LOOP THROUGH EACH NOTEREST ** //
						//for each NoteRest noteRest in bar {
							/*
							voice = noteRest.VoiceNumber;
							*/
							
							//if (voice = currentVoice) {
		
								// ** IS THE NOTE HIDDEN? ** //
								/*
								isHidden = noteRest.Hidden;
								pos = noteRest.Position;
								nextItem = noteRest.NextItem(voice,"NoteRest");
						
								if (nextItem == null) {
									actualDur = bar.Length - pos;
								} else {
									nextItemPos = nextItem.Position;
									actualDur = nextItemPos - pos;
								}
								totalDur = totalDur + actualDur;
								*/
								
							//	if (isHidden) {
									
									/*
									numRests = 0;
									restCrossesBeat = false;
									restStartedOnBeat = false;
									isLastRest = false;
									*/
									
						//		} else {
									
									// noteNum = noteNum + 1;
				
									// ** GET ALL THE VALUES FOR THE VARIOUS PARAMETERS ** //
									/*
									noteCount = noteRest.NoteCount;
									isNote = noteCount > 0;
									isRest = noteCount = 0;
									tupletPlayedDuration = 0;
									tuplet = noteRest.ParentTupletIfAny;
									isTuplet = tuplet != null;
									tupletSubdiv = 0;
									if (isTuplet) tupletSubdiv = tuplet.Unit / tuplet.Left;
									if (isTuplet) tupletPlayedDuration = tuplet.PlayedDuration;
									isTied = false;
									lastNoteInTie = false;
									displayDur = noteRest.Duration;
									posFrac = pos%beatLength;
									isAcc = noteRest.IsAcciaccatura or noteRest.IsAppoggiatura;
									isDoubleTremolo = noteRest.DoubleTremolos > 0;
									isOnTheBeat = (posFrac = 0);
									beam = noteRest.Beam;	
									nextNextItem = null;
									nextNextItemDur = 0;
									nextItemIsNote = false;
									nextNextItemIsNote = false;
									nextItemNoteCount = 0;
									nextItemPitch = 0;
									pitch = 0;
									if (isNote) pitch = noteRest.Highest.Pitch;
									hasPause = noteRest.GetArticulation(TriPauseArtic) or noteRest.GetArticulation(PauseArtic) or noteRest.GetArticulation(SquarePauseArtic);
									nextItemHasPause = false;
									nextItemIsHidden = false;
									*/
									
									// ** CALCULATE INFO ON THE NEXT ITEM IN THE BAR ** //
									/*
									if (nextItem = null) {
										nextItemIsAcc = false;
										beatEnd = bar.Length;
										nextItemDur = 0;
										nextBeam = 0;
										nextNextItem = null;
										lastNoteInBar = true;
									} else {
										nextItemHasPause = nextItem.GetArticulation(TriPauseArtic) or nextItem.GetArticulation(PauseArtic) or nextItem.GetArticulation(SquarePauseArtic);
										nextItemIsHidden = nextItem.Hidden;
										beatEnd = nextItem.Position;
										nextItemIsNote = (nextItem.NoteCount) > 0;
										if (nextItemIsNote) nextItemIsAcc = nextItem.IsAcciaccatura or nextItem.IsAppoggiatura;
										nextItemDur = nextItem.Duration;
										nextItemNoteCount = nextItem.NoteCount;
										nextItemIsRest = (nextItemNoteCount = 0);
										if (not nextItemIsRest) nextItemPitch = nextItem.Highest.Pitch;
										nextBeam = nextItem.Beam;
										nextNextItem = nextItem.NextItem(voice,"NoteRest");
										if (nextNextItem != null) {
											nextNextItemDur = nextNextItem.Duration;
											nextNextItemIsNote = (nextNextItem.NoteCount) > 0;
										}
									}	
									*/
				
									/*
									beatEndFrac = beatEnd%beatLength;
									startBeat = RoundDown(pos/beatLength);
									endBeat = RoundDown(beatEnd/beatLength);
									numBeatsHidden = endBeat-startBeat;
									noteFinishesBeat = (beatEndFrac = 0);
									if (noteFinishesBeat) numBeatsHidden = numBeatsHidden - 1;
									if (isNote) {
										noteTypeString = "Note";
									} else {
										noteTypeString = "Rest";
									}
									*/
				
									// ** GET INFO ON THE TIE ** //
									// ** NEED TO SET THE PARAMETERS ISTIED, LASTNOTEINTIE, WASTIED ** //
									
									/*
									if (isNote and nextItem != null and nextItemIsNote and pitch = nextItemPitch and noteCount = nextItemNoteCount) {
										if (noteRest[0].Tied) {
											notehead = noteRest[0].NoteStyle;
											nextNotehead = nextItem[0].NoteStyle;
											tremNum = noteRest.SingleTremolos;
											nextTremNum = nextItem.SingleTremolos;
											if (notehead = nextNotehead and tremNum = nextTremNum) {
												isTied = not(isAcc) and not(hasPause);
											}
										}
										// ** TIE STARTING ** //
									}*/

									// ** FILL IN THE TIE ARRAY IF WE NEED TO ** //
									/*
									if (isTied) {
										if (tieIndex = 0) {
											tiedNotes.Length = 0;
										}
										tiedNotes[tieIndex] = noteRest;
										tieIndex = tieIndex + 1;
										if (lastNoteInBar or nextItemHasPause) {
											tieIndex = 0;
											lastNoteInTie = true;
										}
									} else {
										if (wasTied) {
											tiedNotes[tieIndex] = noteRest;
											lastNoteInTie = true;
											tieIndex = 0;
										}
									}
									*/
				
									// ** ————————————————————————————————————————————————— ** //
									// **   CHECK 1: CHECK FOR MANUALLY ENTERED BAR REST    ** //
									// ** ————————————————————————————————————————————————— ** //
									
									/*
									isManuallyEnteredBarRest = false;
									if (isRest and (actualDur = bar.Length) and (isHidden = false)) {
										if (isPickupBar) {
											if (actualDur > (Semibreve/timeSigDenom)) {
												if (_addColors) {
													noteRest.Select();
													noteRest.ColorRed = 255;
													noteRest.ColorGreen = 127;
													noteRest.Deselect();
												}
												comment[numComments] = "Split rest to show beats in a pickup bar";
												commentPosition[numComments] = pos;
												numComments = numComments + 1;
											}
										} else {
											if (_addColors) {
												noteRest.Select();
												noteRest.ColorRed = 255;
												noteRest.ColorGreen = 127;
												noteRest.Deselect();
											}
											comment[numComments] = "Bar rest has been manually entered, and is therefore incorrectly positioned. Select the bar, and press delete to revert to a correctly position bar rest.";
											commentPosition[numComments] = pos;
											numComments = numComments + 1;
											isManuallyEnteredBarRest = true;
										}
									}
									*/

									// ** ————————————————————————————————————————————————— ** //
									// **         CHECK 2: DOES THE NOTE HIDE THE BEAT??    ** //
									// ** ————————————————————————————————————————————————— ** //
				
									/*
									noteHidesBeat = false;
									if (noteFinishesBeat) {
										noteHidesBeat = endBeat - startBeat > 1;
										if (noteHidesBeat and currentBar = 23) {
											trace ("noteHidesBeat because endBeat ("&endBeat&") - startBeat ("&startBeat&") > 1");
										}
									} else {
										noteHidesBeat = startBeat != endBeat;
									}
									*/
									
									// ** CHECK FOR BEAMING ISSUES ** //


									// ** ————————————————————————————————————————————————— ** //
									// **       CHECK 3: NOTE/REST SHOULD NOT BREAK BEAM    ** //
									// ** ————————————————————————————————————————————————— ** //
									
									/*
									thisNoteAndPrevAreLessThanCrotchets = displayDur < Crotchet and prevDisplayDur < Crotchet and prevItemIsNote;
									restAtEndOfBeat = isRest and noteFinishesBeat;
									beamBroken = not(isOnTheBeat) and beam < ContinueBeam;


									if (beamBroken and thisNoteAndPrevAreLessThanCrotchets and not(restAtEndOfBeat)) {
										// go through rest of beat looking for a note
										//trace("Here 1");
										dontBreakBeam = true;
										if (not(noteFinishesBeat)) {
											//trace("Here 2");
									
											tempPos = pos;
											tempBeat = startBeat;
											tempNote = nextItem;
											dontBreakBeam = false;
											while (tempBeat = startBeat and dontBreakBeam = false) {
												tempPos = tempNote.Position;
												tempBeat = tempPos / beatLength;
												//trace("Here 3: tempPos = "&tempPos&"; tempBeat = "&tempBeat&"; startBeat = "&startBeat&"; dur = "&tempNote.Duration);
										
												dontBreakBeam = (tempNote.Duration < Crotchet) and (tempBeat = startBeat);
												if (tempNote.NoteCount > 0) {
													tempBeat = startBeat + 1;
												} else {
													tempNote = tempNote.NextItem(0,"NoteRest");
													if (tempNote = null) {
														tempBeat = startBeat + 1;
													} else {
														tempPos = tempNote.Position;
														tempBeat = tempPos / beatLength;
													}
												}
											}
										}
										if (dontBreakBeam) {
											if (_addColors) {
												noteRest.Select();
												noteRest.ColorRed = 255;
												noteRest.ColorGreen = 127;
												noteRest.Deselect();
											}
											if (isNote) {
												comment[numComments] = "Note should be beamed to previous note";
											} else {
										
												comment[numComments] = "Rest should not break beam of previous note";
											}
											commentPosition[numComments] = pos;
											numComments = numComments + 1;
										}
									} // end if beamBroeen
									*/
									
									// ** ————————————————————————————————————————————————— ** //
									// **       CHECK 4: BEAMED to NOTES IN NEXT BEAT       ** //
									// ** ————————————————————————————————————————————————— ** //

									// ** If note is off the beat, at the end of the beat, continuous beam, next beam is continuous or single, then the beam continues over the beat
									
									/*
									if (not(isOnTheBeat) and (beam = ContinueBeam) and actualDur < Crotchet and noteFinishesBeat and nextItem != null and nextBeam > 2 and nextItemDur < Crotchet and isAcc = nextItemIsAcc) {
			
										// ** EXCEPTION ** //
										//or (prevDisplayDur > 255)
										exception1 = (isNote) and (actualDur = Quaver) and (prevDisplayDur = Quaver) and (nextItemDur = Quaver) and (nextNextItemDur = Quaver) and (nextNextItemIsNote);
										exception2 = (barLength = 1024) and (startBeat = 1);
										if ( (exception1 = false) and (exception2 = false) ) {
											if (_addColors) {
												noteRest.Select();
												noteRest.ColorRed = 255;
												noteRest.ColorGreen = 127;
												noteRest.Deselect();
											}
											if (isNote) {
												comment[numComments] = "Note should not be beamed to notes in next beat";
											} else {
												comment[numComments] = "Rest should not be included in beam group of next beat";
											}
											commentPosition[numComments] = pos;
											numComments = numComments + 1;
										}
									}
									*/
				
									// ** ————————————————————————————————————————————————— ** //
									// **           CHECK 5: TIE SIMPLIFICATIONS            ** //
									// ** ————————————————————————————————————————————————— ** //
				
									// ** DO TIE SIMPLIFICATION IF WE"RE ON THE LAST NOTE OF THE TIE ** //
									/*
									if (lastNoteInTie or (isTied and lastNoteInBar)) {
										// ** LOOP THROUGH THE NUMBER OF NOTES IN TIE ** //
										possibleSimplification = -1;
										simplificationIsOnBeat = true;
										possibleSimplificationLastNoteIndex = 0;
										possibleSimplificationFirstNoteIndex = 0;
										theN = tiedNotes[0];
										v = theN.VoiceNumber;
										prevNote = theN.PreviousItem(v,"NoteRest");
								
										for i = 0 to (tiedNotes.Length-1) {
											startNote = tiedNotes[i];
											tiedDisplayDur = startNote.Duration;
											startPos = startNote.Position;
											startBeat = RoundDown(startPos/beatLength);
											startFrac = startPos % beatLength;
											tieIsOnBeat = startFrac = 0;
											tieStartedOnBeat = tiedNotes[i].Position % beatLength = 0;
											startTuplet = startNote.ParentTupletIfAny;
											checkDisplayDur = (startTuplet != null);
									
											if (checkDisplayDur) {
												startTupletPos = startTuplet.Position;
												startTupletDur = startTuplet.PlayedDuration;
												startTupletText = startTuplet.Text;
											}
											tempNextItem = startNote.NextItem(voice,"NoteRest");
											if (tempNextItem = null) {
												tempActualDur = barLength - startPos;
											} else {
												tempNextItemPos = tempNextItem.Position;
												tempActualDur = tempNextItemPos - startPos;
											}
											tiedActualDur = tempActualDur;
											simplifiedDuration = "";
						
											// do onbeat simplifications
											for j = (i+1) to tiedNotes.Length {	
												theNote = tiedNotes[j];
												tempDisplayDur = theNote.Duration;
												tempPos = theNote.Position;
												tempBeat = RoundDown(tempPos/beatLength);
												if (checkDisplayDur) {
													tempTuplet = theNote.ParentTupletIfAny;
													if (tempTuplet = null) {
														checkDisplayDur = false;
													} else {
														if (tempTuplet.Position != startTupletPos or tempTuplet.PlayedDuration != startTupletDur or tempTuplet.Text != startTupletText) {
															checkDisplayDur = false;
														}
													}
												}
												sameBeat = (tempBeat = startBeat);
												tempNextItem = theNote.NextItem(voice,"NoteRest");
												if (tempNextItem = null) {
													tempActualDur = barLength - tempPos;
												} else {
													tempNextItemPos = tempNextItem.Position;
													tempActualDur = tempNextItemPos - tempPos;
												}
												tiedActualDur = tiedActualDur + tempActualDur;
												tiedDisplayDur = tiedDisplayDur + tempDisplayDur;
												if (tieIsOnBeat) {
							
													for k = 0 to possibleOnbeatSimplificationDurs.Length {
														check = true;
														p = possibleOnbeatSimplificationDurs[k];
														if (tiedActualDur = p) {
									
															if (isCompound) {
																if (tiedActualDur > beatLength and tiedActualDur % beatLength > 0) {
																	check = false;
																}
															} else {
																if (tiedActualDur = DottedCrotchet) {
																	check = ((startBeat % 2) = 0);
																}
																if (tiedActualDur = Semibreve) {
																	check = timeSigNum = 4 and timeSigDenom = 4;
																}
															}
									
															if (check) {
																if (k>possibleSimplification) {
																	possibleSimplification = k;
																	possibleSimplificationLastNoteIndex = j;
																	possibleSimplificationFirstNoteIndex = i;
																	simplificationIsOnBeat = true;
																}
															}
														}
													}
													if (checkDisplayDur) {
														for k = 0 to possibleOnbeatSimplificationDurs.Length {
															check = true;
															p = possibleOnbeatSimplificationDurs[k];
															if (tiedDisplayDur = p and check) {
																if (k > possibleSimplification) {
																	possibleSimplification = k;
																	possibleSimplificationLastNoteIndex = j;
																	possibleSimplificationFirstNoteIndex = i;
																	simplificationIsOnBeat = true;
																}
															}
														}
													}
												} else {
													// **** OFFBEAT TIE CONDENSATION **** //

								
													// CHECK ACTUAL DURS
						
													for k = 0 to possibleOffbeatSimplificationDurs.Length {
														p = possibleOffbeatSimplificationDurs[k];
														if (tiedActualDur = p) {
															// don"t simplify anything tied over a beat that is less than a crotchet
															if (isCompound) {
																check = p < beatLength;
															} else {
																check = p < (beatLength * 2);
															}
															if (check) {
																if (p = DottedCrotchet) {
																	check = false;
																}
																if (p = Crotchet) {
																	check = (startFrac = Quaver);
																	if (timeSigDenom = 4) {
																		surr = false;
																		if (prevNote != null and tempNextItem != null) {
																			surr = prevNote.Duration = Quaver and prevNote.NoteCount > 0 and tempNextItem.Duration = Quaver and tempNextItem.NoteCount > 0;
																		}
																		sb = startBeat = 0 or startBeat = 2;
																		check = check and sb and surr;
																	}
																}
																if (p < Crotchet) {
																	placement = startFrac % (beatLength / 4);
																	placementCheck = placement = 0;
																	check = sameBeat and placementCheck;
																}
															}
															if (check) {
																if (k>possibleSimplification) {
																	possibleSimplification = k;
																	possibleSimplificationLastNoteIndex = j;
																}
															}
														}
													}
													// CHECK DISPLAY DURS
													if (checkDisplayDur) {
														for k = 0 to possibleOffbeatSimplificationDurs.Length {
															p = possibleOffbeatSimplificationDurs[k];
															if (tiedDisplayDur = p) {
																if (k > possibleSimplification) {
																	possibleSimplification = k;
																	possibleSimplificationLastNoteIndex = j;
																	possibleSimplificationFirstNoteIndex = i;
																	simplificationIsOnBeat = false;
																}
															}
														}
													}
												}
											}
										} // end for i
										if (possibleSimplification > -1) {
											if (simplificationIsOnBeat) {
												simplification = possibleOnbeatSimplificationLabels[possibleSimplification];
												tempText = "";
												if (tiedDisplayDur = DottedCrotchet and not (isCompound)) {
													tempText = "[Suggestion] ";
												}
												comment[numComments] = tempText&"Tied note can be simplified to a "&simplification&". (Ignore if using tie to show placement of fermata/dynamic/articulation/gliss etc.)";
												commentPosition[numComments] = startPos;
												numComments = numComments + 1;
												if (_addColors) {
													for k = possibleSimplificationFirstNoteIndex to (possibleSimplificationLastNoteIndex+1) {
														theNote = tiedNotes[k];
														theNote.Select();
														theNote.ColorRed = 255;
														theNote.ColorGreen = 127;
														theNote.Deselect();
													}
												}
											} else {
												simplification = possibleOffbeatSimplificationLabels[possibleSimplification];
												tempText = "";
												if (tiedDisplayDur = DottedCrotchet and not (isCompound)) {
													tempText = "[Suggestion] ";
												}
												comment[numComments] = tempText&"Tied note can be simplified to a "&simplification&". (Ignore if using tie to show placement of fermata/dynamic/articulation/gliss etc.)";
												commentPosition[numComments] = startPos;
												numComments = numComments + 1;
												if (_addColors) {
													for k = i to (possibleSimplificationLastNoteIndex+1) {
														theNote = tiedNotes[k];
														theNote.Select();
														theNote.ColorRed = 255;
														theNote.ColorGreen = 127;
														theNote.Deselect();
													}
												}
											}
										}		// end if possibleSimplification			
									} // if lastNoteInTie

									hidesBeat = noteHidesBeat;
									*/
									
									// ** ————————————————————————————————————————————————— ** //
									// **   CHECK 6: NOTE OR REST HIDES THE BEAT            ** //
									// ** ————————————————————————————————————————————————— ** //

									
									// ** ————————————————————————————————————————————————— ** //
									// **    CHECK 7: CONDENSE OVERSPECIFIED REST          ** //
									// ** ————————————————————————————————————————————————— ** //
							
									/*
									if (isNote or hasPause) {
										numRests = 0;
										restCrossesBeat = false;
										restStartedOnBeat = false;
										isLastRest = false;
									} else {
										if (numRests = 0) {
											rests.Length = 0;
										}
										rests[numRests] = noteRest;
										numRests = numRests + 1;				
										if (numRests = 1) {
											restStartedOnBeat = isOnTheBeat;
											restStartBeat = startBeat;
										} else {
											if (startBeat != restStartBeat) {
												restCrossesBeat = true;
											}
										}
										if (nextItemIsNote or nextItem = null or nextItemHasPause or nextItemIsHidden) isLastRest = true;
										if (isLastRest and numRests > 1) {

											possibleSimplification = -1;
											simplificationIsOnBeat = true;
									
											// CHECK THAT IT COULD BE SIMPLIFIED AS A BAR REST
											if ((rests[0].Position = 0) and (rests[numRests-1].NextItem(voice,"NoteRest") = null) and (isPickupBar = false)) {
												comment[numComments] = "Rests can be deleted to make a bar rest.";
												commentPosition[numComments] = noteRest.Position;
												numComments = numComments + 1;
												if (_addColors) {
													for i = 0 to numRests {
														theRest = rests[i];
														theRest.Select();
														theRest.ColorRed = 255;
														theRest.ColorGreen = 127;
														theRest.Deselect();
													}
												}
											} else {
									
												for i = 0 to (numRests-1) {
													startRest = rests[i];
													startRestPrev = startRest.PreviousItem(voice,"NoteRest");
													restDisplayDur = startRest.Duration;
													startPos = startRest.Position;
													startBeat = RoundDown(startPos/beatLength);
													startFrac = startPos % beatLength;
													restIsOnBeat = startFrac = 0;
													startTuplet = startRest.ParentTupletIfAny;
													checkDisplayDur = (startTuplet != null);
													if (checkDisplayDur) {
														startTupletPos = startTuplet.Position;
														startTupletDur = startTuplet.PlayedDuration;
														startTupletText = startTuplet.Text;
													}
													tempNextItem = startRest.NextItem(voice,"NoteRest");
													if (tempNextItem = null) {
														tempActualDur = barLength - startPos;
													} else {
														tempNextItemPos = tempNextItem.Position;
														tempActualDur = tempNextItemPos - startPos;
													}
													restActualDur = tempActualDur;
													simplifiedDuration = "";
													for j = (i+1) to numRests {

														if (i = 0) {
															prevNote = startRestPrev;
														} else {
															prevNote = rests[i-1];
														}
														theRest = rests[j];
														tempDisplayDur = theRest.Duration;
														tempPos = theRest.Position;
														tempBeat = RoundDown(tempPos/beatLength);
														if (checkDisplayDur) {
															tempTuplet = theRest.ParentTupletIfAny;
															if (tempTuplet = null) {
																checkDisplayDur = false;
															} else {
																if (tempTuplet.Position != startTupletPos or tempTuplet.PlayedDuration != startTupletDur or tempTuplet.Text != startTupletText) {
																	checkDisplayDur = false;
																}
															}
														}
														sameBeat = (tempBeat = startBeat);
														tempNextItem = theRest.NextItem(voice,"NoteRest");
														if (tempNextItem = null) {
															tempActualDur = barLength - tempPos;
														} else {
															tempNextItemPos = tempNextItem.Position;
															tempActualDur = tempNextItemPos - tempPos;
														}
														restActualDur = restActualDur + tempActualDur;
														restDisplayDur = restDisplayDur + tempDisplayDur;
								
														// **** ONBEAT REST CONDENSATION **** //
								
														if (restIsOnBeat) {
															for k = 0 to possibleOnbeatSimplificationDurs.Length {
																check = restActualDur < DottedMinim;
																p = possibleOnbeatSimplificationDurs[k];
																// don"t simplify anything tied over a beat that is less than a crotchet
														
																if (restActualDur = Semibreve) {
																	check = (timeSigNum = 4) and (timeSigDenom = 4);
																}
																if (restActualDur = Minim) {
																	check = (isCompound = false) and ((startBeat % 2) = 0) and (barLength > DottedMinim);
																}
																if (restActualDur = DottedCrotchet) {
																	if (isCompound = false) {
																		check = ((timeSigDenom <= 2) or isCompound) and ((startBeat % 2) = 0);
																	}
																}
																if (restActualDur = DottedQuaver) {
																	check = timeSigDenom <= 4;
																}
																if (restActualDur = DottedSemiquaver) {
																	check = timeSigDenom <= 8;
																}
																if (check and isCompound) {
																	check = (restActualDur % beatLength) = 0;
																}
														
																if (check and isCompound) {
																	if (timeSigNum = 4) {
																		check = restActualDur <= DottedCrotchet;
																	}
																}
																if (restActualDur = p and check) {
																	if (k > possibleSimplification) {
																		possibleSimplification = k;
																		possibleSimplificationLastRestIndex = j;
																		possibleSimplificationFirstRestIndex = i;
																		simplificationIsOnBeat = true;
																	}
																}
															}
							
															if (checkDisplayDur) {
																for k = 0 to possibleOnbeatSimplificationDurs.Length {
																	check = true;
																	p = possibleOnbeatSimplificationDurs[k];
																	if (restDisplayDur = p and check) {
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
															for k = 0 to possibleOffbeatSimplificationDurs.Length {
																check = true;
																p = possibleOffbeatSimplificationDurs[k];

																// don"t simplify anything tied over a beat that is less than a crotchet
																if (p = DottedCrotchet) {
																	check = not (isCompound) and (startFrac = Quaver) and (timeSigDenom<=2);
																}
																if (p = Crotchet) {
																	check = false;
																}
																if (p < Crotchet) {
																	check = sameBeat;
																}
																if (check and isCompound) {
																	b = (beatLength * 2 / 3);
																	if (restActualDur = b) {
																		check = false;
																	}
																}
																if (restActualDur = p and check) {
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
																for k = 0 to possibleOffbeatSimplificationDurs.Length {
																	p = possibleOffbeatSimplificationDurs[k];
																	if (restDisplayDur = p) {
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
													exception = isPickupBar and possibleSimplification > 6;
													if (simplificationIsOnBeat) {
														if (exception = false) {
															simplification = possibleOnbeatSimplificationLabels[possibleSimplification];
															tempText = "";
															if (restDisplayDur = DottedCrotchet and not (isCompound)) {
																tempText = "[Suggestion] ";
															}
															comment[numComments] = tempText&"Condense rests as a "&simplification&". (Ignore if using rest to show placement of fermata/etc.)";
															commentPosition[numComments] = startPos;
															numComments = numComments + 1;
															if (_addColors) {
																for k = possibleSimplificationFirstRestIndex to (possibleSimplificationLastRestIndex+1) {
																	theRest = rests[k];
																	theRest.Select();
																	theRest.ColorRed = 255;
																	theRest.ColorGreen = 127;
																	theRest.Deselect();
																}
															}
														}
													} else {
														simplification = possibleOffbeatSimplificationLabels[possibleSimplification];
														p = possibleOffbeatSimplificationDurs[possibleSimplification];
														tempText = "";
														if (restDisplayDur = DottedCrotchet and not (isCompound)) {
															tempText = "[Suggestion] ";
														}
														addComment = true;
														addColors = true;
														numRests = possibleSimplificationLastRestIndex-possibleSimplificationFirstRestIndex+1;
														if (p = DottedQuaver) {
															if (rests[possibleSimplificationLastRestIndex].Duration != Quaver or numRests>2) {
																comment[numComments] = "Spell as a semiquaver followed by a quaver.";
																commentPosition[numComments] = startPos;
																numComments = numComments + 1;
															} else {
																addColors = false;
															}
															addComment = false;
														}
														if (addComment) {
															comment[numComments] = "Condense rests as a "&simplification&". (Ignore if using rest to show placement of fermata/etc.)";
															commentPosition[numComments] = startPos;
															numComments = numComments + 1;
														}
														if (_addColors and addColors) {
															for k = possibleSimplificationFirstRestIndex to (possibleSimplificationLastRestIndex+1) {
																theRest = rests[k];
																theRest.Select();
																theRest.ColorRed = 255;
																theRest.ColorGreen = 127;
																theRest.Deselect();
															}
														}
													}
												} // end if possibleSimplification
												
												
											}
										}
									}
									*/
									/*wasTied = isTied;	
									if (not(isTied)) {
										tiedActualDur = 0;
										tiedDisplayDur = 0;
									}

									prevActualDur = actualDur;
									prevDisplayDur = displayDur;
									prevItemIsNote = isNote;
									prevNoteWasDoubleTremolo = isDoubleTremolo;
									prevNoteCount = noteCount;
									prevPitch = pitch;
									prevTupletSubdiv = tupletSubdiv;
									*/
									//} //end isHidden
						
						/*
						if (totalDur > 0 and totalDur < expectedDuration and currentBar > 1) {
							if (currentVoice = 1) {
								comment[numComments] = "Not enough notes in this bar.";
								//trace ("totalDur = "&totalDur&"; expectedDur = "&expectedDuration);
							} else {
								comment[numComments] = "Not enough notes in Voice "&currentVoice&" in this bar.";
							}
							commentPosition[numComments] = 0;
							numComments = numComments + 1;
						}
						*/
						
					} // end for track loop
				} // end if canCheckThisBar
		
				/*
				for i = 0 to numComments {
					if (_addComments) {
						bar.AddComment(commentPosition[i],comment[i]);
					}
					numErrors = numErrors + 1;
				}
				*/
					segment = segment.nextInMeasure;
				} // end of while segment
				if (currentBar == lastBarInSelection) {
					currentBar = null;
				} else {
					currentBar = currentBar.nextMeasure;
					currentBarNum ++;
				}		
			} // end while currentBar	
		} // end for currentStaff
		
		/*
		Sibelius.DestroyProgressDialog();
		if (numErrors = 0) {
			message = "Congratulations — no errors were found!";
		} else {
			if (numErrors = 1) {
				message = "I found one error.";
			} else {
				message = "I found "&numErrors&" errors.";
			}
			message = message & "\n\nNB: ensure View→Comments is ticked to view the error descriptions.";
		}
		Sibelius.MessageBox(message);*/
		
		
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
			comment.offsetY = element.posY - 2.0 - objectHeight;
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
	      // Qt.WindowStaysOnTopHint => dialog always on top
	      // Qt.FramelessWindowHint  => dialog without title bar
		width: 500
		height: 400        

		StyledTextLabel {
			text: dialog.msg            
			anchors {
				top: parent.top 
				horizontalCenter: parent.horizontalCenter                
				margins:20 
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
