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

public class Person extends Panel implements ActionListener, ItemListener
{
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

    TextField tf[] = new TextField[9];
    PopupMenu PrefabMenu;
    Button Prefab;
    Checkbox Lock;
    TextArea Log;

    Person() {
	super(new GridLayout(4,3));
	for (int yy=0; yy < 3; yy++) {
	    for (int xx=0; xx < 3; xx++) {
		add(tf[xx*3+yy] = new TextField(9));
		
	    }
	}
	setSymmetric();

	PrefabMenu = new PopupMenu();
	PrefabMenu.add("Reset");
	PrefabMenu.addSeparator();
	PrefabMenu.add("Max");
	PrefabMenu.add("Min");
	PrefabMenu.add("Symmetric");
	PrefabMenu.add("Asymmetric");
	PrefabMenu.addSeparator();
	PrefabMenu.add("Follower");
	PrefabMenu.add("Comedian");
	PrefabMenu.add("Novice");
	PrefabMenu.add("Seeker");
	PrefabMenu.add("Teacher");
	PrefabMenu.addActionListener(this);
	add(PrefabMenu);

	Button b1;
	b1 = Prefab = new Button("Prefab");
	b1.addActionListener(this);
	add(b1);
	Lock = new Checkbox("Empathy");
	Lock.addItemListener(this);
	add(Lock);
	b1 = new Button("Describe");
	b1.addActionListener(this);
	add(b1);
    }

    public void setLog(TextArea ta) {
	Log = ta;
    }

    public boolean getAttitude(double att[]) {
	boolean OK=true;
	for (int xx=0; xx < ATTITUDES; xx++) {
	    boolean ok=true;
	    tf[xx].setBackground(Color.white);
	    String str = tf[xx].getText();
	    int mid = str.indexOf('/');
	    if (str.compareTo("?")==0) {
		double val = java.lang.Math.random()*2 - 1;
		att[xx*2] = val;
		att[xx*2+1] = val;
	    } else if (mid != -1) {
		String s1="",s2="";
		try {
		    s1 = str.substring(0,mid);
		    s2 = str.substring(mid+1);
		} catch (StringIndexOutOfBoundsException e) {
		    String err = e.toString();
		    System.out.println(err);
		}
		try {
		    if (s1.compareTo("?")==0) {
			att[xx*2] = java.lang.Math.random()*2 - 1;
		    } else {
			double val = Double.valueOf(s1).doubleValue();
			if (val >= -1 && val <= 1) {
			    att[xx*2] = val;
			} else {
			    ok=false;
			}
		    }
		    if (s2.compareTo("?")==0) {
			att[xx*2+1] = java.lang.Math.random()*2 - 1;
		    } else {
			double val = Double.valueOf(s2).doubleValue();
			if (val >= -1 && val <= 1) {
			    att[xx*2+1] = val;
			} else {
			    ok=false;
			}
		    }
		}
		catch (NumberFormatException e) {
		    ok=false;
		}
	    } else {
		try {
		    double val = Double.valueOf(str).doubleValue();
		    if (val >= -1 && val <= 1) {
			att[xx*2] = val;
			att[xx*2+1] = val;
		    } else {
			ok=false;
		    }
		}
		catch (NumberFormatException e) {
		    ok=false;
		}
	    }
	    if (!ok) {
		tf[xx].setBackground(Color.yellow);
		OK=false;
	    }
	}
	return OK;
    }

    public boolean isEmpathyMode() {
	return Lock.getState();
    }

    public void maybeSetAttitude(int ax, String str) {
	if (tf[ax].getText().compareTo(str) == 0)
	    return;
	tf[ax].setBackground(Color.pink);
	tf[ax].setText(str);
    }

