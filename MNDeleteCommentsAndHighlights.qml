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
	description: "This plugin removes any comments and highlights from your score that were added by the MN Plugins"
	menuPath: "Plugins.MNDeleteCommentsAndHighlights";
	requiresScore: true
	title: "MN Delete Comments and Highlights"
	id: mndeletecommentsandhighlights
	thumbnailName: "MNDeleteCommentsAndHighlights.png"	
	property var selectionArray: [];
	property var frames: [];
	FileIO { id: versionnumberfile; source: Qt.resolvedUrl("./assets/versionnumber.txt").toString().slice(8); onError: { console.log(msg); } }

  onRun: {
		if (!curScore) return;
		var versionNumber = versionnumberfile.read().trim();

		// **** VERSION CHECK **** //
		var version46 = mscoreMajorVersion > 4 || (mscoreMajorVersion == 4 && mscoreMinorVersion > 5);
		if (!version46) {
			dialog.msg = "<p><font size=\"6\">🛑</font> This plugin requires MuseScore v. 4.6 or later.</p> ";
			dialog.show();
			return;
		}
		
		getFrames();
			
		var elementsToRemove = [];
		var elementsToRecolor = [];
				
		// ** CHECK TITLE TEXT FOR HIGHLIGHTS ** //
		for (var i = 0; i < frames.length; i++) {
			var frame = frames[i];
			var elems = frame.elements;
			for (var j = 0; j < elems.length; j++) {
				var e = elems[j];
				var c = e.color;	
				// style the element pink
				if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
			}
		}
		
		// **** SELECT ALL **** //
		curScore.startCmd();
		curScore.selection.selectRange(0,curScore.lastSegment.tick+1,0,curScore.nstaves);
		curScore.endCmd();
		curScore.startCmd();

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

		
		// **** THE FOLLOWING FORCE A SCREEN REDRAW **** //
		selectNone();
		curScore.endCmd();
	}
	
	function selectNone () {
		// ************  								DESELECT AND FORCE REDRAW 							************ //
		//curScore.startCmd();
		cmd('escape');
		//curScore.doLayout(fraction(0, 1), fraction(-1, 1));
		//curScore.endCmd();
	}
	
	function getFrames() {
		var systems = curScore.systems;
		var numSystems = systems.length;
		for (var i = 0; i < numSystems; i++ ) {
			var system = systems[i];
			var measures = system.measures;
			for (var j = 0; j < measures.length; j++ ) {
				var e = measures[j];
				if (e.type == Element.VBOX) frames.push(e);
			}
		}
	}
	
	function saveSelection () {
		selectionArray = [];
		if (curScore.selection.isRange) {
			selectionArray[0] = curScore.selection.startSegment.tick;
			//errorMsg += "\n"+curScore.selection.startSegment+" "+curScore.selection.startSegment.tick;
			
			selectionArray[1] = curScore.selection.endSegment.tick;
			selectionArray[2] = curScore.selection.startStaff;
			selectionArray[3] = curScore.selection.endStaff;
		}
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
