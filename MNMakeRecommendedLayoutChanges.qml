/*
 * Copyright (C) 2025 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.4 or later

import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Muse.UiComponents 1.0
import FileIO 3.0

MuseScore {
	version:  "1.0"
	description: "This plugin automatically makes recommended layout changes to the score, based on preferences curated by Michael Norris"
	menuPath: "Plugins.MNMakeRecommendedLayoutChanges"
	requiresScore: true
	title: "MN Make Recommended Layout Changes"
	id: mnmakerecommendedlayoutchanges
	thumbnailName: "MNMakeRecommendedLayoutChanges.png"	
	property var selectionArray: null
	property var firstMeasure: null
	property var numParts: 0
	property var numStaves: 0
	property var isSoloScore: false
	property var inchesToMM: 25.4
	property var mmToInches: 0.039370079
	property var excerpts: null
	property var numExcerpts: 0
	property var amendedParts: false
	property var removeLayoutBreaksOption: false
	property var setSpacingOption: false
	property var setBravuraOption: false
	property var setTimesOption: false
	property var setFontSizesOption: false
	property var setPartsOption: false
	property var removeStretchesOption: false
	property var removeManualTextFormattingOption: false
	property var setTitleFrameOption: false
	property var formatTempoMarkingsOption: false
	property var connectBarlinesOption: false
	property var spatium: 0
	property var numGrandStaves: 0
	property var isGrandStaff: []
	property var isTopOfGrandStaff: []
	property var grandStaffTops: []
	property var staffVisible: []
	property var instrumentIds: []
	property var instrumentCalcIds: []
	property var firstVisibleStaff: 0
	FileIO { id: versionnumberfile; source: Qt.resolvedUrl("./assets/versionnumber.txt").toString().slice(8); onError: { console.log(msg); } }
	
	onRun: {
		if (!curScore) return;
		
		var versionNumber = versionnumberfile.read().trim();
		dialog.titleText = 'MN MAKE RECOMMENDED LAYOUT CHANGES '+versionNumber;
		if (Qt.platform.os !== "osx") dialog.fontSize = 12;
		// Show the options window
		options.open();		
	}
	
	function makeChanges() {
		removeLayoutBreaksOption = options.removeBreaks;
		setSpacingOption = options.setSpacing;
		setBravuraOption = options.setBravura;
		setTimesOption = options.setTimes;
		setFontSizesOption = options.setFontSizes;
		setPartsOption = options.setParts;
		setTitleFrameOption = options.setTitleFrame;
		removeStretchesOption = options.removeStretches;
		formatTempoMarkingsOption = options.formatTempoMarkings;
		connectBarlinesOption = options.connectBarlines;
		removeManualTextFormattingOption = options.removeManualFormatting;
		
		options.close();
	
		numStaves = curScore.nstaves;
		
		// *** REMOVE ANY COMMENTS AND HIGHLIGHTS THAT MIGHT BE LEFT OVER FROM OTHER PLUGINS ***
		deleteAllCommentsAndHighlights();
		
		var finalMsg = '';
		
		// calculate the spatium
		spatium = curScore.style.value("spatium")*inchesToMM/mscoreDPI;
		
		// *** ANALYSE ALL INSTRUMENTS AND STAVES *** //
		analyseInstrumentsAndStaves();

		// *** SELECT ALL *** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
		firstMeasure = curScore.firstMeasure;
		var visibleParts = [];
		
		// *** Calculate number of parts, but ignore hidden ones *** //
		for (var i = 0; i < curScore.parts.length; i++) if (curScore.parts[i].show) visibleParts.push(curScore.parts[i]);
		numParts = visibleParts.length;
		isSoloScore = numParts == 1;
		excerpts = curScore.excerpts;
		numExcerpts = excerpts.length;
		if (numParts > 1 && numExcerpts < numParts) finalMsg = "<b>NOTE</b>: Parts for this score have not yet been created/opened, so I wasn’t able to change the part layout settings.\nYou can create them by clicking ‘Parts’, then ’Open All’. Once you have created and opened the parts, please run this plug-in again on the score to change the part layout settings. (Ignore this if you do not plan to create parts.)";
		
		// *** REMOVE LAYOUT BREAKS *** //
		if (removeLayoutBreaksOption || removeStretchesOption) removeLayoutBreaksAndStretches();
		
		// *** SET ALL THE SPACING-RELATED SETTINGS *** //
		if (setSpacingOption) setSpacing();
		
		// *** SET ALL THE OTHER STYLE SETTINGS *** //
		if (setOtherStyleSettings) setOtherStyleSettings();
		
		// *** FONT SETTINGS *** //
		if (setTimesOption) setTimes();
		if (setBravuraOption) setBravura();
		if (setFontSizesOption) setFontSizes();
		if (formatTempoMarkingsOption) formatTempoMarkings();
		if (removeManualTextFormattingOption) removeManualTextFormatting();
		
		// *** LAYOUT THE TITLE FRAME ON p. 1 *** //
		if (setTitleFrameOption) setTitleFrame();
		
		// *** SET PART SETTINGS
		if (setPartsOption) setPartSettings();
		
		if (connectBarlinesOption) doConnectBarlines();
		
		
		// CHANGE INSTRUMENT NAMES
		//changeInstrumentNames();
		
		// *** SELECT NONE AND FORCE REDRAW *** //
		
		curScore.startCmd();
		cmd ('escape');
		cmd ('escape');
		cmd ('concert-pitch');
		cmd ('concert-pitch');
		curScore.endCmd();
		
		var dialogMsg = '';
		if (amendedParts) {
			dialogMsg = '<p>Changes to the layout of the score and parts were made successfully.</p><p><b>NOTE</b>: If your parts were open, you may need to close and re-open them if the layout changes have not been updated.</p><p>Note that some changes may not be optimal, and further tweaks are likely to be required.</p>';
		} else {
			dialogMsg = '<p>Changes to the layout of the score were made successfully.</p><p>Note that some changes may not be optimal, and further tweaks are likely to be required.</p>';
			if (finalMsg != '') dialogMsg = dialogMsg + '<p>' + finalMsg + '</p>';
		}
		dialog.msg = dialogMsg;
		dialog.show();
	}
	
	function removeLayoutBreaksAndStretches () {
		var currMeasure = firstMeasure;
		var breaks = [];
		curScore.startCmd();
		while (currMeasure) {
			if (removeLayoutBreaksOption) {
				var elems = currMeasure.elements;
				for (var i = 0; i < elems.length; i ++) if (elems[i].type == Element.LAYOUT_BREAK) breaks.push(elems[i]);
			}
			if (removeStretchesOption) if (currMeasure.userStretch != 1) currMeasure.userStretch = 1;
			
			currMeasure = currMeasure.nextMeasure;
		}
		curScore.endCmd();
		curScore.startCmd();
		for (var i = 0; i < breaks.length; i++ ) removeElement (breaks[i]);
		curScore.endCmd();
	}
	
	function analyseInstrumentsAndStaves () {
		var transposingInstruments = ["brass.bugle.soprano","brass.bugle.mellophone-bugle","brass.bugle.baritone","brass.bugle.contrabass","brass.cornet","brass.euphonium","brass.flugelhorn","brass.french-horn","brass.trumpet.bflat","brass.trumpet.d","brass.trumpet.piccolo","keyboard.celesta","metal.crotales","pitched-percussion.glockenspiel","pitched-percussion.xylophone","pluck.guitar","strings.contrabass","wind.flutes.flute.piccolo","wind.flutes.flute.alto","wind.flutes.flute.bass","wind.reed.clarinet","wind.reed.contrabassoon","wind.reed.english-horn","wind.reed.oboe.bass","wind.reed.oboe-damore","wind.reed.saxophone"];
		numGrandStaves = 0;
		var prevPart = null;
		var prevPrevPart = null;
		var staves = curScore.staves;
		var visiblePartFound = false;
		for (var i = 0; i < numStaves; i++) {
			
			// save the id and staffName
			var part = staves[i].part;
			staffVisible[i] = part.show;
			if (staffVisible[i] && !visiblePartFound) {
				visiblePartFound = true;
				firstVisibleStaff = i;
			}
	
			var id = part.instrumentId;
			instrumentIds.push(id);
			var calcid = id;
			var staffName = staves[i].part.longName;
			var lowerStaffName = staffName.toLowerCase();
			
			if (id.includes('.group')) {
				if (id.includes('strings')) {
					if (lowerStaffName.includes('violin')) calcid = 'strings.violin';
					if (lowerStaffName.includes('viola')) calcid = 'strings.viola';
					if (lowerStaffName.includes('cello')) calcid = 'strings.cello';
					if (lowerStaffName.includes('bass')) calcid = 'strings.contrabass';
				}
				if (id.includes('wind')) {
					if (lowerStaffName.includes('piccolo')) calcid = 'wind.flutes.flute.piccolo';
					if (lowerStaffName.includes('flute')) {
						if (lowerStaffName.includes('alto')) {
							calcid = 'wind.flutes.flute.alto';
						} else {
							if (lowerStaffName.includes('bass')) {
								calcid = 'wind.flutes.flute.bass';
							} else {
								calcid = 'wind.flutes.flute';
							}
						}
					}
					if (lowerStaffName.includes('oboe')) calcid = 'wind.reed.oboe';
					if (lowerStaffName.includes('anglais') || lowerStaffName.includes('english')) calcid = 'wind.reed.english-horn';
					if (lowerStaffName.includes('clarinet')) {
						if (lowerStaffName.includes('bass')) {
							calcid = 'wind.reed.clarinet.bass';
						} else {
							if (lowerStaffName.includes('a cl') || lowerStaffName.includes('in a')) {
								calcid = 'wind.reed.clarinet.a';
							} else {
								if (lowerStaffName.includes('eb cl') || lowerStaffName.includes('in eb')) {
									calcid = 'wind.reed.clarinet.eb';
								} else {
									calcid = 'wind.reed.clarinet.bb';
								}
							}
						}
					}
						
					if (staffName.includes('bassoon')) {
						if (lowerStaffName.includes('contra')) {
							calcid = 'wind.reed.contrabassoon';
						} else {
							calcid = 'wind.reed.bassoon';
						}
					}
				}
				if (id.includes('brass')) {
					if (lowerStaffName.includes('horn')) calcid = 'brass.french-horn';
					if (lowerStaffName.includes('trumpet')) calcid = 'brass.trumpet';
					if (lowerStaffName.includes('trombone')) calcid = 'brass.trombone';
					if (lowerStaffName.includes('tuba')) calcid = 'brass.tuba';
				}
			}
			instrumentCalcIds.push(calcid);
			
			if (i > 0 && part.is(prevPart)) {
				isGrandStaff[i-1] = true;
				isGrandStaff[i] = true;
				isTopOfGrandStaff[i-1] = !prevPart.is(prevPrevPart);
				isTopOfGrandStaff[i] = false;
				grandStaffTops.push(i-1);
				numGrandStaves ++;
				// NOTE: THIS DOESN'T WORK IF YOUR GRAND STAFF HAS MORE THAN 2 STAVES
			} else {
				isTopOfGrandStaff[i] = false;
				isGrandStaff[i] = false;
			}
			prevPrevPart = prevPart;
			prevPart = part;
		}
	}

	
	function doConnectBarlines () {
		// **** CHECK STANDARD CHAMBER LAYOUTS FOR CORRECT SCORE ORDER **** //
		// **** ALSO NOTE ANY GRAND STAVES			  				 **** //
		// **** AND CHECK BARLINES ARE CONNECTED PROPERLY 			**** //
		var scoreHasStrings = false;
		var scoreHasWinds = false;
		var scoreHasBrass = false;
		
		// ** FIRST CHECK THE ORDER OF STAVES IF ONE OF THE INSTRUMENTS IS A GRAND STAFF ** //
		if (numGrandStaves > 0) {
			// CHECK ALL SEXTETS, OR SEPTETS AND LARGER THAT DON"T MIX WINDS & STRINGS
			for (var i = 0; i < numStaves; i++) {
				if (staffVisible[i]) {
					var instrumentType = instrumentIds[i];
					if (instrumentType.includes("strings.")) scoreHasStrings = true;
					if (instrumentType.includes("wind.")) scoreHasWinds = true;
					if (instrumentType.includes("brass.")) scoreHasBrass = true;
				}
			}
			// do we need to check the order of grand staff instruments?
			// only if there are less than 7 parts, or all strings or all winds or only perc + piano
			var checkGrandStaffOrder = (numParts < 7) || ((scoreHasWinds || scoreHasBrass) != scoreHasStrings) || (!(scoreHasWinds || scoreHasBrass) && !scoreHasStrings);
		
			if (checkGrandStaffOrder) {
				for (var i = 0; i < numGrandStaves;i++) {
					var bottomGrandStaffNum = grandStaffTops[i]+1;
					if (bottomGrandStaffNum < numStaves-1) {
						if (!isGrandStaff[bottomGrandStaffNum+1] && staffVisible[bottomGrandStaffNum]) addError("For small ensembles, grand staff instruments should be at the bottom of the score.\nMove ‘"+curScore.staves[bottomGrandStaffNum].part.longName+"’ down using the Instruments tab.","pagetop");
					}
				}
			}
		}
		
		// we don't need to check solos, duos or trios
		if (numParts < 4) return;
		
		var numFl = 0;
		var numOb = 0;
		var numCl = 0;
		var numBsn = 0;
		var numHn = 0;
		var numTpt = 0;
		var numTbn = 0;
		var numTba = 0;
		var numVn = 0;
		var numVa = 0;
		var numVc = 0;
		var numDb = 0;
		var numWinds = 0;
		var numBrass = 0;
		var numStrings = 0;
		var flStaff, obStaff, clStaff, bsnStaff, hnStaff;
		var tpt1Staff, tpt2Staff, tbnStaff, tbaStaff;
		var firstStringPart = 0, firstWindPart = 0, firstBrassPart = 0;
		var lastStringPart = 0, lastWindPart = 0, lastBrassPart = 0;
		
		// Check Quintets
		for (var i = 0; i < numStaves; i ++) {
			if (staffVisible[i]) {
				var id = instrumentIds[i];
				
				// **** CHECK WINDS **** //
				if (id.includes("wind")) {
					numWinds++;
					if (numWinds == 1) firstWindPart = i;
					lastWindPart = i;
				}
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
				
				// **** CHECK BRASS **** //
				if (id.includes("brass")) {
					numBrass ++;
					if (numBrass == 1) firstBrassPart = i;
					lastBrassPart = i;
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
				
				// **** CHECK STRINGS **** //
				if (id.includes ("strings")) {
					numStrings ++;
					if (numStrings == 1) firstStringPart = i;
					lastStringPart = i;
				}
				if (id.includes ("strings.violin")) numVn ++;
				if (id.includes ("strings.viola")) numVa ++;
				if (id.includes ("strings.cello")) numVc ++;
				if (id.includes ("strings.contrabass")) numDb ++;
				
			}
		}
		
		var ensembleType = '';
		
		// **** CHECK ENSEMBLE TYPES **** //
		if (numParts == 5 && numFl == 1 && numOb == 1 && numCl == 1 && numBsn == 1 && numHn == 1) ensembleType = "wind quintet";
		if (numParts == 5 && numTpt == 2 && numHn == 1 && numTbn == 1 && numTba == 1) ensembleType = "brass quintet";
		if (numParts == 4 && numVn == 2 && numVa == 1 && numVc == 1) ensembleType = "string quartet";
		if (numParts == 5 && numVn == 2 && numVa > 0 && numVa < 3 && numVc > 0 && numVc < 3 && numDb < 2) ensembleType = "string quintet";
		if (numParts > 6 && numWinds > 1 && numBrass > 1 && numStrings > 1) ensembleType = "orchestra";
		
		var lastVisibleStaff = 0;
		
		for (var i = 0; i < numStaves; i++) if (staffVisible[i]) lastVisibleStaff = i;
		
		if (ensembleType === "orchestra") {
			curScore.startCmd();

			for (var i = 0; i < numStaves; i ++) {
				if (staffVisible[i]) {
					var staff = curScore.staves[i];
					if (i < lastWindPart && staff.staffBarlineSpan == 0) staff.staffBarlineSpan == 1;
					if (i == lastWindPart && staff.staffBarlineSpan != 0) staff.staffBarlineSpan == 0;
					if (i >= firstBrassPart && i < lastBrassPart && staff.staffBarlineSpan == 0) staff.staffBarlineSpan == 1;
					if (i == lastBrassPart && staff.staffBarlineSpan != 0) staff.staffBarlineSpan == 0;
					if (i >= firstStringPart && i < lastStringPart && staff.staffBarlineSpan == 0) staff.staffBarlineSpan == 1;
				}
			}
			curScore.endCmd();
		} else {
			curScore.startCmd();
			for (var i = 0; i < lastVisibleStaff-1; i++) {
				if (staffVisible[i]) {
					var staff = curScore.staves[i];
					if (staff.staffBarlineSpan == 0) staff.staffBarlineSpan = 1;
				}
			}
			curScore.endCmd();
		}
	}
	
	function changeInstrumentNames () {
		// *** NEEDS API TO CHANGE TO BE WRITEABLE *** //
		/*
		var namesToChange = ["violin 1", "violins 1", "violin 2", "violins 2", "violas", "violas 1", "violas 2", "violoncellos", "cellos 1", "cellos 2", "contrabass", "contrabasses", "vlns. 1", "vln. 1", "vlns 1", "vln 1", "vn. 1", "vn 1", "vlns. 2", "vln. 2", "vlns 2", "vln 2", "vn. 2", "vlas. 1", "vla. 1", "vlas 1", "vla 1", "va. 1", "va 1", "vn 2", "vcs 1", "vcs. 1", "vc 1", "vcs. 1", "cellos 1", "vcs 2", "vcs. 2", "vc 2", "vcs. 2", "cellos 2", "vlas.", "vlas", "vcs.", "vcs", "cb", "cb.", "cbs", "cbs.", "db", "dbs", "db.", "dbs.","d.bs.","d.b.s"];
		
		var namesToChangeTo = ["Violin I", "Violin I", "Violin II", "Violin II", "Viola", "Viola I", "Viola II", "Cello", "Cello I", "Cello II", "Double Bass", "Double Bass", "Vn. I", "Vn. I", "Vn. I", "Vn. I", "Vn. I", "Vn. I", "Vn. II", "Vn. II", "Vn. II", "Vn. II", "Vn. II", "Vn. II", "Va. I", "Va. I", "Va. I", "Va. I", "Va. I", "Va. I", "Va. II", "Va. II", "Va. II", "Va. II", "Va. II", "Va. II", "Cello I", "Cello I", "Cello I", "Cello I", "Cello I", "Cello II", "Cello II", "Cello II", "Cello II", "Cello II", "Viola", "Viola", "Cello", "Cello", "D.B.","D.B.","D.B.","D.B.","D.B.","D.B.","D.B.","D.B.","D.B.","D.B."];
		
		for (var i = 0; i < curScore.nstaves; i++) {
			var theStaff = curScore.staves[i];
			var fullStaffName = theStaff.part.longName.toLowerCase();
			var shortStaffName = theStaff.part.shortName.toLowerCase();
			var fullIndex = namesToChange.indexOf(fullStaffName);
			var shortIndex = namesToChange.indexOf(shortStaffName);
			var inst = theStaff.part.instrumentAtTick(0);
			if (fullIndex > -1 && fullIndex < namesToChangeTo.length) inst.longName = namesToChangeTo[fullIndex];
			if (shortIndex > -1 && shortIndex < namesToChangeTo.length) inst.shortName = namesToChangeTo[shortIndex];
		}*/
	}
	
	function setSpacing() {

		// change staff spacing
		// change min and max system distance
		curScore.startCmd();
		setSetting ("minSystemDistance", 6.0);
		setSetting ("maxSystemDistance", 9.0);
		var lrMargin = 12.;
		var tbMargin = 15.;
		var lrIn = lrMargin*mmToInches;
		var tbIn = tbMargin*mmToInches;
		setSetting("pageEvenLeftMargin",lrIn);
		setSetting("pageOddLeftMargin",lrIn);
		setSetting("pageEvenTopMargin",tbIn);
		setSetting("pageOddTopMargin",tbIn);
		setSetting("pageEvenBottomMargin",tbIn);
		setSetting("pageOddBottomMargin",tbIn);
		var pageWidth = curScore.style.value("pageWidth") * inchesToMM;
		var pagePrintableWidth = (pageWidth - 2 * lrMargin) * mmToInches;
		setSetting("pagePrintableWidth",pagePrintableWidth);
		setSetting("staffLowerBorder",0);
		setSetting("frameSystemDistance",8);
		//setSetting("pagePrintableHeight",10/inchesToMM);
		
		// TO DO: SET SPATIUM
		// **** TEST 1B: CHECK STAFF SIZE ****)
		var staffSize = 6.8;
		if (numParts == 2) staffSize = 6.3;
		if (numParts == 3) staffSize = 6.2;
		if (numParts > 3 && numParts < 8) staffSize = 5.6 - Math.floor((numParts - 4) * 0.5) / 10.;
		if (numParts > 7) {
			staffSize = 5.2 - Math.floor((numParts - 8) * 0.5) / 10.;
			if (staffSize < 3.7) staffSize = 3.7;
		}
		var newSpatium = staffSize / 4.0;
		
		setSetting ("spatium",newSpatium/inchesToMM*mscoreDPI);
		spatium = curScore.style.value("spatium")*inchesToMM/mscoreDPI;

		// SET STAFF NAME VISIBILITY
		setSetting ("hideInstrumentNameIfOneInstrument",1);
		setSetting ("firstSystemInstNameVisibility",0);
		setSetting ("subsSystemInstNameVisibility",1);
		setSetting ("subsSystemInstNameVisibility", (numParts < 6) ? 2: 1);
		setSetting ("enableIndentationOnFirstSystem", !isSoloScore);
		setSetting ("enableVerticalSpread", 1);
		
		// STAFF SPACING
		setSetting ("minStaffSpread", 5);
		setSetting ("maxStaffSpread", isSoloScore ? 6 : 10);
		
		// SYSTEM SPACING
		setSetting ("minSystemSpread", isSoloScore ? 6 : 12);
		setSetting ("maxSystemSpread", isSoloScore ? 14 : 32);	
		curScore.endCmd();	
	}
	
	function setOtherStyleSettings() {
		
		//MARK: TOP OF STYLE SETTINGS
		
		// HERE IS THE COMPLETE LIST OF STYLE IDs
		// SOME OF THEM HAVE BEEN SET IN PREVIOUS ROUTINES
		curScore.startCmd();
		var completeDefaultSettings = [		
		"staffUpperBorder","",
		"staffLowerBorder","",
		"staffHeaderFooterPadding","",
		"staffDistance", 5, // ????
		"instrumentNameOffset","",
		"akkoladeDistance","",
		"minSystemDistance","",
		"maxSystemDistance","",
		"alignSystemToMargin","",
		
		"enableVerticalSpread","",
		"spreadSystem","",
		"spreadSquareBracket","",
		"spreadCurlyBracket","",
		"minSystemSpread","", // set previously
		"maxSystemSpread","", // set previously
		"minStaffSpread","", // set previously
		"maxStaffSpread","", // set previously
		"maxAkkoladeDistance","",
		"maxPageFillSpread","",
		
		"lyricsPlacement", 1, // Lyrics → Position
		"lyricsPosAbove", -2, // Lyrics → Offset above
		"lyricsPosBelow", 3, // Lyrics → Position
		"lyricsMinTopDistance", 1, // Lyrics → Min. margin to current stave
		"lyricsMinBottomDistance", 1.5, // Lyrics → Min. margin to other staves
		"lyricsMinDistance", 0.25, // Lyrics → Min. gap between lyrics
		"lyricsLineHeight","",
		"lyricsDashMinLength","",
		"lyricsDashMaxLength","",
		"lyricsDashMaxDistance","",
		"lyricsDashForce","",
		"lyricsDashFirstAndLastGapAreHalf","",
		"lyricsAlignVerseNumber","",
		"lyricsLineThickness","",
		"lyricsMelismaAlign","",
		"lyricsMelismaPad","",
		"lyricsDashPad","",
		"lyricsDashLineThickness","",
		"lyricsDashYposRatio","",
		
		"lyricsShowDashIfSyllableOnFirstNote","",
		"lyricsMelismaForce","",
		"lyricsMelismaMinLength","",
		"lyricsDashPosAtStartOfSystem","",
		"lyricsAvoidBarlines","",
		"lyricsLimitDashCount","",
		"lyricsMaxDashCount","",
		"lyricsCenterDashedSyllables","",
		
		"lyricsOddFontFace","",
		"lyricsOddFontSize","",
		"lyricsOddLineSpacing","",
		"lyricsOddFontSpatiumDependent","",
		"lyricsOddFontStyle","",
		"lyricsOddColor","",
		"lyricsOddAlign","",
		"lyricsOddFrameType","",
		"lyricsOddFramePadding","",
		"lyricsOddFrameWidth","",
		"lyricsOddFrameRound","",
		"lyricsOddFrameFgColor","",
		"lyricsOddFrameBgColor","",
		
		"lyricsEvenFontFace","",
		"lyricsEvenFontSize","",
		"lyricsEvenLineSpacing","",
		"lyricsEvenFontSpatiumDependent","",
		"lyricsEvenFontStyle","",
		"lyricsEvenColor","",
		"lyricsEvenAlign","",
		"lyricsEvenFrameType","",
		"lyricsEvenFramePadding","",
		"lyricsEvenFrameWidth","",
		"lyricsEvenFrameRound","",
		"lyricsEvenFrameFgColor","",
		"lyricsEvenFrameBgColor","",
		
		"figuredBassFontFamily","",
		"//      figuredBassFontSize","",
		"figuredBassYOffset","",
		"figuredBassLineHeight","",
		"figuredBassAlignment","",
		"figuredBassStyle","",
		"systemFrameDistance","",
		"frameSystemDistance","",
		"minMeasureWidth", isSoloScore ? 14.0 : 16.0, // Bars → Minimum Bar Width
		
		"barWidth", 0.16, // Barlines → Thin Barline Thickness
		"doubleBarWidth","",
		"endBarWidth","",
		"doubleBarDistance","",
		"endBarDistance","",
		"repeatBarlineDotSeparation","",
		"repeatBarTips","",
		"startBarlineSingle","",
		"startBarlineMultiple","",
		"maskBarlinesForText","",
		
		"bracketWidth","",
		"bracketDistance","",
		"akkoladeWidth","",
		"akkoladeBarDistance","",
		"dividerLeft","",
		"dividerLeftSym","",
		"dividerLeftX","",
		"dividerLeftY","",
		"dividerRight","",
		"dividerRightSym","",
		"dividerRightX","",
		"dividerRightY","",
		
		"clefLeftMargin","",
		"keysigLeftMargin","",
		"ambitusMargin","",
		"timesigLeftMargin","",
		
		"midClefKeyRightMargin","",
		"clefKeyRightMargin","",
		"clefKeyDistance","",
		"clefTimesigDistance","",
		"keyTimesigDistance","",
		"keyBarlineDistance","",
		"systemHeaderDistance","",
		"systemHeaderTimeSigDistance","",
		"systemHeaderMinStartOfSystemDistance","",
		"systemTrailerRightMargin","",
		
		"clefBarlineDistance","",
		"timesigBarlineDistance","",
		
		"timeSigPlacement","",
		
		"timeSigCenterOnBarline","",
		"timeSigVSMarginCentered","",
		"timeSigVSMarginNonCentered","",
		"timeSigCenterAcrossStaveGroup","",
		
		"timeSigNormalStyle","",
		"timeSigNormalScale","",
		"timeSigNormalScaleLock","",
		"timeSigNormalNumDist","",
		"timeSigNormalY","",
		"timeSigAboveStyle","",
		"timeSigAboveScale","",
		"timeSigAboveScaleLock","",
		"timeSigAboveNumDist","",
		"timeSigAboveY","",
		"timeSigAcrossStyle","",
		"timeSigAcrossScale","",
		"timeSigAcrossScaleLock","",
		"timeSigAcrossNumDist","",
		"timeSigAcrossY","",
		
		"useStraightNoteFlags", 0, // Notes → Flag Style (0 = Traditional, 1 = Straight)
		"stemWidth", 0.1, // Notes → Stem thickness
		"shortenStem", 1, // Notes → Shorten Stems
		"stemLength","",
		"stemLengthSmall","",
		"shortStemStartLocation","",
		"shortestStem", 2.75, // Notes → Shortest Stem
		"combineVoice","",
		"beginRepeatLeftMargin","",
		"minNoteDistance", isSoloScore ? 1.1 : 0.6, // Bars → Minimum Note Distance
		"barNoteDistance", 1.4, // Bars → Padding → Barline to note
		"barAccidentalDistance", 0.8, // Bars → Padding → Barline to accidental
		"noteBarDistance","",
		
		"measureSpacing", 1.5, // Bars → Spacing ratio
		"measureRepeatNumberPos","",
		"mrNumberSeries","",
		"mrNumberEveryXMeasures","",
		"mrNumberSeriesWithParentheses","",
		"oneMeasureRepeatShow1","",
		"fourMeasureRepeatShowExtenders","",
		"staffLineWidth", 0.1, // Score → Stave line thickness
		"ledgerLineWidth","",
		"ledgerLineLength","",
		"stemSlashPosition","",
		"stemSlashAngle","",
		"stemSlashThickness","",
		"accidentalDistance","",
		"accidentalNoteDistance","",
		"bracketedAccidentalPadding","",
		"alignAccidentalsLeft","",
		"accidentalOrderFollowsNoteDisplacement","",
		"alignAccidentalOctavesAcrossSubChords","",
		"keepAccidentalSecondsTogether","",
		"alignOffsetOctaveAccidentals","",
		"keysigAccidentalDistance","",
		"keysigNaturalDistance","",
		"beamWidth","",
		"useWideBeams","",
		"beamMinLen","",
		"beamNoSlope","",
		"snapCustomBeamsToGrid","",
		"frenchStyleBeams","",
		
		"dotMag","",
		"dotNoteDistance","",
		"dotRestDistance","",
		"dotDotDistance","",
		"propertyDistanceHead","",
		"propertyDistanceStem","",
		"propertyDistance","",
		"articulationMag","",
		"articulationPosAbove","",
		"articulationAnchorDefault","",
		"articulationAnchorLuteFingering","",
		"articulationAnchorOther","",
		"articulationStemHAlign","",
		"articulationKeepTogether","",
		"trillAlwaysShowCueNote","",
		"lastSystemFillLimit", 0, // Page → Last system fill threshold
		
		"hairpinPlacement","",
		"hairpinPosAbove","",
		"hairpinPosBelow","",
		"hairpinLinePosAbove","",
		"hairpinLinePosBelow","",
		"hairpinHeight","",
		"hairpinContHeight","",
		"hairpinLineWidth","",
		"hairpinFontFace","",
		"hairpinFontSize","",
		"hairpinLineSpacing","",
		"hairpinFontSpatiumDependent","",
		"hairpinFontStyle","",
		"hairpinColor","",
		"hairpinTextAlign","",
		"hairpinFrameType","",
		"hairpinFramePadding","",
		"hairpinFrameWidth","",
		"hairpinFrameRound","",
		"hairpinFrameFgColor","",
		"hairpinFrameBgColor","",
		"hairpinText","",
		"hairpinCrescText","",
		"hairpinDecrescText","",
		"hairpinCrescContText","",
		"hairpinDecrescContText","",
		"hairpinLineStyle","",
		"hairpinDashLineLen","",
		"hairpinDashGapLen","",
		"hairpinLineLineStyle","",
		"hairpinLineDashLineLen","",
		"hairpinLineDashGapLen","",
		
		"pedalPlacement","",
		"pedalPosAbove","",
		"pedalPosBelow","",
		"pedalLineWidth","",
		"pedalLineStyle","",
		"pedalDashLineLen","",
		"pedalDashGapLen","",
		"pedalHookHeight","",
		"pedalFontFace","",
		"pedalFontSize","",
		"pedalLineSpacing","",
		"pedalFontSpatiumDependent","",
		"pedalMusicalSymbolsScale","",
		"pedalFontStyle","",
		"pedalColor","",
		"pedalTextAlign","",
		"pedalFrameType","",
		"pedalFramePadding","",
		"pedalFrameWidth","",
		"pedalFrameRound","",
		"pedalFrameFgColor","",
		"pedalFrameBgColor","",
		"pedalText","",
		"pedalHookText","",
		"pedalContinueText","",
		"pedalContinueHookText","",
		"pedalEndText","",
		"pedalRosetteEndText","",
		
		"trillPlacement","",
		"trillPosAbove","",
		"trillPosBelow","",
		
		"vibratoPlacement","",
		"vibratoPosAbove","",
		"vibratoPosBelow","",
		
		"harmonyFretDist","",
		"minHarmonyDistance","",
		"maxHarmonyBarDistance","",
		"maxChordShiftAbove","",
		"maxChordShiftBelow","",
		
		"harmonyPlacement","",
		"romanNumeralPlacement","",
		"nashvilleNumberPlacement","",
		"harmonyVoiceLiteral","",
		"harmonyVoicing","",
		"harmonyDuration","",
		
		"chordSymbolAPosAbove","",
		"chordSymbolAPosBelow","",
		
		"chordSymbolBPosAbove","",
		"chordSymbolBPosBelow","",
		
		"romanNumeralPosAbove","",
		"romanNumeralPosBelow","",
		
		"nashvilleNumberPosAbove","",
		"nashvilleNumberPosBelow","",
		
		"chordSymbolAFontFace","",
		"chordSymbolAFontSize","",
		"chordSymbolALineSpacing","",
		"chordSymbolAFontSpatiumDependent","",
		"chordSymbolAFontStyle","",
		"chordSymbolAColor","",
		"chordSymbolAAlign","",
		"chordSymbolAFrameType","",
		"chordSymbolAFramePadding","",
		"chordSymbolAFrameWidth","",
		"chordSymbolAFrameRound","",
		"chordSymbolAFrameFgColor","",
		"chordSymbolAFrameBgColor","",
		
		"chordSymbolBFontFace","",
		"chordSymbolBFontSize","",
		"chordSymbolBLineSpacing","",
		"chordSymbolBFontSpatiumDependent","",
		"chordSymbolBFontStyle","",
		"chordSymbolBColor","",
		"chordSymbolBAlign","",
		"chordSymbolBFrameType","",
		"chordSymbolBFramePadding","",
		"chordSymbolBFrameWidth","",
		"chordSymbolBFrameRound","",
		"chordSymbolBFrameFgColor","",
		"chordSymbolBFrameBgColor","",
		
		"romanNumeralFontFace","",
		"romanNumeralFontSize","",
		"romanNumeralLineSpacing","",
		"romanNumeralFontSpatiumDependent","",
		"romanNumeralFontStyle","",
		"romanNumeralColor","",
		"romanNumeralAlign","",
		"romanNumeralFrameType","",
		"romanNumeralFramePadding","",
		"romanNumeralFrameWidth","",
		"romanNumeralFrameRound","",
		"romanNumeralFrameFgColor","",
		"romanNumeralFrameBgColor","",
		
		"nashvilleNumberFontFace","",
		"nashvilleNumberFontSize","",
		"nashvilleNumberLineSpacing","",
		"nashvilleNumberFontSpatiumDependent","",
		"nashvilleNumberFontStyle","",
		"nashvilleNumberColor","",
		"nashvilleNumberAlign","",
		"nashvilleNumberFrameType","",
		"nashvilleNumberFramePadding","",
		"nashvilleNumberFrameWidth","",
		"nashvilleNumberFrameRound","",
		"nashvilleNumberFrameFgColor","",
		"nashvilleNumberFrameBgColor","",
		
		"capoPosition","",
		"fretNumMag","",
		"fretNumPos","",
		"fretY","",
		"fretMinDistance","",
		"fretMag","",
		"fretPlacement","",
		"fretStrings","",
		"fretFrets","",
		"fretNut","",
		"fretDotSize","",
		"fretDotSpatiumSize","",
		"fretStringSpacing","",
		"fretFretSpacing","",
		"fretOrientation","",
		"maxFretShiftAbove","",
		"maxFretShiftBelow","",
		"fretNutThickness","",
		"fretUseCustomSuffix","",
		"fretCustomSuffix","",
		"barreAppearanceSlur","",
		"barreLineWidth","",
		"fretShowFingerings","",
		"fretStyleExtended","",
		
		"showPageNumber","",
		"showPageNumberOne","",
		"pageNumberOddEven","",
		"showMeasureNumber","",
		"showMeasureNumberOne", 0, // Bar numbers → Show first
		"measureNumberInterval","",
		"measureNumberSystem","",
		"measureNumberAllStaves","",
		
		"smallNoteMag","",
		"scaleRythmicSpacingForSmallNotes","",
		"graceNoteMag","",
		"graceToMainNoteDist","",
		"graceToGraceNoteDist","",
		"smallStaffMag","",
		"smallClefMag","",
		"genClef","",
		"hideTabClefAfterFirst","",
		"genKeysig","",
		"genCourtesyTimesig","",
		"genCourtesyKeysig","",
		"genCourtesyClef","",
		
		"keySigCourtesyBarlineMode","",
		"timeSigCourtesyBarlineMode","",
		
		"barlineBeforeSigChange","",
		"doubleBarlineBeforeKeySig","",
		"doubleBarlineBeforeTimeSig","",
		
		"swingRatio","",
		"swingUnit","",
		
		"useStandardNoteNames","",
		"useGermanNoteNames","",
		"useFullGermanNoteNames","",
		"useSolfeggioNoteNames","",
		"useFrenchNoteNames","",
		"automaticCapitalization","",
		"lowerCaseMinorChords","",
		"lowerCaseBassNotes","",
		"allCapsNoteNames","",
		"chordStyle","",
		"chordsXmlFile","",
		"chordDescriptionFile","",
		"chordExtensionMag","",
		"chordExtensionAdjust","",
		"chordModifierMag","",
		"chordModifierAdjust","",
		"concertPitch","",
		"multiVoiceRestTwoSpaceOffset","",
		"mergeMatchingRests","",
		"createMultiMeasureRests","",
		"minEmptyMeasures","",
		"singleMeasureMMRestUseNormalRest","",
		"singleMeasureMMRestShowNumber","",
		"minMMRestWidth","",
		"mmRestConstantWidth","",
		"mmRestReferenceWidth","",
		"mmRestMaxWidthIncrease","",
		"mmRestNumberPos","",
		"mmRestBetweenStaves","",
		"mmRestNumberMaskHBar","",
		"multiMeasureRestMargin","",
		"mmRestHBarThickness","",
		"mmRestHBarVStrokeThickness","",
		"mmRestHBarVStrokeHeight","",
		"oldStyleMultiMeasureRests","",
		"mmRestOldStyleMaxMeasures","",
		"mmRestOldStyleSpacing","",
		"hideEmptyStaves","",
		"dontHideStavesInFirstSystem","",
		"enableIndentationOnFirstSystem","",
		"firstSystemIndentationValue","",
		"alwaysShowBracketsWhenEmptyStavesAreHidden","",
		"alwaysShowSquareBracketsWhenEmptyStavesAreHidden","",
		"hideInstrumentNameIfOneInstrument","",
		"firstSystemInstNameVisibility","",
		"subsSystemInstNameVisibility","",
		"gateTime","",
		"tenutoGateTime","",
		"staccatoGateTime","",
		"slurGateTime","",
		
		"arpeggioNoteDistance","",
		"arpeggioAccidentalDistance","",
		"arpeggioAccidentalDistanceMin","",
		"arpeggioLineWidth","",
		"arpeggioHookLen","",
		"arpeggioHiddenInStdIfTab","",
		
		"slurEndWidth", 0.06, // Slurs & Ties → Slurs → Line thickness at end
		"slurMidWidth", 0.16, // Slurs & Ties → Slurs → Line thickness middle
		"slurDottedWidth", 0.1, // Slurs & Ties → Slurs → Dotted line thickness
		"tieEndWidth", 0.06, // Slurs & Ties → Ties → Line thickness at end
		"tieMidWidth", 0.16, // Slurs & Ties → Ties → Line thickness middle
		"tieDottedWidth", 0.1, // Slurs & Ties → Ties → Dotted line thickness
		"minTieLength","",
		"minHangingTieLength","",
		"minStraightGlissandoLength","",
		"minWigglyGlissandoLength","",
		"slurMinDistance","",
		"tieMinDistance","",
		"laissezVibMinDistance","",
		"headerToLineStartDistance", "",   // determines start point of "dangling" lines (ties, gliss","",
		"lineEndToBarlineDistance", "", // determines end point of "dangling" lines (ties, gliss","",
		
		"tiePlacementSingleNote","",
		"tiePlacementChord","",
		"tieDotsPlacement","",
		"tieMinShoulderHeight","",
		"tieMaxShoulderHeight","",
		
		"minLaissezVibLength","",
		"laissezVibUseSmuflSym","",
		
		"sectionPause","",
		"musicalSymbolFont","",
		"musicalTextFont","",
		
		"showHeader","",
		"headerFirstPage","",
		"headerOddEven","",
		"evenHeaderL","",
		"evenHeaderC","",
		"evenHeaderR","",
		"oddHeaderL","",
		"oddHeaderC","",
		"oddHeaderR","",
		
		"showFooter","",
		"footerFirstPage","",
		"footerOddEven","",
		"evenFooterL","",
		"evenFooterC","",
		"evenFooterR","",
		"oddFooterL","",
		"oddFooterC","",
		"oddFooterR","",
		
		"voltaPosAbove","",
		"voltaHook","",
		"voltaLineWidth","",
		"voltaLineStyle","",
		"voltaDashLineLen","",
		"voltaDashGapLen","",
		"voltaFontFace","",
		"voltaFontSize","",
		"voltaLineSpacing","",
		"voltaFontSpatiumDependent","",
		"voltaFontStyle","",
		"voltaColor","",
		"voltaAlign","",
		"voltaOffset","",
		"voltaFrameType","",
		"voltaFramePadding","",
		"voltaFrameWidth","",
		"voltaFrameRound","",
		"voltaFrameFgColor","",
		"voltaFrameBgColor","",
		
		"ottava8VAPlacement","",
		"ottava8VBPlacement","",
		"ottava15MAPlacement","",
		"ottava15MBPlacement","",
		"ottava22MAPlacement","",
		"ottava22MBPlacement","",
		
		"ottava8VAText","",
		"ottava8VAContinueText","",
		"ottava8VBText","",
		"ottava8VBContinueText","",
		"ottava15MAText","",
		"ottava15MAContinueText","",
		"ottava15MBText","",
		"ottava15MBContinueText","",
		"ottava22MAText","",
		"ottava22MAContinueText","",
		"ottava22MBText","",
		"ottava22MBContinueText","",
		
		"ottava8VAnoText","",
		"ottava8VAnoContinueText","",
		"ottava8VBnoText","",
		"ottava8VBnoContinueText","",
		"ottava15MAnoText","",
		"ottava15MAnoContinueText","",
		"ottava15MBnoText","",
		"ottava15MBnoContinueText","",
		"ottava22MAnoText","",
		"ottava22MAnoContinueText","",
		"ottava22MBnoText","",
		"ottava22MBnoContinueText","",
		
		"ottavaPosAbove","",
		"ottavaPosBelow","",
		"ottavaHookAbove","",
		"ottavaHookBelow","",
		"ottavaLineWidth","",
		"ottavaLineStyle","",
		"ottavaDashLineLen","",
		"ottavaDashGapLen","",
		"ottavaNumbersOnly","",
		"ottavaFontFace","",
		"ottavaFontSize","",
		"ottavaLineSpacing","",
		"ottavaFontSpatiumDependent","",
		"ottavaMusicalSymbolsScale","",
		"ottavaFontStyle","",
		"ottavaColor","",
		"ottavaTextAlignAbove","",
		"ottavaTextAlignBelow","",
		"ottavaFrameType","",
		"ottavaFramePadding","",
		"ottavaFrameWidth","",
		"ottavaFrameRound","",
		"ottavaFrameFgColor","",
		"ottavaFrameBgColor","",
		
		"tabClef","",
		
		"tremoloWidth","",
		"tremoloBoxHeight","",
		"tremoloLineWidth","",
		"tremoloDistance","",
		"tremoloStyle","",
		"tremoloStrokeLengthMultiplier","",
		"tremoloNoteSidePadding","",
		"tremoloOutSidePadding","",
		"// TODO tremoloMaxBeamLength","",
		
		"linearStretch","",
		"crossMeasureValues", 0, // Score → display note values across bar boundaries
		"keySigNaturals","",
		
		"tupletMaxSlope","",
		"tupletOutOfStaff","",
		"tupletVHeadDistance","",
		"tupletVStemDistance","",
		"tupletStemLeftDistance","",
		"tupletStemRightDistance","",
		"tupletNoteLeftDistance","",
		"tupletNoteRightDistance","",
		"tupletBracketWidth","",
		"tupletDirection","",
		"tupletNumberType","",
		"tupletBracketType","",
		"tupletFontFace","",
		"tupletFontSize","",
		"tupletLineSpacing","",
		"tupletFontSpatiumDependent","",
		"tupletMusicalSymbolsScale","",
		"tupletFontStyle","",
		"tupletColor","",
		"tupletAlign","",
		"tupletUseSymbols","",
		"tupletBracketHookHeight","",
		"tupletOffset","",
		"tupletFrameType","",
		"tupletFramePadding","",
		"tupletFrameWidth","",
		"tupletFrameRound","",
		"tupletFrameFgColor","",
		"tupletFrameBgColor","",
		
		"scaleBarlines","",
		"barGraceDistance","",
		
		"minVerticalDistance","",
		"skylineMinHorizontalClearance","",
		"ornamentStyle","",
		"spatium","",
		
		"autoplaceHairpinDynamicsDistance","",
		
		"dynamicsHairpinVoiceBasedPlacement","",
		"dynamicsHairpinsAutoCenterOnGrandStaff","",
		"dynamicsHairpinsAboveForVocalStaves","",
		
		"dynamicsOverrideFont","",
		"dynamicsFont","",
		"dynamicsSize","",
		"dynamicsPlacement","",
		"dynamicsPosAbove","",
		"dynamicsPosBelow","",
		"avoidBarLines","",
		"snapToDynamics","",
		"centerOnNotehead","",
		"dynamicsMinDistance","",
		"autoplaceVerticalAlignRange","",
		
		"textLinePlacement","",
		"textLinePosAbove","",
		"textLinePosBelow","",
		"textLineLineWidth","",
		"textLineLineStyle","",
		"textLineDashLineLen","",
		"textLineDashGapLen","",
		"textLineHookHeight","",
		"textLineFrameType","",
		"textLineFramePadding","",
		"textLineFrameWidth","",
		"textLineFrameRound","",
		"textLineFrameFgColor","",
		"textLineFrameBgColor","",
		
		"systemTextLinePlacement","",
		"systemTextLinePosAbove","",
		"systemTextLinePosBelow","",
		"systemTextLineLineWidth","",
		"systemTextLineLineStyle","",
		"systemTextLineDashLineLen","",
		"systemTextLineDashGapLen","",
		"systemTextLineHookHeight","",
		"systemTextLineFrameType","",
		"systemTextLineFramePadding","",
		"systemTextLineFrameWidth","",
		"systemTextLineFrameRound","",
		"systemTextLineFrameFgColor","",
		"systemTextLineFrameBgColor","",
		
		"tremoloBarLineWidth","",
		"jumpPosAbove","",
		"markerPosAbove","",
		
		"defaultFontFace","",
		"defaultFontSize","",
		"defaultLineSpacing","",
		"defaultFontSpatiumDependent","",
		"defaultFontStyle","",
		"defaultColor","",
		"defaultAlign","",
		"defaultFrameType","",
		"defaultFramePadding","",
		"defaultFrameWidth","",
		"defaultFrameRound","",
		"defaultFrameFgColor","",
		"defaultFrameBgColor","",
		"defaultOffset","",
		"defaultOffsetType","",
		"defaultSystemFlag","",
		"defaultText","",
		
		"titleFontFace","",
		"titleFontSize","",
		"titleLineSpacing","",
		"titleFontSpatiumDependent","",
		"titleFontStyle","",
		"titleColor","",
		"titleAlign","",
		"titleOffset","",
		"titleOffsetType","",
		"titleFrameType","",
		"titleFramePadding","",
		"titleFrameWidth","",
		"titleFrameRound","",
		"titleFrameFgColor","",
		"titleFrameBgColor","",
		
		"subTitleFontFace","",
		"subTitleFontSize","",
		"subTitleLineSpacing","",
		"subTitleFontSpatiumDependent","",
		"subTitleFontStyle","",
		"subTitleColor","",
		"subTitleAlign","",
		"subTitleOffset","",
		"subTitleOffsetType","",
		"subTitleFrameType","",
		"subTitleFramePadding","",
		"subTitleFrameWidth","",
		"subTitleFrameRound","",
		"subTitleFrameFgColor","",
		"subTitleFrameBgColor","",
		
		"composerFontFace","",
		"composerFontSize","",
		"composerLineSpacing","",
		"composerFontSpatiumDependent","",
		"composerFontStyle","",
		"composerColor","",
		"composerAlign","",
		"composerOffset","",
		"composerOffsetType","",
		"composerFrameType","",
		"composerFramePadding","",
		"composerFrameWidth","",
		"composerFrameRound","",
		"composerFrameFgColor","",
		"composerFrameBgColor","",
		
		"lyricistFontFace","",
		"lyricistFontSize","",
		"lyricistLineSpacing","",
		"lyricistFontSpatiumDependent","",
		"lyricistFontStyle","",
		"lyricistColor","",
		"lyricistAlign","",
		"lyricistOffset","",
		"lyricistOffsetType","",
		"lyricistFrameType","",
		"lyricistFramePadding","",
		"lyricistFrameWidth","",
		"lyricistFrameRound","",
		"lyricistFrameFgColor","",
		"lyricistFrameBgColor","",
		
		"fingeringFontFace","",
		"fingeringFontSize","",
		"fingeringLineSpacing","",
		"fingeringFontSpatiumDependent","",
		"fingeringFontStyle","",
		"fingeringColor","",
		"fingeringAlign","",
		"fingeringFrameType","",
		"fingeringFramePadding","",
		"fingeringFrameWidth","",
		"fingeringFrameRound","",
		"fingeringFrameFgColor","",
		"fingeringFrameBgColor","",
		"fingeringOffset","",
		
		"lhGuitarFingeringFontFace","",
		"lhGuitarFingeringFontSize","",
		"lhGuitarFingeringLineSpacing","",
		"lhGuitarFingeringFontSpatiumDependent","",
		"lhGuitarFingeringFontStyle","",
		"lhGuitarFingeringColor","",
		"lhGuitarFingeringAlign","",
		"lhGuitarFingeringFrameType","",
		"lhGuitarFingeringFramePadding","",
		"lhGuitarFingeringFrameWidth","",
		"lhGuitarFingeringFrameRound","",
		"lhGuitarFingeringFrameFgColor","",
		"lhGuitarFingeringFrameBgColor","",
		"lhGuitarFingeringOffset","",
		
		"rhGuitarFingeringFontFace","",
		"rhGuitarFingeringFontSize","",
		"rhGuitarFingeringLineSpacing","",
		"rhGuitarFingeringFontSpatiumDependent","",
		"rhGuitarFingeringFontStyle","",
		"rhGuitarFingeringColor","",
		"rhGuitarFingeringAlign","",
		"rhGuitarFingeringFrameType","",
		"rhGuitarFingeringFramePadding","",
		"rhGuitarFingeringFrameWidth","",
		"rhGuitarFingeringFrameRound","",
		"rhGuitarFingeringFrameFgColor","",
		"rhGuitarFingeringFrameBgColor","",
		"rhGuitarFingeringOffset","",
		
		"hammerOnPullOffTappingFontFace","",
		"hammerOnPullOffTappingFontSize","",
		"hammerOnPullOffTappingLineSpacing","",
		"hammerOnPullOffTappingFontSpatiumDependent","",
		"hammerOnPullOffTappingFontStyle","",
		"hammerOnPullOffTappingColor","",
		"hammerOnPullOffTappingAlign","",
		"hammerOnPullOffTappingFrameType","",
		"hammerOnPullOffTappingFramePadding","",
		"hammerOnPullOffTappingFrameWidth","",
		"hammerOnPullOffTappingFrameRound","",
		"hammerOnPullOffTappingFrameFgColor","",
		"hammerOnPullOffTappingFrameBgColor","",
		"hammerOnPullOffTappingOffset","",
		
		"hopoShowOnStandardStaves","",
		"hopoShowOnTabStaves","",
		"hopoUpperCase","",
		"hopoShowAll","",
		
		"stringNumberFontFace","",
		"stringNumberFontSize","",
		"stringNumberLineSpacing","",
		"stringNumberFontSpatiumDependent","",
		"stringNumberFontStyle","",
		"stringNumberColor","",
		"stringNumberAlign","",
		"stringNumberFrameType","",
		"stringNumberFramePadding","",
		"stringNumberFrameWidth","",
		"stringNumberFrameRound","",
		"stringNumberFrameFgColor","",
		"stringNumberFrameBgColor","",
		"stringNumberOffset","",
		"preferSameStringForTranspose","",
		
		"stringTuningsFontSize","",
		
		"harpPedalDiagramFontFace","",
		"harpPedalDiagramFontSize","",
		"harpPedalDiagramLineSpacing","",
		"harpPedalDiagramFontSpatiumDependent","",
		"harpPedalDiagramMusicalSymbolsScale","",
		"harpPedalDiagramFontStyle","",
		"harpPedalDiagramColor","",
		"harpPedalDiagramAlign","",
		"harpPedalDiagramFrameType","",
		"harpPedalDiagramFramePadding","",
		"harpPedalDiagramFrameWidth","",
		"harpPedalDiagramFrameRound","",
		"harpPedalDiagramFrameFgColor","",
		"harpPedalDiagramFrameBgColor","",
		"harpPedalDiagramOffset","",
		"harpPedalDiagramPlacement","",
		"harpPedalDiagramPosAbove","",
		"harpPedalDiagramPosBelow","",
		"harpPedalDiagramMinDistance","",
		
		"harpPedalTextDiagramFontFace","",
		"harpPedalTextDiagramFontSize","",
		"harpPedalTextDiagramLineSpacing","",
		"harpPedalTextDiagramFontSpatiumDependent","",
		"harpPedalTextDiagramFontStyle","",
		"harpPedalTextDiagramColor","",
		"harpPedalTextDiagramAlign","",
		"harpPedalTextDiagramFrameType","",
		"harpPedalTextDiagramFramePadding","",
		"harpPedalTextDiagramFrameWidth","",
		"harpPedalTextDiagramFrameRound","",
		"harpPedalTextDiagramFrameFgColor","",
		"harpPedalTextDiagramFrameBgColor","",
		"harpPedalTextDiagramOffset","",
		"harpPedalTextDiagramPlacement","",
		"harpPedalTextDiagramPosAbove","",
		"harpPedalTextDiagramPosBelow","",
		"harpPedalTextDiagramMinDistance","",
		
		"longInstrumentFontFace","",
		"longInstrumentFontSize","",
		"longInstrumentLineSpacing","",
		"longInstrumentFontSpatiumDependent","",
		"longInstrumentFontStyle","",
		"longInstrumentColor","",
		"longInstrumentAlign","",
		"longInstrumentOffset","",
		"longInstrumentFrameType","",
		"longInstrumentFramePadding","",
		"longInstrumentFrameWidth","",
		"longInstrumentFrameRound","",
		"longInstrumentFrameFgColor","",
		"longInstrumentFrameBgColor","",
		
		"shortInstrumentFontFace","",
		"shortInstrumentFontSize","",
		"shortInstrumentLineSpacing","",
		"shortInstrumentFontSpatiumDependent","",
		"shortInstrumentFontStyle","",
		"shortInstrumentColor","",
		"shortInstrumentAlign","",
		"shortInstrumentOffset","",
		"shortInstrumentFrameType","",
		"shortInstrumentFramePadding","",
		"shortInstrumentFrameWidth","",
		"shortInstrumentFrameRound","",
		"shortInstrumentFrameFgColor","",
		"shortInstrumentFrameBgColor","",
		
		"partInstrumentFontFace","",
		"partInstrumentFontSize","",
		"partInstrumentLineSpacing","",
		"partInstrumentFontSpatiumDependent","",
		"partInstrumentFontStyle","",
		"partInstrumentColor","",
		"partInstrumentAlign","",
		"partInstrumentOffset","",
		"partInstrumentFrameType","",
		"partInstrumentFramePadding","",
		"partInstrumentFrameWidth","",
		"partInstrumentFrameRound","",
		"partInstrumentFrameFgColor","",
		"partInstrumentFrameBgColor","",
		
		"dynamicsFontFace","",
		"dynamicsFontSize","",
		"dynamicsLineSpacing","",
		"dynamicsFontSpatiumDependent","",
		"dynamicsFontStyle","",
		"dynamicsColor","",
		"dynamicsAlign","",
		"dynamicsFrameType","",
		"dynamicsFramePadding","",
		"dynamicsFrameWidth","",
		"dynamicsFrameRound","",
		"dynamicsFrameFgColor","",
		"dynamicsFrameBgColor","",
		
		"expressionFontFace","",
		"expressionFontSize","",
		"expressionLineSpacing","",
		"expressionFontSpatiumDependent","",
		"expressionFontStyle","",
		"expressionColor","",
		"expressionAlign","",
		"expressionPlacement","",
		"expressionOffset","",
		"expressionPosAbove","",
		"expressionPosBelow","",
		"expressionFrameType","",
		"expressionFramePadding","",
		"expressionFrameWidth","",
		"expressionFrameRound","",
		"expressionFrameFgColor","",
		"expressionFrameBgColor","",
		"expressionMinDistance","",
		
		"tempoFontFace","",
		"tempoFontSize","",
		"tempoLineSpacing","",
		"tempoFontSpatiumDependent","",
		"tempoFontStyle",1,
		"tempoColor","",
		"tempoAlign","",
		"tempoSystemFlag","",
		"tempoPlacement","",
		"tempoPosAbove","",
		"tempoPosBelow","",
		"tempoMinDistance","",
		"tempoFrameType","",
		"tempoFramePadding","",
		"tempoFrameWidth","",
		"tempoFrameRound","",
		"tempoFrameFgColor","",
		"tempoFrameBgColor","",
		
		"tempoChangeFontFace","",
		"tempoChangeFontSize","",
		"tempoChangeLineSpacing","",
		"tempoChangeFontSpatiumDependent","",
		"tempoChangeFontStyle",1,
		"tempoChangeColor","",
		"tempoChangeAlign","",
		"tempoChangeSystemFlag","",
		"tempoChangePlacement","",
		"tempoChangePosAbove","",
		"tempoChangePosBelow","",
		"tempoChangeMinDistance","",
		"tempoChangeFrameType","",
		"tempoChangeFramePadding","",
		"tempoChangeFrameWidth","",
		"tempoChangeFrameRound","",
		"tempoChangeFrameFgColor","",
		"tempoChangeFrameBgColor","",
		"tempoChangeLineWidth","",
		"tempoChangeLineStyle","",
		"tempoChangeDashLineLen","",
		"tempoChangeDashGapLen","",
		
		"metronomeFontFace","",
		"metronomeFontSize","",
		"metronomeLineSpacing","",
		"metronomeFontSpatiumDependent","",
		"metronomeFontStyle",0,
		"metronomeColor","",
		"metronomePlacement","",
		"metronomeAlign","",
		"metronomeOffset","",
		"metronomeFrameType","",
		"metronomeFramePadding","",
		"metronomeFrameWidth","",
		"metronomeFrameRound","",
		"metronomeFrameFgColor","",
		"metronomeFrameBgColor","",
		
		"measureNumberFontFace","",
		"measureNumberFontSize","",
		"measureNumberLineSpacing","",
		"measureNumberFontSpatiumDependent","",
		"measureNumberFontStyle","",
		"measureNumberColor","",
		"measureNumberPosAbove","",
		"measureNumberPosBelow","",
		"measureNumberOffsetType","",
		"measureNumberVPlacement","",
		"measureNumberHPlacement","",
		"measureNumberMinDistance","",
		"measureNumberAlign","",
		"measureNumberFrameType","",
		"measureNumberFramePadding","",
		"measureNumberFrameWidth","",
		"measureNumberFrameRound","",
		"measureNumberFrameFgColor","",
		"measureNumberFrameBgColor","",
		
		"mmRestShowMeasureNumberRange","",
		"mmRestRangeBracketType","",
		
		"mmRestRangeFontFace","",
		"mmRestRangeFontSize","",
		"mmRestRangeFontSpatiumDependent","",
		"mmRestRangeFontStyle","",
		"mmRestRangeColor","",
		"mmRestRangePosAbove","",
		"mmRestRangePosBelow","",
		"mmRestRangeOffsetType","",
		"mmRestRangeVPlacement","",
		"mmRestRangeHPlacement","",
		"mmRestRangeAlign","",
		"mmRestRangeFrameType","",
		"mmRestRangeFramePadding","",
		"mmRestRangeFrameWidth","",
		"mmRestRangeFrameRound","",
		"mmRestRangeFrameFgColor","",
		"mmRestRangeFrameBgColor","",
		"mmRestRangeMinDistance","",
		
		"translatorFontFace","",
		"translatorFontSize","",
		"translatorLineSpacing","",
		"translatorFontSpatiumDependent","",
		"translatorFontStyle","",
		"translatorColor","",
		"translatorAlign","",
		"translatorOffset","",
		"translatorFrameType","",
		"translatorFramePadding","",
		"translatorFrameWidth","",
		"translatorFrameRound","",
		"translatorFrameFgColor","",
		"translatorFrameBgColor","",
		
		"systemTextFontFace","",
		"systemTextFontSize","",
		"systemTextLineSpacing","",
		"systemTextFontSpatiumDependent","",
		"systemTextFontStyle","",
		"systemTextColor","",
		"systemTextAlign","",
		"systemTextOffsetType","",
		"systemTextPlacement","",
		"systemTextPosAbove","",
		"systemTextPosBelow","",
		"systemTextMinDistance","",
		"systemTextFrameType","",
		"systemTextFramePadding","",
		"systemTextFrameWidth","",
		"systemTextFrameRound","",
		"systemTextFrameFgColor","",
		"systemTextFrameBgColor","",
		
		"staffTextFontFace","",
		"staffTextFontSize","",
		"staffTextLineSpacing","",
		"staffTextFontSpatiumDependent","",
		"staffTextFontStyle","",
		"staffTextColor","",
		"staffTextAlign","",
		"staffTextOffsetType","",
		"staffTextPlacement","",
		"staffTextPosAbove","",
		"staffTextPosBelow","",
		"staffTextMinDistance","",
		"staffTextFrameType","",
		"staffTextFramePadding","",
		"staffTextFrameWidth","",
		"staffTextFrameRound","",
		"staffTextFrameFgColor","",
		"staffTextFrameBgColor","",
		
		"fretDiagramFingeringFontFace","",
		"fretDiagramFingeringFontSize","",
		"fretDiagramFingeringLineSpacing","",
		"fretDiagramFingeringFontSpatiumDependent","",
		"fretDiagramFingeringFontStyle","",
		"fretDiagramFingeringColor","",
		"fretDiagramFingeringAlign","",
		"fretDiagramFingeringPosAbove","",
		"fretDiagramFingeringFrameType","",
		"fretDiagramFingeringFramePadding","",
		"fretDiagramFingeringFrameWidth","",
		"fretDiagramFingeringFrameRound","",
		"fretDiagramFingeringFrameFgColor","",
		"fretDiagramFingeringFrameBgColor","",
		
		"fretDiagramFretNumberFontFace","",
		"fretDiagramFretNumberFontSize","",
		"fretDiagramFretNumberLineSpacing","",
		"fretDiagramFretNumberFontSpatiumDependent","",
		"fretDiagramFretNumberFontStyle","",
		"fretDiagramFretNumberColor","",
		"fretDiagramFretNumberAlign","",
		"fretDiagramFretNumberPosAbove","",
		"fretDiagramFretNumberFrameType","",
		"fretDiagramFretNumberFramePadding","",
		"fretDiagramFretNumberFrameWidth","",
		"fretDiagramFretNumberFrameRound","",
		"fretDiagramFretNumberFrameFgColor","",
		"fretDiagramFretNumberFrameBgColor","",
		
		"rehearsalMarkFontFace","", // this is done elsewhere
		"rehearsalMarkFontSize", "", // this is done elsewhere
		"rehearsalMarkLineSpacing","",
		"rehearsalMarkFontSpatiumDependent","",
		"rehearsalMarkFontStyle","",
		"rehearsalMarkColor","",
		"rehearsalMarkAlign","",
		"rehearsalMarkFrameType","",
		"rehearsalMarkFramePadding","",
		"rehearsalMarkFrameWidth","",
		"rehearsalMarkFrameRound","",
		"rehearsalMarkFrameFgColor","",
		"rehearsalMarkFrameBgColor","",
		"rehearsalMarkPlacement","",
		"rehearsalMarkPosAbove","",
		"rehearsalMarkPosBelow","",
		"rehearsalMarkMinDistance","",
		
		"repeatLeftFontFace","",
		"repeatLeftFontSize","",
		"repeatLeftLineSpacing","",
		"repeatLeftFontSpatiumDependent","",
		"repeatLeftFontStyle","",
		"repeatLeftColor","",
		"repeatLeftAlign","",
		"repeatLeftPlacement","",
		"repeatLeftFrameType","",
		"repeatLeftFramePadding","",
		"repeatLeftFrameWidth","",
		"repeatLeftFrameRound","",
		"repeatLeftFrameFgColor","",
		"repeatLeftFrameBgColor","",
		
		"repeatRightFontFace","",
		"repeatRightFontSize","",
		"repeatRightLineSpacing","",
		"repeatRightFontSpatiumDependent","",
		"repeatRightFontStyle","",
		"repeatRightColor","",
		"repeatRightAlign","",
		"repeatRightPlacement","",
		"repeatRightFrameType","",
		"repeatRightFramePadding","",
		"repeatRightFrameWidth","",
		"repeatRightFrameRound","",
		"repeatRightFrameFgColor","",
		"repeatRightFrameBgColor","",
		
		"frameFontFace","",
		"frameFontSize","",
		"frameLineSpacing","",
		"frameFontSpatiumDependent","",
		"frameFontStyle","",
		"frameColor","",
		"frameAlign","",
		"frameOffset","",
		"frameFrameType","",
		"frameFramePadding","",
		"frameFrameWidth","",
		"frameFrameRound","",
		"frameFrameFgColor","",
		"frameFrameBgColor","",
		
		"textLineFontFace","",
		"textLineFontSize","",
		"textLineLineSpacing","",
		"textLineFontSpatiumDependent","",
		"textLineFontStyle","",
		"textLineColor","",
		"textLineTextAlign","",
		"textLineSystemFlag","",
		
		"systemTextLineFontFace","",
		"systemTextLineFontSize","",
		"systemTextLineFontSpatiumDependent","",
		"systemTextLineFontStyle","",
		"systemTextLineColor","",
		"systemTextLineTextAlign","",
		"systemTextLineSystemFlag","",
		
		"noteLinePlacement","",
		"noteLineFontFace","",
		"noteLineFontSize","",
		"noteLineLineSpacing","",
		"noteLineFontSpatiumDependent","",
		"noteLineFontStyle","",
		"noteLineColor","",
		"noteLineAlign","",
		"noteLineOffset","",
		"noteLineFrameType","",
		"noteLineFramePadding","",
		"noteLineFrameWidth","",
		"noteLineFrameRound","",
		"noteLineFrameFgColor","",
		"noteLineFrameBgColor","",
		
		"noteLineWidth","",
		"noteLineStyle","",
		"noteLineDashLineLen","",
		"noteLineDashGapLen","",
		
		"glissandoFontFace","",
		"glissandoFontSize","",
		"glissandoLineSpacing","",
		"glissandoFontSpatiumDependent","",
		"glissandoFontStyle","",
		"glissandoColor","",
		"glissandoAlign","",
		"glissandoOffset","",
		"glissandoFrameType","",
		"glissandoFramePadding","",
		"glissandoFrameWidth","",
		"glissandoFrameRound","",
		"glissandoFrameFgColor","",
		"glissandoFrameBgColor","",
		"glissandoLineWidth","",
		"glissandoText","",
		"glissandoStyle","",
		"glissandoStyleHarp","",
		
		"glissandoType","",
		"glissandoLineStyle","",
		"glissandoDashLineLen","",
		"glissandoDashGapLen","",
		"glissandoShowText","",
		
		"bendFontFace","",
		"bendFontSize","",
		"bendLineSpacing","",
		"bendFontSpatiumDependent","",
		"bendFontStyle","",
		"bendColor","",
		"bendAlign","",
		"bendOffset","",
		"bendFrameType","",
		"bendFramePadding","",
		"bendFrameWidth","",
		"bendFrameRound","",
		"bendFrameFgColor","",
		"bendFrameBgColor","",
		"bendLineWidth","",
		"bendArrowWidth","",
		
		"guitarBendLineWidth","",
		"guitarBendLineWidthTab","",
		"guitarBendHeightAboveTABStaff","",
		"guitarBendPartialBendHeight","",
		"guitarBendUseFull","",
		"guitarBendArrowWidth","",
		"guitarBendArrowHeight","",
		"useCueSizeFretForGraceBends","",
		
		"headerFontFace","",
		"headerFontSize","",
		"headerLineSpacing","",
		"headerFontSpatiumDependent","",
		"headerFontStyle","",
		"headerColor","",
		"headerAlign","",
		"headerOffset","",
		"headerFrameType","",
		"headerFramePadding","",
		"headerFrameWidth","",
		"headerFrameRound","",
		"headerFrameFgColor","",
		"headerFrameBgColor","",
		
		"footerFontFace","",
		"footerFontSize","",
		"footerLineSpacing","",
		"footerFontSpatiumDependent","",
		"footerFontStyle","",
		"footerColor","",
		"footerAlign","",
		"footerOffset","",
		"footerFrameType","",
		"footerFramePadding","",
		"footerFrameWidth","",
		"footerFrameRound","",
		"footerFrameFgColor","",
		"footerFrameBgColor","",
		
		"copyrightFontFace","",
		"copyrightFontSize","",
		"copyrightLineSpacing","",
		"copyrightFontSpatiumDependent","",
		"copyrightFontStyle","",
		"copyrightColor","",
		"copyrightAlign","",
		"copyrightOffset","",
		"copyrightFrameType","",
		"copyrightFramePadding","",
		"copyrightFrameWidth","",
		"copyrightFrameRound","",
		"copyrightFrameFgColor","",
		"copyrightFrameBgColor","",
		
		"pageNumberFontFace","",
		"pageNumberFontSize","",
		"pageNumberLineSpacing","",
		"pageNumberFontSpatiumDependent","",
		"pageNumberFontStyle","",
		"pageNumberColor","",
		"pageNumberAlign","",
		"pageNumberOffset","",
		"pageNumberFrameType","",
		"pageNumberFramePadding","",
		"pageNumberFrameWidth","",
		"pageNumberFrameRound","",
		"pageNumberFrameFgColor","",
		"pageNumberFrameBgColor","",
		
		"instrumentChangeFontFace","",
		"instrumentChangeFontSize","",
		"instrumentChangeLineSpacing","",
		"instrumentChangeFontSpatiumDependent","",
		"instrumentChangeFontStyle",0, // Text Styles → Instrument Change → Style
		"instrumentChangeColor","",
		"instrumentChangeAlign","",
		"instrumentChangeOffset","",
		"instrumentChangePlacement","",
		"instrumentChangePosAbove","",
		"instrumentChangePosBelow","",
		"instrumentChangeMinDistance","",
		"instrumentChangeFrameType",1, // Text Styles → Instrument Change → Frame (Rectangle)
		"instrumentChangeFramePadding", 0.4, // Text Styles → Instrument Change → Frame
		"instrumentChangeFrameWidth","",
		"instrumentChangeFrameRound","",
		"instrumentChangeFrameFgColor","",
		"instrumentChangeFrameBgColor","",
		
		"stickingFontFace","",
		"stickingFontSize","",
		"stickingLineSpacing","",
		"stickingFontSpatiumDependent","",
		"stickingFontStyle","",
		"stickingColor","",
		"stickingAlign","",
		"stickingOffset","",
		"stickingPlacement","",
		"stickingPosAbove","",
		"stickingPosBelow","",
		"stickingMinDistance","",
		"stickingFrameType","",
		"stickingFramePadding","",
		"stickingFrameWidth","",
		"stickingFrameRound","",
		"stickingFrameFgColor","",
		"stickingFrameBgColor","",
		
		"figuredBassFontFace","",
		"figuredBassFontSize","",
		"figuredBassLineSpacing","",
		"figuredBassFontSpatiumDependent","",
		"figuredBassFontStyle","",
		"figuredBassColor","",
		
		"letRingFontFace","",
		"letRingFontSize","",
		"letRingLineSpacing","",
		"letRingFontSpatiumDependent","",
		"letRingFontStyle","",
		"letRingColor","",
		"letRingTextAlign","",
		"letRingHookHeight","",
		"letRingPlacement","",
		"letRingPosAbove","",
		"letRingPosBelow","",
		"letRingLineWidth","",
		"letRingLineStyle","",
		"letRingDashLineLen","",
		"letRingDashGapLen","",
		"letRingText","",
		"letRingFrameType","",
		"letRingFramePadding","",
		"letRingFrameWidth","",
		"letRingFrameRound","",
		"letRingFrameFgColor","",
		"letRingFrameBgColor","",
		"letRingEndHookType","",
		
		"palmMuteFontFace","",
		"palmMuteFontSize","",
		"palmMuteLineSpacing","",
		"palmMuteFontSpatiumDependent","",
		"palmMuteFontStyle","",
		"palmMuteColor","",
		"palmMuteTextAlign","",
		"palmMuteHookHeight","",
		"palmMutePlacement","",
		"palmMutePosAbove","",
		"palmMutePosBelow","",
		"palmMuteLineWidth","",
		"palmMuteLineStyle","",
		"palmMuteDashLineLen","",
		"palmMuteDashGapLen","",
		"palmMuteText","",
		"palmMuteFrameType","",
		"palmMuteFramePadding","",
		"palmMuteFrameWidth","",
		"palmMuteFrameRound","",
		"palmMuteFrameFgColor","",
		"palmMuteFrameBgColor","",
		"palmMuteEndHookType","",
		
		"fermataPosAbove","",
		"fermataPosBelow","",
		"fermataMinDistance","",
		
		"fingeringPlacement","",
		
		"articulationMinDistance","",
		"fingeringMinDistance","",
		"hairpinMinDistance","",
		"letRingMinDistance","",
		"ottavaMinDistance","",
		"palmMuteMinDistance","",
		"pedalMinDistance","",
		"repeatMinDistance","",
		"textLineMinDistance","",
		"systemTextLineMinDistance","",
		"trillMinDistance","",
		"vibratoMinDistance","",
		"voltaMinDistance","",
		"figuredBassMinDistance","",
		"tupletMinDistance","",
		
		/// Display options for tab elements (simple and common styles)
		
		"slurShowTabSimple","",
		"slurShowTabCommon","",
		"fermataShowTabSimple","",
		"fermataShowTabCommon","",
		"dynamicsShowTabSimple","",
		"dynamicsShowTabCommon","",
		"hairpinShowTabSimple","",
		"hairpinShowTabCommon","",
		"accentShowTabSimple","",
		"accentShowTabCommon","",
		"staccatoShowTabSimple","",
		"staccatoShowTabCommon","",
		"harmonicMarkShowTabSimple","",
		"harmonicMarkShowTabCommon","",
		"letRingShowTabSimple","",
		"letRingShowTabCommon","",
		"palmMuteShowTabSimple","",
		"palmMuteShowTabCommon","",
		"rasgueadoShowTabSimple","",
		"rasgueadoShowTabCommon","",
		"mordentShowTabSimple","",
		"mordentShowTabCommon","",
		"turnShowTabSimple","",
		"turnShowTabCommon","",
		"wahShowTabSimple","",
		"wahShowTabCommon","",
		"golpeShowTabSimple","",
		"golpeShowTabCommon","",
		
		"tabShowTiedFret","",
		"tabParenthesizeTiedFret","",
		"parenthesizeTiedFretIfArticulation","",
		
		"tabFretPadding","",
		
		"chordlineThickness","",
		
		"dummyMusicalSymbolsScale","",
		
		"autoplaceEnabled","",
		"defaultsVersion","",
		
		"changesBeforeBarlineRepeats","",
		"changesBeforeBarlineOtherJumps","",
		
		"placeClefsBeforeRepeats","",
		"changesBetweenEndStartRepeat","",
		
		"showCourtesiesRepeats","",
		"useParensRepeatCourtesies","",
		
		"showCourtesiesOtherJumps","",
		"useParensOtherJumpCourtesies","",
		
		"showCourtesiesAfterCancellingRepeats","",
		"useParensRepeatCourtesiesAfterCancelling","",
		
		"showCourtesiesAfterCancellingOtherJumps","",
		"useParensOtherJumpCourtesiesAfterCancelling","",
		
		"smallParens",""];
		
		// GO THROUGH ALL THE DEFAULT SETTINGS
		for (var i = 0; i < completeDefaultSettings.length; i += 2) {
			var settingName = completeDefaultSettings[i];
			var settingValue = completeDefaultSettings[i+1];
			if (settingName !== "" && settingValue !== "") setSetting (settingName, settingValue);
		}
		
		//MARK: SETTINGS
		
		curScore.endCmd();
	}
	
	function setPartSettings () {
		
		if (isSoloScore || numExcerpts < numParts) return;
		var newSpatium = (6.8 / 4) / inchesToMM*mscoreDPI;
		
		curScore.startCmd();
		for (var i = 0; i < numExcerpts; i++) {
			var thePart = excerpts[i];
			if (thePart != null) {
				setPartSetting (thePart, "spatium", newSpatium);
				setPartSetting (thePart, "enableIndentationOnFirstSystem", 0);
				setPartSetting (thePart, "enableVerticalSpread", 1);
				setPartSetting (thePart, "minSystemSpread", 6);
				setPartSetting (thePart, "maxSystemSpread", 11);
				setPartSetting (thePart, "minStaffSpread", 6);
				setPartSetting (thePart, "maxStaffSpread", 11);
				setPartSetting (thePart, "frameSystemDistance", 8);
				setPartSetting (thePart, "lastSystemFillLimit", 0);
				setPartSetting (thePart, "minNoteDistance", 1.3);
				setPartSetting (thePart, "createMultiMeasureRests", 1);
				setPartSetting (thePart, "minEmptyMeasures", 2);
				setPartSetting (thePart, "minMMRestWidth", 18);
				setPartSetting (thePart, "partInstrumentFrameType", 1);
				setPartSetting (thePart, "partInstrumentFramePadding", 0.8);
				
				if (setFontSizesOption) {
					setPartSetting (thePart, "tupletFontStyle", 2);
					setPartSetting (thePart, "tupletFontSize", 11);
					setPartSetting (thePart, "measureNumberFontSize", 8.5);
					setPartSetting (thePart, "pageNumberFontStyle",0);
					setPartSetting (thePart, "rehearsalMarkFontSize",14);
					var fontsToTwelvePoint = ["longInstrument", "shortInstrument", "partInstrument", "tempo", "tempoChange", "metronome", "pageNumber", "expression", "staffText", "systemText"];
					for (var j = 0; j < fontsToTwelvePoint.length; j++) setPartSetting (thePart, fontsToTwelvePoint[j]+"FontSize", 12);
				}
				
				if (setBravuraOption) {
					setPartSetting (thePart, "musicalSymbolFont", "Bravura");
					setPartSetting (thePart, "musicalTextFont", "Bravura Text");
				}
				
				if (setTimesOption) {
					var fontsToTimes = ["tuplet", "lyricsOdd", "lyricsEven", "hairpin", "romanNumeral", "volta", "stringNumber", "longInstrument", "shortInstrument","expression", "tempo", "tempoChange", "metronome", "measureNumber", "mmRestRange", "systemText", "staffText", "pageNumber", "instrumentChange"];
					for (var j = 0; j < fontsToTimes.length; j++) setPartSetting (thePart, fontsToTimes[j]+"FontFace", "Times New Roman Accidentals");
				}
				
				if (removeLayoutBreaksOption) {
					var currMeasure = thePart.partScore.firstMeasure;
					var breaks = [];
					while (currMeasure) {
						var elems = currMeasure.elements;
						for (var j = 0; j < elems.length; j ++) if (elems[j].type == Element.LAYOUT_BREAK) breaks.push(elems[j]);
						currMeasure = currMeasure.nextMeasure;
					}
					for (var j = 0; j < breaks.length; j++ ) removeElement (breaks[j]);
				}
			}
		}
		amendedParts = true;
		curScore.endCmd();
	}
	
	function setFontSizes() {
		
		curScore.startCmd();
		
		setSetting ("tupletFontStyle", 2);
		setSetting ("tupletFontSize", 11);
		setSetting ("measureNumberFontSize", 8.5);
		setSetting ("pageNumberFontStyle",0);
		setSetting ("titleFontSize", 24);
		setSetting ("subTitleFontSize", 13);
		setSetting ("composerFontSize", 10);
		setSetting ("rehearsalMarkFontSize", 14);

		setSetting ("partInstrumentFrameType", 1);
		setSetting ("partInstrumentFramePadding", 0.8);
		
		if (spatium > 1.5) {
			setSetting ("tempoFontSize", 12);
			setSetting ("tempoChangeFontSize", 12);
		} else {
			setSetting ("tempoFontSize", 13);
			setSetting ("tempoChangeFontSize", 13);
		}
		
		var fontsToTwelvePoint = ["longInstrument", "shortInstrument", "partInstrument", "metronome", "pageNumber", "expression", "staffText", "systemText"];
		for (var i = 0; i < fontsToTwelvePoint.length; i++) setSetting (fontsToTwelvePoint[i]+"FontSize", 12);
		curScore.endCmd();
	}
	
	function setBravura () {
		
		curScore.startCmd();
		setSetting ("musicalSymbolFont", "Bravura");
		setSetting ("musicalTextFont", "Bravura Text");
		curScore.endCmd();

	}
	
	function setTimes () {
		var fontsToTimes = ["tuplet", "lyricsOdd", "lyricsEven", "hairpin", "romanNumeral", "volta", "stringNumber","expression", "tempo", "tempoChange", "metronome", "measureNumber", "mmRestRange", "systemText", "staffText", "pageNumber"];

		curScore.startCmd();
		for (var i = 0; i < fontsToTimes.length; i++) setSetting (fontsToTimes[i]+"FontFace", "Times New Roman");
		var fontsToTimes = ["longInstrument", "shortInstrument", "instrumentChange"];
		for (var i = 0; i < fontsToTimes.length; i++) setSetting (fontsToTimes[i]+"FontFace", "Times New Roman Accidentals");
		curScore.endCmd();

	}
	
	function setTitleFrame () {
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
		cmd ("insert-vbox");
		var vbox = curScore.selection.elements[0];
		cmd ("title-text");
		var tempText = curScore.selection.elements[0];
		cmd ("select-similar");
		var elems = curScore.selection.elements;
		var firstPageNum = firstMeasure.parent.parent.pagenumber;
		var topbox = null;
		
		curScore.startCmd();
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			if (!e.is(tempText)) {
				//logError ("Found text object "+e.text);
				var eSubtype = e.subtypeName();
				if (eSubtype == "Title" && getPageNumber(e) == firstPageNum) {
					e.align = Align.HCENTER;
					e.offsetY = 0;
					e.offsetX = 0.;
					topbox = e.parent;
				}
				if (eSubtype == "Subtitle" && getPageNumber(e) == firstPageNum) {	
					e.align = Align.HCENTER;
					e.offsetY = 10. / spatium;
					e.offsetX = 0.;
				}
				if (eSubtype == "Composer" && getPageNumber(e) == firstPageNum) {
					e.text = e.text.toUpperCase();
					e.align = Align.BOTTOM | Align.RIGHT;
					e.offsetY = 0;
					e.offsetX = 0;
				}
			}
		}
		curScore.endCmd();
		if (vbox == null) {
			logError ("checkScoreText () — vbox was null");
		} else {
			curScore.startCmd();
			removeElement (vbox);
			curScore.endCmd();
		}
		if (topbox != null) {
			topbox.autoscale = 0;
			topbox.boxHeight = 15;
		}
	}
	
	function formatTempoMarkings () {
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
		var elems = curScore.selection.elements;
		var r = new RegExp('(.*?)(<sym>metNoteQuarterUp<\/sym>|<sym>metNoteHalfUp<\/sym>|<sym>metNote8thUp<\/sym>|\\uECA5|\\uECA7|\\uECA3)(.*?)( |\\u00A0|\\u2009)=( |\\u00A0|\\u2009)');
		var f = new RegExp('<\/?font.*?>','g');
		
		curScore.startCmd();
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			if (e.type == Element.TEMPO_TEXT) {
				var t = e.text;
				if (t.match(r) && !t.includes('<b>')) {
					e.fontStyle = 0;
					//e.text = t.replace(r,'BOB'));
					// delete all font tags
					t = t.replace (f,'');
					if (t.match(r)[1] === '') {
						e.text = t.replace(r,'$2$3\u2009=\u2009');
					} else {
						e.text = '<b>'+t.replace(r,'$1</b>$2$3\u2009=\u2009');
					}
				}
			}
		}
		curScore.endCmd();

	}
	
	function removeManualTextFormatting() {
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
		var elems = curScore.selection.elements;
		curScore.startCmd();
		
		var staffTextFont = curScore.style.value('staffTextFontFace');
		var staffTextFontSize = curScore.style.value('staffTextFontSize');
		var expressionFont = curScore.style.value('expressionFontFace');
		var expressionFontSize = curScore.style.value('expressionFontSize');
		
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			
			if (e.type == Element.STAFF_TEXT || e.type == Element.EXPRESSION) {
				e.fontStyle = 0;
				e.fontFace = (e.type == Element.STAFF_TEXT) ? staffTextFont : expressionFont;
				e.fontSize = (e.type == Element.STAFF_TEXT) ? staffTextFontSize : expressionFontSize;

				var t = e.text;
				if (t.includes('<b>')) t = t.replace (/<[\/]*b>/g,'');
				if (t.includes('<i>')) t = t.replace (/<[\/]*i>/g,'');
				if (t.includes('<font')) t = t.replace (/<[\/]*font[^>]*>/g,'');
				if (t !== e.text) e.text = t;
			}
		}
		curScore.endCmd();
	}
	
	function setSetting (theSetting, theValue) {
		if (theSetting == null || theSetting == undefined) return;
		if (theValue == null || theValue == undefined) return;
		if (theSetting == theValue) return;
		curScore.style.setValue(theSetting,theValue);
	}
	
	function setPartSetting (thePart, theSetting, theValue) {
		if (thePart.partScore.style.value(theSetting) == theValue) return;
		if (thePart.partScore == null) return;
		thePart.partScore.style.setValue(theSetting,theValue);
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
	
	function deleteAllCommentsAndHighlights () {
	
		var elementsToRemove = [];
		var elementsToRecolor = [];
				
		// ** CHECK TITLE TEXT FOR HIGHLIGHTS ** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
		// insert-box does not need startcmd
		cmd ("insert-vbox");
	
		var vbox = curScore.selection.elements[0];
		
		// title-text does not need startcmd
		cmd ("title-text");
		
		// select-similar does not need startcmd
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
			curScore.startCmd();
			removeElement (vbox);
			curScore.endCmd();
		}
		
		// **** SELECT ALL **** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
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
		for (var i = 0; i < elementsToRecolor.length; i++) elementsToRecolor[i].color = "black";
		curScore.startCmd();
		for (var i = 0; i < elementsToRemove.length; i++) removeElement(elementsToRemove[i]);
		curScore.endCmd();
	
	}

	
	StyledDialogView {
		id: dialog
		title: "CHECK COMPLETED"
		contentHeight: 300
		contentWidth: 550
		property var msg: ""
		property var titleText: ""
		property var fontSize: 18
	
		Text {
			id: theText
			width: parent.width-40
			x: 20
			y: 20
	
			text: dialog.titleText
			font.bold: true
			font.pointSize: dialog.fontSize
			color: ui.theme.fontPrimaryColor
		}
		
		Rectangle {
			x:20
			width: parent.width-45
			y:45
			height: 1
			color: ui.theme.fontPrimaryColor
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
				height: parent.height
				textFormat: Text.RichText
				text: dialog.msg
				wrapMode: TextEdit.Wrap
				leftInset: 0
				leftPadding: 0
				readOnly: true
				color: ui.theme.fontPrimaryColor
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
	
	StyledDialogView {
		id: options
		title: "MN MAKE RECOMMENDED LAYOUT CHANGES"
		contentHeight: 480
		contentWidth: 480
		property color backgroundColor: ui.theme.backgroundSecondaryColor
		property var removeBreaks: true
		property var setSpacing: true
		property var setBravura: true
		property var setOtherStyleSettings: true
		property var setTimes: true
		property var setTitleFrame: true
		property var setFontSizes: true
		property var setParts: true
		property var removeStretches: true
		property var formatTempoMarkings: true
		property var connectBarlines: true
		property var removeManualFormatting: true
	
		Text {
			id: styleText
			anchors {
				left: parent.left;
				leftMargin: 20;
				top: parent.top;
				topMargin: 20;
			}
			text: "Options"
			font.bold: true
			font.pointSize: 18
			color: ui.theme.fontPrimaryColor
		}
		
		Rectangle {
			id: rect
			anchors {
				left: styleText.left;
				top: styleText.bottom;
				topMargin: 10;
			}
			width: parent.width-45
			height: 1
			color: ui.theme.fontPrimaryColor
		}
		
		GridLayout {
			id: grid
			columns: 2
			columnSpacing: 15
			rowSpacing: 15
			width: 280
			anchors {
				left: rect.left;
				top: rect.bottom;
				topMargin: 10;
			}
			Text {
				id: layoutLabel
				text: "Change layout"
				font.bold: true
				Layout.columnSpan: 2
				color: ui.theme.fontPrimaryColor
			}
			CheckBox {
				text: "Remove existing layout breaks"
				checked: options.removeBreaks
				onClicked: {
					checked = !checked
					options.removeBreaks = checked
				}
			}
			CheckBox {
				text: "Tweak title frame layout"
				checked: options.setTitleFrame
				onClicked: {
					checked = !checked
					options.setTitleFrame = checked
				}
			}
			CheckBox {
				text: "Set staff/system spacing"
				checked: options.setSpacing
				onClicked: {
					checked = !checked
					options.setSpacing = checked
				}
			}
			CheckBox {
				text: "Change layout for all parts"
				checked: options.setParts
				onClicked: {
					checked = !checked
					options.setParts = checked
				}
			}
			CheckBox {
				text: "Remove all measure stretches"
				checked: options.removeStretches
				onClicked: {
					checked = !checked
					options.removeStretches = checked
				}
			}
			CheckBox {
				text: "Change style settings"
				checked: options.setOtherStyleSettings
				onClicked: {
					checked = !checked
					options.setOtherStyleSettings = checked
				}
			}
			CheckBox {
				text: "Connect/disconnect barlines"
				checked: options.connectBarlines
				onClicked: {
					checked = !checked
					options.connectBarlines = checked
				}
			}
			
			Text {
				text: "Change fonts"
				font.bold: true
				Layout.columnSpan: 2
				color: ui.theme.fontPrimaryColor
			}
			
			CheckBox {
				text: "Set music font to Bravura"
				checked: options.setBravura
				onClicked: {
					checked = !checked
					options.setBravura = checked
				}
			}
			CheckBox {
				text: "Set text font to Times New Roman*"
				checked: options.setTimes
				onClicked: {
					checked = !checked
					options.setTimes = checked
				}
			}
			CheckBox {
				text: "Set recommended font sizes"
				checked: options.setFontSizes
				onClicked: {
					checked = !checked
					options.setFontSizes = checked
				}
			}
			CheckBox {
				text: "Format tempo markings"
				checked: options.formatTempoMarkings
				onClicked: {
					checked = !checked
					options.formatTempoMarkings = checked
				}
			}
			CheckBox {
				text: "Remove manual formatting"
				checked: options.removeManualFormatting
				onClicked: {
					checked = !checked
					options.removeManualFormatting = checked
				}
			}
		}
		
		Text {
			text : '<p>*Requires installation of custom font ‘Times New Roman Accidentals’<br />(provided in download folder)</p>'
			textFormat: Text.RichText
			color: ui.theme.fontPrimaryColor
			anchors {
				left: grid.left
				top: grid.bottom
				topMargin: 36
			}
		}
		
		ButtonBox {
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				margins: 10
			}
			buttons: [ ButtonBoxModel.Cancel, ButtonBoxModel.Ok ]
			navigationPanel.section: dialog.navigationSection
			onStandardButtonClicked: function(buttonId) {
				if (buttonId === ButtonBoxModel.Cancel) {
					options.close()
				}
				if (buttonId === ButtonBoxModel.Ok) {
					makeChanges()
				}
			}
		}
		
		
	}
}