    public void setAttitude(double atti[]) {
	// Without empathy, our personality is immune to emotions.
	if (!isEmpathyMode())
	    return;

	for (int xx=0; xx < ATTITUDES*2; xx++) {
	    if (atti[xx] < -1)
		atti[xx] = -1;
	    if (atti[xx] > 1)
		atti[xx] = 1;
	}
	NumberFormat nf = NumberFormat.getInstance();
	nf.setMaximumFractionDigits(2);
	for (int xx=0; xx < ATTITUDES; xx++) {
	    String str;
	    String oldstr = tf[xx].getText();
	    int mid = oldstr.indexOf('/');
	    if (oldstr.compareTo("?")==0) {
		continue;
	    } else if (mid != -1) {
		String s1="",s2="";
		try {
		    s1 = oldstr.substring(0,mid);
		    s2 = oldstr.substring(mid+1);
		} catch (StringIndexOutOfBoundsException e) {
		    String err = e.toString();
		    System.out.println(err);
		}
		if (s1.compareTo("?")==0 && s2.compareTo("?")==0) {
		    maybeSetAttitude(xx, "?");
		} else if (s1.compareTo("?")==0 || s2.compareTo("?")==0) {
		    if (s1.compareTo("?")==0) {
			maybeSetAttitude(xx, "?/" + nf.format(atti[xx*2+1]));
		    } else {
			maybeSetAttitude(xx, nf.format(atti[xx*2]) + "/?");
		    }
		    continue;
		}
	    }
	    if (xx == IMPASSE || xx == READY ||
		java.lang.Math.abs(atti[xx*2] - atti[xx*2+1]) < .01)
	    {
		maybeSetAttitude(xx, nf.format(atti[xx*2]));
	    } else {
		maybeSetAttitude(xx, nf.format(atti[xx*2])
			       + "/" +
			       nf.format(atti[xx*2+1]));
	    }
	}
    }

    public void setSymmetric()
    {
	NumberFormat nf = NumberFormat.getInstance();
	nf.setMaximumFractionDigits(1);
	for (int xx=0; xx < ATTITUDES; xx++) {
	    tf[xx].setText(nf.format(java.lang.Math.random()*2 - 1));
	}
    }

    public void setReset() {
	for (int xx=0; xx < ATTITUDES; xx++) {
	    tf[xx].setText("?");
	}
    }

    public void actionPerformed(ActionEvent e)
    {
	String cmd = e.getActionCommand();
	if (cmd == "Prefab") {
	    PrefabMenu.show(Prefab, 0,0);
	} else if (cmd == "Reset") {
	    setReset();
	} else if (cmd == "Max") {
	    tf[DESTROYS].setText("-1/1");
	    tf[STEALS].setText("-1/1");
	    tf[UNEASY].setText("1");
	    tf[EXPOSES].setText("-1/1");
	    tf[IMPASSE].setText("0");
	    tf[ADMIRES].setText("1");
	    tf[OBSERVES].setText("1");
	    tf[ACCEPTS].setText("1");
	    tf[READY].setText("0");
	} else if (cmd == "Min") {
	    tf[DESTROYS].setText("1/-1");
	    tf[STEALS].setText("1/-1");
	    tf[UNEASY].setText("-1/1");
	    tf[EXPOSES].setText("1/-1");
	    tf[IMPASSE].setText("1");
	    tf[ADMIRES].setText("0");
	    tf[OBSERVES].setText("1/0");
	    tf[ACCEPTS].setText("-1/1");
	    tf[READY].setText("0");
	} else if (cmd == "Symmetric") {
	    setSymmetric();
	} else if (cmd == "Asymmetric") {
	    NumberFormat nf = NumberFormat.getInstance();
	    nf.setMaximumFractionDigits(1);
	    for (int xx=0; xx < ATTITUDES; xx++) {
		if (xx == IMPASSE || xx == READY) {
		    tf[xx].setText(nf.format(java.lang.Math.random()*2 - 1));
		} else {
		    tf[xx].setText(nf.format(java.lang.Math.random()*2 - 1)
				   + "/" +
				   nf.format(java.lang.Math.random()*2 - 1));
		}
	    }
	} else if (cmd == "Follower") {
	    tf[DESTROYS].setText("-1");
	    tf[STEALS].setText("?");
	    tf[UNEASY].setText("-1");
	    tf[EXPOSES].setText("?");
	    tf[IMPASSE].setText("1");
	    tf[ADMIRES].setText(".5");
	    tf[OBSERVES].setText("0");
	    tf[ACCEPTS].setText("0");
	    tf[READY].setText(".75");
	} else if (cmd == "Comedian") {
	    tf[DESTROYS].setText("-1");
	    tf[STEALS].setText("0");
	    tf[UNEASY].setText("0/-1");
	    tf[EXPOSES].setText("1");
	    tf[IMPASSE].setText("-1");
	    tf[ADMIRES].setText("1");
	    tf[OBSERVES].setText("1");
	    tf[ACCEPTS].setText("0");
	    tf[READY].setText("0");
	} else if (cmd == "Novice") {
	    tf[DESTROYS].setText("0");
	    tf[STEALS].setText("-1");
	    tf[UNEASY].setText("0");
	    tf[EXPOSES].setText("?");
	    tf[IMPASSE].setText("-1");
	    tf[ADMIRES].setText("1/-1");
	    tf[OBSERVES].setText("-1/1");
	    tf[ACCEPTS].setText("1");
	    tf[READY].setText(".75");
	} else if (cmd == "Seeker") {
	    tf[DESTROYS].setText("0");
	    tf[STEALS].setText("-1/1");
	    tf[UNEASY].setText("1");
	    tf[EXPOSES].setText("1");
	    tf[IMPASSE].setText("0");
	    tf[ADMIRES].setText("0");
	    tf[OBSERVES].setText("1");
	    tf[ACCEPTS].setText("0");
	    tf[READY].setText(".5");
	} else if (cmd == "Teacher") {
	    tf[DESTROYS].setText("0");
	    tf[STEALS].setText("0");
	    tf[UNEASY].setText("1/-1");
	    tf[EXPOSES].setText("1");
	    tf[IMPASSE].setText("0");
	    tf[ADMIRES].setText("-1/1");
	    tf[OBSERVES].setText("1");
	    tf[ACCEPTS].setText("0");
	    tf[READY].setText("0");
	} else if (cmd == "Describe") {
	    double atti[] = new double[ATTITUDES*2];
	    if (getAttitude(atti)) {
		Log.append(describe(atti) + "\n");
	    }
	} else {
	    System.out.println(cmd);
	}
    }

