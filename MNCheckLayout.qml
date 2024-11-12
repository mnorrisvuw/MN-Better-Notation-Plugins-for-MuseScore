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
	property var previousKeySigSharps: 0
	property var previousKeySigBarNum: 0
	property var currentBarNum: 0
	property var hasMoreThanOneSystem: false
	property var commentPosArray: []
	property var instrumentIds: []
	property var isGrandStaff: []
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
		var firstMeasure = curScore.firstMeasure;
		var lastMeasure = curScore.lastMeasure;
		var firstSystem = firstMeasure.parent;
		var lastSystem = lastMeasure.parent;
		var firstPage = firstSystem.parent;
		var lastPage = lastSystem.parent;
		hasMoreThanOneSystem = !lastSystem.is(firstSystem);	
		var ledgerLines = [];
		var flaggedLedgerLines = false;
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		
		// **** INITIALISE PROPERTIES AND ARRAYS **** //
		var isSpellingError = false;
		initialTempoExists = false;
		for (var i = 0; i < numStaves; i++) instrumentIds.push(staves[i].part.instrumentId);
		
		// ********************** DELETE ANY EXISTING COMMENTS AND HIGHLIGHTS ********************** //
		deleteAllCommentsAndHighlights();

		// **********************  CHECK SCORE & PAGE SETTINGS ************************** // 
		checkScoreAndPageSettings();
			
		// ********************** SELECT ENTIRE SCORE ********************** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
		curScore.endCmd();
		
		// ********************** CHECK SCORE TEXT ********************** //
		checkScoreText();
		
		// *********************** CHECK FOR STAFF ORDER ISSUES *********************** //
		checkStaffOrder();
			
		// ************************ PREP FOR A FULL LOOP THROUGH THE SCORE ********************** //
		var currentStaffNum, currentBar, prevBarNum, numBarsProcessed, wasTied;
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var prevSoundingDur, prevDisplayDur, tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;

		firstStaffNum = 0;
		lastStaffNum = numStaves;
		
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
		dialog.msg += "\n————————\n\nSTARTING LOOP\n\n";
		
		// ************************ START LOOP THROUGH WHOLE SCORE ************************ //
		for (currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum; currentStaffNum ++) {
			dialog.msg += "\n——— currentStaff = "+currentStaffNum;
			
			// INITIALISE VARIABLES ON A PER-STAFF BASIS
			previousKeySigSharps = -99;
			previousKeySigBarNum = 0;
			prevTimeSig = "";
			
			// **** REWIND TO START OF SELECTION **** //
			// **** GET THE STARTING CLEF OF THIS INSTRUMENT **** //
			cursor.filter = Segment.HeaderClef;
			cursor.staffIdx = currentStaffNum;
			cursor.voice = 0;
			cursor.track = currentStaffNum * 4;
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == null) cursor.next();
			currentBar = cursor.measure;
			prevBarNum = 0;
			var clef = cursor.element;
			//dialog.msg += "\nHeader clef = "+clef.subtypeName();
			
			if (clef == null) {
				dialog.msg += "\nNO CLEF OBJECT FOUND";
			} else {
				setCurrentClefVariables(clef);
			}
			
			cursor.filter = Segment.All;
			cursor.next();
			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
				
				var barStart = currentBar.firstSegment.tick;
				var barLength = currentBar.lastSegment.tick - barStart;
				var startTrack = currentStaffNum * 4;
				var endTrack = startTrack + 4;
				dialog.msg += "\n*** currentBar = "+currentBarNum;
				
				for (var track = startTrack; track < endTrack; track++) {
					
					cursor.track = track;
					cursor2.track = track;
					cursor.rewindToTick(barStart);
				
					var processingThisBar = cursor.element;
					while (processingThisBar) {
						var elem = cursor.element;
						var eType = elem.type;
						
						// **** FOUND A CLEF **** //
						if (eType === Element.CLEF) setCurrentClefVariables(elem);
						
						if (eType === Element.KEYSIG && currentStaffNum == firstStaffNum) checkKeySignature(elem,cursor.keySignature);
						
						if (eType === Element.TEXT || eType === Element.TEMPO_TEXT || eType === Element.STAFF_TEXT || eType === Element.SYSTEM_TEXT) checkTextObject(element, currentBarNum);
						
						if (eType === Element.TIMESIG) checkTimeSignature(elem);
						
						if (eType === Element.CHORD) {
							var noteRest = cursor.element;
							var isHidden = !noteRest.visible;
							var isRest = noteRest.type === Element.REST;
							var isNote = !isRest;
							var displayDur = noteRest.duration.ticks;
							var soundingDur = noteRest.actualDuration.ticks;
							var tuplet = noteRest.tuplet;
							var barsSincePreviousNote = (currentBarNum - prevBarNum);
							if (barsSincePreviousNote > 1) {
								ledgerLines = [];
								flaggedLedgerLines = false;
							}
							// numNoteRests = numNoteRests + 1;
							var pos = cursor.tick - barStart;
							var nn = 0;
							if (isNote) nn = noteRest.notes.length;
							var pitch = 0;
							if (isNote) pitch = noteRest.notes[0].MIDIpitch;
						
							var augDot = (Math.log2((displayDur * 64.) / (division * 3.)) % 1.0) == 0.;
						
							var beam = noteRest.beam;	
							var isCrossStaff = false;
							//if (beam) isCrossStaff = beam.cross;
							// TO FIX
							dialog.msg += "\nFOUND NOTE";
							
							// CHECK THE PASSAGE'S REGISTER
							if (!isRest && !isCrossStaff) {

								prevBarNum = currentBarNum;
								// get the 'centre line offset'
								// this returns how many lines/spaces the note is above the middle line
								var centreLineOffset = getOffsetFromMiddleLine(noteRest);
								var numLedgerLines = 0;
								if (centreLineOffset > 5) numLedgerLines = Math.trunc((centreLineOffset - 6) / 2) + 1; // num ledger lines above staff
								if (centreLineOffset < -5) numLedgerLines = Math.trunc((centreLineOffset + 6) / 2); // num ledger lines below staff
								var numberOfLedgerLinesToCheck = 4;
								if (ledgerLines.length > numberOfLedgerLinesToCheck) ledgerLines = ledgerLines.slice(1);
								ledgerLines.push(numLedgerLines);
								if (!flaggedLedgerLines) {
									if (numLedgerLines > 5) {
										if (isBassClef && (readsTenor || readsTreble)) {
											showError("This passage is very high for bass clef;\nit may be better in tenor or treble clef",noteRest);
											flaggedLedgerLines = true;
										}
										if (isTenorClef && readsTreble) {
											showError("This passage is very high for tenor clef;\nit may be better in treble clef",noteRest);
											flaggedLedgerLines = true;
										}
										if (isTrebleClef && reads8va) {
											showError("This passage is very high for treble clef;\nit may be better with an 8va symbol",noteRest);
											flaggedLedgerLines = true;
										}
									}
									if (numLedgerLines < -5) {
										if (isTrebleClef) {
											if (readsBass) {
												showError(errors,"This passage is very low for treble clef;\nit may be better in bass clef",noteRest);
												flaggedLedgerLines = true;
											} else {
												if (readsAlto) {
													showError("This passage is very low for treble clef;\nit may be better in alto clef",noteRest);
													flaggedLedgerLines = true;
												}
											}
										}
										if (isTenorClef && readsBass) {
											showError(errors,"This passage is very low for tenor clef;\nit may be better in bass clef",noteRest);
											flaggedLedgerLines = true;
										}
										if (isBassClef && reads8va) {
											showError(errors,"This passage is very low for bass clef;\nit may be better with an 8ba",noteRest);
											flaggedLedgerLines = true;
										}
									}
									if (!flaggedLedgerLines && ledgerLines.length >= numberOfLedgerLinesToCheck) {
										var averageNumLedgerLines = ledgerLines.reduce((a,b) => a+b) / ledgerLines.length;
										if (isBassClef) {
											//trace(averageNumLedgerLines);
											if (readsTenor && averageNumLedgerLines > 2) {
												showError("This passage is very high;\nit may be better in tenor or treble clef",noteRest);
												flaggedLedgerLines = true;
											}
											if (readsTreble && averageNumLedgerLines > 3) {
												showError("This passage is very high;\nit may be better in treble clef",noteRest);
												flaggedLedgerLines = true;
											}
											if (reads8va && averageNumLedgerLines < -4) {
												showError("This passage is very low;\nit may be better with an 8ba",noteRest);
												flaggedLedgerLines = true;
											}
										}
					
										if (isTenorClef) {
											if (readsTreble && averageNumLedgerLines > 2) {
												showError("This passage is very high;\nit may be better in treble clef",noteRest);
												flaggedLedgerLines = true;
											}
											if (readsBass && averageNumLedgerLines < -1) {
												showError("This passage is very low;\nit may be better in bass clef",noteRest);
												flaggedLedgerLines = true;
											}
										}
										if (isTrebleClef) {
											if (reads8va && averageNumLedgerLines > 4) {
												showError("This passage is very high;\nit may be better with an 8va",noteRest);
												flaggedLedgerLines = true;
											}
											if (readsTenor && averageNumLedgerLines < -1) {
												showError("This passage is very low;\nit may be better in tenor clef",noteRest);
												flaggedLedgerLines = true;
											} else {
												if (readsBass && averageNumLedgerLines < -2) {
													showError("This passage is very low;\nit may be better in bass clef",noteRest);
													flaggedLedgerLines = true;
												}
											}
										}
									}
								}
							}

							//prevSoundingDur = soundingDur;
							//prevDisplayDur = displayDur;
							//prevItemIsNote = isNote;
							//prevNoteWasDoubleTremolo = isDoubleTremolo;
							//prevNoteCount = noteCount;
						//	prevPitch = pitch;
							//prevTupletSubdiv = tupletSubdiv;
						} // end if eType === Element.Chord

						if (cursor.next()) {
							processingThisBar = cursor.measure.is(currentBar);
						} else {
							processingThisBar = false;
						}
					} // end while processingThisBar
				} // end track loop
				if (currentBar) currentBar = currentBar.nextMeasure;
				numBarsProcessed ++;
			}// end currentBar num
		} // end staffnum loop
		
		// mop up any last tests
		
		// ** CHECK FOR OMITTED INITIAL TEMPO ** //
		if (!initialTempoExists) showError('I couldn’t find an initial tempo marking','top');
		
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
	
	function getInstrumentInfo (instrumentId) {
		checkClefs = false;
		reads8va = false;
		if (instrumentId != "") {
			readsTreble = true;
			readsAlto = false;
			readsTenor = false;
			readsBass = false;
			checkClefs = false;

		// WINDS
			if (instrumentId.includes("wind.")) {
				// Bassoon is the only wind instrument that reads bass and tenor clef
				if (instrumentId.includes("bassoon")) {
					readsTreble = false;
					readsTenor = true;
					readsBass = true;
					checkClefs = true;
				} else {
					checkClefs = true;
				}
			}
			// BRASS
			if (instrumentId.includes("brass.")) {
				brassInstrumentFound = true;
				if (instrumentId.includes("french-horn")) {
					readsBass = true;
					checkClefs = true;
				}
				if (instrumentId.includes("trumpet")) {
					checkClefs = true;
				}
				if (instrumentId.includes("trombone") || instrumentId.includes("tuba") || instrumentId.includes("sousaphone")) {
					if (instrumentId.includes("alto") > 0) {
						readsAlto = true;
						checkClefs = true;
					} else {
						readsTenor = true;
						readsBass = true;
						checkClefs = true;
					}
				}
				if (instrumentId.includes("euphonium")) {
					readsBass = true;
					checkClefs = true;
				}
			}
			
			// STRINGS, HARP, PERCUSSION
			if (instrumentId.includes("instrument.keyboard") || instrumentId.includes("pluck.harp") || instrumentId.includes(".marimba")) {
				readsBass = true;
				reads8va = true;
				checkClefs = true;
			}
			if (instrumentId.includes("timpani")) {
				readsBass = true;
				checkClefs = true;
			}
		
			// STRINGS
			if (instrumentId.includes("strings.")) {
				if (instrumentId.includes("violin")) {
					checkClefs = true;
					reads8va = true;
				}
				if (instrumentId.includes("viola")) {
					readsAlto = true;
					checkClefs = true;
				}
				if (instrumentId.includes("cello") || instrumentId.includes("contrabass")) {
					readsTenor = true;
					readsBass = true;
					checkClefs = true;
				}
			}
			
			// VOICE
			if (instrumentId.includes("voice.")) {
				if (instrumentId.includes("bass") || instrumentId.includes("baritone") || instrumentId.includes(".male")) {
					readsBass = true;
					checkClefs = true;
				}
			}
		}
	}
	
	function checkTextObject (textObject,barNum) {
		var eType = textObject.type;
		dialog.msg += "\nChecking textObject "+textObject;
		// ** CHECK IT'S NOT A COMMENT WE'VE ADDED ** //
		if (!Qt.colorEqual(textObject.frameBgColor,"yellow") || !Qt.colorEqual(textObject.frameFgColor,"black")) {	
			var textStyle = textObject.subStyle;
			var tn = textObject.name.toLowerCase();
			//dialog.msg += "\nText style is "+textStyle+"; tn = "+tn;
			var styledText = textObject.text;
			var plainText = styledText.replace(/<\/[^>]+(>|$)/g, "");
			var lowerCaseText = plainText.toLowerCase();
			if (lowerCaseText != '') {
				var len = plainText.length;
				var isVisible = textObject.visible;
		
				// ** CHECK FOR OMITTED OR DEFAULT TEXT ** //
				if (!initialTempoExists && eType == Element.TEMPO_TEXT && barNum == 1) initialTempoExists = true;
		
				// ** CHECK TEMPO CHANGE MARKING NOT IN TEMPO TEXT ** //
				var isTempoChangeMarking = false;
		
				for (var i = 0; i < tempochangemarkings.length; i++) {
					if (lowerCaseText.includes(tempochangemarkings[i])) {
						isTempoChangeMarking = true;
						break;
					}
				}
				if (isTempoChangeMarking) {
					if (eTypetype != Element.TEMPO_TEXT) showError( "‘"+plainText+"’ is a tempo change marking\nbut has not been entered as Tempo Text",textObject);
					// check capitalisation
					if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) showError("‘"+plainText+"’ looks like it is a temporary change of tempo\nif it is, it should not have a capital first letter (see Behind Bars, p. 182)",textObject);
				}
		
				// ** CHECK TEMPO MARKING NOT IN TEMPO TEXT ** //
				var isTempoMarking = false;
		
				for (var j = 0; j < tempomarkings.length; j++) {
					if (lowerCaseText.includes(tempomarkings[j])) {
						isTempoMarking = true;
						break;
					}
				}
				if (isTempoMarking) {
					// check is in tempo text
					if (eType != Element.TEMPO_TEXT) showError("Text ‘"+plainText+"’ is a tempo marking\nbut has not been entered as Tempo Text",textObject);
				
					// check capitalisation
					if (plainText.substring(0,1) === lowerCaseText.substring(0,1) && lowerCaseText != "a tempo" && lowerCaseText.charCodeAt(0)>32 && !lowerCaseText.substring(0,4).includes("=")) showError("‘"+plainText+"’ looks like it is establishing a new tempo;\nif it is, it should have a capital first letter. (See Behind Bars, p. 182)",textObject);
				}
			
				// ** CHECK WRITTEN OUT TREM ** //
				if (lowerCaseText === "trem" || lowerCaseText === "trem." || lowerCaseText === "tremolo") showError("You don’t need to write ‘"&plainText&"’;\njust use a tremolo marking.",textObject);
		
				// ** CHECK COMMON MISSPELLINGS ** //
				if (lowerCaseText === "mute" || lowerCaseText === "with mute" || lowerCaseText === "add mute" || lowerCaseText === "put on mute" || lowerCaseText === "put mute on" || lowerCaseText === "muted") showError( "This is best written as ‘con sord.’",textObject);
				if (lowerCaseText === "unmuted" || lowerCaseText === "no mute" || lowerCaseText === "remove mute" || lowerCaseText === "take off mute" || lowerCaseText === "take mute off") showError( "This is best written as ‘senza sord.’",textObject);
				if (lowerCaseText.substring(0,5) === "arco.") showError( "‘arco’ should not have a full-stop at the end.",textObject);
				if (lowerCaseText.substring(0,10) === "sul tasto.") showError( "‘tasto’ should not have a full-stop at the end.",textObject);
				if (lowerCaseText === "norm") showError( "‘norm’ should have a full-stop at the end\n(but is more commonly written as ‘ord.’).",textObject);
				if (lowerCaseText.includes("sul. ")) showError( "‘sul’ should not have a full-stop after it.",textObject);
				if (lowerCaseText.includes("  ")) showError( "This text has a double-space in it.",textObject);
				if (lowerCaseText === "normale") showError("Abbreviate ‘normale’ as ‘norm.’ or ‘ord.’.",textObject);
			
				// ** CHECK STRAIGHT/CURLY QUOTES ** //
				if (lowerCaseText.includes("'")) showError("This text has a straight single quote mark in it (').\nChange to curly: ‘ or ’.",textObject);
				if (lowerCaseText.includes('"')) showError('This text has a straight double quote mark in it (").\nChange to curly: “ or ”.',textObject);
			
				// ** CHECK FOR STYLES ** //
				if (styledText.includes("<i>arco")) showError("‘arco’ should not be italicised.",textObject);
				if (styledText.includes("<i>pizz")) showError("‘pizz.’ should not be italicised.",textObject);
				if (styledText.includes("<i>con sord")) showError("‘con sord.’ should not be italicised.",textObject);
				if (styledText.includes("<i>senza sord")) showError("‘senza sord.’ should not be italicised.",textObject);
				if (styledText.includes("<i>ord.")) showError("‘ord.’ should not be italicised.",textObject);
				if (styledText.includes("<i>sul ")) showError("String techniques should not be italicised.",textObject);
				if (styledText.slice(3) === "<b>") showError("In general, you never need to manually set text to bold.\nAre you sure you want this text bold?",textObject);
			
				// ** IS THIS A DYNAMICS SYMBOL OR MANUALLY ENTERED DYNAMICS? ** //
				var isDyn = styledText.includes('<sym>dynamics') || isDynamic(lowerCaseText);
			
				// ** CHECK FOR DYNAMIC ENTERED AS EXPRESSION (OR OTHER) TEXT ** //
			
				if (isDyn && tn != "dynamics") showError("This text object looks like a dynamic,\nbut has not been entered using the Dynamics palette",textObject);
			
				// ** CHECK FOR TECHNIQUES ENTERED AS EXPRESSION TEXT ** //
				var shouldBeTechnique = false;
				if (tn == "expression") {
					for (var i = 0; i < techniques.length; i ++) {
						if (lowerCaseText.includes(techniques[i])) {
							showError("This looks like a technique, but has been incorrectly entered as Expression text.\nPlease check whether this should be in Technique Text instead.",textObject);
							shouldBeTechnique = true;
							break;
						}
					}
				}
				// ** CHECK STARTING WITH SPACE OR NON-ALPHANUMERIC
				if (plainText.charCodeAt(0) == 32) showError("‘"+plainText+"’ begins with a space, which could be deleted.",textObject);
				if (plainText.charCodeAt(0) < 32) showError("‘"+plainText+"’ does not seem to begin with a letter: is that correct?",textObject);
			
				// ** CHECK TEXT THAT SHOULD NOT BE CAPITALISED ** //
				for (var i = 0; i < shouldbelowercase.length; i++) {
					var lowercaseMarking = shouldbelowercase[i];
					if (plainText.length >= lowercaseMarking.length) {
						var subs = plainText.substring(0,lowercaseMarking.length);
						if (subs === lowercaseMarking) {
							if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) showError("‘"+plainText+"’ should not have a capital first letter.",textObject);
							break;
						}
					}
				}
			
				// ** CHECK TEXT THAT SHOULD HAVE A FULL-STOP AT THE END ** //
				for (var i = 0; i < shouldhavefullstop.length; i++) {
					if (plainText === shouldhavefullstop[i]) {
						showError("‘"+plainText+"’ should have a full-stop at the end.",textObject);
						break;
					}
				}
			
				// ** CHECK COMMON SPELLING ERRORS & ABBREVIATIONS ** //
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
						showError("‘"+plainText+"’ is misspelled; it should be ‘"+correctText+"’.",textObject);
						break;
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
							showError("‘"+plainText+"’ is misspelled; it should be ‘"+correctText+"’.",textObject);
							break;
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
							showError("‘"+plainText+"’ can be abbreviated to ‘"+correctText+"’.",textObject);
							break;
						}
					}
				}
			}
		}		
	}
	
	function setCurrentClefVariables (clef) {
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
	}
	
	function checkScoreText() {
		var title = curScore.title;
		var subtitle = curScore.subtitle;
		var composer = curScore.composer;
		if (subtitle === 'Subtitle') showError( "You haven’t changed the Subtitle in File→Project Properties","pagetop");
		if (title === 'Untitled score') {
			showError( "You haven’t changed the Work Title in File→Project Properties","pagetop");
		} else {
			var lowerCaseText = title.toLowerCase();
			for (var i = 0; i < spellingerrorsatstart.length / 2; i++) {
				var spellingError = spellingerrorsatstart[i*2];
				if (lowerCaseText.substring(0,spellingError.length) === spellingError) {
					isSpellingError = true;
					var correctSpelling = spellingerrorsatstart[i*2+1];
					var diff = title.length-spellingError.length;
					var correctText = '';
					if (diff > 0) {
						correctText = correctSpelling+title.substring(spellingError.length,diff);
					} else {
						correctText = correctSpelling;
					}
					showError("The title has a spelling error in it\nit should be ‘"+correctText+"’.","pagetop");
					break;
				}
			}
			if (!isSpellingError) {
				for (var i = 0; i < spellingerrorsanywhere.length / 2; i++) {
					var spellingError = spellingerrorsanywhere[i*2];
					if (title.includes(spellingError)) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsanywhere[i*2+1];
						var correctText = title.replace(spellingError,correctSpelling);
						showError("The title has a spelling error in it; it should be ‘"+correctText+"’.","pagetop");
						break;
					}
				}
			}
		}
				
		if (composer === 'Composer / arranger') showError( "You haven’t changed the default composer in File → Project Properties","pagetop");
	}
	
	function checkKeySignature (keySig,sharps) {
		// *********************** KEY SIGNATURE ERRORS *********************** //
		var keySigSegment = keySig.parent;
		if (sharps != previousKeySigSharps) {
			if (sharps > 6) showError("This key signature has "+sharps+" sharps,\nand would be easier to read if rescored as "+(12-sharps)+" flats.",keySig);
			if (sharps < -6) showError("This key signature has "+Math.abs(sharps)+" flats, and would be easier to read if rescored as "+(12+sharps)+" sharps.",keySig);
			if (currentBarNum - previousKeySigBarNum  < 16) showError("This key change comes only "+ (currentBarNum - previousKeySigBarNum) +" bars after the previous one.\nPerhaps the previous one could be avoided by using accidentals instead.",keySig);
			previousKeySigSharps = sharps;
			previousKeySigBarNum = currentBarNum;
		} else {
			showError("This key signature is the same as the one in bar "+previousKeySigBarNum+".\nPerhaps delete it?",keySig);
		}
	}
	
	function checkTimeSignature (timeSig) {
		var ts = timeSig.str;
		if (ts === prevTimeSig) showError("This time signature appears to be redundant (was already "+prevTimeSig+")\nIt can be safely deleted.",timeSig);
		prevTimeSig = ts;
	}
	
	function checkScoreAndPageSettings () {
		var styleComments = "";
		var pageSettingsComments = ""
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
		//dialog.msg+= "\nspatium = "+spatium+"; staffSize = "+staffSize;
		var staffLineWidth = style.value("staffLineWidth")*inchesToMM;
		var pageEvenLeftMargin = style.value("pageEvenLeftMargin")*inchesToMM;
		var pageOddLeftMargin = style.value("pageOddLeftMargin")*inchesToMM;
		var pageEvenTopMargin = style.value("pageEvenTopMargin")*inchesToMM;
		var pageOddTopMargin = style.value("pageOddTopMargin")*inchesToMM;
		var pageEvenBottomMargin = style.value("pageEvenBottomMargin")*inchesToMM;
		var pageOddBottomMargin = style.value("pageOddBottomMargin")*inchesToMM;
		//dialog.msg += "Margins = "+pageEvenLeftMargin+" "+pageOddLeftMargin+" "+pageEvenTopMargin+" "+pageOddTopMargin+" "+pageEvenBottomMargin+" "+pageOddBottomMargin;
		
		// **** TEST 1A: CHECK MARGINS ****
		var maxMargin = 15;
		var minMargin = 5;
		if ((pageEvenLeftMargin > maxMargin) + (pageOddLeftMargin > maxMargin) + (pageEvenTopMargin > maxMargin) + (pageOddTopMargin > maxMargin) +  (pageEvenBottomMargin > maxMargin) + (pageOddBottomMargin > maxMargin)) pageSettingsComments += "\nDecrease your margins to no more than "+maxMargin+"mm";
		if ((pageEvenLeftMargin < minMargin) + (pageOddLeftMargin < minMargin) + (pageEvenTopMargin < minMargin) + (pageOddTopMargin < minMargin) +  (pageEvenBottomMargin < minMargin) + (pageOddBottomMargin < minMargin)) pageSettingsComments += "\nIncrease your margins to at least "+minMargin+"mm";
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
		
		if (staffSize > maxSize) pageSettingsComments +=  "\nDecrease your stave space to be in the range "+(minSize/4.0)+"–"+(maxSize/4.0)+"mm";		
		if (staffSize < minSize) pageSettingsComments += "\nDecrease your stave space to be in the range "+(minSize/4.0)+"–"+(maxSize/4.0)+"mm";
		
		// **** 1C: CHECK STAFF SPACING
		
		// **** 1D: CHECK SYSTEM SPACING
		if (hasMoreThanOneSystem) {
			if (minSystemDistance < 12) styleComments += "\n(Page tab) Increase the ‘Min. system distance’ to at least 12";
			if (minSystemDistance > 16) styleComments += "\n(Page tab) Decrease the ‘Min. system distance’ to no more than 16";
			if (maxSystemDistance < 12) styleComments += "\n(Page tab) Increase the ‘Max. system distance’ to at least 12";
			if (maxSystemDistance > 16) styleComments += "\n(Page tab) Decrease the ‘Max. system distance’ to no more than 16";
		}
		
		// ** CHECK FOR STAFF NAMES ** //
		var firstStaffNameShouldBeHidden = numParts == 1;
		//dialog.msg += "\nfirstStaffNameShouldBeHidden = "+firstStaffNameShouldBeHidden;
		
		var subsequentStaffNamesShouldBeHidden = numParts < 6;
		
		// ** are the first staff names visible? ** //
		var firstStaffNameVisible = style.value("firstSystemInstNameVisibility") != 0; // note that 0 = long names, 1 = short names, 2 = hidden
		//dialog.msg += "\nfirstSystemInstNameVisibility value = "+firstStaffNameVisible;
		
		if (firstStaffNameVisible) {
			firstStaffNameVisible = false;
			for (var i = 0; i < numParts; i++) {
				if (parts[i].longName != "") {
					firstStaffNameVisible = true;
					break;
				}
			}
		}
		//dialog.msg += "\nfirstStaffNameVisible: "+firstStaffNameVisible;
		
		if (firstStaffNameShouldBeHidden) {
			if (!style.value("hideInstrumentNameIfOneInstrument")) {
				styleComments += "\n(Score tab) Tick ‘Hide if there is only one instrument’";
			} else {
				if (firstStaffNameVisible) styleComments += "\n(Score tab) Hide the staff names for a solo work.";
			}
		} else {
			if (!firstStaffNameVisible) styleComments += "\n(Score tab) Set Instrument names→On first system of sections to ‘Long name’."
		}
		var subsStaffNamesVisible = style.value("subsSystemInstNameVisibility") != 1;
		//dialog.msg += "\nsubsStaffNamesVisible: "+subsStaffNamesVisible;
		
		// CHECK IF PART NAMES WERE MANUALLY DELETED

		if (subsStaffNamesVisible) {
			subsStaffNamesVisible = false;
			for (var i = 0; i < numParts; i++) {
				if (parts[i].shortName != "") {
					subsStaffNamesVisible = true;
					break;
				}
			}
		}
		
		if (subsequentStaffNamesShouldBeHidden) {
			if (subsStaffNamesVisible) styleComments += "\n(Score tab) Switch Instrument names→On subsequent systems to ‘Hide’ for a small ensemble";
		} else {
			if (!subsStaffNamesVisible) styleComments += "\n(Score tab) Switch Instrument names→On subsequent systems to ‘Short name’ for a large ensemble";
		}
		
		// ** OTHER STYLE ISSUES ** //
		
		// ** POST STYLE COMMENTS
		if (styleComments != "") {
			if (styleComments.split('\n').length == 1) {
				styleComments = "I recommend making the following change to the score’s Style (Format→Style…):"+styleComments;
			} else {
				styleComments = "I recommend making the following changes to the score’s Style (Format→Style…):\n"+styleComments.substring(1).split('\n').map((line, index) => `${index + 1}) ${line}`).join('\n');
			}
			showError(styleComments,"pagetop");
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments != "") {
			if (pageSettingsComments.split('\n').length == 1) {	
				pageSettingsComments = "I recommend making the following change to the score’s Page Settings (Format→Page settings…)"+pageSettingsComments;
			} else {
				pageSettingsComments = "I recommend making the following changes to the score’s Page Settings (Format→Page settings…)\n"+pageSettingsComments.substring(1).split('\n').map((line, index) => `${index + 1}) ${line}`).join('\n');
			}
			showError(pageSettingsComments,"pagetop");
		}
	}
	
	function getOffsetFromMiddleLine (noteRest) {
		//dialog.msg += "NOTEREST: "+noteRest.notes.length;
		var highestPitch = 0;
		var highestNote = null;
		for (var i = 0; i<noteRest.notes.length; i++) {
			var theNote = noteRest.notes[i];
			var thePitch = theNote.pitch;
			if (thePitch > highestPitch) {
				highestPitch = thePitch;
				highestNote = theNote;
			}
		}
		if (highestNote) {
			var theTPC = highestNote.tpc2;
			var octave = Math.trunc(highestPitch/12); // where middle C = 5
			var diatonicPitchClass = (((theTPC+1)%7)*4+3) % 7; // where C = 0, D = 1 etc.
			var diatonicPitch = diatonicPitchClass+octave*7; // where middle C = 35
			return diatonicPitch - diatonicPitchOfMiddleLine; // 41 = treble B
		} else {
			return 0;
		}
	}
	
		// **** CHECK STANDARD CHAMBER LAYOUTS FOR CORRECT SCORE ORDER **** //
	function checkStaffOrder () {
		var numGrandStaves = 0;
		var prevPart = null;
		var parts = curScore.parts;
		var numParts = parts.length;
		var numStaves = curScore.nstaves;
		
		for (var i = 0; i < curScore.nstaves; i++) {
			var part = curScore.staves[i].part;
			if (part.is(prevPart)) {
				isGrandStaff[i-1] = true;
				isGrandStaff[i] = true;
				grandStaves.push(i-1);
				grandStaves.push(i);
				numGrandStaves ++;
			} else {
				isGrandStaff[i] = false;
			}
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
					if (bottomGrandStaffNum < numStaves && !isGrandStaff[bottomGrandStaffNum+1]) showError("For small ensembles, grand staff instruments should be at the bottom of the score.\nMove ‘"+curScore.staves[bottomGrandStaffNum].part.longName+"’ down using the Instruments tab.","pagetop");
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
					showError("You appear to be composing a wind quintet\nbut the flute should be the top staff.","topfunction ");
				} else {
					if (obStaff != 1) {
						showError("You appear to be composing a wind quintet\nbut the oboe should be the second staff.","pagetop");
					} else {
						if (clStaff != 2) {
							showError("You appear to be composing a wind quintet\nbut the clarinet should be the third staff.","pagetop");
						} else {
							if (hnStaff != 3) {
								showError("You appear to be composing a wind quintet\nbut the horn should be the fourth staff.","pagetop");
							} else {
								if (bsnStaff != 4) showError("You appear to be composing a wind quintet\nbut the bassoon should be the bottom staff.","pagetop");
							}
						}
					}
				}
			}
		
			// **** CHECK BRASS QUINTET STAFF ORDER **** //
			if (numTpt == 2 && numHn == 1 && numTbn == 1 && numTba == 1) {
				if (tpt1Staff != 0) {
					showError("You appear to be composing a brass quintet\nbut the first trumpet should be the top staff.","pagetop");
				} else {
					if (tpt2Staff != 1) {
						showError("You appear to be composing a brass quintet\nbut the second trumpet should be the second staff.","pagetop");
					} else {
						if (hnStaff != 2) {
							showError("You appear to be composing a brass quintet\nbut the horn should be the third staff.","pagetop");
						} else {
							if (tbnStaff != 3) {
								showError("You appear to be composing a brass quintet\nbut the trombone should be the fourth staff.","pagetop");
							} else {
								if (tbaStaff != 4) showError("You appear to be composing a brass quintet\nbut the tuba should be the bottom staff.","pagetop");
							}
						}
					}
				}
			}
		}
	}
	
	function showError (text, element) {
		var staffNum = 0;
		var elementHeight = 0;
		var commentOffset = 1.0;
		
		if (element !== "top" && element !== "pagetop") {
			// calculate the staff number that this element is on
			elementHeight = element.bbox.height;
			var elemStaff = element.staff;
			while (!curScore.staves[staffNum].is(elemStaff)) staffNum ++;
		}
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
		comment.autoplace = false;;
		var tick = 0;
		var segment = curScore.firstSegment();
		var firstMeasure = curScore.firstMeasure;
		var desiredPosX = 0;
		var desiredPosY = 0;
		if (element === "top") {
			// do nothing
		} else {
			if (element === "pagetop") {
				desiredPosX = 2.5;
				desiredPosY = 10.;
			} else {
				segment = element.parent;
				tick = segment.tick;
			}
		}
		
		// add text object to score
		var cursor = curScore.newCursor();
		cursor.staffIdx = staffNum;
		cursor.rewindToTick(tick);
		cursor.add(comment);
		comment.z = 9600;
		dialog.msg +=  "\nz: "+comment.z;
		var commentHeight = comment.bbox.height;
		if (desiredPosX != 0) comment.offsetX = desiredPosX - comment.pagePos.x;
		if (desiredPosY != 0) {
			comment.offsetY = desiredPosY - comment.pagePos.y;
		} else {
			comment.offsetY -= commentHeight;
		}
		if (element === "pagetop") {
			dialog.msg+="\npagePos = "+comment.pagePos.x+","+comment.pagePos.y;
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
				element.color = "hotpink";
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
		//dialog.msg = "Num elemns: "+elems.length;
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