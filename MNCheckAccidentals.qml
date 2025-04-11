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
	property var numLogs: 0
	
	// **** PROPERTIES **** //

	property var selectionArray: []
	property var diatonicPitchAlts: []
	property var currAccs: []
	property var currPCAccs: []
	property var wasGraceNote: []
	property var barAltered: []
	property var barAlteredPC: []
	property var errorStrings: []
	property var errorObjects: []
	property var prevBarNum: 0
	property var prevMIDIPitch: -1
	property var prevPrevMIDIPitch: -1
	property var prevDiatonicPitch: 0
	property var prevPC: 0
	property var prevScalarInterval: 0
	property var prevScalarIntervalClass: 0
	property var prevScalarIntervalAbs: 0
	property var prevChromaticInterval: 0
	property var prevChromaticIntervalClass: 0
	property var prevDiatonicPitchClass: 0
	property var prevPrevDiatonicPitchClass: 0
	property var prevShowError: false
	property var prevAcc: 0
	property var prevPrevAcc: 0
	property var prevAccVisible: false
	property var prevIsAugDim: false
	property var prevNote: null
	property var prevPrevNote: null
	property var prevAlterationLabel: ""
	property var prevIsTritone: false
	property var currentKeySig: 0
	property var prevWhichNoteToRewrite: null
	property var kFlatStr: 'b'
	property var kNaturalStr: '♮'
	property var kSharpStr: '#'
	property var progressShowing: false
	property var progressStartTime: 0
	property var currentBarNum: 0
	property var currentStaffNum: 0
	property var currentClef: null
	property var clefOffset: 0
	property var isPercussionClef: false
	property var prevAccInKeySig: false
	property var cmdKey: 'command'
	property var thisNoteHighlighted: false
	property var prevNoteHighlighted: false
	property var prevPrevNoteHighlighted: false
	property var scoreIncludesTransposingInstrument: false
	property var lastAccidentalBarNum: 0

  onRun: {
		if (!curScore) return;
		
		// ** VERSION CHECK ** //
		if (MuseScore.mscoreMajorVersion < 4 || (MuseScore.mscoreMajorVersion == 4 && MuseScore.mscoreMajorVersion < 4)) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin requires at MuseScore v. 4.4 or later.</p> ";
			dialog.show();
			return;
		}
		
		saveSelection();
		
		setProgress (0);
		
		// **** GATHER VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		if (Qt.platform.os !== "osx") cmdKey = "ctrl";
		
		// ************  		DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS 		************ //
		deleteAllCommentsAndHighlights();
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) selectAll();
		
		// **** INITIALIZE VARIABLES **** //
		currAccs = Array(120).fill(0);
		currPCAccs = Array(7).fill(0);
		barAltered = Array(120).fill(0);
		barAlteredPC = Array(7).fill(0);
		
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
		
		var firstSystem = firstBarInScore.parent;
		var lastSystem = lastBarInScore.parent;
		var firstPage = firstSystem.parent;
		var lastPage = lastSystem.parent;
		var firstPageNum = firstPage.pagenumber;
		var lastPageNum = lastPage.pagenumber;
				
		// ** LOOP THROUGH NOTES **//
		// ** NB — endStaff IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //
		var loop = 0;
		var numBars = lastBarNum - firstBarNum + 1;
		var totalNumLoops = numStaves * numBars * 4;
		setProgress (5);
		
		checkTransposingInstruments();
		// ************					CHECK IF SCORE IS TRANSPOSED				************ //
		if (curScore.style.value("concertPitch") && scoreIncludesTransposingInstrument) addError ("It looks like you have at least one transposing instrument, but the score is currently displayed in concert pitch.\nBecause of this, comments about accidentals may not be accurate for the transposed/written parts.\nUntick ‘Concert Pitch’ in the bottom right, and re-run the plugin.","pagetop");

		for (currentStaffNum = startStaff; currentStaffNum < endStaff; currentStaffNum ++) {
			
			// ** IGNORE IF THIS STAFF IS HIDDEN ** //
			var theStaff = curScore.staves[currentStaffNum];
			var part = theStaff.part;
			var partVisible = part.show;
			if (!partVisible) continue;

			// ** RESET ALL VARIABLES TO THEIR DEFAULTS ** //
			prevMIDIPitch = -1;
			prevPrevMIDIPitch = -1;
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
			prevAccInKeySig = false;
			thisNoteHighlighted = false;
			prevNoteHighlighted = false;
			prevPrevNoteHighlighted = false;
			prevIsTritone = false;

			// clear the arrays
			currAccs.fill(0);
			currPCAccs.fill(0);
			barAltered.fill(0);
			barAlteredPC.fill(0);
			
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
			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
				//logError(b. "+currentBarNum);
				loop++;
				setProgress(5+loop*95./totalNumLoops);
				var startTrack = currentStaffNum * 4;
				var endTrack = startTrack + 4;
				var barStart = currentBar.firstSegment.tick;
				var barEnd = currentBar.lastSegment.tick;
				
				for (var currentTrack = startTrack; currentTrack < endTrack; currentTrack++) {
					//logError(\nTrack "+currentTrack);
					
					cursor.track = currentTrack;
					cursor.rewindToTick(barStart);
					var processingThisBar = cursor.element && cursor.tick < barEnd;
					
					while (processingThisBar) {
						currentKeySig = cursor.keySignature;
						var eType = cursor.element.type;
						if (eType == Element.CLEF) {
							currentClef = cursor.element;
							checkClef();
						} else {
							if (!isPercussionClef) {
								var noteRest = cursor.element;
								//logError(\nFound "+noteRest.name+" at "+cursor.tick);
								var isRest = noteRest.type == Element.REST;
								var graceNoteChords = noteRest.graceNotes;
								if (graceNoteChords != null) {
									for (var g in graceNoteChords) {
										checkChord (graceNoteChords[g],noteRest.parent,true);
									}
								}	
								if (!isRest) checkChord (noteRest,noteRest.parent,false);
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
		
		// ************  								RESTORE PREVIOUS SELECTION 							************ //
		restoreSelection();
		
		// ** SHOW INFO DIALOG ** //
		var numErrors = errorStrings.length;
		if (errorMsg != "") errorMsg = "<p>————————————<p><p>ERROR LOG (for developer use):</p>" + errorMsg;
		if (numErrors == 0) errorMsg = "<p>CHECK COMPLETED: Congratulations — no issues found!</p><p><font size=\"6\">🎉</font></p>"+errorMsg;
		if (numErrors == 1) errorMsg = "<p>CHECK COMPLETED: I found one issue.</p><p>Please check the score for the yellow comment box that provides more details of the issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove the comment and pink highlight.</p>" + errorMsg;
		if (numErrors > 1) errorMsg = "<p>CHECK COMPLETED: I found "+numErrors+" issues.</p><p>Please check the score for the yellow comment boxes that provide more details on each issue.</p><p>Use the ‘MN Delete Comments And Highlights’ plugin to remove all of these comments and highlights.</p>" + errorMsg;		
		if (progressShowing) progress.close();
		
		var h = 250+numLogs*10;
		if (h > 500) h =500;
		dialog.height = h;
		dialog.contentHeight = h;
		dialog.msg = errorMsg;
		dialog.show();
	}
	
	function checkClef () {
		var clefId = currentClef.subtypeName();
		//logError(Checking clef — "+clefId+" "+currentInstrumentName);
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
	
	function checkTransposingInstruments() {
		var transposingInstruments = ["brass.bugle.soprano","brass.bugle.mellophone-bugle","brass.bugle.baritone","brass.bugle.contrabass","brass.cornet","brass.euphonium","brass.flugelhorn","brass.french-horn","brass.trumpet.bflat","brass.trumpet.d","brass.trumpet.piccolo","wind.flutes.flute.alto","wind.flutes.flute.bass","wind.reed.clarinet","wind.reed.english-horn","wind.reed.oboe-damore","wind.reed.saxophone"];
		for (var i = 0; i < curScore.nstaves; i++) {
			// save the id and staffName
			var part = curScore.staves[i].part;
			if (part.show) {
				var id = part.instrumentId;
				for (var j = 0; j < transposingInstruments.length; j++) {
					if (id.includes(transposingInstruments[j])) scoreIncludesTransposingInstrument = true;
					return;
				}
			}
		}
	}
	
	function checkChord (chord,theSegment,isGraceNote) {
		//logError("checking chord");
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
		var numAccidentals = 0;

		prevPrevNoteHighlighted = prevNoteHighlighted;
		prevNoteHighlighted = thisNoteHighlighted;
		thisNoteHighlighted = false;
		
		for (var i = 0; i < numNotes; i ++) {				
			var note = notes[i];
			var currTick = theSegment.tick;
			var measure = theSegment.parent

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
				if (accVisible) lastAccidentalBarNum = currentBarNum;
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
			var MIDIPitch = note.pitch;
			var l = note.line; // 0 is F5, 1 is E5, 2 is D5, 3 is C5
			var octave = Math.floor((3-l+clefOffset)/7)+6; // lowest possible note needs to be octave 0 — i.e. C-1 (midiPitch 0) will be octave 0; therefore C4 will be octave 5
			var diatonicPitchClass = (((tpc+1)%7)*4+3) % 7;
			var diatonicPitch = diatonicPitchClass+octave*7; // diatonic pitch is where 
			//logError(\nline="+note.line+" octave="+octave+"\ndiatonicPitch="+diatonicPitch+" prevDiatonicPitch="+prevDiatonicPitch+" diatonicPitchClass="+diatonicPitchClass);

			var accInKeySig = false;
			if (currentKeySig == 0 && accType == Accidental.NATURAL) accInKeySig = true;
			if (currentKeySig > 0) {
				accOrder = ((diatonicPitchClass + 4) * 2) % 7;
				if (accType == Accidental.SHARP) {
					//logError(here");
					accInKeySig = accOrder < currentKeySig;
				}
				if (accType == Accidental.NATURAL) accInKeySig = (accOrder + 1) > currentKeySig; 
			}
			if (currentKeySig < 0) {
				accOrder = (2 * (13 - diatonicPitchClass)) % 7;
				if (accType == Accidental.FLAT) accInKeySig = accOrder < Math.abs(currentKeySig);
				if (accType == Accidental.NATURAL) accInKeySig = (accOrder + 1) > Math.abs(currentKeySig);
			}
			//errorMsg += "accInKeySig = "+accInKeySig+"; accType = "+accType+";";

			if (!note.tieBack) {
				var noteLabel = pitchLabels[diatonicPitchClass]+accidentals[acc+2];
				isBadAcc = false;
	
				// ** CHECK Cb OR Fb ** //
				if (currentKeySig > -3) isBadAcc = (tpc == 6 || tpc == 7);
				if (!isBadAcc && currentKeySig < 3) isBadAcc = (tpc == 25 || tpc == 26);

				// **** CHECK UNNECESSARY ACCIDENTALS **** //
				// **** THERE ARE THREE SITUATIONS WE WANT TO FLAG THIS **** //
				
				// **** First we check when this specific pitch was last altered **** //
				prevBarNum = barAltered[diatonicPitch];

				// **** 1. THIS ACCIDENTAL WAS SET EARLIER IN THE BAR (currentBarNum == prevBarNum)
				var situation1 = currAccs[diatonicPitch] == acc && currentBarNum == prevBarNum && accVisible;
				
				// **** 2. THIS ACCIDENTAL WAS IN THE KEY SIGNATURE ALREADY AND THE PREVIOUS ACCIDENTAL WAS AT LEAST 2 BARS AGO
				var situation2 = accInKeySig && currentBarNum > prevBarNum + 2 && accVisible;
				
				// **** 3. THIS ACCIDENTAL WAS IN THE KEY SIGNATURE ALREADY AND THIS WAS ALSO THE PREVIOUS ACCIDENTAL SET IN ANY BAR
				var situation3 = accInKeySig && currAccs[diatonicPitch] == acc && accVisible;
				
				// **** Also, only flag if:
				// **** 	a) the accidental is visible
				// ****		b) if the previous accidental was not a grace note
				// ****		c) the accidental does not have a bracket around it
				var otherAccFlags = accVisible && !wasGraceNote[diatonicPitchClass] && accObject.accidentalBracket == 0;
				if ((situation1 || situation2 || situation3) && otherAccFlags) addError("This was already a "+accidentalNames[acc+2]+".",note);
				
				// **** CHECK NOTES NEEDING COURTESY ACCIDENTALS **** //
				var prevBarNumPC = barAlteredPC[diatonicPitchClass];

				//logError (acc+" "+currAccs[diatonicPitch]+" "+currPCAccs[diatonicPitchClass]+" "+prevBarNum+" "+prevBarNumPC);
				if (currAccs[diatonicPitch] != acc || currPCAccs[diatonicPitchClass] != acc) {
					
					// **** For courtesy accidentals, we can check when this ** pitch class ** was last altered **** //

					if (prevBarNum > 0 || prevBarNumPC != 0) {
						// SITUATION 1
						// An accidental in any octave in prev bar
						if (!accVisible && currentBarNum != prevBarNumPC && currentBarNum - prevBarNumPC < 2) {
							currentAccidental = accidentalNames[acc+2];
							prevAccidental = accidentalNames[currPCAccs[diatonicPitchClass] + 2];
							addError("Put a courtesy "+currentAccidental+" on this note,\nas it was a "+prevAccidental+" in the previous bar.",note);
						}
						
						// SITUATION 2
						// An accidental in any octave in this bar
						if (!accVisible && currentBarNum != prevBarNum && currentBarNum == prevBarNumPC && currPCAccs[diatonicPitchClass] != acc) {
							currentAccidental = accidentalNames[acc+2];
							prevAccidental = accidentalNames[currPCAccs[diatonicPitchClass] + 2];
							addError("Put a courtesy "+currentAccidental+" on this note,\nas it was a "+prevAccidental+" earlier in the bar.",note);
						}
					}
				}
				
				currAccs[diatonicPitch] = acc;
				currPCAccs[diatonicPitchClass] = acc;
				wasGraceNote[diatonicPitchClass] = isGraceNote;
				
				if (accVisible && !accInKeySig) barAlteredPC[diatonicPitchClass] = currentBarNum;
				barAltered[diatonicPitch] = currentBarNum;
				
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
					chromaticInterval = MIDIPitch - prevMIDIPitch;
					//logError(scalarInterval="+scalarInterval+" chromaticInterval="+chromaticInterval);
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
						//logError(scalarIntervalAbs="+scalarIntervalAbs+"); scalarIntervalClass="+scalarIntervalClass+"\nchromaticIntervalAbs="+chromaticIntervalAbs+"; chromaticIntervalClass="+chromaticIntervalClass;
						
						if (scalarIntervalAbs == 7 && chromaticIntervalClass > 9) chromaticIntervalClass = chromaticIntervalClass - 12;
						var dci = defaultChromaticInterval[scalarIntervalClass];
						var alteration = chromaticIntervalClass - dci;
						isTritone = (chromaticIntervalClass == 6);
						
						// **** CHECK CHROMATIC ASCENTS AND DESCENTS **** //
						if (prevPrevMIDIPitch != -1) {
							//logError(prevPrevMIDIPitch = "+prevPrevMIDIPitch+"); prevMIDIPitch="+prevMIDIPitch+" MIDIPitch="+MIDIPitch;
							if (prevMIDIPitch - prevPrevMIDIPitch == 1 && MIDIPitch - prevMIDIPitch == 1 && !prevPrevNote.parent.is(prevNote.parent) && !prevNote.parent.is(chord)) {
								//logError(Found Chromatic Ascent");
								
								if (previousNoteRestIsNote(prevNote) && previousNoteRestIsNote(note)){
									if (prevAcc < 0 && !prevAccInKeySig) addError ("Use of a flat during a chromatic ascent leads to avoidable natural sign.\nConsider respelling (select the note and press "+cmdKey+"-J).", prevNote);
								}
							}
							if (prevMIDIPitch - prevPrevMIDIPitch == -1 && MIDIPitch - prevMIDIPitch == -1 && !prevPrevNote.parent.is(prevNote.parent) && !prevNote.parent.is(chord)) {
								//logError(Found Chromatic Descent");
								if (previousNoteRestIsNote(prevNote) && previousNoteRestIsNote(note)) {
									//logError(Prev notes");
									
									if (prevAcc > 0 && !prevAccInKeySig) addError ("Use of a sharp during a chromatic descent leads to avoidable natural sign.\nConsider respelling (select the note and press "+cmdKey+"-J).", prevNote);
								}
							}
						}

						// ****		IS THIS AUGMENTED OR DIMINISHED? 		**** //
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
						//logError("isAugDim: "+isAugDim+" scalarIntervalClass = "+scalarIntervalClass+" alteration = "+alteration+" is450 = "+isFourthFifthOrUnison);
						
						// **** IF WE ONLY JUST HIGHLIGHTED A NOTE, THEN DON'T DO ANOTHER ONE JUST YET **** //
						if (numNotes == 1 && (prevNoteHighlighted || prevPrevNoteHighlighted)) {
							//logError("returning because prevNoteHighlighted = "+prevNoteHighlighted+" and prevPrevNoteHighlighted = "+prevPrevNoteHighlighted);
							prevPrevNote = prevNote;
							prevNote = note;
							prevPrevMIDIPitch = prevMIDIPitch;
							prevMIDIPitch = MIDIPitch;
							prevPrevDiatonicPitchClass = prevDiatonicPitchClass;
							prevDiatonicPitch = diatonicPitch;
							prevDiatonicPitchClass = diatonicPitchClass;
							prevChromaticInterval = chromaticInterval;
							prevChromaticIntervalClass = chromaticIntervalClass;
							prevPrevAcc = prevAcc;
							prevAcc = acc;
							prevAccVisible = accVisible;
							prevAccInKeySig = accInKeySig;
							prevIsAugDim = isAugDim;
							prevScalarIntervalAbs = scalarIntervalAbs;
							prevScalarIntervalClass = scalarIntervalClass;
							prevAlterationLabel = alterationLabel;
							prevShowError = doShowError;
							prevWhichNoteToRewrite = whichNoteToRewrite;
							prevIsTritone = isTritone;
							return;
						}
						
						// **** SHOW AN ERROR IF BOTH THE CURRENT AND PREVIOUS INTERVAL WERE AUG/DIM **** //
						// **** THOUGH NOT IF CURRENT INTERVAL IS A TRITONE ****
						
						doShowError = isAugDim && prevIsAugDim && !(isTritone && prevIsTritone);
						
						// **** EXCEPTIONS
						// **** IGNORE AUG UNISON IF FOLLOWED BY ANOTHER ONE OR A TRITONE
						if (chromaticIntervalClass == 1 && (prevChromaticInterval == chromaticInterval || prevChromaticIntervalClass == 6)) doShowError = false;
						
						var weightingIsClose = false;							
						if (doShowError) {
							var foundNote = false;
							
							if (!prevAccVisible && accVisible) {
								//logError(whichNoteToRewrite = 2");
								whichNoteToRewrite = 2;
								foundNote = true;
							}
							if (prevAccVisible && !accVisible) {
								//logError(whichNoteToRewrite = 1");
								whichNoteToRewrite = 1;
								foundNote = true;
							}
							if (!foundNote) {
								var weighting1 = weightings[prevPrevDiatonicPitchClass] + (prevPrevAcc * 7) - currentKeySig
								var weighting2 = weightings[prevDiatonicPitchClass] + (prevAcc * 7) - currentKeySig;
								var weighting3 = weightings[diatonicPitchClass] + (acc * 7) - currentKeySig;
								var weightingAverage = (weighting1 + weighting2 + weighting3) / 3.0;
								var w1dist = Math.abs(weightingAverage - weighting1); 
								var w2dist = Math.abs(weightingAverage - weighting2);
								var w3dist = Math.abs(weightingAverage - weighting3);
								// rewrite the one that is the most outlying
								whichNoteToRewrite = 0;
								if (w2dist > w1dist && w2dist > w3dist) whichNoteToRewrite = 1;
								if (w3dist > w1dist && w3dist > w2dist) whichNoteToRewrite = 2;
								var maxWeightingDist = Math.max (w1dist, w2dist, w3dist);
								weightingIsClose = maxWeightingDist < 5;
								//logError("w1dist: "+w1dist+"); w2dist: "+w2dist+"; w3dist: "+w3dist);
								
							} // if !foundNote
						} // if doshowerror
						
						// don't show error if we decide it"s the same note that needs to change
						if (prevShowError && (whichNoteToRewrite == prevWhichNoteToRewrite - 1)) doShowError = false;
						
						if (doShowError) {
							//logError("***** SHOW ERROR because isAugDim is "+isAugDim+" prevIsAugDim = "+prevIsAugDim+" chromaticIntervalClass = "+chromaticIntervalClass+" and prevChromaticIntervalClass = "+prevChromaticIntervalClass);								
							// DOES THIS OR PREV GO AGAINST THE WEIGHT?
							scalarIntervalLabel = intervalNames[scalarIntervalAbs];

							//logError(scalarIntervalAbs = "+scalarIntervalAbs+"); scalarIntervalLabel="+scalarIntervalLabel;
							article = (alterationLabel === "augmented") ? "an" : "a";
							noteToHighlight = note;
							thisNoteHighlighted = true;
							//logError("NOW thisNoteHighlighted "+thisNoteHighlighted);
							theAccToChange = acc;
							thePitchClassToChange = diatonicPitchClass;
							if (prevNote.parent.is(chord)) {
								prevNext = "note below";
							} else {
								prevNext = "previous note";
							}
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
								thisNoteHighlighted = false;
								prevNoteHighlighted = true;
								//logError("NOW thisNoteHighlighted = "+thisNoteHighlighted+" prevNoteHighlighted = "+prevNoteHighlighted);
								if (prevNote.parent.is(chord)) {
									prevNext = "note above";
								} else {
									prevNext = "next note";
								}
								//logError(Choosing prev note: theAccToChange="+theAccToChange+" pc2change="+thePitchClassToChange);
							}
							if (whichNoteToRewrite == 0) {
								theAccToChange = prevPrevAcc;
								thePitchClassToChange = prevPrevDiatonicPitchClass;
								noteToHighlight = prevPrevNote;
								thisNoteHighlighted = false;
								prevNoteHighlighted = false;
								prevPrevNoteHighlighted = true;
								//logError("NOW thisNoteHighlighted = "+thisNoteHighlighted+" prevNoteHighlighted = "+prevNoteHighlighted+" prevPrevNoteHighlighted = "+prevPrevNoteHighlighted);

								if (prevPrevNote.parent.is(chord)) {
									prevNext = "note above";
								} else {
									prevNext = "next note";
								}
								//logError(Choosing prev note: theAccToChange="+theAccToChange+" pc2change="+thePitchClassToChange);
							}
							
							var j = 0;
							switch (theAccToChange) {
								case -2:
									//  if (!flatten) errorMsg += "Error found with "+noteLabel+" in bar "+  +": should be spelt enharmonically downwards";
									//	trace ("bb");
									j = thePitchClassToChange - 1;
									if (j < 0) j += 7;
									var newNotePitch = pitchLabels[j];
									if (newNotePitch === "B" || newNotePitch === "E") {
										newNoteAccidental = kFlatStr;
									} else {
										newNoteAccidental = kNaturalStr;
									}
									//logError(-2 ");
									
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
									//logError(-1 ");
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
									//logError(0 ");
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
									//logError(1 ");
									break;
					
								case 2: 
									//if (!sharpen) logError(Error with "+noteLabel+" in bar "+barNum+" — should be spelt enharmonically upwards");
									j = (thePitchClassToChange + 1) % 7;
									newNotePitch = pitchLabels[j];
									if (newNotePitch === "F" || newNotePitch === "C") {
										newNoteAccidental = kSharpStr;
									} else {
										newNoteAccidental = kNaturalStr;
									}
									//logError(2 ");
									break;
							}
							//if (newNotePitch === "") logError(Couldnt find new note pitch");
							var newNoteLabel = newNotePitch+newNoteAccidental;
							var changeIsBad = newNoteAccidental === "bb" || newNoteAccidental === "x";
							if (!changeIsBad) {
								if (currentKeySig > -3) changeIsBad = (newNoteLabel === "C"+kFlatStr) || (newNoteLabel === "F"+kFlatStr);
								if (currentKeySig < 3) changeIsBad = (newNoteLabel === "B"+kSharpStr) || (newNoteLabel === "E"+kSharpStr);
							}
							if (doShowError && !changeIsBad) {
								var t = "Interval with "+prevNext+" is "+article+" "+alterationLabel+" "+scalarIntervalLabel+".\nConsider respelling as "+newNoteLabel+" (select the note and press Cmd-J)";
								if (weightingIsClose && scalarIntervalAbs != 0) t = "Note: The current spelling may be OK, but depends on\nthe wider tonal/scalar context which I can’t analyse.\n[SUGGESTION] "+t;
								addError(t,noteToHighlight);
								//logError("Added error — now thisNoteHighlighted = "+thisNoteHighlighted+" prevNoteHighlighted = "+prevNoteHighlighted+" prevPrevNoteHighlighted = "+prevPrevNoteHighlighted);
							} else {
								//logError(Did not show error cos doShowError="+doShowError+" & changeIsBad="+changeIsBad);
							}
										
						} // end if doShowError

					 // end if isAugDim
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

				if (chromaticInterval != 0) {
					prevPrevNote = prevNote;
					prevNote = note;
					//logError(prevNote now "+prevNote);
					prevPrevMIDIPitch = prevMIDIPitch;
					prevMIDIPitch = MIDIPitch;
					//logError(prevPrevMIDIPitch now "+prevPrevMIDIPitch+"); prevMIDIPitch now "+prevMIDIPitch;
					prevPrevDiatonicPitchClass = prevDiatonicPitchClass;
					prevDiatonicPitch = diatonicPitch;
					prevDiatonicPitchClass = diatonicPitchClass;
					prevChromaticInterval = chromaticInterval;
					prevChromaticIntervalClass = chromaticIntervalClass;
					prevPrevAcc = prevAcc;
					prevAcc = acc;
					prevAccVisible = accVisible;
					prevAccInKeySig = accInKeySig;
					prevIsAugDim = isAugDim;
					prevScalarIntervalAbs = scalarIntervalAbs;
					prevScalarIntervalClass = scalarIntervalClass;
					prevAlterationLabel = alterationLabel;
					prevShowError = doShowError;
					prevWhichNoteToRewrite = whichNoteToRewrite;
					prevIsTritone = isTritone;
				} // end if chromatic interval
			} // if !note.tieBack
		} // end var i in notes
		
		if (progressShowing) progress.close();
		dialog.msg = errorMsg;
		dialog.show();
	}
	
	function previousNoteRestIsNote (noteRest) {
		var cursor2 = curScore.newCursor();
		cursor2.track = noteRest.track;
		cursor2.rewindToTick(noteRest.parent.tick);
		if (cursor2.prev()) {
			var e = cursor2.element;
			if (e == null) return false;
			return e.type == Element.CHORD;
		}
		return false;
	}
	
	function setProgress (percentage) {
		if (percentage == 0) {
			progressStartTime = Date.now();
		} else {
			if (!progressShowing) {
				var currentTime = Date.now();
				var elapsedTime = currentTime - progressStartTime;
				//logError(elapsedTime now "+elapsedTime);
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
	
	function selectTitleText () {
		curScore.startCmd();
		cmd("title-text");
		cmd("select-similar");
		curScore.endCmd();
	}
	
	function deleteAllCommentsAndHighlights () {
	
		var elementsToRemove = [];
		var elementsToRecolor = [];
		
		// ** SAVE CURRENT SELECTION ** //
		saveSelection();
		
		// ** CHECK TITLE TEXT FOR HIGHLIGHTS ** //
		curScore.startCmd();
		selectAll();
		cmd ("insert-vbox");
		var vbox = curScore.selection.elements[0];
		cmd ("title-text");
		cmd ("select-similar");
		
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			var c = e.color;	
			// style the element pink
			if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
		}
		if (vbox == null) {
			logError ("deleteAllCommentsAndHighlights () — vbox was null");
		} else {
			removeElement (vbox);
		}
		curScore.endCmd();
		
		// **** SELECT ALL **** //
		selectAll();
		
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
		curScore.startCmd();
		for (var i = 0; i < elementsToRecolor.length; i++) elementsToRecolor[i].color = "black";
		for (var i = 0; i < elementsToRemove.length; i++) removeElement(elementsToRemove[i]);
		curScore.endCmd();
		
		restoreSelection();
	}

	function addError (text,element) {
		errorStrings.push(text);
		errorObjects.push(element);
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
	
	function showAllErrors () {
		var objectPageNum;
		var firstStaffNum = 0;
		for (var k = 0; k < curScore.nstaves; k++) {
			if (curScore.staves[k].part.show) {
				break;
			} else {
				firstStaffNum ++;
			}
		}
		var comments = [];
		var commentPages = [];
		
		curScore.startCmd()
		for (var i in errorStrings) {
			var theText = errorStrings[i];
			var element = errorObjects[i];
			var isArray = Array.isArray(element);
			var objectArray;
			if (isArray) {
				objectArray = element;
			} else {
				objectArray = [element];
			}
			for (var j in objectArray) {
				var checkObjectPage = false;
				element = objectArray[j];
				var eType = element.type;
				var staffNum = firstStaffNum;
				
				var elementHeight = 0;
				var commentOffset = 1.0;
				var tick = 0, desiredPosX = 0, desiredPosY = 0, commentPage = null;
			
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
						elementHeight = element.bbox.height;
						if (eType != Element.MEASURE) {
							var elemStaff = element.staff;
							if (elemStaff == undefined) {
								isString = true;
								theLocation = "";
								desiredPosX = element.bbox.x;
								desiredPosY = element.bbox.y;
								//logError(" x = "+desiredPosX+"); y = "+desiredPosY;
							} else {
								staffNum = 0;
								while (!curScore.staves[staffNum].is(elemStaff)) {
									staffNum ++; // I WISH: staffNum = element.staff.staffidx
									if (curScore.staves[staffNum] == null || curScore.staves[staffNum] == undefined) {
										logError ("showAllErrors () — got staff error "+staffNum+" — bailing");
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
				// add a text object at the location where the element is
				var comment = newElement(Element.STAFF_TEXT);
				comment.text = theText;
				//logError ("Adding comment "+theText.substring(0,10));
		
				// style the text object
				comment.frameType = 1;
				comment.framePadding = 0.6;
				comment.frameWidth = 0.2;
				comment.frameBgColor = "yellow";
				comment.frameFgColor = "black";
				comment.fontSize = 7.0;
				comment.fontFace = "Helvetica";
				comment.autoplace = false;
	
				if (isString) {
					if (theLocation.includes("pagetop")) {
						desiredPosX = 2.5;
						desiredPosY = 10.;
					}
					if (theLocation === "system1" || theLocation === "system2") desiredPosX = 5.0;
					if (theLocation === "system2") tick = firstBarInSecondSystem.firstSegment.tick;
				} else {
					tick = getTick(element);
				}
				if (eType == Element.TEXT) {
					checkObjectPage = true;
					objectPageNum = getPageNumber(element);
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
					var commentWidth = comment.bbox.width;
					var placedX = comment.pagePos.x;				
					if (desiredPosX != 0) comment.offsetX = desiredPosX - comment.pagePos.x;
					if (desiredPosY != 0) {
						comment.offsetY = desiredPosY - comment.pagePos.y;
					} else {
						comment.offsetY -= commentHeight;
					}
	
					var commentPage = comment.parent;
					while (commentPage != null && commentPage.type != Element.PAGE && commentPage.parent != undefined) commentPage = commentPage.parent; // in theory this should get the page
	
					if (commentPage != null && commentPage != undefined) {
						if (commentPage.type == Element.PAGE) {
							var commentPageWidth = commentPage.bbox.width; // get page width
							var commentPageNum = commentPage.pagenumber; // get page number
							
							// move over to the top right of the page if needed
							if (theLocation === "pagetopright") comment.offsetX = commentPageWidth - commentWidth - 2.5 - placedX;
	
							// check to see if this comment has been placed too close to other comments
							var maxOffset = 10;
							var minOffset = 1.5;
							for (var k = 0; k < comments.length; k++) {
								var otherComment = comments[k];
								var otherCommentPage = commentPages[k];
								//logError ("Checking against comment "+k);
								if (commentPage.is(otherCommentPage)) {
									var dx = Math.abs(comment.pagePos.x - otherComment.pagePos.x);
									var dy = Math.abs(comment.pagePos.y - otherComment.pagePos.y);
									var isCloseToOtherComment = (dx <= minOffset || dy <= minOffset) && (dx + dy < maxOffset);
									var isNotTooFarFromOriginalPosition = (isString) || (Math.abs(comment.offsetY) < maxOffset && Math.abs(comment.offsetX) < maxOffset);
									
									//logError ("Same page. dx = "+dx+" dy = "+dy+" close = "+isCloseToOtherComment+" far = "+isNotTooFarFromOriginalPosition);
									while (isCloseToOtherComment &&  isNotTooFarFromOriginalPosition) {
										comment.offsetY -= commentOffset;
										comment.offsetX += commentOffset;
										dx = Math.abs(comment.pagePos.x - otherComment.pagePos.x);
										dy = Math.abs(comment.pagePos.y - otherComment.pagePos.y);
										isCloseToOtherComment = (dx <= minOffset || dy <= minOffset) && (dx + dy < maxOffset);
										isNotTooFarFromOriginalPosition = (isString) || (Math.abs(comment.offsetY) < maxOffset && Math.abs(comment.offsetX) < maxOffset);
										//logError ("Too close: shifting comment.offsetX = "+comment.offsetX+" comment.offsetY = "+comment.offsetY+" tooClose = "+isCloseToOtherComment);
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
								}*/
							}
							
							
							if (checkObjectPage && commentPageNum != objectPageNum) comment.text = '[The object this comment refers to is on p. '+(objectPageNum+1)+']\n' +comment.text;
							var rhs = comment.pagePos.x + commentWidth;
							if (rhs > commentPageWidth) comment.offsetX -= (rhs - commentPageWidth);
						} else {
							logError ("parent parent parent parent was not a page — element = "+element.name);
						}
					}
					//logError ("Added comment ‘"+theText.substring(0,10)+"’ at {"+comment.pagePos.x+" "+comment.pagePos.y+"}");
					comments.push (comment);
					commentPages.push (commentPage);
				}
			}
		} // var i
		curScore.endCmd();
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
	
	function logError (str) {
		numLogs ++;
		errorMsg += "<p>Staff "+currentStaffNum+", b. "+currentBarNum+": "+str+"</p>";
	}
	
	StyledDialogView {
		id: dialog
		title: "CHECK COMPLETED"
		contentHeight: 252
		contentWidth: 456
		margins: 10
		property var msg: ""

		Text {
			id: theText
			width: parent.width-40
			x: 20
			y: 20

			text: "MN CHECK ACCIDENTALS"
			font.bold: true
			font.pointSize: 18
		}
		
		Rectangle {
			x:20
			width: parent.width-40
			y:45
			height: 1
			color: "black"
		}

		ScrollView {
			id: view
			x: 20
			y: 60
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
