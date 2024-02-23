all:
	cd loadprog && $(MAKE) TARGET=$(TARGET) all
	cd runtime && $(MAKE) TARGET=$(TARGET) all
	cd runtimelib && $(MAKE) TARGET=$(TARGET) all
	cd system && $(MAKE) TARGET=$(TARGET) all

clean:
	cd loadprog && $(MAKE) TARGET=$(TARGET) clean
	cd runtime && $(MAKE) TARGET=$(TARGET) clean
	cd runtimelib && $(MAKE) TARGET=$(TARGET) clean
	cd system && $(MAKE) TARGET=$(TARGET) clean
