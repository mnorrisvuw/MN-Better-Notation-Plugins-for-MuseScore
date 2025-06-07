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
	
	onRun: {
		if (!curScore) return;
		
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
		
		var finalMsg = '';
		// get some variables
		spatium = curScore.style.value("spatium")*inchesToMM/mscoreDPI;
		
		analyseInstrumentsAndStaves();


		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		
		firstMeasure = curScore.firstMeasure;
		var visibleParts = [];
		// ** calculate number of parts, but ignore hidden ones
		for (var i = 0; i < curScore.parts.length; i++) if (curScore.parts[i].show) visibleParts.push(curScore.parts[i]);
		numParts = visibleParts.length;
		isSoloScore = numParts == 1;
		excerpts = curScore.excerpts;
		numExcerpts = excerpts.length;
		if (numParts > 1 && numExcerpts < numParts) finalMsg = "<b>NOTE</b>: Parts for this score have not yet been created/opened, so I wasn’t able to change the part layout settings.\nYou can create them by clicking ‘Parts’, then ’Open All’. Once you have created and opened the parts, please run this plug-in again on the score to change the part layout settings. (Ignore this if you do not plan to create parts.)";
		
		// REMOVE LAYOUT BREAKS
		if (removeLayoutBreaksOption || removeStretchesOption) removeLayoutBreaksAndStretches();
		
		// SET ALL THE SPACING-RELATED SETTINGS
		if (setSpacingOption) setSpacing();
		
		// SET ALL THE OTHER STYLE SETTINGS
		if (setOtherStyleSettings) setOtherStyleSettings();
		
		// FONT SETTINGS
		if (setTimesOption) setTimes();
		if (setBravuraOption) setBravura();
		if (setFontSizesOption) setFontSizes();
		if (formatTempoMarkingsOption) formatTempoMarkings();
		if (removeManualTextFormattingOption) removeManualTextFormatting();
		
		// LAYOUT THE TITLE FRAME ON p. 1
		if (setTitleFrameOption) setTitleFrame();
		
		// SET PART SETTINGS
		if (setPartsOption) setPartSettings();
		
		if (connectBarlinesOption) doConnectBarlines();
		
		
		// CHANGE INSTRUMENT NAMES
		//changeInstrumentNames();
		
		// SELECT NONE
		
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
		
		curScore.startCmd();
		
		// BAR SETTINGS
		setSetting ("minMeasureWidth", isSoloScore ? 14.0 : 16.0);
		setSetting ("measureSpacing",1.5);
		setSetting ("barWidth",0.16);
		setSetting ("showMeasureNumberOne", 0);
		setSetting ("minNoteDistance", isSoloScore ? 1.1 : 0.6);
		setSetting ("staffDistance", 5);
		setSetting ("barNoteDistance",1.4);
		setSetting ("barAccidentalDistance",0.8);

		// SLUR SETTINGS
		setSetting ("slurEndWidth",0.06);
		setSetting ("slurMidWidth",0.16);
	
		setSetting ("lastSystemFillLimit", 0);
		setSetting ("crossMeasureValues",0);
		setSetting ("tempoFontStyle", 1);
		setSetting ("metronomeFontStyle", 0);
		setSetting ("staffLineWidth",0.1);
		
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
					var fontsToTwelvePoint = ["longInstrument", "shortInstrument", "partInstrument", "tempo", "tempoChange", "metronome", "pageNumber", "expression", "staffText", "systemText", "rehearsalMark"];
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
		setSetting ("partInstrumentFrameType", 1);
		setSetting ("partInstrumentFramePadding", 0.8);
		
		if (spatium > 1.5) {
			setSetting ("tempoFontSize", 12);
			setSetting ("tempoChangeFontSize", 12);
		} else {
			setSetting ("tempoFontSize", 13);
			setSetting ("tempoChangeFontSize", 13);
		}
		
		var fontsToTwelvePoint = ["longInstrument", "shortInstrument", "partInstrument", "metronome", "pageNumber", "expression", "staffText", "systemText", "rehearsalMark"];
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
		curScore.startCmd();

		var fontsToTimes = ["tuplet", "lyricsOdd", "lyricsEven", "hairpin", "romanNumeral", "volta", "stringNumber","expression", "tempo", "tempoChange", "metronome", "measureNumber", "mmRestRange", "systemText", "staffText", "pageNumber"];
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
			
			//curScore.startCmd ();
			topbox.autoscale = 0;
			topbox.boxHeight = 15;
			//curScore.endCmd ();
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
		if (curScore.style.value(theSetting) == theValue) return;
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
	
	StyledDialogView {
		id: dialog
		title: "CHECK COMPLETED"
		contentHeight: 300
		contentWidth: 500
		property var msg: ""
	
		Text {
			id: theText
			width: parent.width-40
			x: 20
			y: 20
	
			text: "MN MAKE RECOMMENDED LAYOUT CHANGES"
			font.bold: true
			font.pointSize: 18
		}
		
		Rectangle {
			x:20
			width: parent.width-45
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
				height: parent.height
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
			color: "black"
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