all:
	cd compiler && $(MAKE) TARGET=$(TARGET) all
	cd compilerasm && $(MAKE) TARGET=$(TARGET) all
	cd editor && $(MAKE) TARGET=$(TARGET) all

clean:
	cd compiler && $(MAKE) TARGET=$(TARGET) clean
	cd compilerasm && $(MAKE) TARGET=$(TARGET) clean
	cd editor && $(MAKE) TARGET=$(TARGET) clean
	cd mkhdr && $(MAKE) TARGET=$(TARGET) clean
	cd tokenizertest && $(MAKE) TARGET=$(TARGET) clean
	cd parsertest && $(MAKE) TARGET=$(TARGET) clean
	cd resolvertest && $(MAKE) TARGET=$(TARGET) clean
	cd typechecktest && $(MAKE) TARGET=$(TARGET) clean
	cd icodetest && $(MAKE) TARGET=$(TARGET) clean
	cd memtest && $(MAKE) TARGET=$(TARGET) clean
	cd compilertestasm && $(MAKE) TARGET=$(TARGET) clean
