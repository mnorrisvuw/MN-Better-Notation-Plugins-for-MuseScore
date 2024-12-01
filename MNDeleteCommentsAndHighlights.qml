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
	description: "This plugin removes any comments and highlights from your score that were added by the MN Plugins"
	menuPath: "Plugins.MNDeleteCommentsAndHighlights";
	requiresScore: true
	title: "MN Delete Comments and Highlights"
	id: mndeletecommentsandhighlights
	

  onRun: {
		if (!curScore) return;
		
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
		
		curScore.selection.selectRange(startTick,endTick+1,startStaff,endStaff+1);
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
