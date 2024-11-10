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
	description: "This plugin checks your score for common accidental spelling issues"
	menuPath: "Plugins.MNCheckAccidentals";
	requiresScore: true
	title: "MN Check Accidentals"
	id: mncheckaccidentals
	
	
	property var diatonicPitchAlts: []
	property var currAccs: []
	property var currPCAccs: []
	property var barAltered: []
	property var prevBarNum
	property var prevMIDIPitch
	property var prevDiatonicPitch
	property var prevPC
	property var prevScalarInterval
	property var prevScalarIntervalClass
	property var prevScalarIntervalAbs
	property var prevChromaticInterval
	property var prevChromaticIntervalClass
	property var prevDiatonicPitchClass
	property var prevShowError
	property var prevAcc
	property var prevAccVisible
	property var prevIsAugDim
	property var prevNote
	property var prevPrevNote
	property var prevAlterationLabel: ""
	property var currentKeySig
	property var prevWhichNoteToRewrite
	property var commentPosArray: []

  onRun: {
		if (!curScore) return;
		
		// **** GATHER VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		currentKeySig = 0;
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) {
			// ** SELECT ALL ** //
			curScore.startCmd();
			curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
			curScore.endCmd();
		}
		
		// ** INITIALIZE VARIABLES ** //

		currAccs = Array(120).fill(0);
		currPCAccs = Array(120).fill(0);
		barAltered = Array(120).fill(0);
		commentPosArray = Array(10000).fill(0);
		
		var startStaff = curScore.selection.startStaff;
		var endStaff = curScore.selection.endStaff;		
		prevNote = null;
		prevPrevNote = null;

		var cursor = curScore.newCursor();
		var firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		// start
		firstBarInScore = curScore.firstMeasure;
		cursor.rewind(Cursor.SELECTION_START);
		firstBarInSelection = cursor.measure;
		firstTickInSelection = cursor.tick;
		firstStaffInSelection = cursor.track;
		dialog.msg = "";
//		dialog.msg += "\nfirstBarInScore="+firstBarInScore+";\nfirstBarInSelection="+firstBarInSelection+";\nfirstTickInSelection="+firstTickInSelection+";\nfirstStaffInSelection="+firstStaffInSelection;
		
		var firstBarNum = 1, lastBarNum = 1;
		var currBar = firstBarInScore;
		while (!currBar.is(firstBarInSelection)) {
			firstBarNum ++;
			currBar = currBar.nextMeasure;
		}
		// end
		lastBarInScore = curScore.lastMeasure;
		cursor.rewind(Cursor.SELECTION_END);
		lastBarInSelection = cursor.measure;
		if (lastBarInSelection == null) lastBarInSelection = lastBarInScore;
		lastTickInSelection = cursor.tick;
		if (lastTickInSelection == 0) lastTickInSelection = curScore.lastSegment.tick + 1;
		lastBarNum = firstBarNum;
//		dialog.msg += "\nlastBarInScore="+lastBarInScore+";\nlastBarInSelection="+lastBarInSelection+";\nlastTickInSelection="+lastTickInSelection+";\nlastStaffInSelection="+lastStaffInSelection;
		
		while (!currBar.is(lastBarInSelection)) {
			lastBarNum ++;
			currBar = currBar.nextMeasure;
		}
