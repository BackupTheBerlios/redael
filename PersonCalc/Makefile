all:	compile

compile:
	javac PersonCalc.java

test:	compile
	appletviewer PersonCalc.html

clean:
	rm -f *.class

dist:
	name=PersonCalc-`date +%Y%m%d`; \
	mkdir $$name; \
	for f in `cat MANIFEST`; do cp $$f $$name/$$f; done; \
	tar -jcf $$name.tar.bz2 $$name; \
	rm -rf $$name