    public void itemStateChanged(ItemEvent e)
    {
	// only used for "Lock" checkbox
	boolean unlock = e.getStateChange()!=java.awt.event.ItemEvent.SELECTED;
	Prefab.setEnabled(unlock);
	for (int xx=0; xx < ATTITUDES; xx++) {
	    tf[xx].setEditable(unlock);
	}
    }

    public int coarse(double val, int slices) {
	return (int) ((val+1)*slices / 2.0001);
    }

    private void _describe_pref(StringBuffer str, double per[], int ax) {
	NumberFormat nf = NumberFormat.getInstance();
	nf.setMaximumFractionDigits(2);

	double xx = per[ax*2];
	double yy = per[ax*2+1];
	if (ax == IMPASSE || ax == READY ||
	    java.lang.Math.abs(xx - yy) < .01)
	{
	    str.append(nf.format(xx) + ": ");
	} else {
	    str.append(nf.format(xx)+"/"+nf.format(yy)+": ");
	}
    }

    public String describe(double per[]) {
	StringBuffer str = new StringBuffer();

	int xx,yy;
	xx = coarse(per[DESTROYS*2], 3);
	yy = coarse(per[DESTROYS*2+1], 3);
	_describe_pref(str, per, DESTROYS);
	if (xx == 0) {
	    str.append("i refuse to kill");
	} else if (xx == 1) {
	    str.append("i can kill someone if there is no other choice");
	} else {
	    str.append("i savor a mortal challenge");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("i am terrified of my own death");
	    } else if (yy == 1) {
		str.append("i don't want to die");
	    } else {
		str.append("i'm willing to sacrifice my life");
	    }
	}
	str.append(".\n");