//		dialog.msg += "\nfirstBarNum="+firstBarNum+"; lastBarNum="+lastBarNum;
		
		// ** LOOP THROUGH NOTES **//
		// ** NB — endStaff IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //

		for (var staffNum = startStaff; staffNum < endStaff; staffNum ++) {
			//dialog.msg += "\nStaff "+staffNum;
			
			// ** RESET ALL VARIABLES TO THEIR DEFAULTS ** //
			prevMIDIPitch = -1;
			prevDiatonicPitch = -1;
			prevPC = -1;
			prevScalarInterval = -1;
			prevScalarIntervalClass = -1;
			prevScalarIntervalAbs = -1;
			prevChromaticInterval = -1;
			prevChromaticIntervalClass = -1;
			prevShowError = false;
			prevAcc = 0;
			prevAccVisible = false;
			prevIsAugDim = false;
			prevNote = null;
			prevPrevNote = null;

			// clear the arrays
			currAccs.fill(0);
			currPCAccs.fill(0);
			barAltered.fill(0);
			
			// go back to beginning
			cursor.rewind(Cursor.SELECTION_START);
			var segment = cursor.segment;
			currentKeySig = cursor.keySignature;
			//dialog.msg += "\nkeySig = "+keySig;
			currBar = firstBarInSelection;
			var barNum = firstBarNum;
			
			while (currBar) {
				//dialog.msg += "\nbar num = "+barNum;
				segment = currBar.firstSegment;
				while (segment && segment.tick < lastTickInSelection) {
					var startTrack = staffNum * 4;
					var endTrack = startTrack + 4;
					for (var track = startTrack; track < endTrack; track++) {
						if (segment.elementAt(track) && segment.elementAt(track).type == Element.KEYSIG) {
							cursor.rewindToTick(segment.tick);
							currentKeySig = cursor.keySignature;
							dialog.msg += "\ncurrentKeySig = "+currentKeySig;
							// ** MAYBE ONLY NEED TO DO THIS WHEN TRACK IS STARTTRACK? ** //
						}
						
						if (segment.elementAt(track) && segment.elementAt(track).type == Element.CHORD) {
							var chord = segment.elementAt(track);
							var graceNoteChords = chord.graceNotes;
							if (graceNoteChords != null) {
								for (var g in graceNoteChords) {
									checkChord (graceNoteChords[g],segment,barNum,staffNum);
								}
							}				
							checkChord (chord,segment,barNum,staffNum);
						} // end if segment.elementAt
					} // end of track loop
					segment = segment.nextInMeasure;
				} // end of while segment
				if (currBar == lastBarInSelection) {
					currBar = null;
				} else {
					currBar = currBar.nextMeasure;
					barNum ++;
				}
			} // end of while currBar
		}
		dialog.show();
	}
	
	function checkChord (chord,segment,barNum,staffNum) {
		var defaultChromaticInterval = [0,2,4,5,7,9,11];
		var accTypes = [Accidental.FLAT2, Accidental.FLAT, Accidental.NATURAL, Accidental.SHARP, Accidental.SHARP2];
		var pitchLabels = ["C","D","E","F","G","A","B"];
		var intervalNames = ["unison","second","third","fourth","fifth","sixth","seventh","octave","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth"];
		var majorIntervalAlts = ["double diminished","diminished","minor","major","augmented","double augmented"];
		var perfectIntervalAlts = ["triple diminished","double diminished","diminished","perfect","augmented","double augmented"];
		var weightings = [-2,0,3,-3,-1,1,4];

		var accidentals = ["bb","b","♮","#","x"];
		var accidentalNames = ["double flat","flat","natural","sharp","double sharp"];
		var isBadAcc = false;
		var isProblematic, accidentalName, currentAccidental, prevAccidental;
		
		
		var notes = chord.notes;
		for (var i in notes) {
				
			var note = notes[i];
			var currTick = segment.tick;
			var measure = segment.parent

				// ** GET INFO ON THE KEY SIGNATURE AT THIS POINT ** //

			/// ** GET INFO ON THE NOTE ** //
			var accObject, accOrder, acc;
			var accVisible = false;
			var accType;
			var tpc = note.tpc;

			if (note.accidental == null) {
				accType = accTypes[parseInt((tpc+1)/7)];
			} else {
				accObject = note.accidental;
				accVisible = accObject.visible;
				accType = note.accidentalType;
			}
			acc = 0;
			var isDoubleAcc = false;
			switch (accType) {
				case Accidental.FLAT2:
					acc = -2;
					isDoubleAcc = true;
					break;
				case Accidental.FLAT:
					acc = -1;
					break;
				case Accidental.SHARP:
					acc = 1;
					break;
				case Accidental.SHARP2:
					acc = 2;
					isDoubleAcc = true;
					break;
			}
			var MIDIpitch = note.pitch;
			var octave = Math.trunc(MIDIpitch/12);
			var diatonicPitchClass = (((tpc+1)%7)*4+3) % 7;
			
			var diatonicPitch = diatonicPitchClass+octave*7;
			//dialog.msg += "\nN: tpc="+tpc+" oct="+octave+" dp="+diatonicPitch+" dpc="+diatonicPitchClass+" p="+MIDIpitch;
			dialog.msg += "\nks = "+currentKeySig;

			var accIsInKS = false;
			if (currentKeySig == 0 && accType == Accidental.NATURAL) accIsInKS = true;
			if (currentKeySig > 0) {
				accOrder = ((diatonicPitchClass + 4) * 2) % 7;
				if (accType == Accidental.SHARP) {
					//dialog.msg += "\nhere";
					accIsInKS = accOrder < currentKeySig;
				}
				if (accType == Accidental.NATURAL) accIsInKS = (accOrder + 1) > currentKeySig; 
			}
			if (currentKeySig < 0) {
				accOrder = (2 * (13 - diatonicPitchClass)) % 7;
				if (accType == Accidental.FLAT) accIsInKS = accOrder < Math.abs(currentKeySig);
				if (accType == Accidental.NATURAL) accIsInKS = (accOrder + 1) > Math.abs(currentKeySig);
			}
			//dialog.msg += "accInKeySig = "+accIsInKS+"; accType = "+accType+";";

			if (!note.tieBack) {
				var noteLabel = pitchLabels[diatonicPitchClass]+accidentals[acc+2];
				isBadAcc = false;
	
				// ** CHECK Cb OR Fb ** //
				if (currentKeySig > -3) isBadAcc = (tpc == 6 || tpc == 7);
				if (!isBadAcc && currentKeySig < 3) isBadAcc = (tpc == 25 || tpc == 26);
				// check redundant accidentals

				// case 1: acc is different from prev, but prev was a long time a go
				// case 2: acc is same as prev and prev is in the same bar
				// case 3: acc is same as prev and acc is in ks
				if (currAccs[diatonicPitch] == acc && currPCAccs[diatonicPitchClass] == acc && accVisible) {
					prevBarNum = barAltered[diatonicPitch];
					if (barNum == prevBarNum || accIsInKS) {
							accidentalName = accidentalNames[acc+2];
							showError("This was already a "+accidentalName+".",note,staffNum);
					}
				}
				// check courtesy accidentals
				if (currAccs[diatonicPitch] != acc) {
					prevBarNum = barAltered[diatonicPitch];
					if (prevBarNum > 0) {
						if (!accVisible && barNum != prevBarNum && barNum - prevBarNum < 2) {
							currentAccidental = accidentalNames[acc+2];
							prevAccidental = accidentalNames[currAccs[diatonicPitch] + 2];
							showError("Put a courtesy "+currentAccidental+" on this note,\nas it was a "+prevAccidental+" in the previous bar.",note,staffNum);
						}
						if (!accVisible && barNum == prevBarNum) {
							currentAccidental = accidentalNames[acc+2];
							prevAccidental = accidentalNames[currAccs[diatonicPitch] + 2];
							showError("Put a courtesy "+currentAccidental+" on this note,\nas it was a "+prevAccidental+" earlier in the bar.",note,staffNum);
						}
						if (accVisible && currPCAccs[diatonicPitchClass] == acc) {
							if (barNum - prevBarNum > 2 && accIsInKS) {
								accidentalName = accidentalNames[acc+2];
								showError("This was already a "+accidentalName+".",note,staffNum);
							}
						}
					}
				}
				currAccs[diatonicPitch] = acc;
				currPCAccs[diatonicPitchClass] = acc;
				if (accVisible && !accIsInKS) {
					barAltered[diatonicPitch] = barNum;
					//dialog.msg += "\nAdded bar "+barNum+" to barAltered["+diatonicPitch+"]";
				}
				var alterationLabel = "";
				var doShowError = false;
				var isAug = false;
				var isDim = false;
				var isAugDim = false;
				var isTritone = false;
				var whichNoteToRewrite = 2;
				var article, noteToHighlight, theAccToChange, thePitchClassToChange;
				var prevNext, newNotePitch = "", newNoteAccidental, flatten, sharpen, direction;
		
				var scalarInterval, chromaticInterval, scalarIntervalLabel = "";
				var scalarIntervalAbs, scalarIntervalClass, chromaticIntervalAbs, chromaticIntervalClass;
				
				if (prevMIDIPitch != -1) {
					
					scalarInterval = diatonicPitch - prevDiatonicPitch;
					chromaticInterval = MIDIpitch - prevMIDIPitch;
					dialog.msg += "\ndp="+diatonicPitch+" pdp="+prevDiatonicPitch+" si="+scalarInterval+" ci="+chromaticInterval;
					if (chromaticInterval != 0) {
						if (scalarInterval < 0) {
							direction = -1;
						} else {
							direction = 1;
						}
						if (scalarInterval == 0) {
							if (chromaticInterval > 0) {
								direction = 1;
							} else {
								direction = -1;
							}
						}
						scalarIntervalAbs = Math.abs(scalarInterval);
						scalarIntervalClass = scalarIntervalAbs % 7;
						chromaticIntervalAbs = Math.abs(chromaticInterval);
						chromaticIntervalClass = chromaticIntervalAbs % 12;
						if (scalarIntervalAbs == 7 && chromaticIntervalClass > 9) chromaticIntervalClass = chromaticIntervalClass - 12;
						var dci = defaultChromaticInterval[scalarIntervalClass];
						var alteration = chromaticIntervalClass - dci;
						dialog.msg += "\ndci="+dci+" alt="+alteration;

						// **		IS THIS AUGMENTED OR DIMINISHED? 		** //
						var isFourthFifthOrUnison = (scalarIntervalClass == 0 || scalarIntervalClass == 3 || scalarIntervalClass == 4);
						if (isFourthFifthOrUnison) {
							alterationLabel = perfectIntervalAlts[alteration+3];
							isDim = alteration < 0;
							isAug = alteration > 0;
						} else {
							alterationLabel = majorIntervalAlts[alteration+3];
							isDim = alteration < -1;
							isAug = alteration > 0;
						}
						isAugDim = isAug || isDim;

						if (isAugDim) {
							//dialog.msg += "\nisAug: "+isAug+"; isDim: "+isDim;
							
							var neverOK = false;
							var neverOKRewriteIfPoss = false;
							var OKRewriteIfPoss = true;
							// = false;

							//if (OKRewriteIfPoss || neverOKRewriteIfPoss) {
							//if (OKRewriteIfPoss) {
							
							doShowError = prevIsAugDim;
	
							// EXCEPTIONS
							// IGNORE AUG UNISON IF FOLLOWED BY ANOTHER ONE OR A TRITONE
							if (chromaticIntervalClass == 1 && (prevChromaticInterval == chromaticInterval || prevChromaticIntervalClass == 6)) doShowError = false;
	
							// IGNORE TRITONE IF FOLLOWED BY ANOTHER ONE OR A SEMITONE
							if (chromaticIntervalClass == 6 && (prevChromaticIntervalClass == 1 || prevChromaticIntervalClass == 6)) doShowError = false;
							
							//}
							//if (neverOKRewriteIfPoss) doShowError = true;
								
							if (doShowError) {
								var foundNote = false;
								
								if (!prevAccVisible && accVisible) {
									dialog.msg += "\nwhichNoteToRewrite = 2";
									whichNoteToRewrite = 2;
									foundNote = true;
								}
								if (prevAccVisible && !accVisible) {
									dialog.msg += "\nwhichNoteToRewrite = 1";
									whichNoteToRewrite = 1;
									foundNote = true;
								}
								if (!foundNote) {
									var weighting1 = Math.abs(weightings[prevDiatonicPitchClass] + (prevAcc * 7) - currentKeySig);
									var weighting2 = Math.abs(weightings[diatonicPitchClass] + (acc * 7) - currentKeySig);
									// rewrite the one that is the most outlying
									dialog.msg += "\nW1: prevDiatonicPitchClass="+prevDiatonicPitchClass+"; prevAcc * 7: "+prevAcc * 7+"; keySig: "+currentKeySig;

									if (weighting1 > weighting2) {
										whichNoteToRewrite = 1;
									} else {
										whichNoteToRewrite = 2;
									}
									dialog.msg += "\nWeighting1: "+weighting1+"; weighting2: "+weighting2+"; ntr = "+whichNoteToRewrite;
									
								} // if !foundNote
							} // if doshowerror
							
								//
							
								//} //OKRewriteIfPoss || neverOKRewriteIfPoss*/
							
							// don't show error if we decide it"s the same note that needs to change
							if (prevShowError && prevWhichNoteToRewrite == 2 && whichNoteToRewrite == 1) doShowError = false;
							if (doShowError) {
								// DOES THIS OR PREV GO AGAINST THE WEIGHT?
								scalarIntervalLabel = intervalNames[scalarIntervalAbs];

								dialog.msg += "\nscalarIntervalAbs = "+scalarIntervalAbs+"; scalarIntervalLabel="+scalarIntervalLabel;
								article = (alterationLabel === "augmented") ? "an" : "a";
								noteToHighlight = note;
								theAccToChange = acc;
								thePitchClassToChange = diatonicPitchClass;
								prevNext = "previous";
								newNotePitch = "";
								newNoteAccidental = "";
								flatten = isAug;
								sharpen = !isAug;
								if (whichNoteToRewrite == 2) {
									flatten = !flatten;
									sharpen = !sharpen;
								}
								if (direction == -1) {
									flatten = !flatten;
									sharpen = !sharpen;
								}
								if (whichNoteToRewrite == 1) {
									theAccToChange = prevAcc;
									thePitchClassToChange = prevDiatonicPitchClass;
									noteToHighlight = prevNote;
									prevNext = "next";
									dialog.msg += "\nChoosing prev note: theAccToChange="+theAccToChange+" pc2change="+thePitchClassToChange;
									
								} else {
									dialog.msg += "\nChoosing curr note: theAccToChange="+theAccToChange+" pc2change="+thePitchClassToChange;
									
								}
								
								var j =0;
								switch (theAccToChange) {
									case -2:
										if (!flatten) dialog.msg += "Error found with "+noteLabel+" in bar "+barNum+": should be spelt enharmonically downwards";
									//	trace ("bb");
										j = thePitchClassToChange - 1;
										if (j < 0) j += 7;
										var newNotePitch = pitchLabels[j];
										if (newNotePitch === "B" || newNotePitch === "E") {
											newNoteAccidental = "b";
										} else {
											newNoteAccidental = "♮";
										}
										dialog.msg += "\n-2 ";
										
										break;
						
									case -1:
										if (!flatten) dialog.msg += "Error found with "&noteLabel&" in bar "&barNum&": should be spelt enharmonically downwards";
										j = thePitchClassToChange - 1;
										if (j < 0) j+=7;
										newNotePitch = pitchLabels[j];
										if (newNotePitch === "B" || newNotePitch === "E") {
											newNoteAccidental = "♮";
										} else {
											newNoteAccidental = "#";
										}
										dialog.msg += "\n-1 ";
										break;
						
									case 0:
										if (flatten) {
											j = thePitchClassToChange - 1;
											if (j < 0) j += 7;
										} else {
											j = (thePitchClassToChange + 1) % 7;
										}
										newNotePitch = pitchLabels[j];
										if (flatten) {
											if (newNotePitch === "E" || newNotePitch === "B") {
												newNoteAccidental = "#";
											} else {
												newNoteAccidental = "x";
											}
										} else {
											if (newNotePitch === "C" || newNotePitch === "F") {
												newNoteAccidental = "b";
											} else {
												newNoteAccidental = "bb";
											}
										}
										dialog.msg += "\n0 ";
										break;
						
									case 1:
										if (!sharpen) dialog.msg += "Error with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards";
										j = (thePitchClassToChange + 1) % 7;
										newNotePitch = pitchLabels[j];
										if (newNotePitch === "F" || newNotePitch === "C") {
											newNoteAccidental = "♮";
										} else {
											newNoteAccidental = "b";
										}
										dialog.msg += "\n1 ";
										break;
						
									case 2: 
										if (!sharpen) dialog.msg += "\nError with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards";
										j = (thePitchClassToChange + 1) % 7;
										newNotePitch = pitchLabels[j];
										if (newNotePitch === "F" || newNotePitch === "C") {
											newNoteAccidental = "#";
										} else {
											newNoteAccidental = "♮";
										}
										dialog.msg += "\n2 ";
										break;
								}
								if (newNotePitch === "") dialog.msg += "\nCouldnt find new note pitch";
								var newNoteLabel = newNotePitch+newNoteAccidental;

								//if (neverOKRewriteIfPoss || OKRewriteIfPoss) {
									var changeIsBad = false;
									if (currentKeySig > -3) changeIsBad = (newNoteLabel === "Cb") || (newNoteLabel === "Fb");
									if (currentKeySig < 3) changeIsBad = (newNoteLabel === "B#") || (newNoteLabel === "E#");
									//if (isBad) doShowError = false;
									//}
								if (doShowError && !changeIsBad) {
									var t = "Interval with "+prevNext+" pitch is "+article+" "+alterationLabel+" "+scalarIntervalLabel+".\nConsider respelling as "+newNoteLabel;
									dialog.msg += "\n"+t;
									dialog.msg += "\n"+noteToHighlight;
									dialog.msg += "\n"+staffNum;
									showError(t,noteToHighlight,staffNum);
								} else {
									dialog.msg += "\nDid not show error cos doShowError="+doShowError+" & changeIsBad="+changeIsBad;
								}
											
							} // end if doShowError

						} // end if isAugDim
					} // end if chromaticInterval != 0
				}
				
				isProblematic = false;

				if (isDoubleAcc) isProblematic = true;
				if (isBadAcc) isProblematic = true;
				var isMicrotonal = false;

				if (!doShowError && accVisible && isProblematic && !isMicrotonal) {
					doShowError = true;
					theAccToChange = acc;
					thePitchClassToChange = diatonicPitchClass;
					noteToHighlight = note;
					newNotePitch = "";
					switch (theAccToChange) {
						case -2:
							i = thePitchClassToChange - 1;
							if (i < 0) i = i + 7;
							newNotePitch = pitchLabels[i];
							//dialog.msg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "B" || newNotePitch === "E") {
								newNoteAccidental = "b";
							} else {
								newNoteAccidental = "♮";
							}
							break;
						case -1:
							i = thePitchClassToChange - 1;
							if (i < 0) i += 7;
							newNotePitch = pitchLabels[i];
							//dialog.msg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "B" || newNotePitch === "E") {
								newNoteAccidental = "♮";
							} else {
								newNoteAccidental = "#";
							}
							break;
			
						case 1:
							i = (thePitchClassToChange + 1) % 7;
							newNotePitch = pitchLabels[i];
							//dialog.msg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "F" || newNotePitch === "C") {
								newNoteAccidental = "♮";
							} else {
								newNoteAccidental = "b";
							}
							break;
			
						case 2:
							i = (thePitchClassToChange + 1) % 7;
							newNotePitch = pitchLabels[i];
							//dialog.msg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "F" || newNotePitch === "C") {
								newNoteAccidental = "#";
							} else {
								newNoteAccidental = "♮";
							}
							break;
					} // end switch TeAccToChange

					if (newNotePitch === "") dialog.msg += ("\nCouldnt find new note pitch — "+thePitchClassToChange+" "+theAccToChange);
					newNoteLabel = newNotePitch+newNoteAccidental;
					if (doShowError) showError("Avoid writing "+noteLabel+"s. Consider respelling as "+newNoteLabel,noteToHighlight);
				} // end if (!doShowError && accVisible && isProblematic && !isMicrotonal)

				if (chromaticInterval != 0 || prevMIDIPitch == -1) {	
					prevNote = note;
					prevMIDIPitch = MIDIpitch;
					prevDiatonicPitch = diatonicPitch;
					prevDiatonicPitchClass = diatonicPitchClass;
					prevChromaticInterval = chromaticInterval;
					prevChromaticIntervalClass = chromaticIntervalClass;
					prevAcc = acc;
					prevAccVisible = accVisible;
					prevIsAugDim = isAugDim;
					prevScalarIntervalAbs = scalarIntervalAbs;
					prevScalarIntervalClass = scalarIntervalClass;
					prevAlterationLabel = alterationLabel;
					prevShowError = doShowError;
					prevWhichNoteToRewrite = whichNoteToRewrite;
				} // end if chromatic interval
			} // if !note.tieBack
		} // end var i in notes
	}
	
	function showError (text, element, staffNum) {
		var commentOffset = 1;
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
		comment.fontSize = 7.0;
		comment.fontFace = "Helvetica"
		comment.autoplace = false;
		var commentHeight = comment.bbox.height;
		var elementHeight = element.bbox.height;
		
		var tick = 0;
		var segment = curScore.firstSegment();
		if (element === "top") {
			var firstMeasure = curScore.firstMeasure;
			var pagePos = firstMeasure.pagePos;
			element = firstMeasure;
			//comment.offsetY = 4.0-pagePos.y;
			
		} else {
			if (element.type == Element.NOTE) {
			
				var chord = element.parent;
				//dialog.msg += "\nParent1 name = "+chord.name;
			
				segment = chord.parent;
				//dialog.msg += "\nParent2 name = "+segment.name;
			
				tick = segment.tick;
				
			}
			
			comment.offsetX = element.posX;
				

		}
		
		var cursor = curScore.newCursor();
		cursor.staffIdx = staffNum;
		cursor.rewindToTick(tick);
		cursor.add(comment);
		// style the element
		element.color = "hotpink";
		
		
		comment.offsetY = -commentHeight;
		var commentTopRounded = Math.round(comment.pagePos.y);
		//dialog.msg += "\ncommentTopRounded is "+commentTopRounded;
		
		while (commentPosArray[commentTopRounded+1000]) {
			commentTopRounded -= commentOffset;
			comment.offsetY -= commentOffset;
			//dialog.msg += "\ncomment.offsetY is now "+comment.offsetY;
		}
		
		commentPosArray[commentTopRounded+1000] = true;
			// check staff height
	//	var measure = segment.parent;
		//
		//var theMeasurePos = segment.pagePos;
		//dialog.msg += "\ntheMeasurePos = "+theMeasurePos;
		
		//var staffTop = theMeasurePos.y;
	
		//dialog.msg += "\nPlacing comment at tick "+tick;
		
		// add text object to score


		//var commentBottom = comment.pagePos.y + commentHeight;
		//dialog.msg += "\nStaff top = "+staffTop+"; commentBottom is = "+commentBottom;
		
		/*if (commentBottom > staffTop) {
			var offset = commentBottom - staffTop;
			comment.offsetY -= offset;
			dialog.msg += "\nShifting comment top by -"+offset+": is now "+comment.pagePos.y;
			
		}*/
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
