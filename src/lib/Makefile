all:
	cd loadprog && $(MAKE) TARGET=$(TARGET) all
	cd runtime && $(MAKE) TARGET=$(TARGET) all
	cd screen && $(MAKE) TARGET=$(TARGET) all
	cd debug && $(MAKE) TARGET=$(TARGET) all
	cd sprites && $(MAKE) TARGET=$(TARGET) all
	cd spritemove && $(MAKE) TARGET=$(TARGET) all
	cd system && $(MAKE) TARGET=$(TARGET) all
	cd asmlib && $(MAKE) TARGET=$(TARGET) all
	cd demolib && $(MAKE) TARGET=$(TARGET) all
	cd time && $(MAKE) TARGET=$(TARGET) all

clean:
	cd loadprog && $(MAKE) TARGET=$(TARGET) clean
	cd runtime && $(MAKE) TARGET=$(TARGET) clean
	cd screen && $(MAKE) TARGET=$(TARGET) clean
	cd debug && $(MAKE) TARGET=$(TARGET) clean
	cd sprites && $(MAKE) TARGET=$(TARGET) clean
	cd spritemove && $(MAKE) TARGET=$(TARGET) clean
	cd system && $(MAKE) TARGET=$(TARGET) clean
	cd time && $(MAKE) TARGET=$(TARGET) clean
	cd asmlib && $(MAKE) TARGET=$(TARGET) clean
	cd demolib && $(MAKE) TARGET=$(TARGET) clean
