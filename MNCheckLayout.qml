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
	
	// ** TEXT FILE DEFINITIONS ** //
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

	property var checkClefs
	property var reads8va
	property var readsTreble
	property var readsAlto
	property var readsTenor
	property var readsBass
	property var isTrebleClef
	property var isAltoClef
	property var isTenorClef
	property var isBassClef
	property var isPercClef
	property var clefIs8va
	property var clefIs8ba
	property var clefIs15ma
	property var commentPosArray: []
	

  onRun: {
		if (!curScore) return;
		
		// ** DECLARATIONS & DEFAULTS **//
		var styleComments = "";
		var pageSettingsComments = ""
		var isGrandStaff = [];
		var grandStaves = [];
		var instrumentIds = [];
		var scoreHasStrings = false;
		var scoreHasWinds = false;
		var scoreHasBrass = false;
		var scoreHasTuplets = false;
		
		// **** READ IN TEXT FILES **** //
		var techniques = techniquesfile.read().trim().split('\n');
		var canbeabbreviated = canbeabbreviatedfile.read().trim().split('\n');
		var metronomemarkings = metronomemarkingsfile.read().trim().split('\n');
		var sharedstaffsearchterms = sharedstaffsearchtermsfile.read().trim().split('\n');
		var shouldbelowercase = shouldbelowercasefile.read().trim().split('\n');
		var shouldhavefullstop = shouldhavefullstopfile.read().trim().split('\n');
		var spellingerrorsanywhere = spellingerrorsanywherefile.read().trim().split('\n');
		var spellingerrorsatstart = spellingerrorsatstartfile.read().trim().split('\n');
		var tempomarkings = tempomarkingsfile.read().trim().split('\n');
		var tempochangemarkings = tempochangemarkingsfile.read().trim().split('\n');
		
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
		var timeSigs = [];
		var numTimeSigs = 0;
		var staffSpacing = style.value("staffDistance");		
		var akkoladeDistance = style.value("akkoladeDistance");
		var minSystemDistance = style.value("minSystemDistance");
		var maxSystemDistance = style.value("maxSystemDistance");
		var staffSize = style.value("spatium")*101.6/360.;
		var staffLineWidth = style.value("staffLineWidth");
		var pageEvenLeftMargin = style.value("pageEvenLeftMargin");
		var pageOddLeftMargin = style.value("pageOddLeftMargin");
		var pageEvenTopMargin = style.value("pageEvenTopMargin");
		var pageOddTopMargin = style.value("pageOddTopMargin");
		var pageEvenBottomMargin = style.value("pageEvenBottomMargin");
		var pageOddBottomMargin = style.value("pageOddBottomMargin");
		var ledgerLines = [];
		var flaggedLedgerLines = false;
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		
		for (var i = 0; i < numStaves; i++) instrumentIds.push(staves[i].part.instrumentId);

		// **********************  CHECK SCORE & PAGE SETTINGS ************************** // 
		// **** 1A: CHECK MARGINS ****
		var maxMargin = 15;
		var numMarginsTooBig = 0;
		numMarginsTooBig += pageEvenLeftMargin > maxMargin;
		numMarginsTooBig += pageOddLeftMargin > maxMargin;
		numMarginsTooBig += pageEvenTopMargin > maxMargin;
		numMarginsTooBig += pageOddTopMargin > maxMargin;
		numMarginsTooBig += pageEvenBottomMargin > maxMargin;
		numMarginsTooBig += pageOddBottomMargin > maxMargin;
		if (numMarginsTooBig > 0) {
			pageSettingsComments += "\nDecrease your margins to no more than "+maxMargin+"mm";
		}
				
		// **** 1B: CHECK STAFF SIZE ****
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
			if (minSystemDistance < 12) styleComments += "\n(Page tab) Increase your Minimum System Distance to at least 12";
			if (minSystemDistance > 16) styleComments += "\n(Page tab) Decrease your Minimum System Distance to no more than 16";
			if (maxSystemDistance < 12) styleComments += "\n(Page tab) Increase your Maximum System Distance to at least 12";
			if (maxSystemDistance > 16) styleComments += "\n(Page tab) Decrease your Maximum System Distance to no more than 16";
		}
		
		// ** CHECK FOR STAFF NAMES ** //
		var numGrandStaves = 0;
		var prevPart = null;
		
		for (var i = 0; i < numStaves; i++) {
			var part = staves[i].part;
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
		var hideSubsequentStaffNames = false;
		var hideFirstStaffName = false;
		if (numParts < 6) hideSubsequentStaffNames = true;
		if (numParts == 1) hideFirstStaffName = true;
		
		// ** are the first staff names visible? ** //
		var firstStaffNameVisible = style.value("firstSystemInstNameVisibility");
		dialog.msg += "\nfirstStaffNameVisible: "+firstStaffNameVisible;
		if (firstStaffNameVisible) {
			firstStaffNameVisble = false;
			for (var i = 0; i < numParts; i++) {
				if (parts[i].longName != "") {
					firstStaffNameVisble = true;
					break;
				}
			}
		}
		
		if (hideFirstStaffName) {
			if (style.value("hideInstrumentNameIfOneInstrument") == false && numParts == 1) {
				styleComments += "\n(Score tab) Tick ‘Hide if there is only one instrument’";
			} else {
				if (firstStaffNameVisible) styleComments += "\nYou do not need the instrument names visible for a solo work.";
			}
		} else {
			if (!firstStaffNameVisible) styleComments += "\nYou should have all instrument names showing on the first system."
		}
		var subsStaffNamesVisible = style.value("subsSystemInstNameVisibility");
		dialog.msg += "\nsubsStaffNamesVisible: "+subsStaffNamesVisible;
		
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
		
		if (hideSubsequentStaffNames) {
			if (subsStaffNamesVisible) {
				if (numParts > 1) {
					styleComments += "\n(Score tab) Set Instrument Names → On subsequent systems to ‘Hide’";
				} else {
					styleComments += "\n(Score tab) Set Instrument Names → On subsequent systems to ‘Hide’ ";
				}
			}
		}
		
		// ** OTHER STYLE ISSUES ** //
		
		// ** POST STYLE COMMENTS
		if (styleComments != "") {
			dialog.msg += "\nstyleComments";
			
			styleComments = "I recommend making the following changes to the score’s Style (Format->Style…)"+styleComments;
			showError(styleComments,"pagetop");
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments != "") {
			dialog.msg += "\npageSettings";
			
			pageSettingsComments = "I recommend making the following changes to the score’s Page Settings (Format->Page settings…)"+pageSettingsComments;
			showError(pageSettingsComments,"pagetop");
		}
		
		// **** GET ALL ELEMENTS **** //
		var textObjects = [];
		var nTextObjects = 0;
		var m = 1;
		curScore.startCmd()
		
		curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
		curScore.endCmd()
		var elems = curScore.selection.elements;
		
		// ** PRE-PROCESS ALL ELEMENTS AS FOLLOWS **
		// ** CLEAR ANY COMMENTS OR HIGHLIGHTS **
		// ** NOTE ALL TEXT OBJECTS ** //

		var elementsToRemove = [];
		var elementsToRecolor = [];
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			var t = e.type;
			var tn = e.name.toLowerCase();
			var c = e.color;
		
			// unstyle the element
			if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
			if (t == Element.STAFF_TEXT && Qt.colorEqual(e.frameBgColor,"yellow") && Qt.colorEqual(e.frameFgColor,"black")) {
				elementsToRemove.push(e);
			} else {
				if (i==0) dialog.msg += "\nELEMENT "+i+" = "+e.name+" | "+t;
				
				if (t == Element.TEXT || t == Element.TEMPO_TEXT || t == Element.STAFF_TEXT || t == Element.SYSTEM_TEXT || t == Element.INSTRUMENT_NAME || t == Element.DYNAMIC || t == Element.LYRICS || tn === "expression") {
					textObjects.push(e);
					nTextObjects++;
				}
			}
		}
		
		dialog.msg += "\nFOUND "+nTextObjects+" TEXT OBJECTS";
		curScore.startCmd();
		for (var i = 0; i < elementsToRecolor.length; i++) {
			elementsToRecolor[i].color = "black";
		}
		for (var i = 0; i < elementsToRemove.length; i++) {
			removeElement(elementsToRemove[i]);
		}
		curScore.endCmd();
		
		// ** GET ALL KEY SIGS ** //
		cursor.filter = Segment.All;
		cursor.rewind(Cursor.SCORE_START);
		cursor.filter = Segment.KeySig;
		cursor.next();
 
		while (cursor.segment) {
			if (cursor.element) {
				var keySig = cursor.element;
				// do something with keySig 
				keySigs.push(keySig);
				dialog.msg += "\nFound a key sig";
			}
			cursor.next();
		}
		numKeySigs = keySigs.length;
		
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
				//dialog.msg += "\nFound a time sig elem? "+ts.timesigNominal.str;
			}
			cursor.next();
		}
		numTimeSigs = timeSigs.length;
		
		// —————————————————————————————————————— //
		// *				CHECK ALL TEXT OBJECTS				//
		// —————————————————————————————————————— //
		var initialTempoExists = false;
		var isSpellingError = false;
		//var composerExists = false;
		//var titleExists = false;
		var title = curScore.title;
		var subtitle = curScore.subtitle;
		var composer = curScore.composer;
		if (subtitle === 'Subtitle') {
			showError( "You haven’t changed the Subtitle in File → Project Properties","pagetop");
		}
		if (title === 'Untitled score') {
			showError( "You haven’t changed the Work Title in File → Project Properties","pagetop");
		} else {
			var lowerCaseText = title.toLowerCase();
			for (var j = 0; j < spellingerrorsatstart.length / 2; j++) {
				var spellingError = spellingerrorsatstart[j*2];
				if (lowerCaseText.substring(0,spellingError.length) === spellingError) {
					isSpellingError = true;
					var correctSpelling = spellingerrorsatstart[j*2+1];
					var diff = title.length-spellingError.length;
					var correctText = '';
					if (diff > 0) {
						correctText = correctSpelling+title.substring(spellingError.length,diff);
					} else {
						correctText = correctSpelling;
					}
					showError("The title has a spelling error in it; it should be ‘"+correctText+"’.","pagetop");
					break;
				}
			}
			if (!isSpellingError) {
				for (var j = 0; j < spellingerrorsanywhere.length / 2; j++) {
					var spellingError = spellingerrorsanywhere[j*2];
					if (title.includes(spellingError)) {
						isSpellingError = true;
						var correctSpelling = spellingerrorsanywhere[j*2+1];
						var correctText = title.replace(spellingError,correctSpelling);
						showError("The title has a spelling error in it; it should be ‘"+correctText+"’.","pagetop");
						break;
					}
				}
			}
		}
				
		if (composer === 'Composer / arranger') showError( "You haven’t changed the default composer in File → Project Properties","pagetop");
		
		for (var i = 0; i < textObjects.length; i++) {
			var textObject = textObjects[i];
			dialog.msg += "\nChecking textObject "+i;
			// IGNORE IF IT'S A COMMENT
			if (textObject.frameBgColor != "yellow" || textObject.frameFgColor != "black") {
				var textStyle = textObject.subStyle;
				tn = textObject.name.toLowerCase();
				dialog.msg += "\nText style "+i+" is "+textStyle+"; tn = "+tn;
				var styledText = textObject.text;
				var plainText = styledText.replace(/<\/[^>]+(>|$)/g, "");
				var lowerCaseText = plainText.toLowerCase();
				if (lowerCaseText != '') {
					var len = plainText.length;
					var isVisible = textObject.visible;
					var parentSegment = textObject.parent;
					var parentMeasure = parentSegment.parent;
					var parentStaff = parentMeasure.parent.parent;
				
					// ** CHECK FOR OMITTED OR DEFAULT TEXT ** //
					if (!initialTempoExists) {
						if (textObject.type == Element.TEMPO_TEXT) {
							if (parentMeasure.is(firstMeasure)) {
								initialTempoExists;
							}
						}
					}
				
					// ** CHECK TEMPO CHANGE MARKING NOT IN TEMPO TEXT ** //
					var isTempoChangeMarking = false;
				
					for (var j = 0; j < tempochangemarkings.length; j++) {
						if (lowerCaseText.includes(tempochangemarkings[j])) {
							isTempoChangeMarking = true;
							break;
						}
					}
					if (isTempoChangeMarking) {
						if (textObject.type != Element.TEMPO_TEXT) {
							showError( "‘"+plainText+"’ is a tempo change marking, but has not been entered as Tempo Text",textObject);
						}
						// check capitalisation
						if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) {
							showError("‘"+plainText+"’ looks like it is a temporary change of tempo; if it is, it should not have a capital first letter. (See Behind Bars, p. 182)",textObject);
						}
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
						if (textObject.type != Element.TEMPO_TEXT) showError("Text ‘"+plainText+"’ is a tempo marking, but has not been entered as Tempo Text",textObject);
						
						// check capitalisation
						if (plainText.substring(0,1) === lowerCaseText.substring(0,1) && lowerCaseText != "a tempo" && lowerCaseText.charCodeAt(0)>32 && !lowerCaseText.substring(0,4).includes("="))showError("‘"+plainText+"’ looks like it is establishing a new tempo; if it is, it should have a capital first letter. (See Behind Bars, p. 182)",textObject);
					}
					
					// ** CHECK WRITTEN OUT TREM ** //
					if (lowerCaseText === "trem" || lowerCaseText === "trem." || lowerCaseText === "tremolo") showError("You don’t need to write ‘"&plainText&"’: just use a tremolo marking.",textObject);
				
					// ** CHECK COMMON MISSPELLINGS ** //
					if (lowerCaseText === "mute" || lowerCaseText === "with mute" || lowerCaseText === "add mute" || lowerCaseText === "put on mute" || lowerCaseText === "put mute on" || lowerCaseText === "muted") showError( "This is best written as ‘con sord.’",textObject);
					if (lowerCaseText === "unmuted" || lowerCaseText === "no mute" || lowerCaseText === "remove mute" || lowerCaseText === "take off mute" || lowerCaseText === "take mute off") showError( "This is best written as ‘senza sord.’",textObject);
					if (lowerCaseText.substring(0,5) === "arco.") showError( "‘arco’ should not have a full-stop at the end.",textObject);
					if (lowerCaseText.substring(0,10) === "sul tasto.") showError( "‘tasto’ should not have a full-stop at the end.",textObject);
					if (lowerCaseText === "norm") showError( "‘norm’ should have a full-stop at the end (may be better as ‘ord.’).",textObject);
					if (lowerCaseText.includes("sul. ")) showError( "‘sul’ should not have a full-stop after it.",textObject);
					if (lowerCaseText.includes("  ")) showError( "This text has a double-space in it.",textObject);
					if (lowerCaseText === "normale") showError("Abbreviate ‘normale’ as ‘norm.’ or ‘ord.’.",textObject);
					
					// ** CHECK STRAIGHT/CURLY QUOTES ** //
					if (lowerCaseText.includes("'")) showError("This text has a straight single quote mark in it (').\nChange to curly — ‘ or ’.",textObject);
					if (lowerCaseText.includes('"')) showError('This text has a straight double quote mark in it (").\nChange to curly — “ or ”.',textObject);
					
					// ** CHECK FOR STYLES ** //
					if (styledText.includes("<i>arco")) showError("‘arco’ should not be italicised.",textObject);
					if (styledText.includes("<i>pizz")) showError("‘pizz.’ should not be italicised.",textObject);
					if (styledText.includes("<i>con sord")) showError("‘con sord.’ should not be italicised.",textObject);
					if (styledText.includes("<i>senza sord")) showError("‘senza sord.’ should not be italicised.",textObject);
					if (styledText.includes("<i>ord.")) showError("‘ord.’ should not be italicised.",textObject);
					if (styledText.includes("<i>sul ")) showError("String techniques should not be italicised.",textObject);
					if (styledText.slice(3) === "<b>") showError("In general, you never need to manually set text to bold.\nAre you sure you want this text bold?",textObject);
					
					// ** IS THIS A DYNAMICS SYMBOL OR MANUALLY ENTERED DYNAMICS? ** //
					var isDyn = styledText.includes('<sym>dynamics');
					if (!isDyn) isDyn = isDynamic(lowerCaseText);
					dialog.msg += "\nText is "+lowerCaseText+"; isDyn = "+isDyn;
					
					// ** CHECK FOR DYNAMIC ENTERED AS EXPRESSION (OR OTHER) TEXT ** //
					
					if (isDyn && tn != "dynamics") showError("This text object looks like a dynamic, but has not been entered using the Dynamics palette",textObject);
					
					// ** CHECK FOR TECHNIQUES ENTERED AS EXPRESSION TEXT ** //
					var shouldBeTechnique = false;
					if (tn == "expression") {
						for (var j = 0; j < techniques.length; j ++) {
							if (lowerCaseText.includes(techniques[j])) {
								showError("This looks like a technique, but has been incorrectly entered as Expression text.\nPlease check whether this should be in Technique Text instead.",textObject);
								shouldBeTechnique = true;
							}
						}
					}
					
					// ** CHECK FOR DYNAMIC TEXT
					
					// ** CHECK STARTING WITH SPACE OR NON-ALPHANUMERIC
					if (plainText.charCodeAt(0) == 32) {
						showError("‘"+plainText+"’ begins with a space, which could be deleted.",textObject);
					}
					if (plainText.charCodeAt(0) < 32) {
						showError("‘"+plainText+"’ does not seem to begin with a letter: is that correct?",textObject);
					}
					
					// ** CHECK TEXT THAT SHOULD NOT BE CAPITALISED ** //
					for (j = 0; j < shouldbelowercase.length; j++) {
						var lowercaseMarking = shouldbelowercase[j];
						var subs = plainText.substring(0,lowercaseMarking.length);
						if (subs === lowercaseMarking) {
							if (plainText.substring(0,1) != lowerCaseText.substring(0,1)) {
								showError("‘"+plainText+"’ should not have a capital first letter.",textObject);
							}
						}
					}
					
					// ** CHECK TEXT THAT SHOULD HAVE A FULL-STOP AT THE END ** //
					for (var j = 0; j < shouldhavefullstop.length; j++) {
						if (plainText === shouldhavefullstop[j]) {
							showError("‘"+plainText+"’ should have a full-stop at the end.",textObject);
						}
					}
					
					// ** CHECK COMMON SPELLING ERRORS & ABBREVIATIONS ** //
					var isSpellingError = false;
					for (var j = 0; j < spellingerrorsatstart.length / 2; j++) {
						var spellingError = spellingerrorsatstart[j*2];
						if (lowerCaseText.substring(0,spellingError.length) === spellingError) {
							isSpellingError = true;
							var correctSpelling = spellingerrorsatstart[j*2+1];
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
					if (!isSpellingError) {
						for (var j = 0; j < spellingerrorsanywhere.length / 2; j++) {
							var spellingError = spellingerrorsanywhere[j*2];
							if (plainText.includes(spellingError)) {
								isSpellingError = true;
								var correctSpelling = spellingerrorsanywhere[j*2+1];
								var correctText = plainText.replace(spellingError,correctSpelling);
								showError("‘"+plainText+"’ is misspelled; it should be ‘"+correctText+"’.",textObject);
								break;
							}
						}
					}
					if (!isSpellingError) {
						for (var j = 0; j < canbeabbreviated.length / 2; j++) {
							var fullText = canbeabbreviated[j*2];
							if (plainText.includes(fullText)) {
								var abbreviatedText = canbeabbreviated[j*2+1];
								var correctText = plainText.replace(fullText,abbreviatedText);
								showError("‘"+plainText+"’ can be abbreviated to ‘"+correctText+"’.",textObject);
								break;
							}
						}
					}
				}
			}
		}
		
		// ** CHECK FOR OMITTED TEXT ** //
		if (!initialTempoExists) showError('I couldn’t find an initial tempo marking','top');
		
		
		// *********** CHECK STAFF ORDER *********** //
		
		
		// ** FIRST CHECK THE ORDER OF STAVES IF ONE OF THE INSTRUMENTS IS A GRAND STAFF ** //
		if (numGrandStaves > 0) {
			
			dialog.msg += "\nnumGrandStaves > 0";
			// CHECK ALL SEXTETS, OR SEPTETS AND LARGER THAT DON"T MIX WINDS & STRINGS
			for (var i = 0; i < numStaves; i++) {
				var instrumentType = instrumentIds[i];
	
				if (instrumentType.includes("strings.")) scoreHasStrings = true;
				if (instrumentType.includes("wind.")) scoreHasWinds = true;
				if (instrumentType.includes("brass.")) scoreHasBrass = true;

			}
			dialog.msg += "\nscoreHasStrings = "+scoreHasStrings;
			dialog.msg += "\nscoreHasWinds = "+scoreHasWinds;
			dialog.msg += "\nscoreHasBrass = "+scoreHasBrass;
			
			// do we need to check the order of grand staff instruments?
			// only if there are less than 7 parts, or all strings or all winds or only perc + piano
			var checkGrandStaffOrder = numParts < 7;
			if (!checkGrandStaffOrder) {
				var scoreHasWindsOrBrass = scoreHasWinds || scoreHasBrass;
				if ((scoreHasWindsOrBrass != scoreHasStrings) || (!scoreHasWindsOrBrass && !scoreHasStrings)) {
					checkGrandStaffOrder = true;
				}
			}
	
			if (checkGrandStaffOrder) {
				//dialog.msg += "\ncheckGrandStaffOrder";
				//dialog.msg += "\nnumGrandStaves = "+numGrandStaves;
				
				for (var i = 0; i < numGrandStaves;i++) {
					var bottomGrandStaffNum = grandStaves[i*2+1];
					//dialog.msg += "\nbottomGrandStaffNum = "+bottomGrandStaffNum;
					if (bottomGrandStaffNum < numStaves && !isGrandStaff[bottomGrandStaffNum+1]) showError("For small ensembles, grand staff instruments should be at the bottom of the score.\nMove ‘"+staves[bottomGrandStaffNum].part.longName+"’ down using the Instruments tab.","pagetop");
				}
			}
		}
		
		// **** CHECK STANDARD CHAMBER LAYOUTS FOR CORRECT SCORE ORDER **** //
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
		
		
		// *********************** KEY SIGNATURE ERRORS *********************** //
		for (var i = 0; i < numKeySigs; i++) {
			//svar keySig = keySig[i];
			//var keySigSegment = keySig.parent;
			/*sharps = k.Sharps;
			ktext = k.AsText;
			if (ktext = "Atonal") {
				sharps = 0;
			}
			if (sharps != previousKeySigSharps) {
				//trace ("found key sig — sharps is "&sharps&" bar = "&currentBar&"; ks = "&k.AsText);
				if (sharps > 6) {
					showError("This key signature has "&sharps&" sharps, and would be easier to read if rescored as "&(12-sharps)&" flats.","KeySignature",k);
				}
				if (sharps < -6) {
					showError("This key signature has "&utils.AbsoluteValue(sharps)&" flats, and would be easier to read if rescored as "&(12+sharps)&" sharps.","KeySignature",k);
				}
				prevKeySigDur = (currentBar - previousKeySigBar);
				if (prevKeySigDur < 16) {
					showError("This key change comes only "&prevKeySigDur&" bars after the previous one. Perhaps the previous one could be avoided by using accidentals instead.","KeySignature",k);
				}
				previousKeySigSharps = s;
				previousKeySigBar = currentBar;
			}*/
		}
		
		// ************************ TIME SIGNATURE ERRORS ********************** //
		var prevTimeSig = "";
		for (var i = 0; i < numTimeSigs; i++) {
			var ts = timeSigs[i].timesig.str;
			dialog.msg += "timeSig.str = "+ts;
			if (ts === prevTimeSig) showError("This time signature appears to be redundant (was already "+prevTimeSig+"), and can be safely deleted.",timeSigs[i]);
			prevTimeSig = ts;
		}
		
		
		// ************************ PREP FOR A FULL LOOP THROUGH THE SCORE ********************** //
		var currentStaffNum, currentBar, currentBarNum, prevBarNum;
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var numBarsProcessed;
		var wasTied;
		var prevSoundingDur, prevDisplayDur;
		var tiedSoundingDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;

		firstStaffNum = 0;
		lastStaffNum = numStaves;
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
		dialog.msg += "\nfirstBarNum = "+firstBarNum;
		
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
		dialog.msg += "\nlastBarNum = "+lastBarNum;
		
		dialog.msg += "\n————————\n\nSTARTING LOOP\n\n";
		var cursor = curScore.newCursor();
		
		// **** START LOOP THROUGH WHOLE SCORE **** //
		for (currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum; currentStaffNum ++) {
			dialog.msg += "\n——— currentStaff = "+currentStaffNum;
			
			// ** REWIND TO START OF SELECTION ** //
			//dialog.msg += "\ncursor = "+cursor;
			
			cursor.filter = Segment.HeaderClef;
			cursor.staffIdx = currentStaffNum;
			cursor.voice = 0;
			cursor.track = currentStaffNum * 4;
			
			cursor.rewind(Cursor.SCORE_START);
			if (cursor.element == null) cursor.next();
			currentBar = cursor.measure;
			prevBarNum = 0;
			
			var clef = cursor.element;
			dialog.msg += "\nHeader clef = "+clef.subtypeName();
			
			// **** GET THE STARTING CLEF OF THIS INSTRUMENT **** //
			if (clef == null) {
				dialog.msg += "\nNO CLEF OBJECT FOUND";
			} else {
				setCurrentClefVariables(clef);
			}
			
				
			
			cursor.filter = Segment.ChordRest | Segment.Clef;
			cursor.next();

			

			
			for (currentBarNum = firstBarNum; currentBarNum <= lastBarNum && currentBar; currentBarNum ++) {
				
				var barStart = currentBar.firstSegment.tick;
				var barLength = currentBar.lastSegment.tick - barStart;
				var startTrack = currentStaffNum * 4;
				var endTrack = startTrack + 4;
				dialog.msg += "\ncurrentBar = "+currentBarNum;
				
				for (var track = startTrack; track < endTrack; track++) {
					
					cursor.track = track;
					cursor2.track = track;
					cursor.rewindToTick(barStart);
					
						// ** LOOP THROUGH EACH VOICE ** //
				
					var processingThisBar = cursor.element;
					while (processingThisBar) {
						dialog.msg += "\nfound element = "+cursor.element.name;
						
						if (cursor.element.type === Element.CLEF) {
							clef = cursor.element;
							dialog.msg += "\nMid-staff clef = "+clef.subtypeName();
							
							if (clef == null) {
								dialog.msg += "\nNO CLEF OBJECT FOUND";
							} else {
								setCurrentClefVariables(clef);
							}
						} else {
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
								var centreLineOffset = getCentreLineOffset(noteRest);
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
						} // end if it's a clef
						if (cursor.next()) {
							processingThisBar = cursor.measure.is(currentBar);
						} else {
							processingThisBar = false;
						}
					} // end while processingThisBar
				} // end track loop
				if (currentBar) {
					dialog.msg += "\nTrying to get next measure";
					currentBar = currentBar.nextMeasure;
				}
				if (!currentBar) dialog.msg += "\nnextMeasure failed";

				numBarsProcessed ++;
				
				dialog.msg += "\nProcessed "+numBarsProcessed+" bars";
			}// end currentBar num
		} // end staffnum loop
		
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
	
	function getCentreLineOffset (noteRest) {
		var highestNote = null;
		var highestPitch = 0;
		var diatonicPitchOfMiddleLine = 41; // B4 = 41 in diatonic pitch notation (where C4 = 35)
		if (isAltoClef) diatonicPitchOfMiddleLine = 35; // C4 = 35
		if (isTenorClef) diatonicPitchOfMiddleLine = 33; // A3 = 33
		if (isBassClef) diatonicPitchOfMiddleLine = 29; // D3 = 29
		if (clefIs8va) diatonicPitchOfMiddleLine += 7;
		if (clefIs15ma) diatonicPitchOfMiddleLine += 14;
		if (clefIs8ba) diatonicPitchOfMiddleLine -= 7;
		//dialog.msg += "NOTEREST: "+noteRest.notes.length;
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
	
	function setCurrentClefVariables (clef) {
		var clefId = clef.subtypeName();
		isTrebleClef = clefId === "Treble clef";
		isAltoClef = clefId === "Alto clef";
		isTenorClef = clefId === "Tenor clef";
		isBassClef = clefId === "Bass clef";
		isPercClef = clefId === "Percussion";
		clefIs8va = clefId.includes("8va alta");
		clefIs15ma = clefId.includes("15ma alta");
		clefIs8ba = clefId.includes("8va bassa");
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
		comment.autoplace = false;
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