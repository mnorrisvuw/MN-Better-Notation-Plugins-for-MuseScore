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
	

  onRun: {
		if (!curScore) return;
		
		// ** DECLARATIONS & DEFAULTS **//
		var defaultChromaticInterval = [0,2,4,5,7,9,11];
		var pitchLabels = ["C","D","E","F","G","A","B"];
		var intervalNames = ["unison","second","third","fourth","fifth","sixth","seventh","octave","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth"];
		var majorIntervalAlts = ["double diminished","diminished","minor","major","augmented","double augmented"];
		var perfectIntervalAlts = ["triple diminished","double diminished","diminished","perfect","augmented","double augmented"];
		var diatonicPitchAlts = [];
		var weightings = [-2,0,3,-3,-1,1,4];
		var currAccs = [];
		var currPCAccs = [];
		var currGraceNoteAccs = [];
		var barAltered = [];
		var accidentals = ["bb","b","♮","#","x"];
		var accidentalNames = ["double flat","flat","natural","sharp","double sharp"];
		var tiedPitches = [];
		
		// **** GATHER VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		var parts = curScore.parts;
		var numParts = parts.length;
		var firstMeasure = curScore.firstMeasure;
		var lastMeasure = curScore.lastMeasure;
		var firstSystem = firstMeasure.parent;
		var lastSystem = lastMeasure.parent;
		var firstPage = firstSystem.parent;
		var lastPage = lastSystem.parent;
		var hasMoreThanOneSystem = !lastSystem.is(firstSystem);	
		var style = curScore.style;
		var keySigs = [];
		var numKeySigs = 0;
		var notes = [];
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) {
			// ** SELECT ALL ** //
			curScore.startCmd();
			curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
			curScore.endCmd();
		}
		
		var startStaff = curScore.selection.startStaff;
		var endStaff = curScore.selection.endStaff;
		
		var prevPitch,prevDiatonicPitch,prevPC;
		var prevScalarInterval,prevScalarIntervalClass,prevScalarIntervalAbs;
		var prevChromaticInterval,prevChromaticIntervalClass,prevShowError;
		var prevNn,prevAcc,prevAccVisible,prevIsTritone,prevIsAugDim;
		var prevNote = null;
		var prevPrevNote = null;
		var resetVariables = true;
		var scalarInterval = 0;
		var chromaticInterval = 0;
		var chromaticIntervalClass = 0;
	
		var prevAlterationLabel = "";
		var scalarIntervalLabel = "";
		var scalarIntervalAbs = -1;
		var scalarIntervalClass = -1;
	
		var isDoubleAcc = false;
		var isBadAcc = false;
		var isTritone = false;
		var noteNum = 0;
	
		var currAccs = Array(120).fill(0), currPCAccs = Array(120).fill(0), barAltered = Array(120).fill(0);
		var cursor = curScore.newCursor();
		
		// ** LOOP THROUGH NOTES **//
		for (var staffNum = startStaff; staffNum < endStaff; staffNum ++) {
			dialog.msg += "\nStaff "+staffNum;
			
			// ** RESET ALL VARIABLES TO THEIR DEFAULTS ** //
			prevPitch = -1;
			prevDiatonicPitch = -1;
			prevPC = -1;
			prevScalarInterval = -1;
			prevScalarIntervalClass = -1;
			prevScalarIntervalAbs = -1;
			prevChromaticInterval = -1;
			prevChromaticIntervalClass = -1;
			prevShowError = false;
			prevNn = null;
			prevAcc = 0;
			prevAccVisible = false;
			prevIsTritone = false;
			prevIsAugDim = false;
			prevNote = null;
			prevPrevNote = null;
			scalarInterval = 0;
			chromaticInterval = 0;
			chromaticIntervalClass = 0;
			prevAlterationLabel = "";
			scalarIntervalLabel = "";
			scalarIntervalAbs = -1;
			scalarIntervalClass = -1;
			isDoubleAcc = false;
			isBadAcc = false;
			isTritone = false;
			noteNum = 0;
			currAccs.fill(0);
			currPCAccs.fill(0);
			barAltered.fill(0);
			cursor.track=0;
			cursor.staffIdx = staffNum;
			cursor.inputStateMode = Cursor.INPUT_STATE_SYNC_WITH_SCORE;
			cursor.rewind(Cursor.SELECTION_END);
			var lastTick = cursor.tick;
			if (lastTick == 0) lastTick = curScore.lastSegment.tick + 1;
			//dialog.msg += "\nlastTick "+lastTick;
			
			cursor.rewind(Cursor.SELECTION_START);
			//dialog.msg += "\ncursor "+cursor.tick;
			
			var segment = cursor.segment;
			var keySig = cursor.keySignature;
			//dialog.msg += "\nkeySig = "+keySig;
			while (segment && segment.tick < lastTick) {
				var startTrack = staffNum * 4;
				var endTrack = startTrack + 4;
				for (var track = startTrack; track < endTrack; track++) {
					if (segment.elementAt(track) && segment.elementAt(track).type == Element.KEYSIG) {
						cursor.rewindToTick(segment.tick);
						keySig = cursor.keySignature;

						//dialog.msg += "\nkeySig = "+keySig;
						// ** MAYBE ONLY NEED TO DO THIS WHEN TRACK IS STARTTRACK? ** //
					}
					if (segment.elementAt(track) && segment.elementAt(track).type == Element.CHORD) {
						var elem = segment.elementAt(track);
						var notes = segment.elementAt(track).notes;
						//dialog.msg += "\nFound element "+elem.name;
						notes = elem.notes;
						
						// GET ALL NOTES IN THIS PART
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
								if (tpc < 6) {
									accType = Accidental.FLAT2;
								} else if(tpc < 13) {
									accType = Accidental.FLAT;
								} else if(tpc < 20) {
									accType = Accidental.NATURAL;
								} else if(tpc < 27) {
									accType = Accidental.SHARP;
								} else {
									accType = Accidental.SHARP2;
								}
							} else {
								accObject = note.accidental;
								accVisible = accObject.visible;
								accType = note.accidentalType;
							}
							acc = 0;
							isDoubleAcc = false;
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
							var diatonicPitchClass = Math.round((((tpc+1)%7)*7+5) % 12);
							dialog.msg += "\naccType = "+accType+"; dpc = "+diatonicPitchClass+"; p = "+MIDIpitch;

							var accIsInKS = false;
							if (keySig == 0 && accType == Accidental.NATURAL) accIsInKS = true;
							if (keySig > 0) {
								accOrder = ((diatonicPitchClass + 4) * 2) % 7;
								if (accType == Accidental.SHARP) accIsInKS = accOrder < keySig;
								if (accType == Accidental.NATURAL) accIsInKS = (accOrder + 1) > keySig; 
							}
							if (keySig < 0) {
								accOrder = (2 * (13 - diatonicPitchClass)) % 7;
								if (accType == Accidental.FLAT) accIsInKS = accOrder < Math.abs(keySig);
								if (accType == Accidental.NATURAL) accIsInKS = (accOrder + 1) > Math.abs(keySig);
							}
							dialog.msg += "\naccInKeySig = "+accIsInKS;
							
							if (!tiedPitches[pitch]) {
								var noteLabel = pitchLabels[diatonicPitchClass]+accidentals[acc+2];
								isBadAcc = false;
								
								// ** CHECK Cb OR Fb ** //
								if (keySig > -3) isBadAcc = tpc == 6 || tpc == 7;
								if (!isBadAcc && keySign < 3) isBadAcc = tpc == 25 || tpc == 26;
				
								noteNum = noteNum + 1;
								
								// check redundant accidentals
					
								// case 1: acc is different from prev, but prev was a long time a go
								// case 2: acc is same as prev and prev is in the same bar
								// case 3: acc is same as prev and acc is in ks
								//trace("currAccs = "&currAccs[diatonicPitch]&"; currPCAccs = "&currPCAccs[diatonicPitchClass]);
								if (currAccs[diatonicPitch] == acc && currPCAccs[diatonicPitchClass] == acc && accVisible) {
									prevBarNum = barAltered[diatonicPitch];
									if (barNum == prevBarNum || accIsInKS) {
										if (currGraceNoteAccs[diatonicPitch] == -8) {
											accidentalName = accidentalNames[acc+2];
											showError("You may not need to put an accidental on this note, as it was already a "+accidentalName+".",note);
										}
									}
								}
								
								// check courtesy accidentals
								if (currAccs[diatonicPitch] != acc) {
									//trace ("5");
									prevBarNum = barAltered[diatonicPitch];
									if (!accVisible && barNum != prevBarNum && barNum - prevBarNum < 2) {
										currentAccidental = accidentalNames[acc+2];
										prevAccidental = accidentalNames[currAccs[diatonicPitch] + 2];
										showError("It would be useful to put a courtesy "+currentAccidental+" on this note, as it was a "+prevAccidental+" in the previous bar.",note);
									}
									if ((accVisible = false) and (barNum = prevBarNum)) {
										currentAccidental = accidentalNames[acc+2];
										prevAccidental = accidentalNames[currAccs[diatonicPitch] + 2];
										showError("It would be useful to put a courtesy "+currentAccidental+" on this note, as it was a "+prevAccidental+" earlier in the bar.",note);
									}
									if (accVisible && currPCAccs[diatonicPitchClass] == acc) {
									if (barNum - prevBarNum > 2 && accIsInKS) {
										accidentalName = accidentalNames[acc+2];
										showError("You may not need to put an accidental on this note, as it was already a "+accidentalName+".",note);
									}
								}
					
								currAccs[diatonicPitch] = acc;
								currPCAccs[diatonicPitchClass] = acc;
								barAltered[diatonicPitch] = barNum;
								if (isGraceNote) currGraceNoteAccs[diatonicPitch] = acc;
								alterationLabel = "";
								showError = false;
								isAug = false;
								isDim = false;
								isAugDim = false;
								isTritone = false;
								whichNoteToRewrite = 2;
				
								if (prevPitch != -1) {
									scalarInterval = diatonicPitch - prevDiatonicPitch;
									chromaticInterval = pitch - prevPitch;
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
										if (scalarIntervalAbs = 7 and chromaticIntervalClass > 9) chromaticIntervalClass = chromaticIntervalClass - 12;
										dci = defaultChromaticInterval[scalarIntervalClass];
										alteration = chromaticIntervalClass - dci;
					
										// **		IS THIS AUGMENTED OR DIMINISHED? 		** //
										var isFourthFifthOrUnison = scalarIntervalClass == 0 || scalarIntervalClass == 3 || scalarIntervalClass == 4;
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
										isTritone = ((scalarIntervalClass == 3 && alteration == 1) || (scalarIntervalClass == 4 && alteration == -1)) {
											//trace ("scalarIntervalClass = "&scalarIntervalClass&". alterationLabel = "&alterationLabel&"; alteration = "&alteration&"; isAugDim = "&isAugDim&"; isTritone = "&isTritone);
		
					
										if (isAugDim) {
											showError = true;
											neverOK = false;
											neverOKRewriteIfPoss = false;
											OKRewriteIfPoss = true;
											showError = neverOK;
						
											if (OKRewriteIfPoss || neverOKRewriteIfPoss) {
												if (OKRewriteIfPoss) {
													showError = prevIsAugDim;
								
													// EXCEPTIONS
													// IGNORE AUG UNISON IF FOLLOWED BY ANOTHER ONE OR A TRITONE
													if (chromaticIntervalClass == 1 && (prevChromaticInterval == chromaticInterval || prevChromaticIntervalClass = 6)) showError = false;
								
													// IGNORE TRITONE IF FOLLOWED BY ANOTHER ONE OR A SEMITONE
													if (chromaticIntervalClass == 6 && (prevChromaticIntervalClass == 1 || prevChromaticIntervalClass = 6) showError = false;
												}
												if (neverOKRewriteIfPoss) showError = true;
												if (showError) {
													foundNote = false;
													if (!prevAccVisible && accVisible) {
														whichNoteToRewrite = 2;
														foundNote = true;
													}
													if (prevAccVisible && !accVisible) {
														whichNoteToRewrite = 1;
														foundNote = true;
													}
													if (!foundNote) {
														var weighting1 = Maths.abs(weightings[prevDiatonicPitchClass] + (prevAcc * 7) - keySig);
														var weighting2 = Maths.abs(weightings[diatonicPitchClass] + (acc * 7) - keySig);
														// rewrite the one that is the most outlying
														if (weighting1 > weighting2) {
															whichNoteToRewrite = 1;
														} else {
															whichNoteToRewrite = 2;
														}
													}
												}
											}
						
											// don't show error if we decide it"s the same note that needs to change
											if (prevShowError) {
												//trace ("prevWhichNoteToRewrite="&prevWhichNoteToRewrite&"; whichNoteToRewrite = "&whichNoteToRewrite);
												if (prevWhichNoteToRewrite == 2 && whichNoteToRewrite == 1) {
													showError = false;
												}
											}
											if (showError) {
												// DOES THIS OR PREV GO AGAINST THE WEIGHT?
												scalarIntervalLabel = intervalNames[scalarIntervalAbs];
												var article = alterationLabel == "augmented" ? "an" : "a";
												var noteToHighlight = nn;
												var theAccToChange = acc;
												var thePitchClassToChange = diatonicPitchClass;
												var prevNext = "previous";
												var newNotePitch = "";
												var newNoteAccidental = "";
												var flatten = isAug;
												var sharpen = !isAug;
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
													noteToHighlight = prevNn;
													prevNext = "next";
												}
												switch (theAccToChange) {
												case -2:
													if (!flatten) dialog.msg += "Error found with "+noteLabel+" in bar "+barNum+": should be spelt enharmonically downwards";
												//	trace ("bb");
													var i = thePitchClassToChange - 1;
													if (i < 0) i = i + 7;
													var newNotePitch = pitchLabels[i];
													if (newNotePitch === "B" || newNotePitch === "E") {
														newNoteAccidental = "b";
													} else {
														newNoteAccidental = "♮";
													}
													break;
													
												case -1:
													if (!flatten) dialog.msg += "Error found with "&noteLabel&" in bar "&barNum&": should be spelt enharmonically downwards";
													i = thePitchClassToChange - 1;
													if (i < 0) i = i + 7;
													newNotePitch = pitchLabels[i];
													if (newNotePitch === "B" || newNotePitch === "E") {
														newNoteAccidental = "♮";
													} else {
														newNoteAccidental = "#";
													}
													break;
													
												case 0:
													if (flatten) {
														i = thePitchClassToChange - 1;
														if (i < 0) {
															i = i + 7;
														}
													} else {
														i = (thePitchClassToChange + 1) % 7;
													}
													newNotePitch = pitchLabels[i];
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
													break;
													
												case 1: 
								
													if (!sharpen) dialog.msg += "Error with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards";
													i = (thePitchClassToChange + 1) % 7;
													newNotePitch = pitchLabels[i];
													if (newNotePitch === "F" || newNotePitch === "C") {
														newNoteAccidental = "♮";
													} else {
														newNoteAccidental = "b";
													}
													break;
													
												case 2: 
													if (!sharpen) dialog.msg += "\nError with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards";
													}
													i = (thePitchClassToChange + 1) % 7;
													newNotePitch = pitchLabels[i];
													if (newNotePitch = "F" or newNotePitch = "C") {
														newNoteAccidental = "#";
													} else {
														newNoteAccidental = "♮";
													}
												}
												if (newNotePitch === "") dialog.msg += "\nCouldnt find new note pitch";
												newNoteLabel = newNotePitch+newNoteAccidental;
							
												if (neverOKRewriteIfPoss || OKRewriteIfPoss) {
													var isBad = false;
													if (keySig > -3) isBad = (newNoteLabel === "Cb") || (newNoteLabel === "Fb");
													if (keySig < 3) isBad = (newNoteLabel === "B#") || (newNoteLabel === "E#");
													if (isBad) showError = false;
												}
												article = alterationLabel = "augmented" ? "an":"a";

					
												scalarIntervalLabel = intervalNames[scalarIntervalAbs];
												if (showError) showError("Interval with "+prevNext+" new pitch is "+article+" "+alterationLabel+" "+scalarIntervalLabel+". Consider respelling as "+newNoteLabel,noteToHighlight);
												break;
											}
										}
									}
								}
								isProblematic = false;
					
								if (isDoubleAcc) isProblematic = true;
								if (isBadAcc) isProblematic = true;
								var isMicrotonal = false;
								//if (supportsMicrotones = true) {
								//	if (acc = QuarterSharp or acc = ThreeQuarterSharp or acc = QuarterFlat or acc = ThreeQuarterFlat) {
								//		isMicrotonal = true;
								//	}
								//}
								if (!showError && accVisible && isProblematic && !isMicrotonal) {
						
									showError = true;
									theAccToChange = acc;
									thePitchClassToChange = diatonicPitchClass;
									noteToHighlight = nn;
									newNotePitch = "";
									switch (theAccToChange) {
									case -2:
										i = thePitchClassToChange - 1;
										if (i < 0) i = i + 7;
										newNotePitch = pitchLabels[i];
										if (newNotePitch === "B" || newNotePitch === "E") {
											newNoteAccidental = "b";
										} else {
											newNoteAccidental = "♮";
										}
										break;
									case -1:
										i = thePitchClassToChange - 1;
										if (i < 0) i = i + 7;
										newNotePitch = pitchLabels[i];
										if (newNotePitch === "B" || newNotePitch ==== "E") {
											newNoteAccidental = "♮";
										} else {
											newNoteAccidental = "#";
										}
										break;
										
									case 1:
										i = (thePitchClassToChange + 1) % 7;
										newNotePitch = pitchLabels[i];
										if (newNotePitch === "F" || newNotePitch === "C") {
											newNoteAccidental = "♮";
										} else {
											newNoteAccidental = "b";
										}
										break;
										
									case 2:
										i = (thePitchClassToChange + 1) % 7;
										newNotePitch = pitchLabels[i];
										if (newNotePitch === "F" || newNotePitch === "C") {
											newNoteAccidental = "#";
										} else {
											newNoteAccidental = "♮";
										}
										break;
									}
					
									if (newNotePitch == "") dialog.msg += ("\nCouldnt find new note pitch — "+thePitchClassToChange+" "+theAccToChange);
									newNoteLabel = newNotePitch+newNoteAccidental;
									if (showError) showError("Avoid writing "+noteLabel+"s. Consider respelling as "+newNoteLabel,noteToHighlight);
								}
				
								if (chromaticInterval != 0 || prevPitch = -1) {	
									prevNote = n;
									prevNn = nn;
									prevPitch = pitch;
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
									prevShowError = showError;
									prevIsTritone = isTritone;
									prevWhichNoteToRewrite = whichNoteToRewrite;
								}
							}
							tiedPitches[pitch] = note.tieForward;
						}
					}
				}
				segment = segment.next;
			}
		}
		//cursor.add(comment);
		//dialog.msg = "is Range = "+selection.isRange;
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
