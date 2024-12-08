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
	thumbnailName: "MNCheckAccidentals.png"
	
	
	// ** DEBUG **
	property var debug: true
	property var errorMsg: ''
	property var currentZ: 16384
	
	// **** PROPERTIES **** //

	property var selectionArray: []
	property var diatonicPitchAlts: []
	property var currAccs: []
	property var currPCAccs: []
	property var barAltered: []
	property var errorStrings: []
	property var errorObjects: []
	property var prevBarNum: 0
	property var prevMIDIPitch: -1
	property var prevDiatonicPitch
	property var prevPC: 0
	property var prevScalarInterval: 0
	property var prevScalarIntervalClass: 0
	property var prevScalarIntervalAbs: 0
	property var prevChromaticInterval: 0
	property var prevChromaticIntervalClass: 0
	property var prevDiatonicPitchClass: 0
	property var prevShowError: false
	property var prevAcc: 0
	property var prevAccVisible: false
	property var prevIsAugDim: false
	property var prevNote: null
	property var prevPrevNote: null
	property var prevAlterationLabel: ""
	property var currentKeySig: 0
	property var prevWhichNoteToRewrite: null
	property var commentPosArray: []
	property var kFlatStr: 'b'
	property var kNaturalStr: '♮'
	property var kSharpStr: '#'
	property var progressShowing: false
	property var progressStartTime: 0
	property var currentBarNum: 0
	property var currentClef: null
	property var clefOffset: 0
	property var isPercussionClef: false

  onRun: {
		if (!curScore) return;
		
		saveSelection();
		
		setProgress (0);
		
		// **** GATHER VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		
		// ************  		DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS 		************ //
		deleteAllCommentsAndHighlights();
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) selectAll();
		
		// ** INITIALIZE VARIABLES ** //
		currAccs = Array(120).fill(0);
		currPCAccs = Array(120).fill(0);
		barAltered = Array(120).fill(0);
		commentPosArray = Array(10000).fill(0);
		
		var startStaff = curScore.selection.startStaff;
		var endStaff = curScore.selection.endStaff;
		var cursor = curScore.newCursor();
		var firstBarInScore, firstBarInSelection, firstTickInSelection;
		var lastBarInScore, lastBarInSelection, lastTickInSelection;
		// start
		firstBarInScore = curScore.firstMeasure;
		cursor.rewind(Cursor.SELECTION_START);
		firstBarInSelection = cursor.measure;
		firstTickInSelection = cursor.tick;
		//errorMsg += "\nstartStaff="+startStaff+"; endStaff="+endStaff;
				
		var firstBarNum = 1, lastBarNum = 1;
		var currentBar = firstBarInScore;
		while (!currentBar.is(firstBarInSelection)) {
			firstBarNum ++;
			currentBar = currentBar.nextMeasure;
		}
		setProgress (1);
		
		// end
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
		//errorMsg += "\nfirstBarNum="+firstBarNum+"; lastBarNum="+lastBarNum;
				
		// ** LOOP THROUGH NOTES **//
		// ** NB — endStaff IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //
		var loop = 0;
		var numBars = lastBarNum - firstBarNum + 1;
		var totalNumLoops = numStaves * numBars * 4;
		setProgress (5);

		for (var currentStaffNum = startStaff; currentStaffNum < endStaff; currentStaffNum ++) {
			//if (!curScore.staves[currentStaffNum].part.show) continue;
			var theStaff = curScore.staves[currentStaffNum];
			var part = theStaff.part;
			var partVisible = part.show;
			errorMsg += "\n——— STAFF "+currentStaffNum+" ————";
			if (!partVisible) continue;
			
			
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
			
			// get start clef
			cursor.filter = Segment.HeaderClef;
			cursor.staffIdx = currentStaffNum;
			cursor.voice = 0;
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == null) cursor.next();
			currentClef = cursor.element;
			checkClef ();
			
			// ** REWIND TO START OF SELECTION ** //
			cursor.filter = Segment.All;
			cursor.rewind(Cursor.SELECTION_START);
			cursor.staffIdx = currentStaffNum;
			cursor.filter = Segment.ChordRest | Segment.Clef;
			currentBar = cursor.measure;
			currentKeySig = cursor.keySignature;
			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
				errorMsg += "\nb. "+currentBarNum;
				loop++;
				setProgress(5+loop*95./totalNumLoops);
				var startTrack = currentStaffNum * 4;
				var endTrack = startTrack + 4;
				var barStart = currentBar.firstSegment.tick;
				var barEnd = currentBar.lastSegment.tick;
				
				for (var currentTrack = startTrack; currentTrack < endTrack; currentTrack++) {
					//errorMsg += "\n\nTrack "+currentTrack;
					
					cursor.track = currentTrack;
					cursor.rewindToTick(barStart);
					var processingThisBar = cursor.element && cursor.tick < barEnd;
					
					while (processingThisBar) {
						var eType = cursor.element.type;
						if (eType == Element.CLEF) {
							currentClef = cursor.element;
							checkClef();
						} else {
							if (!isPercussionClef) {
								var noteRest = cursor.element;
								//errorMsg += "\n\nFound "+noteRest.name+" at "+cursor.tick;
								var isRest = noteRest.type == Element.REST;
								var graceNoteChords = noteRest.graceNotes;
								if (graceNoteChords != null) {
									for (var g in graceNoteChords) {
										checkChord (graceNoteChords[g],noteRest.parent,currentBarNum,currentStaffNum);
									}
								}	
								if (!isRest) {		
									checkChord (noteRest,noteRest.parent,currentBarNum,currentStaffNum);
								}
							}
						}
						if (cursor.next()) {
							processingThisBar = cursor.measure.is(currentBar);
						} else {
							processingThisBar = false;
						}
					} // end while Processing this bar
				} // end track loop
				if (currentBar) currentBar = currentBar.nextMeasure;
				
			} // end of currentBarNum loop
			
		} // staff num loop
		// ** SHOW ALL OF THE ERRORS ** //
		showAllErrors();
		
		// ** SHOW INFO DIALOG ** //

		var numErrors = errorStrings.length;
		if (numErrors == 0) errorMsg = "SCORE CHECK COMPLETED\n\nCongratulations! No errors found!\n\nLog:" + errorMsg;
		if (numErrors == 1) errorMsg = "SCORE CHECK COMPLETED\n\nOne error found.\n\nLog:" + errorMsg;
		if (numErrors > 1) errorMsg = "SCORE CHECK COMPLETED\n\nI found "+numErrors+" errors.\n\nLog:" + errorMsg;
			
		restoreSelection();
		dialog.msg = errorMsg;
		dialog.show();
	}
	
	function checkClef () {
		var clefId = currentClef.subtypeName();
		//errorMsg += "\nChecking clef — "+clefId+" "+currentInstrumentName;
		var isTrebleClef = clefId.includes("Treble clef");
		var isAltoClef = clefId === "Alto clef";
		var isTenorClef = clefId === "Tenor clef";
		var isBassClef = clefId.includes("Bass clef");
		var clefIs8va = clefId.includes("8va alta");
		var clefIs15ma = clefId.includes("15ma alta");
		var clefIs8ba = clefId.includes("8va bassa");
		
		// set this property so that we can ignore any notes
		isPercussionClef = clefId === "Percussion";
		
		if (isTrebleClef) clefOffset = 0;
		if (isAltoClef) clefOffset = -6; // C4 = 35
		if (isTenorClef) clefOffset = -8; // A3 = 33
		if (isBassClef) clefOffset = -12; // D3 = 29
		if (clefIs8va) clefOffset += 7;
		if (clefIs15ma) clefOffset += 14;
		if (clefIs8ba) clefOffset -= 7;
	}
	
	function checkChord (chord,theSegment,barNum,staffNum) {
		var defaultChromaticInterval = [0,2,4,5,7,9,11];
		var accTypes = [Accidental.FLAT2, Accidental.FLAT, Accidental.NATURAL, Accidental.SHARP, Accidental.SHARP2];
		var pitchLabels = ["C","D","E","F","G","A","B"];
		var intervalNames = ["unison","second","third","fourth","fifth","sixth","seventh","octave","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth"];
		var majorIntervalAlts = ["double diminished","diminished","minor","major","augmented","double augmented"];
		var perfectIntervalAlts = ["triple diminished","double diminished","diminished","perfect","augmented","double augmented"];
		var weightings = [-2,0,3,-3,-1,1,4];

		var accidentals = ["bb",kFlatStr,kNaturalStr,kSharpStr,"x"];
		var accidentalNames = ["double flat","flat","natural","sharp","double sharp"];
		var isBadAcc = false;
		var isProblematic, accidentalName, currentAccidental, prevAccidental;
		
		var notes = chord.notes;
		var numNotes = notes.length;
		//errorMsg += "\nChecking chord... has "+numNotes+" notes";
		
		for (var i = 0; i < numNotes; i ++) {
			//errorMsg += "\ni = "+i;
				
			var note = notes[i];
			var currTick = theSegment.tick;
			var measure = theSegment.parent

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
			var l = note.line; // 0 is F5, 1 is E5, 2 is D5, 3 is C5
			var octave = Math.floor((3-l+clefOffset)/7)+6; // lowest possible note needs to be octave 0 — i.e. C-1 (midiPitch 0) will be octave 0; therefore C4 will be octave 5
			var diatonicPitchClass = (((tpc+1)%7)*4+3) % 7;
			var diatonicPitch = diatonicPitchClass+octave*7; // diatonic pitch is where 
			//errorMsg += "\n\nline="+note.line+" octave="+octave+"\ndiatonicPitch="+diatonicPitch+" prevDiatonicPitch="+prevDiatonicPitch+" diatonicPitchClass="+diatonicPitchClass;

			var accIsInKS = false;
			if (currentKeySig == 0 && accType == Accidental.NATURAL) accIsInKS = true;
			if (currentKeySig > 0) {
				accOrder = ((diatonicPitchClass + 4) * 2) % 7;
				if (accType == Accidental.SHARP) {
					//errorMsg += "\nhere";
					accIsInKS = accOrder < currentKeySig;
				}
				if (accType == Accidental.NATURAL) accIsInKS = (accOrder + 1) > currentKeySig; 
			}
			if (currentKeySig < 0) {
				accOrder = (2 * (13 - diatonicPitchClass)) % 7;
				if (accType == Accidental.FLAT) accIsInKS = accOrder < Math.abs(currentKeySig);
				if (accType == Accidental.NATURAL) accIsInKS = (accOrder + 1) > Math.abs(currentKeySig);
			}
			//errorMsg += "accInKeySig = "+accIsInKS+"; accType = "+accType+";";

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
							addError("This was already a "+accidentalName+".",note);
					}
				}
				// check courtesy accidentals
				if (currAccs[diatonicPitch] != acc) {
					prevBarNum = barAltered[diatonicPitch];
					if (prevBarNum > 0) {
						if (!accVisible && barNum != prevBarNum && barNum - prevBarNum < 2) {
							currentAccidental = accidentalNames[acc+2];
							prevAccidental = accidentalNames[currAccs[diatonicPitch] + 2];
							addError("Put a courtesy "+currentAccidental+" on this note,\nas it was a "+prevAccidental+" in the previous bar.",note);
						}
						if (!accVisible && barNum == prevBarNum) {
							currentAccidental = accidentalNames[acc+2];
							prevAccidental = accidentalNames[currAccs[diatonicPitch] + 2];
							addError("Put a courtesy "+currentAccidental+" on this note,\nas it was a "+prevAccidental+" earlier in the bar.",note);
						}
						if (accVisible && currPCAccs[diatonicPitchClass] == acc) {
							if (barNum - prevBarNum > 2 && accIsInKS) {
								accidentalName = accidentalNames[acc+2];
								addError("This was already a "+accidentalName+".",note);
							}
						}
					}
				}
				currAccs[diatonicPitch] = acc;
				currPCAccs[diatonicPitchClass] = acc;
				if (accVisible && !accIsInKS) {
					barAltered[diatonicPitch] = barNum;
					//errorMsg += "\nAdded bar "+barNum+" to barAltered["+diatonicPitch+"]";
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
				
				if (prevMIDIPitch != -1 && prevDiatonicPitch != -1) {
					
					scalarInterval = diatonicPitch - prevDiatonicPitch;
					chromaticInterval = MIDIpitch - prevMIDIPitch;
					//errorMsg += "\nscalarInterval="+scalarInterval+" chromaticInterval="+chromaticInterval;
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
						//errorMsg += "\nscalarIntervalAbs="+scalarIntervalAbs+"; scalarIntervalClass="+scalarIntervalClass+"\nchromaticIntervalAbs="+chromaticIntervalAbs+"; chromaticIntervalClass="+chromaticIntervalClass;
						
						if (scalarIntervalAbs == 7 && chromaticIntervalClass > 9) chromaticIntervalClass = chromaticIntervalClass - 12;
						var dci = defaultChromaticInterval[scalarIntervalClass];
						var alteration = chromaticIntervalClass - dci;
						//errorMsg += "\ndci="+dci+" alt="+alteration;

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
							//errorMsg += "\nisAug: "+isAug+"; isDim: "+isDim;
							
							var neverOK = false;
							var neverOKRewriteIfPoss = false;
							var OKRewriteIfPoss = true;

							doShowError = prevIsAugDim;
	
							// EXCEPTIONS
							// IGNORE AUG UNISON IF FOLLOWED BY ANOTHER ONE OR A TRITONE
							if (chromaticIntervalClass == 1 && (prevChromaticInterval == chromaticInterval || prevChromaticIntervalClass == 6)) doShowError = false;
	
							// IGNORE TRITONE IF FOLLOWED BY ANOTHER ONE OR A SEMITONE
							if (chromaticIntervalClass == 6 && (prevChromaticIntervalClass == 1 || prevChromaticIntervalClass == 6)) doShowError = false;
															
							if (doShowError) {
								var foundNote = false;
								
								if (!prevAccVisible && accVisible) {
									//errorMsg += "\nwhichNoteToRewrite = 2";
									whichNoteToRewrite = 2;
									foundNote = true;
								}
								if (prevAccVisible && !accVisible) {
									//errorMsg += "\nwhichNoteToRewrite = 1";
									whichNoteToRewrite = 1;
									foundNote = true;
								}
								if (!foundNote) {
									var weighting1 = Math.abs(weightings[prevDiatonicPitchClass] + (prevAcc * 7) - currentKeySig);
									var weighting2 = Math.abs(weightings[diatonicPitchClass] + (acc * 7) - currentKeySig);
									// rewrite the one that is the most outlying
									//errorMsg += "\nW1: prevDiatonicPitchClass="+prevDiatonicPitchClass+"; prevAcc * 7: "+prevAcc * 7+"; keySig: "+currentKeySig;

									if (weighting1 > weighting2) {
										whichNoteToRewrite = 1;
									} else {
										whichNoteToRewrite = 2;
									}
									//errorMsg += "\nWeighting1: "+weighting1+"; weighting2: "+weighting2+"; ntr = "+whichNoteToRewrite;
									
								} // if !foundNote
							} // if doshowerror
							
								//
							
								//} //OKRewriteIfPoss || neverOKRewriteIfPoss*/
							
							// don't show error if we decide it"s the same note that needs to change
							if (prevShowError && prevWhichNoteToRewrite == 2 && whichNoteToRewrite == 1) doShowError = false;
							if (doShowError) {
								//errorMsg += "\n***** SHOW ERROR";
								
								// DOES THIS OR PREV GO AGAINST THE WEIGHT?
								scalarIntervalLabel = intervalNames[scalarIntervalAbs];

								//errorMsg += "\nscalarIntervalAbs = "+scalarIntervalAbs+"; scalarIntervalLabel="+scalarIntervalLabel;
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
									//errorMsg += "\nChoosing prev note: theAccToChange="+theAccToChange+" pc2change="+thePitchClassToChange;
									
								}
								
								var j = 0;
								switch (theAccToChange) {
									case -2:
										//if (!flatten) errorMsg += "Error found with "+noteLabel+" in bar "+barNum+": should be spelt enharmonically downwards";
									//	trace ("bb");
										j = thePitchClassToChange - 1;
										if (j < 0) j += 7;
										var newNotePitch = pitchLabels[j];
										if (newNotePitch === "B" || newNotePitch === "E") {
											newNoteAccidental = kFlatStr;
										} else {
											newNoteAccidental = kNaturalStr;
										}
										//errorMsg += "\n-2 ";
										
										break;
						
									case -1:
										//if (!flatten) errorMsg += "Error found with "&noteLabel&" in bar "&barNum&": should be spelt enharmonically downwards";
										j = thePitchClassToChange - 1;
										if (j < 0) j+=7;
										newNotePitch = pitchLabels[j];
										if (newNotePitch === "B" || newNotePitch === "E") {
											newNoteAccidental = kNaturalStr;
										} else {
											newNoteAccidental = kSharpStr;
										}
										//errorMsg += "\n-1 ";
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
												newNoteAccidental = kSharpStr;
											} else {
												newNoteAccidental = "x";
											}
										} else {
											if (newNotePitch === "C" || newNotePitch === "F") {
												newNoteAccidental = kFlatStr;
											} else {
												newNoteAccidental = "bb";
											}
										}
										//errorMsg += "\n0 ";
										break;
						
									case 1:
										//if (!sharpen) errorMsg += "Error with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards";
										j = (thePitchClassToChange + 1) % 7;
										newNotePitch = pitchLabels[j];
										if (newNotePitch === "F" || newNotePitch === "C") {
											newNoteAccidental = kNaturalStr;
										} else {
											newNoteAccidental = kFlatStr;
										}
										//errorMsg += "\n1 ";
										break;
						
									case 2: 
										//if (!sharpen) errorMsg += "\nError with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards";
										j = (thePitchClassToChange + 1) % 7;
										newNotePitch = pitchLabels[j];
										if (newNotePitch === "F" || newNotePitch === "C") {
											newNoteAccidental = kSharpStr;
										} else {
											newNoteAccidental = kNaturalStr;
										}
										//errorMsg += "\n2 ";
										break;
								}
								//if (newNotePitch === "") errorMsg += "\nCouldnt find new note pitch";
								var newNoteLabel = newNotePitch+newNoteAccidental;

								//if (neverOKRewriteIfPoss || OKRewriteIfPoss) {
									var changeIsBad = false;
									if (currentKeySig > -3) changeIsBad = (newNoteLabel === "C"+kFlatStr) || (newNoteLabel === "F"+kFlatStr);
									if (currentKeySig < 3) changeIsBad = (newNoteLabel === "B"+kSharpStr) || (newNoteLabel === "E"+kSharpStr);
									//if (isBad) doShowError = false;
									//}
								if (doShowError && !changeIsBad) {
									var t = "Interval with "+prevNext+" pitch is "+article+" "+alterationLabel+" "+scalarIntervalLabel+".\nConsider respelling as "+newNoteLabel;
									// "\n"+t;
									//errorMsg += "\n******** Note to highlight = "+noteToHighlight;
									//errorMsg += "\n"+staffNum;
									addError(t,noteToHighlight);
								} else {
									//errorMsg += "\nDid not show error cos doShowError="+doShowError+" & changeIsBad="+changeIsBad;
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
							//errorMsg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "B" || newNotePitch === "E") {
								newNoteAccidental = kFlatStr;
							} else {
								newNoteAccidental = kNaturalStr;
							}
							break;
						case -1:
							i = thePitchClassToChange - 1;
							if (i < 0) i += 7;
							newNotePitch = pitchLabels[i];
							//errorMsg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "B" || newNotePitch === "E") {
								newNoteAccidental = kNaturalStr;
							} else {
								newNoteAccidental = kSharpStr;
							}
							break;
			
						case 1:
							i = (thePitchClassToChange + 1) % 7;
							newNotePitch = pitchLabels[i];
							//errorMsg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "F" || newNotePitch === "C") {
								newNoteAccidental = kNaturalStr;
							} else {
								newNoteAccidental = kFlatStr;
							}
							break;
			
						case 2:
							i = (thePitchClassToChange + 1) % 7;
							newNotePitch = pitchLabels[i];
							//errorMsg += "newNotePitch: "+newNotePitch+"; i="+i;
							if (newNotePitch === "F" || newNotePitch === "C") {
								newNoteAccidental = kSharpStr;
							} else {
								newNoteAccidental = kNaturalStr;
							}
							break;
					} // end switch TeAccToChange

					if (newNotePitch === "") errorMsg += ("\nCouldnt find new note pitch — "+thePitchClassToChange+" "+theAccToChange);
					newNoteLabel = newNotePitch+newNoteAccidental;
					if (doShowError) addError("Avoid writing "+noteLabel+"s.\nConsider respelling as "+newNoteLabel,noteToHighlight);
				} // end if (!doShowError && accVisible && isProblematic && !isMicrotonal)

				if (chromaticInterval != 0 || prevMIDIPitch == -1) {	
					prevNote = note;
					//errorMsg += "\nprevNote now "+prevNote;
					prevMIDIPitch = MIDIpitch;
					//errorMsg += "\nprevMIDIPitch now "+prevMIDIPitch;
					
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
				var elapsedTime = currentTime - progressStartTime;
				//errorMsg += "\nelapsedTime now "+elapsedTime;
				if (elapsedTime > 3000) {
					progress.show();
					progressShowing = true;
				}
			} else {
				progress.progressPercent = percentage;
			}
		}
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
	
	function selectAll () {
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,curScore.nstaves);
		curScore.endCmd();
		var startStaff = curScore.selection.startStaff;
		var endStaff = curScore.selection.endStaff;
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
	
	function addError (text,element) {
		errorStrings.push(text);
		errorObjects.push(element);
	}
	
	function showAllErrors () {
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
				element = objectArray[j];
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
						if (theLocation === "system2" && !hasMoreThanOneSystem) continue; // don't show if only one system
					}
				} else {
					// calculate the staff number that this element is on
					if (element.bbox == undefined) {
						errorMsg += "\nbbox undefined — elem type is "+element.name;
					} else {
						elementHeight = element.bbox.height;
						if (eType != Element.MEASURE) {
							var elemStaff = element.staff;
							while (!curScore.staves[staffNum].is(elemStaff)) staffNum ++; // I WISH: staffNum = element.staff.staffidx
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
				var tick = 0, desiredPosX = 0, desiredPosY = 0;
				var spannerArray = [Element.HAIRPIN, Element.SLUR, Element.PEDAL, Element.PEDAL_SEGMENT, Element.OTTAVA, Element.OTTAVA_SEGMENT];
				if (isString) {
					if (theLocation === "pagetop") {
						desiredPosX = 2.5;
						desiredPosY = 10.;
					}
					if (theLocation === "system1" || theLocation === "system2") desiredPosX = 5.0;
					if (theLocation === "system2") tick = firstBarInSecondSystem.firstSegment.tick;
				} else {
					if (spannerArray.includes(eType)) {
						tick = element.spannerTick.ticks;
					} else {
						if (eType == Element.MEASURE) {
							tick = element.firstSegment.tick;
						} else {
							if (element.parent == undefined || element.parent == null) {
								errorMsg += "\nELEMENT PARENT IS "+element.parent+"; etype is "+element.name;
							} else {
								if (element.parent.type == Element.CHORD) {
									// it's either a notehead or a gracenote
									if (element.parent.parent.type == Element.CHORD) {
										// it's a grace note, so need to get parent of parent
										tick = element.parent.parent.parent.tick;
									} else {
										tick = element.parent.parent.tick;
									}
								} else {
									tick = element.parent.tick;
								}
							}
						}
					}
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
				}		
			}
		}
		curScore.endCmd();
	}
	
	ApplicationWindow {
		id: dialog
		title: "COMPLETION"
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
