configuration TestUserButtonAppC {

}

implementation {

	components TestUserButtonC;

	components MainC;
	TestUserButtonC.Boot -> MainC;

	components UserButtonC;
	TestUserButtonC.Get -> UserButtonC;
	TestUserButtonC.Notify -> UserButtonC;

	components LedsC;
	TestUserButtonC.Leds -> LedsC;

	components new TimerMilliC();
	TestUserButtonC.Timer -> TimerMilliC;
}
