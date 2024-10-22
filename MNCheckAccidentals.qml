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
			while (segment && segment.tick < lastTick) {
				var startTrack = staffNum * 4;
				var endTrack = startTrack + 4;
				for (var track = startTrack; track < endTrack; track++) {
					
					if (segment.elementAt(track) && segment.elementAt(track).type == Element.CHORD) {
						var elem = segment.elementAt(track);
						var notes = segment.elementAt(track).notes;
						dialog.msg += "\nFound element "+elem.name;
						notes = elem.notes;
						
						// GET ALL NOTES IN THIS PART
						for (var i in notes) {
							var note = notes[i];
							var currTick = segment.tick;
							var measure = segment.parent
		
							// ** GET INFO ON THE KEY SIGNATURE AT THIS POINT ** //
		
							/// ** GET INFO ON THE NOTE ** //
							var accObject
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
							var MIDIpitch = note.pitch;
							var diatonicPitchClass = Math.round((((tpc+1)%7)*7+5) % 12);
							dialog.msg += "\naccType = "+accType+"; dpc = "+diatonicPitchClass+"; p = "+MIDIpitch;
						}
					}
				}
				segment = segment.next;
			}
				//var accIsInKS = false;
			//	if (sharps = 0 and acc = Natural) {
			//		accIsInKS = true;
			//	}
			/*	if (sharps > 0) {
					accOrder = ((diatonicPitchClass + 4) * 2) % 7;
					if (acc = Sharp) {
						accIsInKS = accOrder < sharps;
					}
					if (acc = Natural) {
						accIsInKS = (accOrder + 1) > sharps; 
					}
				}
				if (sharps < 0) {
					accOrder = (2 * (13 - diatonicPitchClass)) % 7;
					if (acc = Flat) {
						accIsInKS = accOrder < utils.AbsoluteValue(sharps);
					}
					if (acc = Natural) {
						accIsInKS = (accOrder + 1) > utils.AbsoluteValue(sharps);
					}
				}*/
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
