/*
 Copyright (C) 2001 Free Software Foundation, Inc.

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2, or (at your option)
 any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
*/

import java.awt.*;
import java.awt.event.*;
import java.text.NumberFormat;
// import java.lang.Math;  why doesn't this work!?!?

import Person;

public class PersonCalc extends java.applet.Applet
    implements ActionListener, Runnable
{
    Thread AutoCalc = null;
    TextArea Log;
    Label Harmony;

    final int
	DESTROYS=0,
	STEALS=1,
	UNEASY=2,
	EXPOSES=3,
	IMPASSE=4,
	ADMIRES=5,
	OBSERVES=6,
	ACCEPTS=7,
	READY=8,
	ATTITUDES=9;

    Person person[] = new Person[2];

    public void init()
    {
	Button b1;

	setBackground(Color.white);
	setForeground(Color.black);

	setLayout( new FlowLayout() );

	person[0] = new Person();
	add(person[0]);

	Panel panel = new Panel(new GridLayout(5,1));
	add(panel);
	Harmony = new Label("0.00", java.awt.Label.CENTER);
	panel.add(Harmony);
	//b1 = new Button("Initiate");
	//b1.addActionListener(this);
	//panel.add(b1);
	b1 = new Button("Music");
	b1.addActionListener(this);
	panel.add(b1);
	b1 = new Button("Juggle");
	b1.addActionListener(this);
	panel.add(b1);
	b1 = new Button("Play Go");
	b1.addActionListener(this);
	panel.add(b1);
	b1 = new Button("(about)");
	b1.addActionListener(this);
	panel.add(b1);

	person[1] = new Person();
	add(person[1]);

	Log = new TextArea(30,74);
	add(Log);
	Log.setEditable(false);
	Log.append("Any similarity between this program's descriptions and real people is purely\ncoincidental.  Personality is a myth!\n\n");
	Log.append("Suggestion:  Lock empathy for a symmetric personality and try to coax\nthe pair to positive harmony (the top-middle number) only by music, juggling,\nand playing Go.\n\n");

	for (int xx=0; xx < 2; xx++) {
	    person[xx].setLog(Log);
	}
    }
    
    public void run() {
	while (AutoCalc != null) {
	    try {
		Thread.sleep(1500);
	    }	
	    catch (InterruptedException e)
	    {
		String err = e.toString();
		System.out.println(err);
	    }

	    double a0[] = new double[ATTITUDES*2];
	    double a1[] = new double[ATTITUDES*2];
	    if (person[0].getAttitude(a0) &&
		person[1].getAttitude(a1))
	    {
		double har = -disharmony(a0, a1);
		NumberFormat nf = NumberFormat.getInstance();
		nf.setMaximumFractionDigits(3);
		Harmony.setText(nf.format(har));
	    }
	}
    }

    public double _disharmony(double l[], double r[]) {
	double ouch=0;

	double diff = l[DESTROYS*2] - r[DESTROYS*2+1];
	if (diff > 0) {
	    ouch += diff/2;
	}
	diff = l[STEALS*2] - r[STEALS*2+1];
	if (diff > 0) {
	    ouch += diff/2;
	}

	if (l[UNEASY*2+1] > 0) {
	    if (r[UNEASY*2] <= l[UNEASY*2+1]) {
		ouch -= java.lang.Math.min(r[UNEASY*2], l[UNEASY*2+1]);
	    } else {
		ouch += r[UNEASY*2] - l[UNEASY*2+1];
	    }
	}

	diff = l[EXPOSES*2] - r[EXPOSES*2+1];
	if (diff > 0) {
	    ouch += diff/2;
	}

	double sharp = (java.lang.Math.abs(l[IMPASSE*2]) -
			java.lang.Math.abs(r[IMPASSE*2]));
	if (sharp > 0) {
	    ouch += sharp;
	}

	if (r[ADMIRES*2] > 0 && r[ADMIRES*2] <= l[ADMIRES*2+1]) {
	    ouch -= r[ADMIRES*2];
	}

	ouch -= java.lang.Math.abs((r[ADMIRES*2] + l[ADMIRES*2]) / 2);

	if (r[OBSERVES*2] > 0 && l[OBSERVES*2+1] >= 0) {
	    if (r[OBSERVES*2] <= l[OBSERVES*2+1]) {
		ouch -= java.lang.Math.min(r[OBSERVES*2], l[OBSERVES*2+1]);
	    } else {
		ouch += r[OBSERVES*2] - l[OBSERVES*2+1];
	    }
	}

	if (l[ACCEPTS*2] < r[ACCEPTS*2+1]) {
	    ouch += (r[ACCEPTS*2+1] - l[ACCEPTS*2])/2;
	}

	if (r[ACCEPTS*2+1] > 0 && l[ACCEPTS*2] > 0) {
	    ouch -= java.lang.Math.min(r[ACCEPTS*2+1], l[ACCEPTS*2]);
	}

	ouch -= (l[READY*2] + r[READY*2]) / 2;

	return ouch;
    }

    public double disharmony(double p0[], double p1[]) {
	double ouch = _disharmony(p0, p1) + _disharmony(p1, p0);

	ouch *= (1-java.lang.Math.abs(p0[READY*2])) + (1-java.lang.Math.abs(p1[READY*2]));

	return ouch / 4;
    }

    public void start() {
	AutoCalc = new Thread(this);
	AutoCalc.start();
	// System.out.println("start");
    }
    public void stop() {
	AutoCalc = null;
	// System.out.println("stop");
    }

    public void dump_matrix(double vec[]) {
	StringBuffer buf = new StringBuffer();
	NumberFormat nf = NumberFormat.getInstance();
	nf.setMaximumFractionDigits(2);

	for (int yy=0; yy < 3; yy++) {
	    for (int xx=0; xx < 3; xx++) {
		int ax = xx*3+yy;
		if (java.lang.Math.abs(vec[ax*2] - vec[ax*2+1]) < .01) {
		    buf.append(" "+nf.format(vec[ax*2])+" ");
		} else {
		    buf.append(" "+nf.format(vec[ax*2])+"/"+
			       nf.format(vec[ax*2+1])+" ");
		}
	    }
	    buf.append("\n");
	}
	System.out.println(buf);
    }

    public void applyMusic(String name, int what, double a0[]) {
	switch (what) {
	  case UNEASY:
	    if (a0[ADMIRES*2+1] > .75) {
		a0[UNEASY*2] += .1;
		Log.append(name+" wants to be a musician.\n");
	    }
	    break;
	  case EXPOSES:
	    break;
	  case IMPASSE:
	    break;
	  case ADMIRES:
	    a0[ADMIRES*2] += .1;
	    Log.append(name+" loves music!\n");
	    break;
	  case OBSERVES:
	    break;
	  case ACCEPTS:
	    break;
	  case READY:
	    if (java.lang.Math.abs(a0[READY*2]) > .75) {
		a0[READY*2] *= .9;
		Log.append("Maybe it is nice to pay attention ...\n");
	    }
	    break;
	}
    }

    public void applyJuggle(String name, int what, double a0[]) {
	switch (what) {
	  case UNEASY:
	    if (a0[UNEASY*2] < 1) {
		a0[UNEASY*2] += .1;
		Log.append("Juggling is easy to learn.\n");
	    }
	    break;
	  case EXPOSES:
	    a0[EXPOSES*2] *= .9;
	    Log.append("(It's hard to assign blame when we mess up.)\n");
	    break;
	  case IMPASSE:
	    if (java.lang.Math.abs(a0[IMPASSE*2]) > .2) {
		a0[IMPASSE*2] *= .9;
		Log.append("Juggling develops balanced concern.\n");
	    }
	    break;
	  case OBSERVES:
	    if (a0[OBSERVES*2] < 0) {
		a0[OBSERVES*2] += .1;
		Log.append(name+" enjoys observing her partner's mistakes.\n");
	    }
	    if (a0[OBSERVES*2+1] < .25) {
		a0[OBSERVES*2+1] += .1;
		Log.append("Being in the spotlight is fun.\n");
	    }
	    break;
	  case ACCEPTS:
	    a0[ACCEPTS*2] += .1;
	    Log.append("Acceptance is essential to juggling.\n");
	    if (a0[ACCEPTS*2+1] < 0) {
		a0[ACCEPTS*2+1] += .1;
		Log.append(name+" expects to be accepted.\n");
	    }
	    break;
	  case READY:
	    if (java.lang.Math.abs(a0[READY*2]) > .25) {
		a0[READY*2] *= .9;
		Log.append(name+" feels more ready.\n");
	    }
	    break;
	}
    }

    public boolean applyGo(String name, int what, double a0[]) {
	if (a0[UNEASY*2] <= 0) {
	    Log.append(name+" thinks Go is too intellectual.\n");
	    return false;
	}
	if (a0[ADMIRES*2] <= 0) {
	    Log.append(name+" is not motivated to play Go.\n");
	    return false;
	}
	if (a0[OBSERVES*2+1] <= 0) {
	    Log.append(name+" declines to accept the possibility of losing.\n");
	    return false;
	}

	switch (what) {
	  case DESTROYS:
	    if (java.lang.Math.abs(a0[DESTROYS*2]) > .25) {
		a0[DESTROYS*2] *= .9;
		Log.append(name + " struggles for relentless determination.\n");
	    }
	    break;
	  case EXPOSES:
	    if (a0[EXPOSES*2] < 1) {
		a0[EXPOSES*2] += .1;
		Log.append(name+" exposes her opponent.\n");
	    }
	    if (a0[EXPOSES*2] > .9) {
		a0[EXPOSES*2+1] += .1;
		Log.append(name+" wants to be exposed.\n");
	    }
	    break;
	  case IMPASSE:
	    if (java.lang.Math.abs(a0[IMPASSE*2]) > .1) {
		a0[IMPASSE*2] *= .9;
		Log.append(name+" struggles for balanced concern.\n");
	    }
	    break;
	  case OBSERVES:
	    a0[OBSERVES*2+1] += .1;
	    Log.append(name+" feel more ready for the spotlight.\n");
	    if (a0[OBSERVES*2+1] > .5 && a0[OBSERVES*2] < 1) {
		a0[OBSERVES*2] += .1;
		Log.append(name+" studies the games of peers.\n");
	    }
	    break;
	  case ACCEPTS: // asymmetry!! XXX
	    if (a0[ACCEPTS*2] > 0) {
		a0[ACCEPTS*2] *= .9;
		Log.append(name+" feels nitpicky about acceptance.\n");
	    }
	    if (a0[ACCEPTS*2+1] < .5) {
		a0[ACCEPTS*2+1] += .1;
		Log.append(name+" expects to be accepted.\n");
	    }
	    break;
	  case READY:
	    if (java.lang.Math.abs(a0[READY*2]) > java.lang.Math.random()) {
		a0[READY*2] *= 1.1;
		Log.append(name+" feel queasy.\n");
	    }
	    break;
	}
	return true;
    }

    public void actionPerformed(ActionEvent e)
    {
	String cmd = e.getActionCommand();
	if (cmd == "(about)") {
	    Log.append("Personality Calculator [5 Mar 2001]\nCopyright (C) 2001 Free Software Foundation, Inc.\n\n");
	    Log.append("This program is free software; you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation; either version 2, or (at your option)\nany later version.\n\n");
	    Log.append("This program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\n");
	    Log.append("The source code and latest version of this program is available\nat <http://why-compete.org>.\n\n");

	} else if (cmd == "Music" || cmd == "Juggle" || cmd == "Play Go") {

	    if (!person[0].isEmpathyMode() && !person[1].isEmpathyMode()) {
		Log.append("Neither opponent is empathy locked.  Please click the empathy button.\n\n");
		return;
	    }

	    double a0[] = new double[ATTITUDES*2];
	    double a1[] = new double[ATTITUDES*2];
	    if (!person[0].getAttitude(a0) || !person[1].getAttitude(a1))
		return;

	    int what = (int) (java.lang.Math.random()*8.99);

	    if (what == DESTROYS) {
		// i hate java
		if (a0[DESTROYS*2] > .5 &&
		    a0[DESTROYS*2] + a1[DESTROYS*2+1] > 0) {
		    if (a1[DESTROYS*2+1] >= 0) {
			a0[DESTROYS*2] -= .5;
			a0[ADMIRES*2] += .5;
			person[0].setAttitude(a0);
		    }
		    Log.append("Left stabs Right in the back.\n\n");
		    person[1].setReset();
		} else if (a1[DESTROYS*2] > .5 &&
			   a1[DESTROYS*2] + a0[DESTROYS*2+1] > 0) {
		    if (a0[DESTROYS*2+1] >= 0) {
			a1[DESTROYS*2] -= .5;
			a1[ADMIRES*2] += .5;
			person[1].setAttitude(a1);
		    }
		    Log.append("Right stabs Left in the back.\n\n");
		    person[0].setReset();
		}
	    }
	    if (what == STEALS) {
		return; // XXX
	    }

	    boolean ok=true;
	    if (cmd == "Music") { // i hate java
		if (person[0].isEmpathyMode())
		    applyMusic("Left", what, a0);
		if (person[1].isEmpathyMode())
		    applyMusic("Right", what, a1);
	    } else if (cmd == "Juggle") {
		if (person[0].isEmpathyMode())
		    applyJuggle("Left", what, a0);
		if (person[1].isEmpathyMode())
		    applyJuggle("Right", what, a1);
	    } else if (cmd == "Play Go") {
		if (person[0].isEmpathyMode()) {
		    if (!applyGo("Left", what, a0))
			ok=false;
		}
		if (ok && person[1].isEmpathyMode()) {
		    if (!applyGo("Right", what, a1))
			ok=false;
		}
	    } else {
		System.out.println("oops");
	    }
	    if (ok) {
		person[0].setAttitude(a0);
		person[1].setAttitude(a1);
	    }
	} else {
	    System.out.println(cmd);
	}
    }

}