	xx = coarse(per[STEALS*2], 3);
	yy = coarse(per[STEALS*2+1], 3);
	_describe_pref(str, per, STEALS);
	if (xx == 0) {
	    str.append("i never think of stealing");
	} else if (xx == 1) {
	    str.append("i steal infrequently");
	} else {
	    str.append("Theft is my way of life");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("i assume my possessions are perfectly safe");
	    } else if (yy == 1) {
		str.append("i take reasonable care to secure my possessions");
	    } else {
		str.append("i am paranoid about thieves");
	    }
	}
	str.append(".\n");
    
	xx = coarse(per[UNEASY*2], 3);
	yy = coarse(per[UNEASY*2+1], 3);
	_describe_pref(str, per, UNEASY);
	if (xx == 0) {
	    str.append("i am confident that i know what i'm doing");
	} else if (xx == 1) {
	    str.append("i don't mind feeling like a beginner sometimes");
	} else {
	    str.append("Learning something new is great fun");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("i am careful not to pressure slow learners");
	    } else if (yy == 1) {
		str.append("sometime i will observe how your study is progressing");
	    } else {
		str.append("i keep a close eye on your progress");
	    }
	}
	str.append(".\n");
    
	xx = coarse(per[EXPOSES*2], 3);
	yy = coarse(per[EXPOSES*2+1], 3);
	_describe_pref(str, per, EXPOSES);
	if (xx == 0) {
	    str.append("Even if someone is doing something dumb, i mind my own business");
	} else if (xx == 1) {
	    str.append("i correct people when it is necessary");
	} else {
	    str.append("Criticism is devilishly fun");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("i am offended if someone points out a defect in my behavior");
	    } else if (yy == 1) {
		str.append("i can usual take criticism constructively");
	    } else {
		str.append("i love to be scolded");
	    }
	}
	str.append(".\n");
    
	xx = coarse(per[IMPASSE*2], 3);
	_describe_pref(str, per, IMPASSE);
	if (xx == 0) {
	    str.append("i avoid serious confrontation at any cost");
	} else if (xx == 1) {
	    str.append("i approach impasse with balanced concern");
	} else {
	    str.append("Debating is too much fun");
	}
	str.append(".\n");
    
	xx = coarse(per[ADMIRES*2], 3);
	yy = coarse(per[ADMIRES*2+1], 3);
	_describe_pref(str, per, ADMIRES);
	if (xx == 0) {
	    str.append("i haven't met anyone worth my admiration");
	} else if (xx == 1) {
	    str.append("i admire those who follows the saints");
	} else {
	    str.append("i admire everyone");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("you shouldn't admire me");
	    } else if (yy == 1) {
		str.append("i like to be admired on occation");
	    } else {
		str.append("you should worship me");
	    }
	}
	str.append(".\n");
    
	xx = coarse(per[OBSERVES*2], 3);
	yy = coarse(per[OBSERVES*2+1], 3);
	_describe_pref(str, per, OBSERVES);
	if (xx == 0) {
	    str.append("i am bored watching people in the spotlight");
	} else if (xx == 1) {
	    str.append("Sometimes i like to watch people in the spotlight");
	} else {
	    str.append("i love to watch someone who is in the spotlight");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("i am terrified of taking the spotlight");
	    } else if (yy == 1) {
		str.append("sometimes i enjoy being in the spotlight");
	    } else {
		str.append("i must be in spotlight");
	    }
	}
	str.append(".\n");
    
	xx = coarse(per[ACCEPTS*2], 3);
	yy = coarse(per[ACCEPTS*2+1], 3);
	_describe_pref(str, per, ACCEPTS);
	if (xx == 0) {
	    str.append("i refuse to accept you on your own terms");
	} else if (xx == 1) {
	    str.append("i accept reasonable requests");
	} else {
	    str.append("i am surrendered to your will");
	}
	if (xx != yy) {
	    str.append(", but ");
	    if (yy == 0) {
		str.append("i never ask for anything");
	    } else if (yy == 1) {
		str.append("i ask only for what i need");
	    } else {
		str.append("i am very demanding");
	    }
	}
	str.append(".\n");
    
	xx = coarse(per[READY*2], 5);
	_describe_pref(str, per, READY);
	if (xx == 0) {
	    str.append("i am depressed.");
	} else if (xx == 1) {
	    str.append("i am pessimistic.");
	} else if (xx == 2) {
	    str.append("i am ready!");
	} else if (xx == 3) {
	    str.append("i am optimistic.");
	} else {
	    str.append("i daydream about my love.");
	}
	str.append("\n");

	return str.toString();
    }
}
