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
	
	// **** GLOBALS **** //
	property var timeSigs: []
	property var timeSigTicks: []

  onRun: {
		if (!curScore) return;
		
		// **** INITIALISE VARIABLES **** //
		var staves = curScore.staves;
		var numStaves = curScore.nstaves;
		var cursor = curScore.newCursor();
		var cursor2 = curScore.newCursor();
		var firstStaffNum, firstBarNum, firstBarInScore, firstBarInSelection, firstTickInSelection, firstStaffInSelection;
		var lastStaffNum, lastBarNum, lastBarInScore, lastBarInSelection, lastTickInSelection, lastStaffInSelection;
		var currentBar, segment;
		var numBars, totalNumBars;
		var tiedNotes = [];
		var rests = [];
		var	simplifiedDuration = [];
		var d = division;
		var Semibreve = 4*d;
		var DottedMinim = 3*d;
		var Minim = 2*d;
		var DottedCrotchet = 1.5*d;
		var Crotchet = d;
		var DoubleDottedQuaver = 0.875*d;
		var DottedQuaver = 0.75*d;
		var Quaver = 0.5*d;
		var DottedSemiquaver = 0.375*d;
		var Semiquaver = 0.25*d;
		
		var possibleOnbeatSimplificationDurs = [Semiquaver,DottedSemiquaver,Quaver,DottedQuaver,DoubleDottedQuaver,Crotchet,DottedCrotchet,Minim,DottedMinim,Semibreve];
		var possibleOnbeatSimplificationLabels = ["semiquaver","dotted semiquaver","quaver","dotted quaver","double-dotted quaver","crotchet","dotted crotchet","minim","dotted minim","semibreve"];
		var possibleOffbeatSimplificationDurs = [Semiquaver,DottedSemiquaver,Quaver,DottedQuaver,DoubleDottedQuaver,Crotchet,DottedCrotchet];
		var	possibleOffbeatSimplificationLabels = ["semiquaver","dotted semiquaver","quaver","dotted quaver","double-dotted quaver","crotchet","dotted crotchet"];

		
		dialog.msg = "";
		
		// **** EXTEND SELECTION? **** //
		if (!curScore.selection.isRange) {
			// ** SELECT ALL ** //
			curScore.startCmd();
			curScore.selection.selectRange(0,curScore.lastSegment.tick + 1,0,numStaves);
			curScore.endCmd();
		}
		
		firstStaffNum = curScore.selection.startStaff;
		lastStaffNum = curScore.selection.endStaff;
		dialog.msg+="firstStaffNum= "+firstStaffNum+"; lastStaffNum = "+lastStaffNum;
		
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
				timeSigTicks.push(cursor.tick);
				dialog.msg += "\nFound a time sig elem: "+ts.timesigNominal.str;
			}
			cursor.next();
		}
		if (timeSigs.length == 0) dialog.msg += "\nDidn't find any time sigs";
		
		numBars = (lastBarNum-firstBarNum)+1;
		totalNumBars = numBars*numStaves;


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
		
		// **** INITIALISE VARIABLES FOR THE LOOP **** //
		var currentBarNum, currentStaffNum;
		var numBarsProcessed;
		var wasTied;
		var currentTimeSig;
		var prevActualDur, prevDisplayDur, prevNoteWasDoubleTremolo;
		var tiedActualDur, tiedDisplayDur, tieStartedOnBeat, isTied, tieIndex, tieIsSameTuplet;
		var numRests, restCrossesBeat, restStartedOnBeat, isLastRest;
		var prevItemIsNote, prevNoteCount, prevPitch, prevTupletSubDiv;
		var lastNoteInBar, lastRest;
		var numComments, totalDur;
		
		numBarsProcessed = 0;
		
		// **** LOOP THROUGH THE SELECTED STAVES AND THE SELECTED BARS **** //
		// ** NB — lastStaffNum IS EXCLUDED FROM RANGE — SEE MUSESCORE DOCS ** //
		for (currentStaffNum = firstStaffNum; currentStaffNum < lastStaffNum; currentStaffNum ++) {
			
			//staff = score.NthStaff(currentStaff);

			wasTied = false;
			
			// ** REWIND TO START OF SELECTION ** //
			cursor.rewind(Cursor.SELECTION_START);
			cursor.staffIdx = currentStaffNum;
			cursor2.staffIdx = currentStaffNum;
			cursor.filter = Segment.ChordRest;
			cursor2.filter = Segment.ChordRest;
			currentBar = cursor.measure;
			currentBarNum = firstBarNum;
			
			while (currentBar) {
				
				numBarsProcessed ++;
				dialog.msg += "\n—————————————————\nStaff: "+currentStaffNum+"; Bar num: "+currentBarNum;
				
				// ** UPDATE PROGRESS MESSAGE ** //
				
								
				// **** GET TIME SIGNATURE **** //
				currentTimeSig = currentBar.timesigActual; //getTimeSignatureForBar(currentBar);
				//dialog.msg += "\ncurrentTimeSig = "+currentTimeSig;
				
				dialog.msg += "\nts = "+currentTimeSig.numerator+"/"+currentTimeSig.denominator;
				var timeSigNum = currentTimeSig.numerator;
				var timeSigDenom = currentTimeSig.denominator;
				var barTick = currentBar.firstSegment.tick;
				var barLength = currentBar.lastSegment.tick - barTick;
				
				dialog.msg += "\nbarTick = "+barTick+"; barLength = "+barLength;
				
				var beatLength = Crotchet;
				var isPickupBar = false;
				var expectedDuration = timeSigNum * (Semibreve/timeSigDenom);
				dialog.msg += "\nexpectedDur = "+expectedDuration;
				
				if (currentBarNum == 1 && expectedDuration != barLength) isPickupBar = true;
				var canCheckThisBar = false;
				var isCompound = false;
				
				if (timeSigDenom == 8) {
					isCompound = !(timeSigNum % 3);
					if (isCompound) beatLength = DottedCrotchet;
				}
				if (timeSigDenom == 4 || timeSigDenom == 2) isCompound = !(timeSigNum % 3) && (timeSigNum > 3);
				if (isCompound && timeSigDenom > 4) {
					canCheckThisBar = true;
				} else {
					if (timeSigNum < 5 || !(timeSigNum % 2) || timeSigDenom == 4) canCheckThisBar = true;
				}

	
				// ** LOOP THROUGH ALL THE NOTERESTS IN THIS BAR ** //
				if (canCheckThisBar) {
				
					// ** INITIALISE PARAMETERS ** //
			
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
					var startTrack = currentStaffNum * 4;
					var endTrack = startTrack + 4;
					for (var track = startTrack; track < endTrack; track++) {
						// **** GET SEGMENT **** //
						//segment = currentBar.firstSegment;
						cursor.voice = track;
						cursor2.voice = track;
						cursor.rewindToTick(barTick);
						//cursor.next();
						dialog.msg += "\ncursorTick = "+cursor.tick;
						dialog.msg += "\ncursor.element = "+cursor.element;
						
							// ** LOOP THROUGH EACH VOICE ** //
					
						totalDur = 0;
						currentBar = cursor.measure;
						var processingThisBar = cursor.element;
						while (processingThisBar) {
							var noteRest = cursor.element;
							var isHidden = !noteRest.visible;
							var pos = cursor.tick;
							var nextItemPos;
							cursor2.rewindToTick(pos);
							if (cursor2) dialog.msg += "\n1 cursor2Tick = "+cursor2.tick;
							
							cursor2.next();
							if (cursor2) dialog.msg += "\n2 cursor2Tick now = "+cursor2.tick;
							
							var actualDur;
							
							if (cursor2) {
								nextItemPos = cursor2.tick;
								actualDur = nextItemPos - pos;
								dialog.msg += "\ncursor2: "+cursor2.tick;
							} else {
								actualDur = barLength - pos;
								dialog.msg += "\nbarLength: "+barLength;
							}
								
							totalDur = totalDur + actualDur;
							dialog.msg += "\nactualDur = "+actualDur+"; totalDur = "+totalDur;
						
							if (isHidden) {
								numRests = 0;
								restCrossesBeat = false;
								restStartedOnBeat = false;
								isLastRest = false;
							}
							
							if (cursor.next()) {
								processingThisBar = cursor.measure.is(currentBar);
							} else {
								processingThisBar = false;
							}
							
						} // end while processingThisBar
					} // end track loop
				} // end if canCheckThisBar
			} // end while currentBar	
		} // end for currentStaff
		
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
