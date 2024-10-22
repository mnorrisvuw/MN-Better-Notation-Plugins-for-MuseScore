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
			showError(styleComments,"top");
		}
		
		// ** SHOW PAGE SETTINGS ERROR ** //
		if (pageSettingsComments != "") {
			dialog.msg += "\npageSettings";
			
			pageSettingsComments = "I recommend making the following changes to the score’s Page Settings (Format->Page settings…)"+pageSettingsComments;
			showError(pageSettingsComments,"top");
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
		var cursor = curScore.newCursor();
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
			showError( "You haven’t changed the Subtitle in File → Project Properties","top");
		}
		if (title === 'Untitled score') {
			showError( "You haven’t changed the Work Title in File → Project Properties","top");
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
					showError("The title has a spelling error in it; it should be ‘"+correctText+"’.","top");
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
						showError("The title has a spelling error in it; it should be ‘"+correctText+"’.","top");
						break;
					}
				}
			}
		}
				
		if (composer === 'Composer / arranger') showError( "You haven’t changed the default composer in File → Project Properties","top");
		
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
				dialog.msg += "\ncheckGrandStaffOrder";
				dialog.msg += "\nnumGrandStaves = "+numGrandStaves;
				
				for (var i = 0; i < numGrandStaves;i++) {
					var bottomGrandStaffNum = grandStaves[i*2+1];
					dialog.msg += "\nbottomGrandStaffNum = "+bottomGrandStaffNum;
					//trace("Checking grand staff "&i&"; b = "&b&"; numStaves = "&numStaves&"; isGrandStaff[b+1] = "&isGrandStaff[b+1]);
					if (bottomGrandStaffNum < numStaves) {
						if (!isGrandStaff[bottomGrandStaffNum+1]) showError("For small ensembles, grand staff instruments should be at the bottom of the score. Move ‘"+staves[bottomGrandStaffNum].part.longName+"’ down using the Instruments tab.","top");
					}
				}
			}
		}
		
		// ** NEXT CHECK STANDARD LAYOUTS ** //
		var numFl = 0;
		var numOb = 0;
		var numCl = 0;
		var numBsn = 0;
		var numHn = 0;
		var numTpt = 0;
		var numTbn = 0;
		var numTba = 0;
		var fl, ob, cl, bsn, hn;
		
		// Check Quintets
		if (numStaves == 5) {
			for (var i = 0; i < 5; i ++) {
				var id = instrumentIDs[i];
				if (id.includes("wind.flutes.flute")) {
					numFl ++;
					fl = i;
				}
				if (id.includes("wind.reed.oboe") || id.includes("wind.reed.english-horn")) {
					numOb ++;
					ob = i;
				}
				if (id.includes("wind.reed.clarinet")) {
					numCl ++;
					cl = i;
				}
				if (id.includes("wind.reed.bassoon") || id.includes("wind.reed.contrabassoon")) {
					numBsn ++;
					bsn = i;
				}
				if (id.includes( "brass.french-horn")) {
					numHn ++;
					hn = i;
				}
				if (id.includes( "brass.trumpet")) {
					numTpt ++;
					if (numTpt == 1) tpt1 = i;
					if (numTpt == 2) tpt2 = i;
				}
				if (id.includes("brass.trombone")) {
					numTbn ++;
					tbn = i;
				}
				if (id.includes ("brass.tuba")) {
					numTba ++;
					tba = i;
				}
			}
			
			// CHECK FOR WIND QUINTET
			if (numFl == 1 && numOb == 1 && numCl == 1 && numBsn == 1 && numHn == 1) {
				//WIND QUINTET
				// check staff order
				if (fl != 0) showError("You appear to be composing a wind quintet, but the flute should be the top staff.","top");
				if (ob != 1) showError("You appear to be composing a wind quintet, but the oboe should be the second staff.","top");
				if (cl != 2) showError("You appear to be composing a wind quintet, but the clarinet should be the third staff.","top");
				if (hn != 3) showError("You appear to be composing a wind quintet, but the horn should be the fourth staff.","top");
				if (bsn != 4) showError("You appear to be composing a wind quintet, but the bassoon should be the bottom staff.","top");
			}
			if (numTpt == 2 && numHn == 1 && numTbn == 1 && numTba == 1) {
				// BRASS QUINTET
				if (tpt1 != 0) showError("You appear to be composing a brass quintet, but the first trumpet should be the top staff.","top");
				if (tpt2 != 1) showError("You appear to be composing a brass quintet, but the second trumpet should be the second staff.","top");
				if (hn != 2) showError("You appear to be composing a brass quintet, but the horn should be the third staff.","top");
				if (tbn != 3) showError("You appear to be composing a brass quintet, but the trombone should be the fourth staff.","top");
				if (tba != 4) showError("You appear to be composing a brass quintet, but the tuba should be the bottom staff.","top");
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
